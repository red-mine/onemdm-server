class PkgsController  < ApplicationController
  before_action :authenticate_device

  def index
    render json: Pkg.all
  end
end
