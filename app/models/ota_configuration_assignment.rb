class OtaConfigurationAssignment < ApplicationRecord
  belongs_to :ota_configuration
  belongs_to :group

  validates :group_id, uniqueness: { scope: :ota_configuration_id }
  validate :deployment_consistency

  private

  def deployment_consistency
    return if ota_configuration.nil? || group.nil?
    if ota_configuration.deployment_id != group.deployment_id
      errors.add(:group_id, "must be in the same deployment as the configuration")
    end
  end
end

