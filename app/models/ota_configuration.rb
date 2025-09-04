class OtaConfiguration < ApplicationRecord
  belongs_to :deployment

  validates :name, presence: true
  validates :deployment_id, presence: true
  validates :name, uniqueness: { scope: :deployment_id }

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
end

