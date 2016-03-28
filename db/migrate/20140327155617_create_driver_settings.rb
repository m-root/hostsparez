class CreateDriverSettings < ActiveRecord::Migration
  def change
    create_table :driver_settings do |t|
      t.integer :user_id
      t.boolean :is_job_push
      t.boolean :is_rating_push
      t.boolean :is_message_push
      t.boolean :is_job_email
      t.boolean :is_rating_email
      t.boolean :is_message_email
      t.float :distance_push
      t.float :distance_email


      t.timestamps
    end
  end
end
