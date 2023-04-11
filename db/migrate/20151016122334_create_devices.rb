class CreateDevices < ActiveRecord::Migration[7.0]
  def change
    create_table :devices do |t|
      t.string :model
      t.string :unique_id
      t.string :imei_number
      t.string :access_token

      t.timestamps null: false
    end
  end
end
