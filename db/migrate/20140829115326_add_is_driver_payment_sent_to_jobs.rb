class AddIsDriverPaymentSentToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :is_driver_payment_sent, :boolean, :default => false
  end
end
