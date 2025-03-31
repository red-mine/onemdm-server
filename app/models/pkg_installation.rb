class PkgInstallation < ActiveRecord::Base
  enum status: [:pushed, :downloaded, :cancelled, :installed]
  delegate :pkg, to: :pkg_batch_installation

  belongs_to :device
  belongs_to :pkg_batch_installation

  after_create :push_pkgs

  def as_json(options={})
    {
      :id => self.id,
      :name => self.pkg.name,
      :finger_print => self.pkg.finger_print,
      :ota_url => self.pkg.ota_url
    }
  end

  def push_pkgs
    if self.pushed?
      fcm = FCM.new(
        '/home/hunt/Downloads/onemdm-server-firebase-adminsdk-fbsvc-aafa0b47d3.json',
        'onemdm-server'
      )
      message = {
        'token': self.device.gcm_token,
        'data': {
          message: self.to_json
        },
      }
      logger.debug "message #{message}"
      response = fcm.send_v1(message)
      logger.debug "response #{response}"
    end
  end
end
