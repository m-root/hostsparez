class TravellingTime < ActiveRecord::Base
  attr_accessible :user_id, :clock_in, :clock_out, :latitude, :longitude, :total_miles
  validates_presence_of :latitude, :longitude
  belongs_to :user
end
