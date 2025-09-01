# app/models/pkg.rb
class Pkg < ActiveRecord::Base
  default_scope -> { order("name") }

  has_many :pkg_batch_installations, dependent: :destroy

  validates :name, :finger_print, presence: true

  # 你的 ota_url 逻辑如有常量，保持不动
  def ota_url
    return DEFAULT_OTA_URL if self.finger_print.to_s == DEFAULT_OTA_FINGER_PRINT
    ""
  end

  # 典型 Android Build.FINGERPRINT 形如：
  # brand/product/device:osRelease/buildId/incremental:buildType/tags
  FINGERPRINT_REGEX = %r{
    \A
    (?<brand>[^/]+) /
    (?<product>[^/]+) /
    (?<device>[^:]+) :
    (?<os_release>[^/]+) /
    (?<build_id>[^/]+) /
    (?<incremental>[^:]+) :
    (?<build_type>[^/]+) /
    (?<tags>[^\s]+)
    \z
  }x.freeze

  # 解析指纹为 Hash；无法匹配时返回 {}
  def parsed_fingerprint
    fp = finger_print.to_s.strip
    m = FINGERPRINT_REGEX.match(fp)
    return {} unless m
    # 统一键名风格
    {
      brand:        m[:brand],
      product:      m[:product],
      device:       m[:device],
      os_release:   m[:os_release],
      build_id:     m[:build_id],
      incremental:  m[:incremental],
      build_type:   m[:build_type],
      tags:         m[:tags]
    }
  end

  # 便捷读取（nil 安全）
  def fp_brand       = parsed_fingerprint[:brand]
  def fp_product     = parsed_fingerprint[:product]
  def fp_device      = parsed_fingerprint[:device]
  def fp_os_release  = parsed_fingerprint[:os_release]
  def fp_build_id    = parsed_fingerprint[:build_id]
  def fp_incremental = parsed_fingerprint[:incremental]
  def fp_build_type  = parsed_fingerprint[:build_type]
  def fp_tags        = parsed_fingerprint[:tags]
end
