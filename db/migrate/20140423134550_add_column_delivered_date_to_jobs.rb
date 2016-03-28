class AddColumnDeliveredDateToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :delivered_date, :datetime
  end
end
