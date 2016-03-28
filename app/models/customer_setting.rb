class CustomerSetting < ActiveRecord::Base
  attr_accessible :user_id, :is_push_notification, :is_email_notification, :is_text_notification
end
