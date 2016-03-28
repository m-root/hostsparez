class AddIsWebToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :is_web, :boolean, :default => false
  end
end
