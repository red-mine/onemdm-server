class Pkg < ActiveRecord::Base

  default_scope -> {order("name")}

  has_many :pkg_batch_installations, dependent: :destroy

  validates :name, :finger_print, presence: true

  def ota_url
    return DEFAULT_OTA_URL if self.finger_print.eql?(DEFAULT_OTA_PACKAGE_NAME)
    ""
  end
end
