class RenamePackageNameToFingerPrintInPackages < ActiveRecord::Migration[7.0]
  def change
    rename_column :pkgs, :package_name, :finger_print
  end
end
