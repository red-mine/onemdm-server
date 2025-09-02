class Group < ActiveRecord::Base
  belongs_to :deployment, optional: true

  has_many :devices

  validates :name, presence: true
end
