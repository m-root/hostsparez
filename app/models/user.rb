class User < ActiveRecord::Base
  before_create :generate_token
  #before_create :save_driver_id
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  has_many :locations
  has_many :payment_methods
  before_create :register_user
  #before_create :save_driver_id


  attr_accessible :device_token, :device_type, :latitude, :longitude,  :is_disabled, :email_sent_at, :send_email, :driver_id, :authentication_token,
                  :status, :facebook_uid, :customer_id, :first_name, :last_name, :email, :password, :date_of_birth, :company_name, :time_zone,
                  :password_confirmation, :remember_me, :profile_attributes

  #validates_presence_of :first_name, :last_name

  has_many :roles_users, :dependent => :destroy
  has_many :roles, :through => :roles_users

  has_many :customer_jobs, :class_name => "Job", :as => :customer
  has_many :driver_jobs, :class_name => "Job", :as => :driver

  has_many :customer_reviews, :class_name => "Review", :as => :customer
  has_many :driver_reviews, :class_name => "Review", :as => :driver
  has_one :profile
  accepts_nested_attributes_for :profile, :allow_destroy => true, :update_only => true
  has_many :sent_messages, :class_name => "Message", :as => :sender
  has_many :received_messages, :class_name => "Message", :as => :receiver

  #has_many :UserCouponCodes
  has_many :CouponCodeUser
  #has_many :user_coupon_codes


  #has_one :driver_phone_type, :class_name => "PhoneType", :as => :customer
  #has_one :driver_vehicle_type, :class_name => "VehicleType", :as => :customer

  #belongs_to :phone_type
  #belongs_to :vehicle_type

  has_many :packages, :dependent => :destroy
  has_many :phone_types, :dependent => :destroy
  has_many :vehicle_types, :dependent => :destroy

  has_one :driver_setting

  has_one :customer_setting

  has_many :transaction_histories

  has_many :travelling_times, :order => "id ASC"

  has_many :billings, :as => :owner

  has_many :file_claims


  has_one :promotion_code, :class_name => "CouponCode", :as => :promotion_code_user




  def clone_customer_setting(customer)
    customer_setting = CustomerSetting.new
    customer_setting.user_id = customer.id
    customer_setting.save
  end

  def filtered_distance(user)
    puts "PPP", user.inspect
    setting = DriverSetting.where(:user_id => user.id).first
    if setting.distance == -1 or setting.distance >= 100
      return true, 0
    else
      return false, setting.distance
    end
  end

  def active_for_authentication?
    if self.driver?
      !self.is_disabled and self.status == 'active'
    elsif self.customer?
      self.status == 'active'
    else
      true
    end
    #puts "CCC", !self.is_disabled
    #super && self.driver? && !self.is_disabled
  end

  def register_user
    return true if self.super_admin?
    return true if self.driver?
    self.customer? ? register_customer : false
  end

  def save_driver_id
    self.driver_id = loop do
      random_token = SecureRandom.hex(4)
      break random_token unless User.exists?(:driver_id => random_token)
      update_attributes!(:driver_id => random_token)
    end
    #random_string = SecureRandom.hex(4)
    #break random_string unless User.exists?(:driver_id => random_string)
    #update_attributes!(:driver_id => random_string)
  end

  def complete_address
    "#{profile.address}, #{profile.city},#{profile.state},#{profile.zip_code}"
  end

  def register_customer
    puts "IIIIIIIIIIIIIIIIIIIII"
    brain_customer = Braintree::Customer.create(
        :first_name => self.first_name,
        :last_name => self.last_name,
        :email => self.email
    )
    if brain_customer.success?
      puts "PPPPPPPPPPPPPPPPPPPPPPPPP"
      self.customer_id = brain_customer.customer.id
      return true
    else
      codes = []
      brain_customer.errors.each { |a| codes << a.code }
      self.errors.add("Braintree:", codes.join(","))
      return false
    end
  end

  def driver_rating
    driver_rating = 0
    driver_reviews.each do |driver_review|
      driver_rating += driver_review.rating
    end
    if driver_rating > 0
      driver_rating = driver_rating/driver_reviews.size
    end
    if driver_rating > 0 and driver_rating <= 0.5
      driver_rating = 0.5
    elsif driver_rating > 0.5 and driver_rating <= 1
      driver_rating = 1
    elsif driver_rating > 1 and driver_rating <= 1.5
      driver_rating = 1.5
    elsif driver_rating > 1.5 and driver_rating <= 2
      driver_rating = 2
    elsif driver_rating > 2 and driver_rating <= 2.5
      driver_rating = 2.5
    elsif driver_rating > 2.5 and driver_rating <= 3
      driver_rating = 3
    elsif driver_rating > 3 and driver_rating <= 3.5
      driver_rating = 3.5
    elsif driver_rating > 3.5 and driver_rating <= 4
      driver_rating = 4
    elsif driver_rating > 4 and driver_rating <= 4.5
      driver_rating = 4.5
    elsif driver_rating > 4.5 and driver_rating <= 5
      driver_rating = 5
    end
    driver_rating_whole = 0
    driver_rating_part = 0
    if driver_rating > 0
      driver_rating_parts = driver_rating.to_s.split(".")
      driver_rating_whole = driver_rating_parts[0]
      if driver_rating_parts[1].blank?
        driver_rating_part = 0
      else
        driver_rating_part = 0.5
      end
    end
    return driver_rating_whole, driver_rating_part
  end

  def average_rating
    rating = 0
    driver_reviews.each do |review|
      rating = rating + review.rating
    end
    if driver_reviews.size != 0
      rating = rating/driver_reviews.size
    end
    return rating
  end

  def total_time
    total_time = 0
    travelling_times.each do |travelling_time|
      if travelling_time.clock_in.present? and travelling_time.clock_out.present?
        total_time += ((travelling_time.clock_out - travelling_time.clock_in) / 3600)
      end
    end
    return total_time.round(4)
  end




  def total_distance
    distance = 0
    unless driver_jobs.where(:status => "delivered").blank?
      driver_jobs.where(:status => "delivered").each do |job|
        unless job.distance_value.blank?
          distance += job.distance_value
        end
      end
    end
    return distance.round(4)
  end

  #def is_clock_in
  #  if travelling_times.blank?
  #    is_clock_in = false
  #  else
  #    if travelling_times.last.clock_out.blank?
  #      is_clock_in = true
  #    else
  #      is_clock_in = false
  #    end
  #  end
  #  return is_clock_in
  #end

  def delivered_jobs
    driver_jobs.where(:status => "delivered", :is_driver_payment_sent => false)
  end

  def self.total_delivered_jobs
    Job.where(:status => "delivered")
  end

  def driver?
    roles.include?(Role.find_by_name("driver"))
  end

  def self.drivers
    User.includes(:roles).where("roles.name" => "driver")
  end

  def self.active_drivers
    User.includes(:roles).where("roles.name" => "driver", "users.is_disabled" => false)
  end

  def self.in_active_drivers
    User.includes(:roles).where("roles.name" => "driver", "users.is_disabled" => true)
  end

  def self.customers
    User.includes(:roles).where("roles.name" => "customer")
  end

  def role
    return "super_admin" if super_admin?
    return "customer" if customer?
    return "driver" if driver?
  end

  def super_admin?
    roles.include?(Role.find_by_name("super_admin"))
  end

  def customer?
    roles.include?(Role.find_by_name("customer"))
  end

  def driver?
    roles.include?(Role.find_by_name("driver"))
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def approved?
    self.status == "approved"
  end

  def is_active
    self.is_disabled == false
  end


  def self.find_for_facebook_oauth(auth, signed_in_resource=nil)
    user = User.where(:facebook_uid => auth.uid).first
    unless user
      user_with_same_email = User.where(:email => auth.info.email).first
      if user_with_same_email
        user_with_same_email.update_attributes(:facebook_uid => auth.uid)
        #user_with_same_email.skip_confirmation!
        return user_with_same_email
      else
        user = User.new(:first_name => auth.extra.raw_info.name,
                        :first_name => auth.info.first_name,
                        :last_name => auth.info.last_name,
                        :facebook_uid => auth.uid,
                        :email => auth.info.email,
                        :password => Devise.friendly_token[0, 20]
        )
        user.roles << Role.find_by_name("customer")
        user.status = 'active'
        user.save
        return user
      end
    end
    puts "FB hash", auth
    user
  end


  def payment_method_json(user)
    user.payment_methods.where(:is_deleted => false).blank? ? [] : user.payment_methods.where(:is_deleted => false).map{|pm| {:id => pm.id, :holder_name => pm.holder_name, :month => pm.month, :year => pm.year, :cvv => pm.cvv, :card_number => pm.mask_number(pm.token), :nick_name => pm.nick_name, :is_active => pm.is_active, :token => pm.token, :card_type => pm.card_type, :billing_address_id => pm.billing_address.blank? ? "" : pm.billing_address.id}}
  end

  def customer_json(u, new_user=false)
    {
        :id => u.id,
        :email => u.email,
        :token => u.authentication_token,
        :first_name => u.first_name,
        :last_name => u.last_name,
        :status => u.status,
        :created_at => u.created_at,
        :updated_at => u.updated_at,
        :new_user => new_user,
        :profile => u.profile.blank? ? nil : customer_profile_json(u.profile),
        :reviews => u.customer_reviews.map { |review| review_json(review) },
        :customer_setting => {:id => u.customer_setting.id, :user_id => u.customer_setting.user_id, :is_push_notification => u.customer_setting.is_push_notification, :is_email_notification => u.customer_setting.is_email_notification, :is_text_notification => u.customer_setting.is_text_notification}
    }
  end


  def customer_profile_json(p)
    {
        :phone_number => p.phone_number,
        :address => p.address,
        :city => p.city,
        :state => p.state,
        :zip_code => p.zip_code,
        :picture_url => p.asset.blank? ? nil : "#{p.asset.avatar.url(:thumb)}"
    }
  end

  def review_json(review)
    {:id => review.subject,
     :description => review.description,
     :rating => review.rating
    }
  end



  protected

  def generate_token
    self.authentication_token = loop do
      random_token = SecureRandom.urlsafe_base64(nil, false)
      break random_token unless User.exists?(:authentication_token => random_token)
      update_attributes!(:authentication_token => random_token)
    end
  end


end
