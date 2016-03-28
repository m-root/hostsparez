class ChangeDefaultValueForDistance < ActiveRecord::Migration
  def change
    change_column :driver_settings, :distance, :float, :default => 99
  end
end
