class AddDiscountToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :discount, :float
  end
end
