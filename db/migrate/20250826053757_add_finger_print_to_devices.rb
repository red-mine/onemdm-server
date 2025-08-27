class AddFingerPrintToDevices < ActiveRecord::Migration[7.0]
  def change
    add_column :devices, :finger_print, :string
  end
end
