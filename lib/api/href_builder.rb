module Api
  class HrefBuilder
    attr_reader :request

    def initialize(request)
      @request = request
    end

    ##
    # Returns a valid href given a resource
    # If the resource is not part of a valid collection/subcollection, returns nil
    #
    def href_for(resource)
      collection_name = collection_config.name_for_subclass(resource.class)
      return nil unless collection_name.present?

      key_id = collection_config.resource_identifier(collection_name)

      if collection_name.to_s == request.subcollection
        # We unconventionally support nested single resources w/o toplevel collections
        # e.g. /:collection/:c_id/:subcollection/:id without /:subcollection/:id
        # We cannot deduce with the resource alone what collection this
        # object should be under. Therefore, we assume that if the object
        # being returned is the subcollection in the request, nesting it under
        # the request's collection is the most valid href.
        normalize_url("#{request.collection}/#{request.collection_id}/#{collection_name}/#{resource.send(key_id)}")
      else
        normalize_url("#{collection_name}/#{resource.send(key_id)}")
      end
    end

    def href_for!(resource)
      href = href_for(resource)

      unless href.present?
        raise StandardError, "Can't identify resource '#{resource.class}' to build a valid href"
      end

      href
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

    def collection_config
      @collection_config = CollectionConfig.new
    end
  end
end
