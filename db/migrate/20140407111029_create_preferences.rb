class CreatePreferences < ActiveRecord::Migration
  def change
    create_table :preferences do |t|
      t.float :package_tax_percentage

      t.timestamps
    end
  end
end
