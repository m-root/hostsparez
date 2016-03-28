class AddHouseNoToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :house_no, :string
  end
end
