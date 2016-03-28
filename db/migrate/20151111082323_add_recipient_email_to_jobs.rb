class AddRecipientEmailToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :recipient_email, :string
    add_column :jobs, :pick_up_email, :string
  end
end
