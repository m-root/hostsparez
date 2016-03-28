class ChangeIsDisabledDefaultValue < ActiveRecord::Migration
  def change
    change_column :users, :is_disabled, :boolean, :default => true
  end
end
