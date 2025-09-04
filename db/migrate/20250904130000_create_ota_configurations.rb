# frozen_string_literal: true
class CreateOtaConfigurations < ActiveRecord::Migration[7.0]
  def change
    create_table :ota_configurations do |t|
      t.references :deployment, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.boolean :automatic_update, default: false, null: false
      t.boolean :in_production, default: false, null: false
      t.datetime :rollout_start_at
      t.timestamps
    end

    add_index :ota_configurations, [:deployment_id, :name], unique: true
  end
end

