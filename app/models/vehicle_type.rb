class VehicleType < ActiveRecord::Base
  attr_accessible :name, :description, :user_id
  validates_presence_of :name, :description
  belongs_to :user
end
