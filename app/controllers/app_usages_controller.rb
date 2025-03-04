class AppUsagesController < ApplicationController
  before_action :authenticate_device
  respond_to :json

  def create
    begin
      @device.app_usages << AppUsage.create!(app_usage_params)
      render json: {}, status: :created
    rescue Exception => e
      logger.warn "Error while saving App Usage #{e.message}"
      render json: {},
              status: :unprocessable_entity
    end
  end
  private

  def app_usage_params
    params.require(:app_usage).permit(app_usage: [:package_name,
                                                  :usage_duration_in_seconds,
                                                  :used_on])

  end
end
