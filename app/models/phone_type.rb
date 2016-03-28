class PhoneType < ActiveRecord::Base
  attr_accessible :user_id, :name, :description
  validates_presence_of :name, :description
  belongs_to :user
end
