class CreateReviews < ActiveRecord::Migration
  def change
    create_table :reviews do |t|
      t.integer :customer_id
      t.string :customer_type
      t.integer :driver_id
      t.string :driver_type
      t.integer :job_id
      t.string :subject
      t.string :description
      t.float :rating

      t.timestamps
    end
  end
end
