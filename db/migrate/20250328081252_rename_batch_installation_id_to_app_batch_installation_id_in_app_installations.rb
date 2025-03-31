class RenameBatchInstallationIdToAppBatchInstallationIdInAppInstallations < ActiveRecord::Migration[7.0]
  def change
    rename_column :app_installations, :batch_installation_id, :app_batch_installation_id
  end
end
