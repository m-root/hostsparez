class Blog < ActiveRecord::Base
  attr_accessible :title, :description, :is_archived
  validates_presence_of :title, :description
end
