## This file should contain all the record creation needed to seed the database with its default values.
## The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
##
## Examples:
##
##   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
##   Mayor.create(name: 'Emanuel', city: cities.first)
##
##
#
def create_user
  puts "Deleting existing roles..."
  roles = Role.all
  roles.each { |role| role.destroy } if roles.present?

  puts "Creating roles..."
  %w(super_admin customer driver).each do |name|
    Role.create!(:name => name)
  end

  puts "Deleting existing users.."
  users = User.all
  users.each { |user| user.destroy } if users.present?

  puts "Creating default super super_admin ...."
  super_admin = User.new(:email => "super_admin@hostsparez.com",
                         :password => "12345678",
                         :password_confirmation => "12345678",
                         :first_name => "Super",
                         :last_name => "Admin",
  )
  super_admin.roles << Role.find_by_name("super_admin")
  super_admin.save!

  puts "Creating default customer"
  customer = User.new(:email => "customer@ziply.com",
                      :password => "12345678",
                      :password_confirmation => "12345678",
                      :first_name => "First",
                      :last_name => "Customer"


  )
  customer.profile = Profile.new(
      :phone_number => "111-111-1111",
      :address => "STC",
      :city => "Lahore",
      :state => "Punjab",
      :zip_code => "54000")

  customer.roles << Role.find_by_name("customer")
  customer.save!

  seed_package(super_admin.id)
  phone_id = create_phone_type(super_admin.id)
  vehicle_id = create_vehicle_type(super_admin.id)
  seed_driver_setting
  puts "Creating default driver"
  driver = User.new(:email => "driver@hostsparez.com",
                    :password => "12345678",
                    :password_confirmation => "12345678",
                    :first_name => "First",
                    :last_name => "Driver"

  )
  driver.profile = Profile.new(
      :phone_type_id => phone_id,
      :vehicle_type_id => vehicle_id,
      :phone_number => "111-111-1111",
      :address => "STC",
      :city => "Lahore",
      :state => "Punjab",
      :zip_code => "54000")
  driver.roles << Role.find_by_name("driver")
  driver.save!
  DriverSetting.create!(:user_id => driver.id, :is_job_push => true, :is_rating_push => true, :is_message_push => true, :is_job_email => true, :is_rating_email => true, :is_message_email => true, :distance_push => 5, :distance_email => 5)
end

def seed_package(user_id)
  puts "Deleting existing packages.."
  packages = Package.all
  packages.each { |package| package.destroy } if packages.present?
  Package.create!(:name => "Small", :weight => 5, :description => "7x3.5", :amount => 10, :user_id => user_id, :basic_fee => 5, :cost_per_mile => 1.20, :min_fare => 6.20)
  Package.create!(:name => "Medium", :weight => 10, :description => "11x14", :amount => 20, :user_id => user_id, :basic_fee => 7, :cost_per_mile => 1.25, :min_fare => 8.25)
  Package.create!(:name => "Large", :weight => 20, :description => "10x8x6", :amount => 30, :user_id => user_id, :basic_fee => 35, :cost_per_mile => 1.40, :min_fare => 36.40)
  Package.create!(:name => "X-Large", :weight => 40, :description => "24x24x12", :amount => 40, :user_id => user_id, :basic_fee => 40, :cost_per_mile => 1.50, :min_fare => 41.50)
end


def create_phone_type(user_id)
  puts "Deleting existing phone types.."
  phone_type = PhoneType.all
  phone_type.each { |phone| phone.destroy } if phone_type.present?
  phone = PhoneType.create!(:name => "I phone", :description => "I phone", :user_id => user_id)
  PhoneType.create!(:name => "Android", :description => "Android", :user_id => user_id)
  PhoneType.create!(:name => "Windows", :description => "Windows", :user_id => user_id)
  return phone.id
end

def create_vehicle_type(user_id)
  puts "Deleting existing vehicles.."
  vehicle_types = VehicleType.all
  vehicle_types.each { |vehicle_type| vehicle_type.destroy } if vehicle_types.present?
  vehicle = VehicleType.create!(:name => "BUS", :description => "BUS", :user_id => user_id)
  VehicleType.create!(:name => "TRUCK", :description => "TRUCK", :user_id => user_id)
  VehicleType.create!(:name => "CAR", :description => "CAR", :user_id => user_id)
  return vehicle.id
end

def seed_driver_setting
  puts "Deleting existing driver setting.."
  driver_settings = DriverSetting.all
  driver_settings.each { |driver_setting| driver_setting.destroy } if driver_settings.present?
  DriverSetting.create!(:is_job_push => true, :is_rating_push => true, :is_message_push => true, :is_job_email => true, :is_rating_email => true, :is_message_email => true, :distance_push => 5, :distance_email => 5)
end


def seed_preferences
  Preferences.create!(:package_tax_percentage => 5)
end
#
#
create_user
seed_preferences
user = User.find(1)
brain_customer = Braintree::Customer.create(
    :first_name => user.first_name,
    :last_name => user.last_name,
    :email => user.email
)
if brain_customer.success?
  user.customer_id = brain_customer.customer.id
  user.save
  puts "saved"
  #return true
else
  puts "CCC", errors
end
