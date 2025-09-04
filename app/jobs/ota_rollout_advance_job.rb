class OtaRolloutAdvanceJob < ApplicationJob
  queue_as :default

  def perform(ota_configuration_id)
    cfg = OtaConfiguration.find_by(id: ota_configuration_id)
    return unless cfg
    return unless cfg.ready_for_advance?

    cfg.advance_rollout!
  end
end

