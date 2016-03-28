class Job < ActiveRecord::Base
  after_create :save_code

  before_validation :geocode
  geocoded_by :complete_address


  attr_accessible :job_tax, :delivered_date, :driver_id, :status, :driver_type, :customer_id, :customer_type, :sender_location_id, :sender_location_type, :receiver_location_id,
                  :receiver_location_type, :package_id, :pick_up_time, :amount, :distance_text, :time_text, :distance_value, :time_value, :job_code, :pick_up_address, :pick_up_phone, :pick_up_comment,
                  :destination_address, :recipient_name, :recipient_phone, :recipient_comment, :latitude, :longitude, :dest_latitude, :dest_longitude, :asset, :asset_attributes, :payment_method_id, :billing_address_id, :discount, :is_time_out, :sender_suit_number, :recipient_suit_number, :accepted_time, :is_web


  belongs_to :customer, :class_name => 'User'
  belongs_to :driver, :class_name => 'User'
  belongs_to :sender_location, :class_name => 'Location'
  belongs_to :receiver_location, :class_name => 'Location'
  belongs_to :package
  has_one :transaction_history
  has_many :activity_logs
  validates_presence_of :package_id, :message => "Please Select Package Size"
  validates_presence_of :customer_id, :customer_type, :sender_location_id, :sender_location_type, :receiver_location_id, :receiver_location_type, :pick_up_time, :amount, :distance_text, :time_text, :distance_value, :time_value,
                        :pick_up_address, :destination_address, :recipient_name, :latitude, :longitude, :dest_latitude, :dest_longitude

  has_one :asset, :as => :owner, :dependent => :destroy
  accepts_nested_attributes_for :asset, :allow_destroy => true

  belongs_to :payment_method


  def complete_address
    "#{self.pick_up_address}"
  end


  def save_code
    random_string = SecureRandom.hex(4)
    update_attributes!(:job_code => random_string)
  end

  #def self.nearby_jobs(lat, long, distance)
  #  jobs_array = []
  #  jobs = []
  #  locations = Location.near([lat, long], 10)
  #  locations.each do |location|
  #    jobs_array = jobs_array + location.sender_location_jobs
  #    jobs_array.each do |job|
  #      unless job.blank? or job.sender_location.blank?
  #        if  job.status == "available"
  #          jobs << job
  #        end
  #      end
  #    end
  #  end
  #  return jobs.uniq_by { |j| j.id }
  #end


  def self.nearby_jobs(lat, long, user)
    filter = user.filtered_distance(user)
    if filter[0]
      jobs = Job.all
    else
      puts "CCCCC", filter[1].inspect
      jobs = Job.near([lat, long], filter[1])
    end
    jobs = jobs.select { |j| j.status == 'available'}
    return jobs
  end

  def self.get_zip_code(long_lat)
    #abc = Geocoder.search(long_lat)
    #zip = ""
    #unless abc.blank?
    #  abc[0].address_components.each do |address_component|
    #    puts "CCC", address_component.inspect
    #    address_component["types"].each do |type|
    #      if type == "postal_code"
    #        zip = address_component["short_name"]
    #      end
    #    end
    #  end
    #end
    #return zip
    return long_lat.to_zip
  end

  def self.zip_code_existing(zip_code1)
    puts "ZZZZ", zip_code1
    #puts "ZZZZggg", zip_code2
    is_exist = false
    if zip_code1.present?
      code1 = CaZipCode.find_by_code(zip_code1)
      #code2 = CaZipCode.find_by_code(zip_code2)
      puts "CCC", code1
      #puts "CCCDD", code2
      if code1.present?
        is_exist = true
      end
    end
    return is_exist
  end


  def get_status
    if status == "unavailable"
      "Unavailable"
    elsif status == "available"
      "Available"
    elsif status == "accepted"
      "Awaiting Pickup"
    elsif status == "picked"
      "Picked"
    elsif status == "delivered"
      "Delivered"
    end
  end

  def filter_pick_address
    array = self.pick_up_address.split(",")
    #array.pop
    return array.map(&:to_s).join(', ')
  end

  def filter_dest_address
    array = self.destination_address.split(",")
    #array.pop
    return array.map(&:to_s).join(', ')
  end

  def customer_job_json(j)
    puts "JJJ", j.inspect
    puts "JJJDDDD", j.transaction_history.inspect
    {:id => j.id,
     :job_code => j.job_code,
     :status => j.status,
     :customer_type => j.customer_type,
     :driver_id => j.driver_id,
     :driver_type => j.driver_type,
     :driver_name => j.driver.blank? ? nil : j.driver.full_name,
     :driver_phone => j.driver.blank? ? nil : j.driver.profile.blank? ? nil : j.driver.profile.phone_number,
     :driver_image => j.status == "delivered" ? j.asset.blank? ? nil : j.asset.avatar.url(:thumb) : nil,
     :status => j.status,
     :distance_text => j.distance_text,
     :time_text => j.time_text,
     :pick_up_time => j.pick_up_time.in_time_zone(j.customer.time_zone).strftime("%d %b, %Y-%l:%M %p"),
     :delivery_time => (j.pick_up_time + j.time_value.minute).in_time_zone(j.customer.time_zone).strftime("%d %b, %Y-%l:%M %p"),
     :is_active => j.is_active,
     :amount => j.transaction_history.blank? ? j.amount : j.transaction_history.amount,
     :pick_up_address => j.filter_pick_address,
     :pick_up_phone => j.customer.blank? ? nil : j.customer.profile.blank? ? nil : j.customer.profile.phone_number,
     :pick_up_comment => j.pick_up_comment,
     :destination_address => j.filter_dest_address,
     :recipient_name => j.recipient_name,
     :recipient_phone => j.recipient_phone,
     :recipient_comment => j.recipient_comment,
     :latitude => j.latitude,
     :longitude => j.longitude,
     :dest_latitude => j.dest_latitude,
     :dest_longitude => j.dest_longitude,
     :job_tax => j.job_tax,
     :is_read => j.is_read,
     :sender => j.customer.blank? ? nil :
         {
             :id => j.customer.id,
             :first_name => j.customer.first_name,
             :last_name => j.customer.last_name,
             :status => j.customer.status,
             :email => j.customer.email,
             :phone => j.customer.profile.blank? ? nil : j.customer.profile.phone_number
         },
     :package => j.package.blank? ? nil : {:id => j.package.id, :name => j.package.name.capitalize},
     :car_number => j.payment_method.blank? ? nil : j.payment_method.card_number,
     :car_type => j.payment_method.blank? ? nil : j.payment_method.card_type,
    }
  end

  def get_push_notify_drivers(job)
    drivers = []
    User.drivers.each do |driver|
      unless driver.travelling_times.last.blank?
        if driver.travelling_times.last.clock_out.blank?
          filter = driver.filtered_distance(driver)
          if filter[0]
            drivers << driver.device_token if driver.device_token
          else
            distance = job.distance_to([driver.travelling_times.last.latitude, driver.travelling_times.last.longitude], units = :mi)
            if driver.driver_setting.distance >= distance and driver.status == 'active'and driver.is_disabled == false
              drivers << driver.device_token if driver.device_token
            end
          end
        end
      end
    end
    return drivers
  end

  def get_email_notify_drivers(job)
    drivers = []
    User.drivers.each do |driver|
      filter = driver.filtered_distance(driver)
      if filter[0]
        drivers << driver
      else
        unless driver.travelling_times
          distance = job.distance_to([driver.travelling_times.last.latitude.blank? ? 0 : driver.travelling_times.last.latitude, driver.travelling_times.last.longitude.blank? ? 0 : driver.travelling_times.last.longitude], units = :mi)
          if driver.driver_setting.distance >= distance and driver.status == 'active' and is_disabled == false
            drivers << driver
          end
        end
      end
    end
    return drivers
  end



end
