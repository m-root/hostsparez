class AddParentIdAndParentTypeToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :parent_id, :integer
    add_column :messages, :parent_type, :string
  end
end
