class AddDistanceToDriverSettings < ActiveRecord::Migration
  def change
    add_column :driver_settings, :distance, :float, :default => -1
  end
end
