class CreateCaZipCodes < ActiveRecord::Migration
  def change
    create_table :ca_zip_codes do |t|
      t.string :code
      t.string :area_name

      t.timestamps
    end
  end
end
