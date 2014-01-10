module Restforce
	module Rails
		module ActiveModel

			def self.included(base)				
				base.class_eval do
					
					@has_many ||= []

					def self.attributes attributes=['Id','Name']
						@@attributes = attributes if attributes.present?
						@@attributes
					end

					def self.has_many table_name, options={}
						@has_many << [table_name, options]
					end

					def self.restforce options={}
						options.reverse_merge!({
							client: Restforce::Client.new,
							table_name: self.name.tableize.split('/').last.titleize.gsub(' ','_')+'__c',
							attributes: ['Id','Name']
						})
						@restforce_client ||= options[:client]
						@restforce_table_name ||= options[:table_name]
						@restforce_attributes ||= options[:attributes]

						def self.method_missing method_name, *args, &block
							
							client = @restforce_client.send(@restforce_table_name, @restforce_attributes)

							if !@has_many.nil? && !@has_many.empty?
								@has_many.each do |params|
									client = client.with_many params[0], params[1]
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