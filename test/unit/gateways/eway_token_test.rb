require 'test_helper'

class EwayTokenTest < Test::Unit::TestCase
  def setup
    @gateway = EwayTokenGateway.new(
      :customer_id => '87654321',
      :login => 'test@eway.com.au',
      :password => 'test123'
    )

    @customer = {
      :title => 'Mr',
      :first_name => 'Joe',
      :last_name => 'Bloggs',
      :address => 'Bloggs Enterprise',
      :suburb => 'Capital City',
      :state => 'ACT',
      :company => 'Bloggs',
      :post_code => '2111',
      :country => 'Australia',
      :email => 'test@eway.com.au',
      :fax => '0298989898',
      :phone => '0297979797',
      :mobile => '',
      :customer_ref => 'Ref123',
      :job_desc => '',
      :comments => 'Please Ship ASAP',
      :url => 'http://www.test.com.au',
      :credit_card => credit_card
    }

    @payment = {
      :managed_customer_id => '12345678901',
      :amount => 1000,
      :invoice_reference => 'Test Inv',
      :invoice_description => 'Test Description'
    }
  end

  def test_successful_create_customer
    @gateway.expects(:ssl_post).returns(successful_create_customer_response)
   
    assert response = @gateway.create_customer(@customer)

    assert_instance_of Response, response
    assert_success response
    assert_nil response.authorization
    assert_equal 'Test 123', response.params['create_customer_result']
  end

  def test_failed_create_customer
    @gateway.expects(:ssl_post).returns(failed_create_customer_response)
   
    assert response = @gateway.create_customer(@customer)
    assert_instance_of Response, response
    assert_failure response
    assert_nil response.authorization
    assert_equal "The 'CustomerCountry' element is invalid - The value 'australia' is invalid according to its datatype 'Country' - The Pattern constraint failed.", response.message
  end

  def test_successful_update_customer
    @gateway.expects(:ssl_post).returns(successful_update_customer_response)
   
    assert response = @gateway.update_customer(@customer)

    assert_instance_of Response, response
    assert_success response
    assert_nil response.authorization
    assert_equal 'true', response.params['update_customer_result']
  end

  def test_failed_update_customer
    @gateway.expects(:ssl_post).returns(failed_update_customer_response)
   
    assert response = @gateway.update_customer(@customer)
    assert_instance_of Response, response
    assert_failure response
    assert_nil response.authorization
    assert_equal "The 'CustomerURL' element is invalid - The value 'test' is invalid according to its datatype 'AnyURL' - The Pattern constraint failed.", response.message
  end

  def test_successful_query_customer
    @gateway.expects(:ssl_post).returns(successful_query_customer_response)
   
    assert response = @gateway.query_customer({ :managed_customer_id => '123456789012' })

    assert_instance_of Response, response
    assert_success response
    assert_nil response.authorization
    assert_equal '127421360542', response.params['query_customer_result']['managed_customer_id']
    assert_equal 'Testing - 123', response.params['query_customer_result']['customer_ref']
    assert_equal 'Miss', response.params['query_customer_result']['customer_title']
    assert_equal 'Account', response.params['query_customer_result']['customer_first_name']
    assert_equal 'Testing', response.params['query_customer_result']['customer_company']
    assert_equal 'Tester', response.params['query_customer_result']['customer_job_desc']
    assert_equal 'test@eway.com.au', response.params['query_customer_result']['customer_email']
    assert_equal '37 test', response.params['query_customer_result']['customer_address']
    assert_equal 'Ngu', response.params['query_customer_result']['customer_suburb']
    assert_equal 'ACT', response.params['query_customer_result']['customer_state']
    assert_equal '2211', response.params['query_customer_result']['customer_post_code']
    assert_equal 'au', response.params['query_customer_result']['customer_country']
    assert_equal '0255556677', response.params['query_customer_result']['customer_phone1']
    assert_equal '040411225588', response.params['query_customer_result']['customer_phone2']
    assert_equal '0255556666', response.params['query_customer_result']['customer_fax']
    assert_equal 'http://www.test-test.com', response.params['query_customer_result']['customer_url']
    assert_equal 'Testing web services modified', response.params['query_customer_result']['customer_comments']
    assert_equal 'Moe Oo', response.params['query_customer_result']['cc_name']
    assert_equal '2', response.params['query_customer_result']['cc_expiry_month']
    assert_equal '12', response.params['query_customer_result']['cc_expiry_year']
  end

  def test_failed_query_customer
    @gateway.expects(:ssl_post).returns(failed_query_customer_response)
   
    assert response = @gateway.query_customer(@customer)
    assert_instance_of Response, response
    assert_failure response
    assert_nil response.authorization
    assert_equal "", response.message
  end

  def test_successful_process_payment
    @gateway.expects(:ssl_post).returns(successful_process_payment_response)
   
    assert response = @gateway.process_payment(@payment)
    assert_instance_of Response, response
    assert_success response
    assert_equal '12345', response.authorization
    assert_equal 'Transaction Approved(Test Gateway)', response.message
  end

  def test_failed_process_payment
    @gateway.expects(:ssl_post).returns(failed_process_payment_response)
   
    assert response = @gateway.process_payment(@payment)
    
    assert_instance_of Response, response
    assert_failure response
    assert_nil response.authorization
    assert_equal "Error: Invalid eWAY TEST Gateway account. Your credit card has not been billed for this transaction.(Test Gateway)", response.message
  end

  def test_successful_query_payment
    @gateway.expects(:ssl_post).returns(successful_query_payment_response)
   
    assert response = @gateway.query_payment(@payment)
    assert_instance_of Response, response
    assert_success response
    assert_equal 3, response.params['query_payment_result']['managed_transaction'].size

    assert_equal "0", response.params['query_payment_result']['managed_transaction'][0]['result']
    assert_equal "10", response.params['query_payment_result']['managed_transaction'][0]['total_amount']
    assert_equal "1000788", response.params['query_payment_result']['managed_transaction'][0]['eway_trxn_number']
    assert_equal "2007-05-10T00:00:00", response.params['query_payment_result']['managed_transaction'][0]['transaction_date']
    assert_equal "Approved", response.params['query_payment_result']['managed_transaction'][0]['response_text']

    assert_equal "1", response.params['query_payment_result']['managed_transaction'][1]['result']
    assert_equal "101", response.params['query_payment_result']['managed_transaction'][1]['total_amount']
    assert_equal "1000791", response.params['query_payment_result']['managed_transaction'][1]['eway_trxn_number']
    assert_equal "2007-05-10T00:00:00", response.params['query_payment_result']['managed_transaction'][1]['transaction_date']
    assert_equal "Declined", response.params['query_payment_result']['managed_transaction'][1]['response_text']
    
    assert_equal "1", response.params['query_payment_result']['managed_transaction'][2]['result']
    assert_equal "101", response.params['query_payment_result']['managed_transaction'][2]['total_amount']
    assert_equal "1000792", response.params['query_payment_result']['managed_transaction'][2]['eway_trxn_number']
    assert_equal "2007-05-10T00:00:00", response.params['query_payment_result']['managed_transaction'][2]['transaction_date']
    assert_equal "Declined", response.params['query_payment_result']['managed_transaction'][2]['response_text']
  end

  def test_empty_query_payment
    @gateway.expects(:ssl_post).returns(empty_query_payment_response)
   
    assert response = @gateway.query_payment(@payment)
    
    assert_instance_of Response, response
    assert_success response
    assert_nil response.params['query_payment_result']
  end

  # Response Stubs
  def successful_create_customer_response
    <<-XML
      <?xml version="1.0" encoding="utf-8"?>
      <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
          <CreateCustomerResponse xmlns="https://www.eway.com.au/gateway/managedpayment">
            <CreateCustomerResult>Test 123</CreateCustomerResult>
          </CreateCustomerResponse>
        </soap:Body>
      </soap:Envelope>
    XML
  end

  def failed_create_customer_response
    <<-XML
      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <soap:Body>
          <soap:Fault>
            <faultcode>soap:Client</faultcode>
            <faultstring>The 'CustomerCountry' element is invalid - The value 'australia' is invalid according to its datatype 'Country' - The Pattern constraint failed.</faultstring>
          </soap:Fault>
        </soap:Body>
      </soap:Envelope>
    XML
  end

  def successful_update_customer_response
    <<-XML
      <?xml version="1.0" encoding="utf-8"?>
      <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
          <UpdateCustomerResponse xmlns="https://www.eway.com.au/gateway/managedpayment">
            <UpdateCustomerResult>true</UpdateCustomerResult>
          </UpdateCustomerResponse>
        </soap:Body>
      </soap:Envelope>
    XML
  end

  def failed_update_customer_response
    <<-XML
      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <soap:Body>
          <soap:Fault>
            <faultcode>soap:Client</faultcode>
            <faultstring>The 'CustomerURL' element is invalid - The value 'test' is invalid according to its datatype 'AnyURL' - The Pattern constraint failed.</faultstring>
          </soap:Fault>
        </soap:Body>
      </soap:Envelope>
    XML
  end

  def successful_query_customer_response
    <<-XML
      <?xml version="1.0" encoding="utf-8"?>
      <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
          <QueryCustomerResponse xmlns="https://www.eway.com.au/gateway/managedpayment">
            <QueryCustomerResult>
              <ManagedCustomerID>127421360542</ManagedCustomerID>
              <CustomerRef>Testing - 123</CustomerRef> 
              <CustomerTitle>Miss</CustomerTitle> 
              <CustomerFirstName>Account</CustomerFirstName> 
              <CustomerLastName>Test</CustomerLastName> 
              <CustomerCompany>Testing</CustomerCompany> 
              <CustomerJobDesc>Tester</CustomerJobDesc> 
              <CustomerEmail>test@eway.com.au</CustomerEmail> 
              <CustomerAddress>37 test</CustomerAddress> 
              <CustomerSuburb>Ngu</CustomerSuburb> 
              <CustomerState>ACT</CustomerState> 
              <CustomerPostCode>2211</CustomerPostCode> 
              <CustomerCountry>au</CustomerCountry> 
              <CustomerPhone1>0255556677</CustomerPhone1> 
              <CustomerPhone2>040411225588</CustomerPhone2> 
              <CustomerFax>0255556666</CustomerFax> 
              <CustomerURL>http://www.test-test.com</CustomerURL> 
              <CustomerComments>Testing web services modified</CustomerComments> 
              <CCName>Moe Oo</CCName> <CCNumber>44443XXXXXXX1111</CCNumber> 
              <CCExpiryMonth>2</CCExpiryMonth>
              <CCExpiryYear>12</CCExpiryYear>
            </QueryCustomerResult> 
          </QueryCustomerResponse> 
        </soap:Body>
      </soap:Envelope>
    XML
  end

  def failed_query_customer_response
    <<-XML
      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <soap:Body>
          <QueryCustomerResponse xmlns="https://www.eway.com.au/gateway/managedpayment"/>
        </soap:Body>
      </soap:Envelope>
    XML
  end

  def successful_process_payment_response
    <<-XML
      <?xml version="1.0" encoding="utf-8"?>
      <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
          <ProcessPaymentResponse xmlns="https://www.eway.com.au/gateway/managedpayment"> 
            <ewayResponse> 
              <ewayTrxnError>00,Transaction Approved(Test Gateway)</ewayTrxnError> 
              <ewayTrxnNumber>1011138</ewayTrxnNumber> 
              <ewayTrxnStatus>True</ewayTrxnStatus> 
              <ewayReturnAmount>1000</ewayReturnAmount> 
              <ewayAuthCode>12345</ewayAuthCode>
            </ewayResponse> 
          </ProcessPaymentResponse>
        </soap:Body>
      </soap:Envelope>
    XML
  end

  def failed_process_payment_response
    <<-XML
      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <soap:Body>
          <ProcessPaymentResponse xmlns="https://www.eway.com.au/gateway/managedpayment"> 
            <ewayResponse> 
              <ewayTrxnError>Error: Invalid eWAY TEST Gateway account. Your credit card has not been billed for this transaction.(Test Gateway)</ewayTrxnError> 
              <ewayTrxnStatus>False</ewayTrxnStatus> 
              <ewayTrxnNumber>1011138</ewayTrxnNumber> 
              <ewayReturnAmount>1000</ewayReturnAmount> 
              <ewayAuthCode/> 
            </ewayResponse> 
          </ProcessPaymentResponse>
        </soap:Body>
      </soap:Envelope>
    XML
  end

   def successful_query_payment_response
    <<-XML
      <?xml version="1.0" encoding="utf-8"?>
      <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
          <QueryPaymentResponse xmlns="https://www.eway.com.au/gateway/managedpayment"> 
            <QueryPaymentResult> 
              <ManagedTransaction> 
                <TotalAmount>10</TotalAmount> 
                <Result>0</Result> 
                <ResponseText>Approved</ResponseText> 
                <TransactionDate>2007-05-10T00:00:00</TransactionDate> 
                <ewayTrxnNumber>1000788</ewayTrxnNumber> 
              </ManagedTransaction> 
              <ManagedTransaction> 
                <TotalAmount>101</TotalAmount> 
                <Result>1</Result> 
                <ResponseText>Declined</ResponseText> 
                <TransactionDate>2007-05-10T00:00:00</TransactionDate> 
                <ewayTrxnNumber>1000791</ewayTrxnNumber> 
              </ManagedTransaction> 
              <ManagedTransaction> 
                <TotalAmount>101</TotalAmount> 
                <Result>1</Result> 
                <ResponseText>Declined</ResponseText> 
                <TransactionDate>2007-05-10T00:00:00</TransactionDate> 
                <ewayTrxnNumber>1000792</ewayTrxnNumber>
              </ManagedTransaction>
            </QueryPaymentResult> 
          </QueryPaymentResponse>
        </soap:Body>
      </soap:Envelope>
    XML
  end

  def empty_query_payment_response
    <<-XML
      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <soap:Body>
          <QueryPaymentResponse xmlns="https://www.eway.com.au/gateway/managedpayment">
            <QueryPaymentResult/> 
          </QueryPaymentResponse>
        </soap:Body>
      </soap:Envelope>
    XML
  end
end 
