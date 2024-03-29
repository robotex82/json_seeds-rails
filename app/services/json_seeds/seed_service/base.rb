module JsonSeeds
  module SeedService
    # Specifying polymorphic associations:
    #
    # {
    #   "account": [
    #     {
    #       "accountable.club.name": "1. TFC Frankfurt",
    #       "name": "Mitgliedsbeiträge",
    #       "number": "4400",
    #       "kind": "revenue"
    #     }
    #   ]
    # }
    #
    # The key is composed of three parts:
    #
    # 1. The association name
    # 2. The type of the associated record (this will be passed to the model_name_map)
    # 3. The attribute name that will be used to find the associated record
    #
    class Base < Rao::Service::Base
      private

      def _perform
        say "Using #{seed_path} as seed path"
        ActiveRecord::Base.transaction do
          wipe! if ActiveModel::Type::Boolean.new.cast(@options[:wipe])
          before_import if respond_to?(:before_import, true)
          json_files.each do |filename|
            say "Seeding #{filename}"
            import(filename)
          end
          after_import if respond_to?(:after_import, true)
        end
      end

      def seed_path
        @seed_path ||= Rails.root.join("db", "seeds")
      end

      def json_files
        @json_files ||= Dir.glob(File.join(seed_path, "*.json"))
      end

      def wipe!
        wipe_scopes.each do |scope|
          say "Wiping all #{scope}" do
            scope.destroy_all
          end
        end
      end

      def import(filename)
        say "Importing #{filename}" do
          file = File.read(filename)
          begin
            json = JSON.parse(file)
          rescue JSON::ParserError => e
            raise "Could not parse #{filename}: #{e.message}"
          end
          json.each do |model_name, data|
            import_model_data(model_name, data)
          end
        end
      end

      def import_model_data(model_name, data)
        class_name, _ = map_model_name(model_name)
        say "Processing #{data.size} entries for #{class_name}" do
          data.each do |attributes|
            associations = attributes.select { |key, value| key.to_s.match(/.*\..*/) }
            attributes.except!(*associations.keys)
            begin
              record = class_name.constantize.new(map_attributes(class_name, attributes))
            rescue ActiveModel::UnknownAttributeError => e
              raise e
            rescue NameError => e
              raise e, "Could not find class #{class_name}. Did you forget to add it to the model_name_map?"
            end
            associations.map { |associated, value| associate(record, associated, value) }
            # TODO: refactor this to be less ugly
            record.is_a?(Rao::Service::Base) ? record.perform : record.save!
          rescue => e
            binding.pry
          end
        end
      end

      def model_name_map
        @model_name_map ||= {}
      end

      def map_model_name(model_name)
        class_name_or_options = model_name_map[model_name]
        if class_name_or_options.is_a?(Hash)
          class_name = class_name_or_options[:class_name]
          association_name = class_name_or_options[:as]
        else
          class_name = class_name_or_options || model_name
          association_name = class_name.underscore.include?("/") ? class_name.underscore.split("/").last : class_name.underscore
        end
        [class_name, association_name]
      end

      def map_attributes(class_name, attributes)
        attributes.each_with_object({}) do |(attribute_name, value), memo|
          key = map_attribute_name(class_name, attribute_name)
          memo[key] = map_attribute_value(class_name, attribute_name, value)
        end
      end

      def map_attribute_name(class_name, attribute_name)
        attribute_name_map[class_name.to_sym].try(:[], attribute_name.to_sym) || attribute_name
      end

      def map_attribute_value(class_name, attribute_name, value)
        mapping = attribute_value_map[class_name.to_sym].try(:[], attribute_name.to_sym)
        return value if mapping.nil?
        if mapping.respond_to?(:call)
          mapping.call(value) || value
        else
          value
        end
      end

      def attribute_name_map
        @attribute_name_map ||= {}
      end

      def attribute_value_map
        @attribute_value_map ||= {}
      end

      def associate(record, associated, value)
        splitted_associated = associated.split(".")
        if splitted_associated.size == 3
          attribute_name = splitted_associated.last
          association_name = splitted_associated.first
          class_name, _ = map_model_name(splitted_associated[1])
        else
          association_name, attribute_name = associated.split(".")
          class_name, association_name = map_model_name(association_name)
        end
        attribute = map_attribute_name(class_name, attribute_name)
        value = map_attribute_value(class_name, attribute_name, value)
        begin
          associated_record = class_name.constantize.where(attribute => value).first!
        rescue ActiveRecord::RecordNotFound => e
          raise e, "Could not find #{class_name} with #{attribute} = #{value.inspect}"
        end
        r = record.send("#{association_name}=", associated_record)
      rescue => e
        binding.pry
      end
    end
  end
end
