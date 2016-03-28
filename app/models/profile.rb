class Profile < ActiveRecord::Base
  attr_accessible :user_id, :phone_number, :phone_type_id, :vehicle_type_id, :address, :city, :state, :zip_code, :asset_attributes
  has_one :asset, :as => :owner, :dependent => :destroy
  accepts_nested_attributes_for :asset, :allow_destroy => true
  belongs_to :phone_type
  belongs_to :vehicle_type
  validates :phone_number, :format => /\d{3}-\d{3}-\d{4}/, :allow_blank => true
end
