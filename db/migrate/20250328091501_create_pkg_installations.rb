class CreatePkgInstallations < ActiveRecord::Migration[7.0]
  def change
    create_table :pkg_installations do |t|
      t.belongs_to :device, foreign_key: true, index: true
      t.belongs_to :pkg_batch_installation, foreign_key: true, index: true
      t.integer :status, default: 0, null: false

      t.timestamps null: false
    end

  end
end
