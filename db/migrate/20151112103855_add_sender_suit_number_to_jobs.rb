class AddSenderSuitNumberToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :sender_suit_number, :string
    add_column :jobs, :recipient_suit_number, :string
  end
end
