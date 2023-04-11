class AddClientVersionAndOsVersionToDevices < ActiveRecord::Migration[7.0]
  def change
    add_column :devices, :client_version, :string
    add_column :devices, :os_version, :string
  end
end
