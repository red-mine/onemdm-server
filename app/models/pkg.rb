class Pkg < ActiveRecord::Base
  # 1) 用 symbol 版 order，避免字符串注入风险
  default_scope -> { order(:name) }

  has_many :pkg_batch_installations, dependent: :destroy
  validates :name, :finger_print, presence: true

  # 2) 可选：限制 name 只含安全字符，避免穿越/奇怪文件名
  validates :name, format: { with: /\A[\w\-.]+\z/,
                             message: "只允许字母数字下划线、短横和点" }

  # 你原有的 ota_url 逻辑保留
  def ota_url
    return DEFAULT_OTA_URL if finger_print.eql?(DEFAULT_OTA_FINGER_PRINT)
    "" # 其他情况走 ActiveAdmin 的 download 动作
  end
end
