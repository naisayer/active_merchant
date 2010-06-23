require 'test_helper'
require 'pp'

class EwayTokenTest < Test::Unit::TestCase
  def setup
    Base.mode = :test

    @gateway = EwayTokenGateway.new(
      :customer_id => '87654321',
      :login => 'test@eway.com.au',
      :password => 'test123'
    )
  
    @customer = {
      :title => 'Mr.',
      :first_name => 'Joe',
      :last_name => 'Bloggs',
      :address => 'Bloggs Enterprise',
      :suburb => 'Capital City',
      :state => 'ACT',
      :company => 'Bloggs',
      :post_code => '2111',
      :country => 'AU',
      :email => 'test@eway.com.au',
      :fax => '0298989898',
      :phone => '0297979797',
      :mobile => '',
      :customer_ref => 'Ref123',
      :job_desc => '',
      :comments => 'Please Ship ASAP',
      :url => 'http://www.test.com.au',
      :credit_card => credit_card(4444333322221111)
    }

    @am_customer = {
      :title => 'Mr.',
      :first_name => 'Joe',
      :last_name => 'Bloggs',
      :company => 'Bloggs',
      :email => 'test@eway.com.au',
      :customer_ref => 'Ref123',
      :job_desc => '',
      :comments => 'Please Ship ASAP',
      :url => 'http://www.test.com.au',
      :billing_address => {
        :address1 => 'Bloggs Enterprise',
        :phone => '0297979797',
        :zip => '2111',
        :city => 'Capital City',
        :country => 'AU',
        :state => 'ACT',
        :mobile => '',
        :fax => '0298989898' 
      },
    }
    @credit_card = credit_card(4444333322221111)

    @payment = {
      :managed_customer_id => '9876543211000',
      :amount => 1000,
      :invoice_reference => 'Test Inv',
      :invoice_description => 'Test Description'
    }
  end

  def test_successful_create_customer
    response = @gateway.create_customer(@customer)
    assert_instance_of Response, response
    assert_success response
    assert_nil response.authorization
    assert_equal '112233445566', response.params['create_customer_result']
  end

  def test_failed_create_customer
    @customer[:title] = 'Invalid'
    response = @gateway.create_customer(@customer)
    assert_failure response
    assert_nil response.authorization
  end

  def test_successful_store
    response = @gateway.store(@credit_card, @am_customer)
    assert_instance_of Response, response
    assert_success response
    assert_nil response.authorization
    assert_equal '112233445566', response.params['create_customer_result']
  end

  def test_failed_store
    @am_customer[:title] = 'Invalid'
    response = @gateway.store(@credit_card, @am_customer)
    assert_failure response
    assert_nil response.authorization
  end

  def test_successful_update_customer
    @customer[:managed_customer_id] = '9876543211000'
    response = @gateway.update_customer(@customer)
    assert_instance_of Response, response
    assert_success response
    assert_nil response.authorization
    assert_equal 'true', response.params['update_customer_result']
  end

  def test_non_existent_update_customer
    @customer[:managed_customer_id] = '12345657899000'
    response = @gateway.update_customer(@customer)
    assert_instance_of Response, response
    assert_failure response
    assert_nil response.authorization
    assert_equal 'Invalid managedCustomerID', response.message
  end

  def test_failed_update_customer
    @customer[:managed_customer_id] = '9876543211000'
    @customer[:title] = 'Invalid'
    response = @gateway.update_customer(@customer)
    assert_instance_of Response, response
    assert_failure response
    assert_nil response.authorization
  end

  def test_successful_update
    credit_card = @am_customer.delete(:credit_card)
    response = @gateway.update('9876543211000', @credit_card, @am_customer)
    assert_instance_of Response, response
    assert_success response
    assert_nil response.authorization
    assert_equal 'true', response.params['update_customer_result']
  end

  def test_non_existent_update
    @am_customer[:title] = 'Invalid'
    response = @gateway.update('1234567899000', @credit_card, @am_customer)
    assert_instance_of Response, response
    assert_failure response
    assert_nil response.authorization
    assert_equal 'Invalid managedCustomerID', response.message
  end

  def test_failed_update
    @am_customer[:title] = 'Invalid'
    response = @gateway.update('9876543211000', @credit_card, @am_customer)
    assert_instance_of Response, response
    assert_failure response
    assert_nil response.authorization
  end



  def test_query_customer
    response = @gateway.query_customer({ :managed_customer_id => '9876543211000' })
    assert_instance_of Response, response
    assert_success response
    assert_nil response.authorization
  end

  def test_non_existent_query_customer
    response = @gateway.query_customer({ :managed_customer_id => '1234567899000' })
    assert_instance_of Response, response
    assert_failure response
    assert_nil response.authorization
    assert_equal "", response.message
  end

  def test_query_customer_by_reference
    response = @gateway.query_customer_by_reference({ :customer_reference => 'Test 123' })
    assert_instance_of Response, response
    assert_success response
    assert_nil response.authorization
  end

  def test_non_existent_query_customer_by_reference
    response = @gateway.query_customer_by_reference({ :customer_reference => 'Test ABC' })
    assert_instance_of Response, response
    assert_failure response
    assert_nil response.authorization
    assert_equal "", response.message
  end

  def test_process_payment
    response = @gateway.process_payment(@payment)
    assert_instance_of Response, response
    assert_success response
    assert_equal '123456', response.authorization
    assert_equal 'Transaction Approved(Test Gateway)', response.message
  end

  def test_failed_process_payment
    @payment[:amount] = 1001
    response = @gateway.process_payment(@payment)
    assert_instance_of Response, response
    assert_failure response
    assert_equal "Refer to Issuer(Test Gateway)", response.message
    #assert_nil response.authorization
  end

  def test_purchase
    money = @payment.delete(:amount)
    managed_customer_id = @payment.delete(:managed_customer_id)

    response = @gateway.purchase(money, managed_customer_id, @payment)
    assert_instance_of Response, response
    assert_success response
    assert_equal '123456', response.authorization
    assert_equal 'Transaction Approved(Test Gateway)', response.message
  end

  def test_failed_process_payment
    @payment.delete(:amount)
    money = 1001
    managed_customer_id = @payment.delete(:managed_customer_id)

    response = @gateway.purchase(money, managed_customer_id, @payment)
    assert_instance_of Response, response
    assert_failure response
    assert_equal "Refer to Issuer(Test Gateway)", response.message
    #assert_nil response.authorization
  end

   def test_successful_query_payment
    assert response = @gateway.query_payment(@payment)
    assert_instance_of Response, response
    assert_success response
    assert_equal 2, response.params['query_payment_result']['managed_transaction'].size

    assert_equal "1", response.params['query_payment_result']['managed_transaction'][0]['result']
    assert_equal "1000", response.params['query_payment_result']['managed_transaction'][0]['total_amount']
    assert_equal "1", response.params['query_payment_result']['managed_transaction'][0]['eway_trxn_number']
    assert_equal "Approved", response.params['query_payment_result']['managed_transaction'][0]['response_text']

    assert_equal "1", response.params['query_payment_result']['managed_transaction'][1]['result']
    assert_equal "1008", response.params['query_payment_result']['managed_transaction'][1]['total_amount']
    assert_equal "1", response.params['query_payment_result']['managed_transaction'][1]['eway_trxn_number']
    assert_equal "Approved", response.params['query_payment_result']['managed_transaction'][1]['response_text']
  end

  def test_failed_query_payment
    @payment[:managed_customer_id] = '1234567899000'
    assert response = @gateway.query_payment(@payment)
    assert_instance_of Response, response
    assert_failure response
    assert_nil response.params['query_payment_result']
  end
end
