class FileClaim < ActiveRecord::Base
  belongs_to :job
  belongs_to :user
  attr_accessible :job_id, :description, :user_id, :subject, :status
  validates_presence_of :description, :subject, :user_id
  validates_presence_of :job_id, :message => "Package is required"
end
