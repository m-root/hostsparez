class Review < ActiveRecord::Base
  belongs_to :customer, :class_name => 'User'
  belongs_to :driver, :class_name => 'User'
  belongs_to :job
  attr_accessible :customer_id, :customer_type, :driver_id, :driver_type, :job_id, :subject, :description, :rating
  validates_presence_of :customer_id, :customer_type, :driver_id, :driver_type, :job_id, :subject, :description, :rating
end
