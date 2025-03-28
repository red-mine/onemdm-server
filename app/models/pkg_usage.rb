class PkgUsage < ActiveRecord::Base
  validates :finger_print, :usage_duration_in_seconds, :used_on, presence: true
  belongs_to :device

  scope :pkg_usages_per_device_pkg_day, lambda {
          PkgUsage.select(:finger_print, :device_id, :used_on).
          where("device_id IS NOT NULL").
          order("used_on desc").
          order("device_id").
          order("finger_print").
          group("device_id", "finger_print", "used_on").
          sum("usage_duration_in_seconds")}
end
