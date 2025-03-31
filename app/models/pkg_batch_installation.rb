class PkgBatchInstallation < ActiveRecord::Base
  belongs_to :pkg

  has_many :pkg_installations, dependent: :destroy
end
