Rails.application.routes.draw do
  # Enablement for the REST API

  namespace :api, :path => "api(/:version)", :version => Api::VERSION_CONSTRAINT, :defaults => {:format => "json"} do
    root :to => "api#index", :as => :entrypoint
    match "/", :to => "api#options", :via => :options

    get "/ping" => "ping#index"

    Api::ApiConfig.collections.each do |collection_name, collection|
      # OPTIONS action for each collection
      match collection_name.to_s, :controller => collection_name, :action => :options, :via => :options, :as => nil

      scope collection_name, :controller => collection_name do
        subcollections = Array(collection.subcollections).each_with_object({}) do |name, memo|
          memo[name] = Api::ApiConfig.collections[name]
        end

        collection.verbs.each do |verb|
          if collection.options.include?(:primary)
            case verb
            when :get
              root :action => Api::VERBS_ACTIONS_MAP[verb], :as => collection_name
            else
              root :action => Api::VERBS_ACTIONS_MAP[verb], :via => verb
            end
          end

          next unless collection.options.include?(:collection)

          if collection.options.include?(:arbitrary_resource_path)
            case verb
            when :get
              root :action => :index, :as => collection_name.to_s.pluralize
              get "/*c_suffix", :action => :show, :as => collection_name.to_s.singularize
            else
              match "(/*c_suffix)", :action => Api::VERBS_ACTIONS_MAP[verb], :via => verb
            end
          else
            case verb
            when :get
              root :action => :index, :as => collection_name
              get "/:c_id", :action => :show, :as => collection_name.to_s.singularize
            when :put
              put "/:c_id", :action => :update
            when :patch
              patch "/:c_id", :action => :update
            when :delete
              delete "/:c_id", :action => :destroy
            when :post
              post "/", :action => :create, :constraints => Api::CreateConstraint.new
              post "(/:c_id)", :action => :update
            end
          end
        end

        subcollections.each do |subcollection_name, subcollection|
          next unless subcollection.options.include?(:subcollection)

          subcollection.verbs.each do |verb|
            if subcollection.options.include?(:subcollection_arbitrary_resource_path)
              get "/:c_id/#{subcollection_name}", :action => subcollection_name.to_s.pluralize, :as => "#{collection_name.to_s.singularize}_#{subcollection_name.to_s.pluralize}"
            else
              case verb
              when :get
                get "/:c_id/#{subcollection_name}", :action => :index, :as => "#{collection_name.to_s.singularize}_#{subcollection_name.to_s.pluralize}"
                get "/:c_id/#{subcollection_name}/:s_id", :action => :show, :as => "#{collection_name.to_s.singularize}_#{subcollection_name.to_s.singularize}"
              when :put
                put "/:c_id/#{subcollection_name}/:s_id", :action => :update
              when :patch
                patch "/:c_id/#{subcollection_name}/:s_id", :action => :update
              when :delete
                delete "/:c_id/#{subcollection_name}/:s_id", :action => :destroy
              when :post
                post "/:c_id/#{subcollection_name}", :action => :create, :constraints => Api::CreateConstraint.new
                post "/:c_id/#{subcollection_name}(/:s_id)", :action => :update
              end
            end
          end
        end
      end
    end
  end
end
