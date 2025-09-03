# frozen_string_literal: true
class Deployment < ApplicationRecord
  has_many :devices, dependent: :nullify
  has_many :groups, dependent: :nullify

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
end
