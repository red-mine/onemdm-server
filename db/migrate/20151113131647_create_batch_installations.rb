class CreateBatchInstallations < ActiveRecord::Migration[7.0]
  def change
    create_table :batch_installations do |t|
      t.belongs_to :app, foreign_key: true, index: true
      t.timestamps null: false
    end
  end
end
