module Restforce
	module Rails
		class ActiveModel

			def self.restforce client, table_name
				@@restforce_client ||= client
				@@restforce_table_name ||= table_name

				def self.method_missing method_name, *args, &block
		  		if @@restforce_client.send(@@restforce_table_name).respond_to?(method_name)
						@@restforce_client.send(@@restforce_table_name).send(method_name, *args, &block)
					else
						super
					end
				end

			end
		end
	end
end