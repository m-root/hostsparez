class AddSubjectToFileClaims < ActiveRecord::Migration
  def change
    add_column :file_claims, :subject, :string
  end
end
