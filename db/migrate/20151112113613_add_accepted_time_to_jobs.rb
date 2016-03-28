class AddAcceptedTimeToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :accepted_time, :datetime
  end
end
