require 'ostruct'
require 'rss'
require 'open-uri'
require 'action_view'
#require 'byebug'

module Pylon
  # Applies to all Rails apps
  class General
    # Displays all the associations on a Rails app.
    #
    # It works by retrieving all files on the app/models folder,
    # trying to turn the file names into classes (which will probably fail in namespaced models...),
    # and calling ActiveRecord.reflect_on_all_associations method on them and parsing the response.
    def self.reflect_on_all_associations
      all_model_classes = Dir[Rails.root.join('app', 'models', '*.rb')].map { |model| model.split("/")[-1].split(".")[0] }
      constantized_model_classes = all_model_classes.map { |model_name| model_name.camelize.constantize }
      active_model_classes = constantized_model_classes.select { |model| model.respond_to?(:reflect_on_all_associations) }
      active_model_classes.each do |model|
        model.reflect_on_all_associations.each do |assoc|
          assoc_name = derive_association_name_from_class(assoc)
          puts "#{model} [#{assoc_name}] #{assoc.name.to_s.camelize}"
        end
      end
      true
    end

    # Receives an ActiveRecord::Reflection's inherited class, parses its name and spits out a String
    # that represents the association.
    #
    # i.e. ActiveRecord::Reflection::BelongsToReflection returns "belongs_to"
    #
    # It's been built to be used by `self.reflect_on_all_associations`
    def self.derive_association_name_from_class(klass)
      klass.class.to_s.split("::")[-1].gsub("Reflection","").underscore
    end

    def self.set_trace
      trace = TracePoint.new(:call, :return) { |tp| p "*** #{[tp.path.gsub(Rails.root.to_s, ''), tp.lineno, tp.event, tp.method_id]}" if tp.path.include?(Rails.root.to_s) }
      trace.enable
      yield
      trace.disable
    end
  end
end
