class Message < ActiveRecord::Base
  attr_accessible :sender_id, :sender_type, :receiver_id, :receiver_type, :subject, :description, :status, :message_type,
                  :job_id, :sender_deleted, :receiver_deleted, :parent_id, :parent_type
  validates_presence_of :sender_id, :sender_type, :receiver_id, :receiver_type, :subject, :description, :status, :job_id
  belongs_to :sender, :class_name => 'User'
  belongs_to :receiver, :class_name => 'User'
  belongs_to :job

  has_many :message_children, :class_name => "Message", :as => :parent
  belongs_to :parent, :polymorphic => true

  def self.full_messages(user_id)
    all_messages = []
    receiver_messages = Message.where(:receiver_id => user_id)
    sent_messages = Message.where(:sender_id => user_id)
    receiver_messages.map { |receiver_message| all_messages << receiver_message }
    sent_messages.map { |sent_message| all_messages << sent_message }
    unless all_messages.blank?
      all_messages = all_messages.sort_by { |m| m.id }
    end
    return all_messages
  end

end
