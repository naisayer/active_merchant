require 'rexml/document'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class EwayTokenGateway < Gateway
      class_inheritable_accessor :test_url, :live_url

      self.test_url = 'https://www.eway.com.au/gateway/ManagedPaymentService/test/managedCreditCardPayment.asmx'
      self.live_url = 'https://www.eway.com.au/gateway/ManagedPaymentService/managedCreditCardPayment.asmx'
    
      EWAY_TOKEN_ACTIONS = {
        :create_customer => 'CreateCustomer',
        :update_customer => 'UpdateCustomer',
        :query_customer => 'QueryCustomer',
        :query_customer_by_reference => 'QueryCustomerByReference',
        :process_payment => 'ProcessPayment',
        :query_payment => 'QueryPayment'
      }

      # Creates a new EwayTokenGateway
      #
      # The gateway requires a valid Eway Customer ID, Username and Password in the +options+ hash.
      #
      # ==== Options
      #
      # * <tt>:login</tt> -- Your Eway Business Centre Login, which is actually an email address (REQUIRED)
      # * <tt>:password</tt> -- Your Eway Business Centre Password (REQUIRED)
      # * <tt>:customer_id</tt> -- Your Eway Customer ID (REQUIRED)
      # * <tt>:test</tt> -- +true+ or +false+. If true, perform transactions against the test server. 
      #   Otherwise, perform transactions against the production server.
      def initialize(options)
        requires!(options, :login, :password, :customer_id)
        @options = options
        super
      end

      # Create a new Eway Customer
      # 
      # ==== Options
      #
      # * <tt>:title</tt> -- Your customers title and it must be one of these values; Mr., Ms., Mrs., Miss, Dr., Sir. or Prof. (REQUIRED)
      # * <tt>:first_name</tt> -- The first name of your customer
      # * <tt>:last_name</tt> -- The last name of your customer
      # * <tt>:address</tt> -- Your customers physical address
      # * <tt>:suburb</tt> -- Your customers city/suburb
      # * <tt>:state</tt> -- Your customers State
      # * <tt>:company</tt> -- The company your customer works for
      # * <tt>:post_code</tt> -- Your customers Post code
      # * <tt>:country</tt> -- Your customers Country. It must be valid two character country code. E.g. au for Australia and uk for United Kingdom. (REQUIRED)
      # * <tt>:email</tt> -- Your customers Email address
      # * <tt>:fax</tt> -- Your customers fax number (Only digit numbers allowed)
      # * <tt>:phone</tt> -- Your customers Phone Number (Only digit numbers allowed)
      # * <tt>:mobile</tt> -- Your customers mobile number (Only digit numbers allowed),
      # * <tt>:customer_ref</tt> -- Your own reference number for your customer
      # * <tt>:job_desc</tt> -- Your customers job description/title, e.g. CEO, Director etc
      # * <tt>:comments</tt> -- Any comments that your customer wishes to add, or you wish to add about the customer
      # * <tt>:url</tt> -- The URL of your customers website
      # * <tt>:credit_card</tt> -- A valid credit card object
      #
      # ==== Returns
      # 
      # * A eway customer id
      #
      # ==== Example
      # 
      #   @gateway = ActiveMerchant::Billing::Base.gateway(:eway_token).new(:login => '87654321', :username => 'test@eway.com.au', :password => 'test123')
      #   result = @gateway.create_customer({
      #     :title => 'Mr.',
      #     :first_name => 'Joe',
      #     :last_name => 'Bloggs',
      #     :address => 'Bloggs Enterprise',
      #     :suburb => 'Capital City',
      #     :state => 'ACT',
      #     :company => 'Bloggs',
      #     :post_code => '2111',
      #     :country => 'AU',
      #     :email => 'test@eway.com.au',
      #     :fax => '0298989898',
      #     :phone => '0297979797',
      #     :mobile => '',
      #     :customer_ref => 'Ref123',
      #     :job_desc => '',
      #     :comments => 'Please Ship ASAP',
      #     :url => 'http://www.test.com.au',
      #     :credit_card => credit_card(4444333322221111)
      #   })
      #   result.params['create_customer_result']
      #   => 112233445566
      def create_customer(options)
        request = build_request(:create_customer, options) 
        commit(:create_customer, request)
      end

      # Returns the details of a customer. Returns a failed result if the customer doesn't exist
      #
      # ==== Options
      #
      # * <tt>:managed_customer_id</tt> The eway customer id (REQUIRED)
      #
      # ==== Returns
      #
      # * A customer object
      #
      # ==== Example
      #
      #     @gateway = ActiveMerchant::Billing::Base.gateway(:eway_token).new(:login => '87654321', :username => 'test@eway.com.au', :password => 'test123')
      #     result = @gateway.query_customer({ :managed_customer_id => 9876543211000 })
      #     if result.success
      #       result.params['query_customer_result']['managed_customer_id']
      #       result.params['query_customer_result']['customer_ref']
      #       response.params['query_customer_result']['customer_title']
      #       response.params['query_customer_result']['customer_first_name']
      #       response.params['query_customer_result']['customer_company']
      #       response.params['query_customer_result']['customer_job_desc']
      #       response.params['query_customer_result']['customer_email']
      #       response.params['query_customer_result']['customer_address']
      #       response.params['query_customer_result']['customer_suburb']
      #       response.params['query_customer_result']['customer_state']
      #       response.params['query_customer_result']['customer_post_code']
      #       response.params['query_customer_result']['customer_country']
      #       response.params['query_customer_result']['customer_phone1']
      #       response.params['query_customer_result']['customer_phone2']
      #       response.params['query_customer_result']['customer_fax']
      #       response.params['query_customer_result']['customer_url']
      #       response.params['query_customer_result']['customer_comments']
      #       response.params['query_customer_result']['cc_name']
      #       response.params['query_customer_result']['cc_expiry_month']
      #       response.params['query_customer_result']['cc_expiry_year']
      #     else
      #       error = response.message
      #     end
      def query_customer(options)
        request = build_request(:query_customer, options) 
        commit(:query_customer, request)
      end

      # Returns the details of a customer, identified by your customer reference. Returns a failed result if the customer doesn't exist
      #
      # ==== Options
      #
      # * <tt>:customer_reference</tt> The customer reference (REQUIRED)
      #
      # ==== Returns
      #
      # * A customer object
      #
      # ==== Example
      #
      #     @gateway = ActiveMerchant::Billing::Base.gateway(:eway_token).new(:login => '87654321', :username => 'test@eway.com.au', :password => 'test123')
      #     result = @gateway.query_customer_by_reference({ :customer_reference => 'test 123' })
      #     if result.success
      #       result.params['query_customer_result']['managed_customer_id']
      #       result.params['query_customer_result']['customer_ref']
      #       response.params['query_customer_result']['customer_title']
      #       response.params['query_customer_result']['customer_first_name']
      #       response.params['query_customer_result']['customer_company']
      #       response.params['query_customer_result']['customer_job_desc']
      #       response.params['query_customer_result']['customer_email']
      #       response.params['query_customer_result']['customer_address']
      #       response.params['query_customer_result']['customer_suburb']
      #       response.params['query_customer_result']['customer_state']
      #       response.params['query_customer_result']['customer_post_code']
      #       response.params['query_customer_result']['customer_country']
      #       response.params['query_customer_result']['customer_phone1']
      #       response.params['query_customer_result']['customer_phone2']
      #       response.params['query_customer_result']['customer_fax']
      #       response.params['query_customer_result']['customer_url']
      #       response.params['query_customer_result']['customer_comments']
      #       response.params['query_customer_result']['cc_name']
      #       response.params['query_customer_result']['cc_expiry_month']
      #       response.params['query_customer_result']['cc_expiry_year']
      #     else
      #       error = response.message
      #     end
      def query_customer_by_reference(options)
        request = build_request(:query_customer_by_reference, options) 
        commit(:query_customer_by_reference, request)
      end

      # Update an existing Eway Customer
      # 
      # ==== Options
      #
      # * <tt>:managed_customer_id</tt> -- The eway customer id of the customer you wish to update
      # * <tt>:title</tt> -- Your customers title and it must be one of these values; Mr., Ms., Mrs., Miss, Dr., Sir. or Prof. (REQUIRED)
      # * <tt>:first_name</tt> -- The first name of your customer
      # * <tt>:last_name</tt> -- The last name of your customer
      # * <tt>:address</tt> -- Your customers physical address
      # * <tt>:suburb</tt> -- Your customers city/suburb
      # * <tt>:state</tt> -- Your customers State
      # * <tt>:company</tt> -- The company your customer works for
      # * <tt>:post_code</tt> -- Your customers Post code
      # * <tt>:country</tt> -- Your customers Country. It must be valid two character country code. E.g. au for Australia and uk for United Kingdom. (REQUIRED)
      # * <tt>:email</tt> -- Your customers Email address
      # * <tt>:fax</tt> -- Your customers fax number (Only digit numbers allowed)
      # * <tt>:phone</tt> -- Your customers Phone Number (Only digit numbers allowed)
      # * <tt>:mobile</tt> -- Your customers mobile number (Only digit numbers allowed),
      # * <tt>:customer_ref</tt> -- Your own reference number for your customer
      # * <tt>:job_desc</tt> -- Your customers job description/title, e.g. CEO, Director etc
      # * <tt>:comments</tt> -- Any comments that your customer wishes to add, or you wish to add about the customer
      # * <tt>:url</tt> -- The URL of your customers website
      # * <tt>:credit_card</tt> -- A valid credit card object
      #
      # ==== Returns
      # 
      # * A eway customer id
      #
      # ==== Example
      # 
      #   @gateway = ActiveMerchant::Billing::Base.gateway(:eway_token).new(:login => '87654321', :username => 'test@eway.com.au', :password => 'test123')
      #   result = @gateway.create_customer({
      #     :managed_customer_id => 9876543211000,
      #     :title => 'Mr.',
      #     :first_name => 'Joe',
      #     :last_name => 'Bloggs',
      #     :address => 'Bloggs Enterprise',
      #     :suburb => 'Capital City',
      #     :state => 'ACT',
      #     :company => 'Bloggs',
      #     :post_code => '2111',
      #     :country => 'AU',
      #     :email => 'test@eway.com.au',
      #     :fax => '0298989898',
      #     :phone => '0297979797',
      #     :mobile => '',
      #     :customer_ref => 'Ref123',
      #     :job_desc => '',
      #     :comments => 'Please Ship ASAP',
      #     :url => 'http://www.test.com.au',
      #     :credit_card => credit_card(4444333322221111)
      #   })
      #   response.params['update_customer_result']
      #   => true
      def update_customer(options)
        request = build_request(:update_customer, options)
        commit(:update_customer, request)
      end

      # Trigger a payment
      #
      # ==== Options
      # 
      # * <tt>:managed_customer_id</tt> -- The eway customer id of the customer you wish to update
      # * <tt>:amount</tt> -- The amount in cents
      # * <tt>:invoice_reference</tt> -- A reference for the invoice
      # * <tt>:invoice_description</tt> -- A decription for the invoice
      #
      # ==== Returns
      #
      # An ActiveMerchant response object
      #
      # ==== Example
      #   @gateway = ActiveMerchant::Billing::Base.gateway(:eway_token).new(:login => '87654321', :username => 'test@eway.com.au', :password => 'test123')
      #   result = @gateway.process_payment({
      #     :managed_customer_id => 9876543211000,
      #     :amount => 1000,
      #     :invoice_reference => 'INV1',
      #     :invoice_description => 'New invoice'
      #   })
      #
      #   if result.success
      #     response.authorization
      #     response.message
      #   else
      #     response.message
      #   end
      def process_payment(options)
        request = build_request(:process_payment, options)
        commit(:process_payment, request)
      end

      # Returns all past payments for the customer
      #
      # ==== Options
      #
      # * <tt>:managed_customer_id</tt> -- The eway customer id of the customer you wish to update
      #
      # ==== Returns 
      #
      # an array of payments
      #
      # ==== Example
      #
      #   @gateway = ActiveMerchant::Billing::Base.gateway(:eway_token).new(:login => '87654321', :username => 'test@eway.com.au', :password => 'test123')
      #   result = @gateway.query_payment({
      #     :managed_customer_id => 9876543211000,
      #   })
      #
      #   response.params['query_payment_result']['managed_transaction'].size # Returns the number of transactions
      #   
      #   response.params['query_payment_result']['managed_transaction'][0]['result']
      #   response.params['query_payment_result']['managed_transaction'][0]['total_amount']
      #   response.params['query_payment_result']['managed_transaction'][0]['eway_trxn_number']
      #   response.params['query_payment_result']['managed_transaction'][0]['response_text']
      def query_payment(options)
        request = build_request(:query_payment, options)
        commit(:query_payment, request)
      end

      # A more ActiveMerchant style method to create a customer
      #
      # * <tt>:credit_card</tt> -- A valid credit card object
      # 
      # ==== Options
      # * <tt>:title</tt> -- Your customers title and it must be one of these values; Mr., Ms., Mrs., Miss, Dr., Sir. or Prof. (REQUIRED)
      # * <tt>:first_name</tt> -- The first name of your customer
      # * <tt>:last_name</tt> -- The last name of your customer
      # * <tt>:company</tt> -- The company your customer works for
      # * <tt>:email</tt> -- Your customers Email address
      # * <tt>:customer_ref</tt> -- Your own reference number for your customer
      # * <tt>:job_desc</tt> -- Your customers job description/title, e.g. CEO, Director etc
      # * <tt>:comments</tt> -- Any comments that your customer wishes to add, or you wish to add about the customer
      # * <tt>:url</tt> -- The URL of your customers website
      # * <tt>billing_address</tt> -- An ActiveMerchant billing_address object 
      #
      # ==== Returns
      #
      # See the create_customer method
      def store(credit_card, options = {})
        requires!(options, :billing_address)
        options = convert_address(options)
        create_customer(options.merge({ :credit_card => credit_card }))
      end

      # A more ActiveMerchant style method to update a customer
      #
      # * <tt>managed_customer_id</tt> The managed customer id
      # * <tt>:credit_card</tt> -- A valid credit card object
      #
      # ==== Options
      #
      # * <tt>:title</tt> -- Your customers title and it must be one of these values; Mr., Ms., Mrs., Miss, Dr., Sir. or Prof. (REQUIRED)
      # * <tt>:first_name</tt> -- The first name of your customer
      # * <tt>:last_name</tt> -- The last name of your customer
      # * <tt>:company</tt> -- The company your customer works for
      # * <tt>:email</tt> -- Your customers Email address
      # * <tt>:customer_ref</tt> -- Your own reference number for your customer
      # * <tt>:job_desc</tt> -- Your customers job description/title, e.g. CEO, Director etc
      # * <tt>:comments</tt> -- Any comments that your customer wishes to add, or you wish to add about the customer
      # * <tt>:url</tt> -- The URL of your customers website
      # * <tt>billing_address</tt> -- An ActiveMerchant billing_address object 
      #
      # ==== Returns
      #
      # See the update_customer method
      def update(managed_customer_id, credit_card, options = {})
        requires!(options, :billing_address)
        options = convert_address(options)
        update_customer(options.merge({ :managed_customer_id => managed_customer_id, :credit_card => credit_card }))
      end

      # A more ActiveMerchant style method to process a payment
      #
      # ==== Options
      #
      # * <tt>money</tt> The amount in cents
      # * <tt>managed_customer_id</tt> The managed customer id
      # * <tt>options</tt> See the options paramaters for process_payment (you can omit the managed_customer_id and amount options)
      #
      # ==== Returns
      #
      # See the process_payment method

      def purchase(money, managed_customer_id, options = {})
        process_payment(options.merge({ :managed_customer_id => managed_customer_id, :amount => money }))
      end

    protected
      # Build methods
      def build_request(action, options = {})
        xml = Builder::XmlMarkup.new(:indent => 0)
        xml.instruct!(:xml, :version => '1.0', :encoding => 'utf-8')

        xml.soap :Envelope, { 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema', 'xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/'  } do |envelope|
          envelope.soap :Header do |header|
            header.eWAYHeader :xmlns => 'https://www.eway.com.au/gateway/managedpayment' do |ewayHeader|
              ewayHeader.eWAYCustomerID(@options[:customer_id])
              ewayHeader.Username(@options[:login])
              ewayHeader.Password(@options[:password])
            end
          end

          envelope.soap :Body do |body|
            send("build_#{action}_request", body, options)
          end
        end
      end

      def build_create_customer_request(xml, options)
        xml.CreateCustomer :xmlns => "https://www.eway.com.au/gateway/managedpayment" do |customer|
          add_customer(xml, options)
        end
      end

      def build_query_customer_request(xml, options)
        xml.QueryCustomer :xmlns => "https://www.eway.com.au/gateway/managedpayment" do |customer|
        requires!(options, :managed_customer_id)
          customer.managedCustomerID(options[:managed_customer_id])
        end
      end

      def build_query_customer_by_reference_request(xml, options)
        requires!(options, :customer_reference)
        xml.QueryCustomerByReference :xmlns => "https://www.eway.com.au/gateway/managedpayment" do |customer|
          customer.CustomerReference(options[:customer_reference])
        end
      end

      def build_update_customer_request(xml, options)
        requires!(options, :managed_customer_id)
        xml.UpdateCustomer :xmlns => "https://www.eway.com.au/gateway/managedpayment" do |customer|
          customer.managedCustomerID(options[:managed_customer_id])
          add_customer(xml, options)
        end
      end

      def add_customer(xml, options)
        requires!(options, :title, :address)
        
        xml.Title(options[:title])
        xml.FirstName(options[:first_name])
        xml.LastName(options[:last_name])
        xml.Address(options[:address])
        xml.Suburb(options[:suburb])
        xml.State(options[:state])
        xml.Company(options[:company])
        xml.PostCode(options[:post_code])
        xml.Country(options[:country].downcase)
        xml.Email(options[:email])
        xml.Fax(options[:fax])
        xml.Phone(options[:phone])
        xml.Mobile(options[:mobile])
        xml.CustomerRef(options[:customer_ref])
        xml.JobDesc(options[:job_desc])
        xml.Comments(options[:comments])
        xml.URL(options[:url])

        add_credit_card(xml, options[:credit_card]) 
      end

      def add_credit_card(xml, credit_card)
        return unless credit_card
        
        xml.CCNumber(credit_card.number)
        xml.CCNameOnCard(credit_card.name)
        xml.CCExpiryMonth(sprintf("%.2i", credit_card.month))
        xml.CCExpiryYear(sprintf("%.4i", credit_card.year)[-2..-1])
      end

      def convert_address(options = {})
        billing_address = options.delete(:billing_address)

        options[:address]  = billing_address[:address1].to_s
        options[:phone]  = billing_address[:phone].to_s
        options[:post_code]  = billing_address[:zip].to_s
        options[:suburb]  = billing_address[:city].to_s
        options[:country]  = billing_address[:country].to_s
        options[:state]  = billing_address[:state].to_s
        options[:mobile]  = billing_address[:mobile].to_s
        options[:fax]  = billing_address[:fax].to_s

        options
      end

      def build_process_payment_request(xml, options)
        requires!(options, :managed_customer_id, :amount)
        xml.ProcessPayment :xmlns => "https://www.eway.com.au/gateway/managedpayment" do |payment|
          payment.managedCustomerID(options[:managed_customer_id])
          payment.amount(options[:amount])
          payment.invoiceReference(options[:invoice_reference])
          payment.invoiceDescription(options[:invoice_description])
        end
      end

      def build_query_payment_request(xml, options)
        xml.QueryPayment :xmlns => "https://www.eway.com.au/gateway/managedpayment" do |query|
          query.managedCustomerID(options[:managed_customer_id])
        end
      end

      def commit(action, request)
        url = test? ? test_url : live_url
        begin
          xml = ssl_post(url, request, "Content-Type" => "text/xml; charset=utf-8", 'SOAPAction' => "\"https://www.eway.com.au/gateway/managedpayment/#{EWAY_TOKEN_ACTIONS[action]}\"")
        rescue ActiveMerchant::ResponseError => e
          xml = e.response.body
        end
        
        response_params = parse(action, xml)
        test_mode = test?
        
        message = ''
        if response_params && response_params['eway_response']
          success = response_params['eway_response']['eway_trxn_status'] == 'True'
          message = response_params['eway_response']['eway_trxn_error'].split(',').last
        else
          success = response_params != nil && response_params['faultcode'] == nil 
          message = response_params['faultstring'] if response_params
        end

        response = Response.new(success, message, response_params || {},
          :test => test_mode,
          :authorization => response_params && response_params['eway_response'] ? response_params['eway_response']['eway_auth_code'] : nil # Put auth number in here
        )
        response
      end

      # Parse actions
      def parse(action, xml)
        xml = REXML::Document.new(xml)
        root = REXML::XPath.first(xml, "//#{EWAY_TOKEN_ACTIONS[action]}Response") || REXML::XPath.first(xml, "//soap:Fault")
        response = parse_element(root) if root
        response
      end

      def parse_element(node)
        if node.has_elements?
          response = {}
          node.elements.each{ |e|
            key = e.name.underscore
            value = parse_element(e)
            if response.has_key?(key)
              if response[key].is_a?(Array)
                response[key].push(value)
              else
                response[key] = [response[key], value]
              end
            else
              response[key] = parse_element(e) 
            end 
          }
        else
          response = node.text
        end

        response
      end
    end
  end
end
