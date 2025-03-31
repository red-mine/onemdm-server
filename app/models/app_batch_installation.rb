class AppBatchInstallation < ActiveRecord::Base
  belongs_to :app

  has_many :app_installations, dependent: :destroy
end
