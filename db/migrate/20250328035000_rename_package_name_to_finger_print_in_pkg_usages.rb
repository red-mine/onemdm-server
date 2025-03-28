class RenamePackageNameToFingerPrintInPkgUsages < ActiveRecord::Migration[7.0]
  def change
    rename_column :pkg_usages, :package_name, :finger_print
  end
end
