class AddIsReadToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :is_read, :boolean, :default => false
  end
end
