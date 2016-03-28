class CreateAssets < ActiveRecord::Migration
  def change
    create_table :assets do |t|
      t.integer :owner_id
      t.string :owner_type
      t.attachment :avatar

      t.timestamps
    end
  end
end
