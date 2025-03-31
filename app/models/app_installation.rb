class AppInstallation < ActiveRecord::Base
  enum status: [:pushed, :downloaded, :cancelled, :installed]
  delegate :app, to: :app_batch_installation

  belongs_to :device
  belongs_to :app_batch_installation

  after_create :push_apps

  def as_json(options={})
    {
      :id => self.id,
      :name => self.app.name,
      :package_name => self.app.package_name,
      :apk_url => self.app.apk_url
    }
  end

  def push_apps
    if self.pushed?
      fcm = FCM.new(
        '/home/hunt/Downloads/onemdm-server-firebase-adminsdk-fbsvc-aafa0b47d3.json',
        'onemdm-server'
      )
      message = {
        'token': self.device.gcm_token,
        'data': {
          message: self.to_json,
          type: "app"
        },
      }
      logger.debug "message #{message}"
      response = fcm.send_v1(message)
      logger.debug "response #{response}"
    end
  end
end
