class CreatePkgBatchInstallations < ActiveRecord::Migration[7.0]
  def change
    create_table :pkg_batch_installations do |t|
      t.belongs_to :pkg, foreign_key: true, index: true
      t.timestamps null: false
    end
  end
end
