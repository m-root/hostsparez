class CreateBlogs < ActiveRecord::Migration
  def change
    create_table :blogs do |t|
      t.string :title
      t.text :description
      t.boolean :is_archived, :default => false

      t.timestamps
    end
  end
end
