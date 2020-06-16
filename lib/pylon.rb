require 'ostruct'
require 'rss'
require 'open-uri'
require 'action_view'

require 'pylon/tracer'

module Pylon
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
      sequence_tracer = []
      trace = TracePoint.new(:call, :return) do |tp|
        if tp.path.include?(Rails.root.to_s)
          sequence_tracer << [tp.defined_class, tp.method_id, tp.event]
          #puts "#{sequence_tracer[-1][0]} -- #{sequence_tracer[-1][1]} -- #{sequence_tracer[-1][2]}"
        end
      end
      trace.enable
      yield
      trace.disable

      File.open("sequence_trace.txt", "w") do |file|
        last_call = sequence_tracer[0]
        last_call[0] = parse_class_name(last_call[0])
        return_stack = [{ class: last_call[0], method: last_call[1] }]
        file.puts "actor System"
        file.puts "System->#{last_call[0]}:#{last_call[1]}"
        sequence_tracer[1..-1].each do |method_call|
          method_call[0] = parse_class_name(method_call[0])
          if method_call[2] == :return
            return_to = return_stack.find { |call| call[:class] == method_call[0] && call[:method] == method_call[1] }
            next if return_to.nil?
            return_to_class = return_to&.fetch(:class)
            return_to_method = return_to&.fetch(:method)
            # Let's skip the return arrow if the call is to the class itself, it's unnecessary
            if return_to_class != method_call[0]
              file.puts "#{return_to_class}<--#{method_call[0]}:#{method_call[1]}"
            end
          else
            return_stack << { class: method_call[0], method: method_call[1] }
            file.puts "#{last_call[0]}->#{method_call[0]}:#{method_call[1]}"
          end
          last_call = method_call
        end
      end
    end

    def self.parse_class_name(klass)
      class_name = klass.to_s
      # Sometimes the class is returned in the format: #<Class:NameOfTheClass>
      class_name = if class_name.starts_with?("#")
                     class_name.gsub("#<Class:","").gsub(">","")
                   else
                     class_name.to_s
                   end
      class_name = class_name.gsub("::","_")
      # ActiveRecord models seem to bring with them the attributes in paranthesis.
      # As in User(id: integer, name: string)
      # We want to remove the parenthesis part
      class_name = class_name.split("(")[0]
      class_name
    end
  end
end
