class AddLatitudeAndLongitudeToTravellingTimes < ActiveRecord::Migration
  def change
    add_column :travelling_times, :latitude, :float
    add_column :travelling_times, :longitude, :float
    add_column :travelling_times, :total_miles, :float, :default => 0
  end
end
