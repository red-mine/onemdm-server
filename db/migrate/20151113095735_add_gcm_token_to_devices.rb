class AddGcmTokenToDevices < ActiveRecord::Migration[7.0]
  def change
    add_column :devices, :gcm_token, :string
  end
end
