module Api
  class CollectionConfig
    def initialize
      @cfg = ApiConfig.collections
    end

    def [](collection_name)
      return unless include?(collection_name)
      @cfg[collection_name.to_sym]
    end

    def option?(collection_name, option_name)
      self[collection_name][:options].include?(option_name) if self[collection_name]
    end

    def collection?(collection_name)
      option?(collection_name, :collection)
    end

    def custom_actions?(collection_name)
      option?(collection_name, :custom_actions)
    end

    def primary?(collection_name)
      option?(collection_name, :primary)
    end

    def show?(collection_name)
      option?(collection_name, :show)
    end

    def show_as_collection?(collection_name)
      option?(collection_name, :show_as_collection)
    end

    def supports_http_method?(collection_name, method)
      Array(self[collection_name][:verbs]).include?(method)
    end

    def subcollections(collection_name)
      Array(self[collection_name][:subcollections])
    end

    def subcollection?(collection_name, subcollection_name)
      subcollections(collection_name).include?(subcollection_name.to_sym)
    end

    def subcollection_denied?(collection_name, subcollection_name)
      self[collection_name][:subcollections] &&
        !self[collection_name][:subcollections].include?(subcollection_name.to_sym)
    end

    def typed_collection_actions(collection_name, target)
      self[collection_name]["#{target}_actions".to_sym]
    end

    def typed_subcollection_actions(collection_name, subcollection_name, target = :subcollection)
      self[collection_name]["#{subcollection_name}_#{target}_actions".to_sym]
    end

    def typed_subcollection_action(collection_name, subcollection_name, method)
      typed_subcollection_actions(collection_name, subcollection_name).try(:fetch_path, method.to_sym)
    end

    def names_for_feature(product_feature_name)
      names_for_features[product_feature_name]
    end

    def klass(collection_name)
      self[collection_name][:klass].try(:constantize)
    end

    ##
    # Fetch the name of *a* collection that utilizes resource_klass
    # Note that this returns the first collection that matches regardless of context
    #
    # e.g.: name_for_klass(MiqAeDomain) => :automate
    # (MiqAeDomain matches both the collections 'automate' and 'automate_domains')
    def name_for_klass(resource_klass)
      @cfg.detect { |_, spec| spec[:klass] == resource_klass.name }.try(:first)
    end

    ##
    # Fetch the name of *all* collections that utilize resource_klass
    #
    # e.g.: names_for_klass(MiqAeDomain => [:automate, :automate_domains]
    #       names_for_klass(Blah) => []
    def names_for_klass(resource_klass)
      collections = []
      @cfg.each do |collection_name, spec|
        collections << collection_name if spec[:klass] == resource_klass.name
      end

      collections
    end

    ##
    # Fetch the name of *a* collection that utilizes a class which is a parent of resource_class
    # Note that this returns the first collection that specifies a parent class of resource_class regardless of context
    #
    # e.g.: name_for_subclass(ManageIQ::Providers::Redhat::InfraManager::Vm) => :vms
    #       name_for_subclass(ServiceReconfigureRequest) => :requests
    def name_for_subclass(resource_class)
      resource_class = resource_class.to_s
      @cfg.detect do |collection, _|
        collection_class = klass(collection)
        collection_class && (collection_class.to_s == resource_class || collection_class.descendants.collect(&:to_s).include?(resource_class))
      end.try(:first)
    end

    ##
    # Fetch the name of *all* collections that utilizes a class which is a parent of resource_class
    #
    # e.g.: names_for_subclass(ManageIQ::Providers::Amazon::CloudManager::Vm) => [:instances, :vms]
    # Because ManageIQ::Providers::Amazon::CloudManager::Vm is a subclass of both:
    #   * ManageIQ::Providers::CloudManager::Vm from the /instances collection
    #   * Vm from the /vms collection
    def names_for_subclass(resource_class)
      collections = []
      resource_class = resource_class.to_s
      @cfg.each do |collection, _|
        collection_class = klass(collection)
        if collection_class && (collection_class.to_s == resource_class || collection_class.descendants.collect(&:to_s).include?(resource_class))
          collections << collection
        end
      end

      collections
    end

    def what_refers_to_feature(product_feature_name)
      referenced_identifiers[product_feature_name]
    end

    def collections_with_description
      @cfg.each_with_object({}) do |(collection, cspec), result|
        result[collection] = cspec[:description] if cspec[:options].include?(:collection)
      end
    end

    def resource_identifier(collection_name)
      self[collection_name].try(:resource_identifier) || "id"
    end

    private

    def as_hash
      @as_hash ||= @cfg.to_h
    end

    def include?(collection_name)
      as_hash.include?(collection_name.to_sym)
    end

    def names_for_features
      @names_for_features ||= @cfg.each_with_object(Hash.new { |h, k| h[k] = [] }) do |(collection, cspec), result|
        ident = cspec[:identifier]
        next unless ident
        result[ident] << collection
      end
    end

    def referenced_identifiers
      @referenced_identifiers ||= @cfg.each_with_object({}) do |(collection, cspec), result|
        next unless cspec[:collection_actions].present?
        cspec[:collection_actions].each do |method, action_definitions|
          next unless action_definitions.present?
          action_definitions.each do |action|
            identifier = action[:identifier]
            next if action[:disabled] || result.key?(identifier)
            result[identifier] = [collection, method, action]
          end
        end
      end
    end
  end
end
