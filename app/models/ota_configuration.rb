class OtaConfiguration < ApplicationRecord
  belongs_to :deployment
  belongs_to :pkg, optional: true

  validates :name, presence: true
  validates :deployment_id, presence: true
  validates :name, uniqueness: { scope: :deployment_id }

  validates :rollout_total_percent, :rollout_step_percent, :rollout_current_percent,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :rollout_strategy, inclusion: { in: %w[immediate staged] }
  validates :pkg_id, presence: true, if: -> { rollout_strategy.present? }

  # groups removed from OTA Configurations; no cross-deployment validation needed

  scope :in_production, -> { where(in_production: true) }
  scope :automatic, -> { where(automatic_update: true) }

  def title
    in_production? ? "#{name} (in production)" : name
  end

  def duplicate!(new_name: nil)
    copy = dup
    copy.name = new_name.presence || "#{name} copy"
    copy.in_production = false
    copy.save!
    copy
  end

  # Devices targeted by this configuration
  def target_devices
    deployment.devices
  end

  def target_devices_count
    target_devices.count
  end

  def rollout_progress
    return 100 if rollout_strategy == 'immediate'
    (rollout_current_percent || 0).clamp(0, 100)
  end

  def advance_rollout!
    raise "Not staged" unless rollout_strategy == 'staged'
    step = rollout_step_percent.to_i
    total = rollout_total_percent.to_i
    cur = rollout_current_percent.to_i
    new_val = [cur + step, total].min
    update!(rollout_current_percent: new_val, last_advanced_at: Time.current)
  end

  # Whether this config is due for an automatic advance
  def ready_for_advance?
    return false unless rollout_strategy == 'staged'
    return false if paused?
    return false if rollout_current_percent.to_i >= rollout_total_percent.to_i
    return false if rollout_start_at.present? && rollout_start_at > Time.current

    last = last_advanced_at || rollout_start_at || created_at
    interval = rollout_step_interval_hours.to_i.hours
    Time.current >= (last + interval)
  end

  private
end
