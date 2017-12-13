module Api
  class HrefBuilder
    attr_reader :request

    def initialize(request)
      @request = request
    end

    # DEPRECATED
    def normalize_href(type, value)
      if type.to_s == request.subcollection
        normalize_url("#{request.collection}/#{request.collection_id}/#{type}/#{value}")
      else
        normalize_url("#{type}/#{value}")
      end
    end

    def normalize_url(value)
      svalue = value.to_s
      pref   = request.api_prefix
      suffix = request.api_suffix
      svalue.match(pref) ? svalue : "#{pref}/#{svalue}#{suffix}"
    end

    private
  end
end
