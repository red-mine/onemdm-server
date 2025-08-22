class AddSerialNoToDevices < ActiveRecord::Migration[7.0]
  def change
    add_column :devices, :serial_no, :string
  end
end
