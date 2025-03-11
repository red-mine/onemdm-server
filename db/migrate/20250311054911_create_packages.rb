class CreatePackages < ActiveRecord::Migration[7.0]
  def change
    create_table :pkgs do |t|
      t.string :name
      t.string :package_name

      t.timestamps null: false
    end
  end
end
