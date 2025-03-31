class RenameTableBatchInstallationsToAppBatchInstallations < ActiveRecord::Migration[7.0]
  def change
    rename_table :batch_installations, :app_batch_installations
  end
end
