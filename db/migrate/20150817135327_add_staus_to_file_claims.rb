class AddStausToFileClaims < ActiveRecord::Migration
  def change
    add_column :file_claims, :status, :string
  end
end
