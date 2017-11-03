module Api
  class ServersController < BaseController
    ##
    # GET /servers/:id/settings
    #
    def settings
      render_resource(:settings, MiqServer.find(params[:c_id]).settings_for_resource.to_hash)
    end
  end
end
