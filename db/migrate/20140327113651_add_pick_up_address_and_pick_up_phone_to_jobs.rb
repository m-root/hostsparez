class AddPickUpAddressAndPickUpPhoneToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :pick_up_address, :text
    add_column :jobs, :pick_up_phone, :string
    add_column :jobs, :pick_up_comment, :text
    add_column :jobs, :destination_address, :text
    add_column :jobs, :recipient_name, :string
    add_column :jobs, :recipient_phone, :string
    add_column :jobs, :recipient_comment, :text
    add_column :jobs, :latitude, :float
    add_column :jobs, :longitude, :float
    add_column :jobs, :dest_latitude, :float
    add_column :jobs, :dest_longitude, :float
  end
end
