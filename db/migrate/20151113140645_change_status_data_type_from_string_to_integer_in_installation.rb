class ChangeStatusDataTypeFromStringToIntegerInInstallation < ActiveRecord::Migration[7.0]
  def change
    change_column :installations, :status, :integer
  end
end
