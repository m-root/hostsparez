class CreateFileClaims < ActiveRecord::Migration
  def change
    create_table :file_claims do |t|
      t.integer :job_id
      t.string :description
      t.integer :user_id

      t.timestamps
    end
  end
end
