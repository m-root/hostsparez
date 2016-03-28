class AddDriverCodeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :driver_code, :string
  end
end
