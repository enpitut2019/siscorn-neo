class Author < ApplicationRecord
	has_many :paper_authors
	has_many :papers, through: :paper_authors
end
