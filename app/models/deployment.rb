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
end
