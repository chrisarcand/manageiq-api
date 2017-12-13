module Api
  class HrefBuilder
    attr_reader :request

    def initialize(request)
      @request = request
    end

    def normalize_href(type, value)
      type.to_s == request.subcollection ? subcollection_href(type, value) : collection_href(type, value)
    end

    def normalize_url(value)
      svalue = value.to_s
      pref   = request.api_prefix
      suffix = request.api_suffix
      svalue.match(pref) ? svalue : "#{pref}/#{svalue}#{suffix}"
    end

    private

    def subcollection_href(type, value)
      normalize_url("#{request.collection}/#{request.collection_id}/#{type}/#{value}")
    end

    def collection_href(type, value)
      normalize_url("#{type}/#{value}")
    end
  end
end
