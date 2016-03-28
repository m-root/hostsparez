class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.integer :customer_id
      t.string :customer_type
      t.integer :driver_id
      t.string :driver_type
      t.integer :sender_location_id
      t.string :sender_location_type
      t.integer :receiver_location_id
      t.string :receiver_location_type
      t.integer :package_id
      t.string :status, :default => "unavailable"
      t.datetime :pick_up_time
      t.datetime :delivery_time
      t.boolean :is_active
      t.float :amount
      t.string :distance_text
      t.string :time_text
      t.integer :distance_value
      t.integer :time_value
      t.string :job_code

      t.timestamps
    end
  end
end
