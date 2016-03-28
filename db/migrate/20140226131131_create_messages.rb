class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.integer :sender_id
      t.string :sender_type
      t.integer :receiver_id
      t.string :receiver_type
      t.string :subject
      t.text :description
      t.string :status
      t.string :message_type
      t.integer :job_id

      t.timestamps
    end
  end
end
