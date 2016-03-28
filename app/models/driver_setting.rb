class DriverSetting < ActiveRecord::Base

  attr_accessible :user_id, :is_job_push, :is_rating_push, :is_message_push, :is_job_email, :is_rating_email, :is_message_email, :distance_push, :distance_email, :distance
end
