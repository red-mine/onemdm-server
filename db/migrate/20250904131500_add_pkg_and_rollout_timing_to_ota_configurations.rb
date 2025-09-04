# frozen_string_literal: true
class AddPkgAndRolloutTimingToOtaConfigurations < ActiveRecord::Migration[7.0]
  def change
    add_reference :ota_configurations, :pkg, foreign_key: true
    add_column :ota_configurations, :last_advanced_at, :datetime
  end
end

