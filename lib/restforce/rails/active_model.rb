module Restforce
	module Rails
    CALLBACKS = ActiveModel::Callbacks
    #TODO Send self.object to callback

		module ActiveModel

			def self.included(base)				

				base.class_eval do
          extend CALLBACKS

          define_model_callbacks :create, :update, :destroy

          def id ; @id ; end
          def id=(id) ; @id=id ; end
          def object ; @object ; end
          def object=(object) ; @object = object ; end
					
					@has_many ||= []
					@belongs_to ||= []

					def self.has_many table_name, options={}
						@has_many << [table_name, options]
					end

					def self.belongs_to table_name, options={}
						@belongs_to << [table_name, options]
					end

					def self.create(*args)
            instance = new
            instance.run_callbacks :create do
					    instance.object = @restforce_client.create(@restforce_table_name, *args)
              instance.id = instance.object if instance.object.present?
            end
					end

					def self.create!(*args)
            instance = new
            instance.run_callbacks :create do
						  instance.object = @restforce_client.create!(@restforce_table_name, *args)
              instance.id = instance.object if instance.object.present?
            end
					end

					def self.create_and_return(*args)
            instance = new
            instance.run_callbacks :create do
						  instance.object = self.find(@restforce_client.create(@restforce_table_name, *args))
              instance.id = instance.object if instance.object.try(:Id).present?
            end
					end

					def self.create_and_return!(*args)
            instance = new
            instance.run_callbacks :create do
						  instance.object = self.find(@restforce_client.create!(@restforce_table_name, *args))
              instance.id = instance.object if instance.object.try(:Id).present?
            end
					end

          def self.update(*args)
            instance = new
            instance.run_callbacks :update do
              instance.id = args[0].with_indifferent_access[:Id] if args[0].is_a?(Hash) && args[0].with_indifferent_access[:Id].present?
              instance.object = @restforce_client.update(@restforce_table_name, *args)
            end
          end

          def self.update!(*args)
            instance = new
            instance.run_callbacks :update do
              instance.id = args[0].with_indifferent_access[:Id] if args[0].is_a?(Hash) && args[0].with_indifferent_access[:Id].present?
              instance.object = @restforce_client.update!(@restforce_table_name, *args)
            end
          end

          def self.upsert(*args)
            instance = new
            instance.run_callbacks :update do
              instance.id = args[0].with_indifferent_access[:Id] if args[0].is_a?(Hash) && args[0].with_indifferent_access[:Id].present?
              instance.object = @restforce_client.upsert(@restforce_table_name, *args)
            end
          end

          def self.upsert!(*args)
            instance = new
            instance.run_callbacks :update do
              instance.id = args[0].with_indifferent_access[:Id] if args[0].is_a?(Hash) && args[0].with_indifferent_access[:Id].present?
              instance.object = @restforce_client.upsert!(@restforce_table_name, *args)
            end
          end

					def self.destroy(id)
            instance = new
            instance.run_callbacks :destroy do
              instance.id = args[0].with_indifferent_access[:Id] if args[0].is_a?(Hash) && args[0].with_indifferent_access[:Id].present?
						  instance.object = @restforce_client.destroy(@restforce_table_name, id)
            end
					end

					def self.destroy!(id)
            instance = new
            instance.run_callbacks :destroy do
              instance.id = args[0].with_indifferent_access[:Id] if args[0].is_a?(Hash) && args[0].with_indifferent_access[:Id].present?
						  instance.object = @restforce_client.destroy!(@restforce_table_name, id)
            end
					end

          def method_missing method_name, *args, &block
            if object.respond_to?(method_name)
              object.send(method_name, *args, &block)
            else
              super(method_name, *args, &block)
            end
          end

					def self.restforce options={}
						options.reverse_merge!({
							client: Restforce::Client.new,
							table_name: self.name.tableize.split('/').last.titleize.gsub(' ','_')+'__c',
							attributes: ['Id','Name']
						})
						@restforce_client ||= options[:client]
						@restforce_table_name ||= options[:table_name]
						@restforce_attributes ||= options[:attributes].kind_of?(String) ? options[:attributes].split(',') : options[:attributes]

						def self.method_missing method_name, *args, &block
							client = @restforce_client.send(@restforce_table_name, @restforce_attributes)

							if !@has_many.nil? && !@has_many.empty?
								@has_many.each do |params|
									client = client.with_many params[0], params[1]
								end
							end

							if !@belongs_to.nil? && !@belongs_to.empty?
								@belongs_to.each do |params|
									client = client.with_one params[0], params[1]
								end
							end

				  		if client.respond_to?(method_name) || method_name.to_s =~ /^find_by_(.+)$/
								client.send(method_name, *args, &block)
							else
								super
							end
						end

					end
					
				end
			end

			
		end
	end
end