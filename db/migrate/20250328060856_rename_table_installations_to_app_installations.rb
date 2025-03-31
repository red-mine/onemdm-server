class RenameTableInstallationsToAppInstallations < ActiveRecord::Migration[7.0]
  def change
    rename_table :installations, :app_installations
  end
end
