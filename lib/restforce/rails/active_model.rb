module Restforce
	module Rails
		module ActiveModel

			def self.included(base)				
				base.class_eval do
					
					@has_many ||= []

					def self.has_many table_name, options={}
						@has_many << [table_name, options]
					end

					def self.restforce client, table_name
						@restforce_client ||= client
						@restforce_table_name ||= table_name

						def self.method_missing method_name, *args, &block
							
							client = @restforce_client.send(@restforce_table_name)

							if !@has_many.nil? && !@has_many.empty?
								@has_many.each do |params|
									client = client.with_many params[0], params[1]
								end
							end

				  		if client.respond_to?(method_name)
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