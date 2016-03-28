class CreateBillings < ActiveRecord::Migration
  def change
    create_table :billings do |t|
      t.string :document_file_name
      t.string :document_content_type
      t.integer :document_file_size
      t.integer :owner_id
      t.string :owner_type
      t.date :billing_month
      t.timestamps
    end
  end
end