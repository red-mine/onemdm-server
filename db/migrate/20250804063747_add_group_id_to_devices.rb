class AddGroupIdToDevices < ActiveRecord::Migration[7.0]
  def change
    add_column :devices, :group_id, :integer
    add_index :devices, :group_id
    add_foreign_key :devices, :groups
  end
end
