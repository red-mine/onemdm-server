class PkgUsagesController < ApplicationController
  before_action :authenticate_device
  respond_to :json

  def create
    begin
      @device.pkg_usages << PkgUsage.create!(pkg_usage_params)
      render json: {}, status: :created
    rescue Exception => e
      logger.warn "Error while saving Pkg Usage #{e.message}"
      render json: {},
              status: :unprocessable_entity
    end
  end
  private

  def pkg_usage_params
    params.permit(pkg_usage: [:finger_print,
                              :usage_duration_in_seconds,
                              :used_on]).require(:pkg_usage)
  end
end
