class AddIsTimeOutToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :is_time_out, :boolean, :default => false
  end
end
