require 'restforce/client/verbs'

module Restforce
  class Client
    module API
      extend Restforce::Client::Verbs

      # Public: Helper methods for performing arbitrary actions against the API using
      # various HTTP verbs.
      #
      # Examples
      #
      #   # Perform a get request
      #   client.get '/services/data/v24.0/sobjects'
      #   client.api_get 'sobjects'
      #
      #   # Perform a post request
      #   client.post '/services/data/v24.0/sobjects/Account', { ... }
      #   client.api_post 'sobjects/Account', { ... }
      #
      #   # Perform a put request
      #   client.put '/services/data/v24.0/sobjects/Account/001D000000INjVe', { ... }
      #   client.api_put 'sobjects/Account/001D000000INjVe', { ... }
      #
      #   # Perform a delete request
      #   client.delete '/services/data/v24.0/sobjects/Account/001D000000INjVe'
      #   client.api_delete 'sobjects/Account/001D000000INjVe'
      #
      # Returns the Faraday::Response.
      define_verbs :get, :post, :put, :delete, :patch, :head

      # Public: Get the names of all sobjects on the org.
      #
      # Examples
      #
      #   # get the names of all sobjects on the org
      #   client.list_sobjects
      #   # => ['Account', 'Lead', ... ]
      #
      # Returns an Array of String names for each SObject.
      def list_sobjects
        describe.collect { |sobject| sobject['name'] }
      end
      
      # Public: Returns a detailed describe result for the specified sobject
      #
      # sobject - Stringish name of the sobject (default: nil).
      #
      # Examples
      #
      #   # get the global describe for all sobjects
      #   client.describe
      #   # => { ... }
      #
      #   # get the describe for the Account object
      #   client.describe('Account')
      #   # => { ... }
      #
      # Returns the Hash representation of the describe call.
      def describe(sobject = nil)
        if sobject
          api_get("sobjects/#{sobject.to_s}/describe").body
        else
          api_get('sobjects').body['sobjects']
        end
      end

      # Public: Get the current organization's Id.
      #
      # Examples
      #
      #   client.org_id
      #   # => '00Dx0000000BV7z'
      #
      # Returns the String organization Id
      def org_id
        query('select id from Organization').first['Id']
      end
      
      # Public: Executs a SOQL query and returns the result.
      #
      # soql - A SOQL expression.
      #
      # Examples
      #
      #   # Find the names of all Accounts
      #   client.query('select Name from Account').map(&:Name)
      #   # => ['Foo Bar Inc.', 'Whizbang Corp']
      #
      # Returns a Restforce::Collection if Restforce.configuration.mashify is true.
      # Returns an Array of Hash for each record in the result if Restforce.configuration.mashify is false.
      def query(soql)
        response = api_get 'query', :q => soql
        mashify? ? response.body : response.body['records']
      end
      
      # Public: Perform a SOSL search
      #
      # sosl - A SOSL expression.
      #
      # Examples
      #
      #   # Find all occurrences of 'bar'
      #   client.search('FIND {bar}')
      #   # => #<Restforce::Collection >
      #
      #   # Find accounts match the term 'genepoint' and return the Name field
      #   client.search('FIND {genepoint} RETURNING Account (Name)').map(&:Name)
      #   # => ['GenePoint']
      #
      # Returns a Restforce::Collection if Restforce.configuration.mashify is true.
      # Returns an Array of Hash for each record in the result if Restforce.configuration.mashify is false.
      def search(sosl)
        api_get('search', :q => sosl).body
      end
      
      # Public: Insert a new record.
      #
      # sobject - String name of the sobject.
      # attrs   - Hash of attributes to set on the new record.
      #
      # Examples
      #
      #   # Add a new account
      #   client.create('Account', Name: 'Foobar Inc.')
      #   # => '0016000000MRatd'
      #
      # Returns the String Id of the newly created sobject.
      # Returns false if something bad happens.
      def create(*args)
        create!(*args)
      rescue *exceptions
        false
      end
      alias_method :insert, :create

      # Public: Insert a new record.
      #
      # sobject - String name of the sobject.
      # attrs   - Hash of attributes to set on the new record.
      #
      # Examples
      #
      #   # Add a new account
      #   client.create!('Account', Name: 'Foobar Inc.')
      #   # => '0016000000MRatd'
      #
      # Returns the String Id of the newly created sobject.
      # Raises exceptions if an error is returned from Salesforce.
      def create!(sobject, attrs)
        api_post("sobjects/#{sobject}", attrs).body['id']
      end
      alias_method :insert!, :create!

      # Public: Update a record.
      #
      # sobject - String name of the sobject.
      # attrs   - Hash of attributes to set on the record.
      #
      # Examples
      #
      #   # Update the Account with Id '0016000000MRatd'
      #   client.update('Account', Id: '0016000000MRatd', Name: 'Whizbang Corp')
      #
      # Returns true if the sobject was successfully updated.
      # Returns false if there was an error.
      def update(*args)
        update!(*args)
      rescue *exceptions
        false
      end

      # Public: Update a record.
      #
      # sobject - String name of the sobject.
      # attrs   - Hash of attributes to set on the record.
      #
      # Examples
      #
      #   # Update the Account with Id '0016000000MRatd'
      #   client.update!('Account', Id: '0016000000MRatd', Name: 'Whizbang Corp')
      #
      # Returns true if the sobject was successfully updated.
      # Raises an exception if an error is returned from Salesforce.
      def update!(sobject, attrs)
        id = attrs.delete(attrs.keys.find { |k| k.to_s.downcase == 'id' })
        raise 'Id field missing.' unless id
        api_patch "sobjects/#{sobject}/#{id}", attrs
        true
      end

      # Public: Update or create a record based on an external ID
      #
      # sobject - The name of the sobject to created.
      # field   - The name of the external Id field to match against.
      # attrs   - Hash of attributes for the record.
      #
      # Examples
      #
      #   # Update the record with external ID of 12
      #   client.upsert('Account', 'External__c', External__c: 12, Name: 'Foobar')
      #
      # Returns true if the record was found and updated.
      # Returns the Id of the newly created record if the record was created.
      # Returns false if something bad happens.
      def upsert(*args)
        upsert!(*args)
      rescue *exceptions
        false
      end

      # Public: Update or create a record based on an external ID
      #
      # sobject - The name of the sobject to created.
      # field   - The name of the external Id field to match against.
      # attrs   - Hash of attributes for the record.
      #
      # Examples
      #
      #   # Update the record with external ID of 12
      #   client.upsert!('Account', 'External__c', External__c: 12, Name: 'Foobar')
      #
      # Returns true if the record was found and updated.
      # Returns the Id of the newly created record if the record was created.
      # Raises an exception if an error is returned from Salesforce.
      def upsert!(sobject, field, attrs)
        external_id = attrs.delete(attrs.keys.find { |k| k.to_s.downcase == field.to_s.downcase })
        response = api_patch "sobjects/#{sobject}/#{field.to_s}/#{external_id}", attrs
        (response.body && response.body['id']) ? response.body['id'] : true
      end

      # Public: Delete a record.
      #
      # sobject - String name of the sobject.
      # id      - The Salesforce ID of the record.
      #
      # Examples
      #
      #   # Delete the Account with Id '0016000000MRatd'
      #   client.destroy('Account', '0016000000MRatd')
      #
      # Returns true if the sobject was successfully deleted.
      # Returns false if an error is returned from Salesforce.
      def destroy(*args)
        destroy!(*args)
      rescue *exceptions
        false
      end

      # Public: Delete a record.
      #
      # sobject - String name of the sobject.
      # id      - The Salesforce ID of the record.
      #
      # Examples
      #
      #   # Delete the Account with Id '0016000000MRatd'
      #   client.destroy('Account', '0016000000MRatd')
      #
      # Returns true of the sobject was successfully deleted.
      # Raises an exception if an error is returned from Salesforce.
      def destroy!(sobject, id)
        api_delete "sobjects/#{sobject}/#{id}"
        true
      end

      # Public: Finds a single record and returns all fields.
      #
      # sobject - The String name of the sobject.
      # id      - The id of the record. If field is specified, id should be the id
      #           of the external field.
      # field   - External ID field to use (default: nil).
      #
      # Returns the Restforce::SObject sobject record.
      def find(sobject, id, field=nil)
        api_get(field ? "sobjects/#{sobject}/#{field}/#{id}" : "sobjects/#{sobject}/#{id}").body
      end

    private

      def method_missing(method_name, *args, &block)
        if self.class == Restforce::Client
          proxy(method_name)
        elsif self.class == Restforce::Client::Query
          proxy.send(method_name, *args, &block)
        else
          super
        end
      end

      def proxy(entity=nil)
        self.kind_of?(Restforce::Client::Query) ? self : Query.new(self,entity)
      end

      # Internal: Returns a path to an api endpoint
      #
      # Examples
      #
      #   api_path('sobjects')
      #   # => '/services/data/v24.0/sobjects'
      def api_path(path)
        "/services/data/v#{@options[:api_version]}/#{path}"
      end

      # Internal: Errors that should be rescued from in non-bang methods
      def exceptions
        [Faraday::Error::ClientError]
      end


      class Query
        include Enumerable

        def initialize klass, entity
          @klass = klass
          @entity = entity
          @criteria = {}
          @criteria[:selects], @criteria[:conditions], @criteria[:orders],@criteria[:limit] = [], {}, [], ''

          @fetch_data = false
          @single_element = true
        end

        def select *fields
          options = {}
          if fields.last.kind_of? Hash
            options = fields.pop
            options.reverse_merge!(:fetch_data => false) 
          end

          @criteria[:selects].concat fields

          @fetch_data = true if options[:fetch_data]
          self
        end

        def all
          @fetch_data = true
          self
        end

        def where *where_clauses
          where_clauses.each do |where_clause|
            case where_clause.class.name
            when 'String'
              unless where_clause.empty?
                @criteria[:conditions][:string] = '' if @criteria[:conditions][:string].nil?
                unless @criteria[:conditions][:string].empty?
                  @criteria[:conditions][:string] << " AND #{where_clause}"
                else
                  @criteria[:conditions][:string] << where_clause 
                end
              end
            when 'Hash'
              @criteria[:conditions].merge!(where_clause) unless where_clause.empty?
            end
          end

          @fetch_data = true
          self
        end

        def order *order_clause
          @criteria[:orders].concat order_clause
          @fetch_data = true
          self 
        end

        def limit limit
          @criteria[:limit] = limit.to_s if limit.kind_of?(String) || limit.kind_of?(Integer)
          @fetch_data = true
          self
        end

        def inspect
          execute_query
        end

        def each(&block)
          execute_query('each', &block)
        end

        def to_a
          execute_query
        end

        def to_s
          execute_query
        end

        private

        def fetch_array array
          array.join(',')
        end

        def fetch_hash hash
          hash.map{|k,v| k == :string ? v : "#{k} = '#{v}'"}.join(' AND ')
        end

        def fetch_select
          unless @criteria[:selects].empty?
            fetch_array @criteria[:selects]  
          else
            'Id,Name'
          end
        end

        def fetch_where
          fetch_hash @criteria[:conditions] unless @criteria[:conditions].empty?
        end

        def fetch_order
          fetch_array @criteria[:orders] unless @criteria[:orders].empty?
        end

        def fetch_limit
          @criteria[:limit] unless @criteria[:limit].empty?
        end

        def build_query
          where, order, limit = fetch_where, fetch_order, fetch_limit 

          result = []
          result << "SELECT #{fetch_select}"
          result << "FROM #{@entity}"
          result << "WHERE #{fetch_where}" unless where.nil? || where.empty?
          result << "ORDER BY #{fetch_order}" unless order.nil? || order.empty?
          result << "LIMIT #{@criteria[:limit]}" unless limit.nil? || limit.empty?
          result.join(' ')
        end

        def method_missing(method_name, *args, &block)
          if self.to_a.respond_to? method_name
            self.to_a.send(method_name, *args, &block)
          else
            super
          end
        end

        def execute_query type=nil, &block
          case type
          when 'each'
            @klass.query(build_query).each do |record|
              if block_given?
                block.call record
              else
                yield record
              end
            end
          else
            @fetch_data ? @klass.query(build_query) : self
          end
        end
      end
    end
  end
end
