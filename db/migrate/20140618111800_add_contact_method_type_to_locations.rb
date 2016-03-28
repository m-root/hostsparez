class AddContactMethodTypeToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :contact_method_type, :integer
  end
end
