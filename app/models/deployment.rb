# frozen_string_literal: true
class Deployment < ApplicationRecord
  has_many :devices, dependent: :nullify
  has_many :groups, dependent: :nullify
  has_many :ota_configurations, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  def title_with_prefix
    if build_prefix.present?
      "#{name} (#{build_prefix} ... #{build_suffix})"
    else
      name
    end
  end

  def ota_packages
    sample_fp = devices.where.not(finger_print: [nil, ""]).limit(1).pluck(:finger_print).first
    return Pkg.none if sample_fp.blank?

    prefix = sample_fp.split(":").first
    return Pkg.none if prefix.blank?

    Pkg.where("finger_print LIKE ?", "#{prefix}%")
  end

  # === Dashboard-style rollout metrics ===
  def active_devices_count
    devices.active.count
  end

  def ota_offered_count
    PkgInstallation.joins(:device).where(devices: { deployment_id: id }).count
  end

  def ota_installed_count
    PkgInstallation.joins(:device).where(devices: { deployment_id: id }).installed.count
  end

  def ota_install_percentage
    offered = ota_offered_count
    return 0 if offered.zero?
    ((ota_installed_count.to_f / offered) * 100).round(1)
  end

  def ota_last_update_at
    PkgInstallation.joins(:device).where(devices: { deployment_id: id }).maximum(:updated_at)
  end
end
