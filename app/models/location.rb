class Location < ActiveRecord::Base
  #before_create :check_unique_address
  attr_accessible :address, :contact_phone, :nick_name, :comments, :contact_person, :user_id, :latitude, :longitude,
                  :city, :state, :country, :address, :house_no, :zip_code, :is_active, :contact_method_type, :contact_email
  belongs_to :user
  has_many :sender_location_jobs, :class_name => "Job", :as => :sender_location
  has_many :receiver_location_jobs, :class_name => "Job", :as => :receiver_location
  validates_presence_of :address, :contact_person, :country
  validates_presence_of :city, :message => "Pick location and Dest location must contain city"
  validates_presence_of :state, :message => "Pick location and Dest location must contain state"
  geocoded_by :complete_address

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  VALID_PHONE_REGEX = /\d{3}-\d{3}-\d{4}/

  @contact_method_type = ""


  #before_validation :validate_phone_and_email

  after_validation :geocode


  def complete_address
    "#{self.address}"
  end

  def validate_phone_and_email
    if contact_phone.present?
      if contact_method_type == 1
        if contact_phone.match(/\d{3}-\d{3}-\d{4}/).blank?
          self.errors.add(" ", "Phone format is incorrect")
        end
      else
        if contact_phone.match(/\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i).blank?
          self.errors.add(" ", "Email format is incorrect")
        end
      end
    end
  end

  #def check_unique_address
  #  existing_location = Location.where(:user_id => self.user_id).select { |location| location.latitude == latitude and location.longitude == longitude }
  #  existing_location.blank? ? (return true) : (self.errors.add(" ", "You cannot add same address twice please login and go to my locations") and return false)
  #end


end
