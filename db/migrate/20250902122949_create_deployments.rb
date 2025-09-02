# frozen_string_literal: true
class CreateDeployments < ActiveRecord::Migration[7.0]
  def up
    create_table :deployments do |t|
      # 存 brand/product/device 短键，例如 "MicroTouch/M1_IC0_N702/MACH_10"
      t.string :name, null: false
      # 贴近 Google OTA Portal 的元数据（可选）
      t.string :description
      t.string :build_prefix
      t.string :build_suffix
      t.string :partner_product_id
      t.timestamps
    end
    add_index :deployments, :name, unique: true

    add_column :devices, :deployment_id, :bigint
    add_index  :devices, :deployment_id

    # 回填：按 devices.finger_print 的短键插入 deployments，并建立关联
    say_with_time "Backfilling deployments from devices.finger_print" do
      execute <<~SQL
        INSERT INTO deployments(name, created_at, updated_at)
        SELECT DISTINCT split_part(finger_print, ':', 1) AS short_key,
               CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        FROM devices
        WHERE finger_print IS NOT NULL AND finger_print <> ''
        ON CONFLICT (name) DO NOTHING;
      SQL

      execute <<~SQL
        UPDATE devices
        SET deployment_id = d.id
        FROM deployments d
        WHERE split_part(devices.finger_print, ':', 1) = d.name
          AND devices.deployment_id IS NULL;
      SQL
    end
  end

  def down
    remove_index  :devices, :deployment_id if index_exists?(:devices, :deployment_id)
    remove_column :devices, :deployment_id if column_exists?(:devices, :deployment_id)
    remove_index  :deployments, :name if index_exists?(:deployments, :name)
    drop_table    :deployments if table_exists?(:deployments)
  end
end
