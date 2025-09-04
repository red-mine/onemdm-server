class OtaConfiguration < ApplicationRecord
  belongs_to :deployment
  has_many :assignments, class_name: 'OtaConfigurationAssignment', dependent: :destroy
  has_many :groups, through: :assignments

  accepts_nested_attributes_for :assignments, allow_destroy: true

  validates :name, presence: true
  validates :deployment_id, presence: true
  validates :name, uniqueness: { scope: :deployment_id }

  validates :rollout_total_percent, :rollout_step_percent, :rollout_current_percent,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :rollout_strategy, inclusion: { in: %w[immediate staged] }

  validate :groups_belong_to_same_deployment

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
    # Duplicate assignments too
    assignments.find_each do |a|
      copy.assignments.create!(group_id: a.group_id)
    end
    copy
  end

  # Devices targeted by this configuration
  def target_devices
    base = deployment.devices
    if groups.exists?
      base = base.where(group_id: groups.select(:id))
    end
    base
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
    update!(rollout_current_percent: new_val)
  end

  private

  def groups_belong_to_same_deployment
    bad = groups.detect { |g| g.deployment_id != deployment_id }
    errors.add(:groups, "must belong to the same deployment") if bad
  end
end
