# frozen_string_literal: true
class AddStagedRolloutAndAssignments < ActiveRecord::Migration[7.0]
  def change
    change_table :ota_configurations do |t|
      t.string  :rollout_strategy, null: false, default: 'immediate' # immediate|staged
      t.integer :rollout_total_percent, null: false, default: 100
      t.integer :rollout_step_percent, null: false, default: 10
      t.integer :rollout_step_interval_hours, null: false, default: 24
      t.integer :rollout_current_percent, null: false, default: 0
      t.boolean :paused, null: false, default: false
    end

    create_table :ota_configuration_assignments do |t|
      t.references :ota_configuration, null: false, foreign_key: true, index: { name: 'index_ota_cfg_assignments_on_cfg' }
      t.references :group, null: false, foreign_key: true
      t.timestamps
    end

    add_index :ota_configuration_assignments, [:ota_configuration_id, :group_id], unique: true, name: 'index_ota_cfg_assignments_uniqueness'
  end
end

