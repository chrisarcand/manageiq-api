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
      collection_name = collection_name_from_class(resource.class) || collection_name_from_subclass(resource.class)
      return nil unless collection_name.present?

      key_id = collection_config.resource_identifier(collection_name)

      if collection_name.to_s == request.subcollection && collection_config.subcollection?(request.collection, collection_name.to_s)
        # We unconventionally support nested single resources w/o toplevel collections
        # e.g. /:collection/:c_id/:subcollection/:id without /:subcollection/:id
        # We cannot deduce with the resource alone what collection this
        # object should be under. Therefore, we assume that if the object
        # being returned is the subcollection in the request, nesting it under
        # the request's collection is the most valid href.
        normalize_url("#{request.collection}/#{request.collection_id}/#{collection_name}/#{resource.send(key_id)}")
      elsif collection_config.collection?(collection_name.to_s)
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
      @collection_config ||= CollectionConfig.new
    end

    ##
    # Search for the collection name via collections that explicitly use this class
    #
    # If there exists more than one, use the collection that is being queried in the request
    #
    def collection_name_from_class(klass)
      potential_collection_names = collection_config.names_for_klass(klass)
      potential_collection_names.detect { |name| name.to_s == request.collection }
    end

    ##
    # Search for the collection name via collections that use a parent class of klass
    #
    # If there exists more than one, use the one that exists as a unique subcollection of the request's collection
    # e.g.: /providers?expand=vms
    #       Vms map to both /instances and /vms, /vms is subcollection of /providers so use that.
    #
    # If neither are a unique subcollection under the request collection, just return one.
    #
    # e.g.: /generic_object_definitions/:id/generic_objects/:id?associations=vms
    #      Vms are not a subcollection of generic object definitions but they have two possible collections
    #      deduced from the parent class used in /instances and /vms. Returns /instances because that's
    #      what is first (collections are alphabetical)
    #
    def collection_name_from_subclass(klass)
      potential_collection_names = collection_config.names_for_subclass(klass)
      return potential_collection_names.first if potential_collection_names.size == 1

      if potential_collection_names.size > 1
        subcollection_of_request_collection = collection_config.subcollections(request.collection) | potential_collection_names

        if subcollection_of_request_collection.size == 1
          return subcollection_of_request_collection.first
        else
          potential_collection_names.first
        end
      end
    end
  end
end
