class AppInstallationsController < ApplicationController
  before_action :authenticate_device
  respond_to :json

  def installed
    AppInstallation.find(params[:id]).installed!
    render json:{}, status: :ok
  end
end
