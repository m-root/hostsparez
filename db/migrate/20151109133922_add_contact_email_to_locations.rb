class AddContactEmailToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :contact_email, :string
  end
end
