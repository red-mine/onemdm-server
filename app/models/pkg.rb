class Pkg < ActiveRecord::Base

  default_scope -> {order("name")}

  has_many :batch_installations, dependent: :destroy

  validates :name, :package_name, presence: true

  def ota_url
    return DEFAULT_OTA_URL if self.package_name.eql?(DEFAULT_OTA_PACKAGE_NAME)
    ""
  end
end
