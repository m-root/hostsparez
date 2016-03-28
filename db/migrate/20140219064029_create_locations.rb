class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.integer :user_id
      t.text :address
      t.string :contact_person
      t.string :contact_phone
      t.string :nick_name
      t.text :comments
      t.text :address
      t.string :city
      t.string :state
      t.string :country
      t.integer :zip_code
      t.float :latitude
      t.float :longitude
      t.boolean :is_active
      t.timestamps
    end
  end
end
