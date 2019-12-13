require 'rexml/document'
# require "google/cloud/translate"

class SearchController < ApplicationController
    def get_xml
        require 'net/http'
        require 'uri'
        search_word = URI.encode_www_form_component(params['search_word'])
        
        url = URI.parse("http://export.arxiv.org/api/query?search_query=abs:#{search_word}&start=0&max_results=30")
        res = Net::HTTP.get_response(url)
        body = res.body
        papers = parseXML(body)

        render(json: papers)
    end

    private
    def parseXML(xmlString)
        papers = Array.new
        doc = REXML::Document.new(xmlString)
        doc.elements.each('//entry') do |e|
            title = e.elements['title'] ? e.elements['title'].text : ''
            arxiv_id = e.elements['id'] ? e.elements['id'].text : ''
            abstract = e.elements['summary'] ? e.elements['summary'].text : ''
            url = e.elements['link[@type="text/html"]'] ? e.elements['link[@type="text/html"]'].attributes['href'] : ''
            url_pdf = e.elements['link[@type="application/pdf"]'] ? e.elements['link[@type="application/pdf"]'].attributes['href'] : ''
            published_at = e.elements['published'] ? e.elements['published'].text : ''
            journal = e.elements['arxiv:journal_ref'] ? e.elements['arxiv:journal_ref'].text : ''
            author_names = Array.new
            e.elements.each('author') do |authors_elements|
                author_name = authors_elements.elements['name'] ? authors_elements.elements['name'].text : ''
                author_names.push(author_name)
            end
            paper = Paper.find_by(:aixiv_id => arxiv_id)
            if paper.nil? then
              paper = Paper.create!(title: title, url: url, pdf_url: url_pdf, journal: journal, abstract: abstract, aixiv_id: arxiv_id, published_at: DateTime.parse(published_at))
              author_names.map do |author_name|
                paper.authors.create!(name: author_name)
              end
            end
            papers.push(paper)
        end

        return papers
    end
end
