class CreateTravellingTimes < ActiveRecord::Migration
  def change
    create_table :travelling_times do |t|
      t.integer :user_id
      t.datetime :clock_in
      t.datetime :clock_out

      t.timestamps
    end
  end
end
