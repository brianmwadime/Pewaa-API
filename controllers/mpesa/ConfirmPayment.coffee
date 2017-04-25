'use strict'
ParseResponse   = require "#{__dirname}/../../components/mpesa/ParseResponse"
SOAPRequest     = require "#{__dirname}/../../components/mpesa/SOAPRequest"
responseError   = require "#{__dirname}/../../handlers/mpesa_error_handler"
parseResponse   = new ParseResponse("transactionconfirmresponse")
soapRequest     = new SOAPRequest()

class ConfirmPayment
  constructor: (@request, @parser) ->
    @parser = @parser
    @soapRequest = @request

  buildSoapBody: (data) ->
    transactionConfirmRequest = if typeof data.transactionID != 'undefined' then '<TRX_ID>' + data.transactionID + '</TRX_ID>' else '<MERCHANT_TRANSACTION_ID>' + data.merchantTransactionID + '</MERCHANT_TRANSACTION_ID>'
    @body = "<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:tns='tns:ns'>
        <soapenv:Header>
            <tns:CheckOutHeader>
            <MERCHANT_ID>#{process.env.PAYBILL_NUMBER}</MERCHANT_ID>
            <PASSWORD>#{data.encryptedPassword}</PASSWORD>
            <TIMESTAMP>#{data.timeStamp}</TIMESTAMP>
            </tns:CheckOutHeader>
        </soapenv:Header>
        <soapenv:Body>
            <tns:transactionConfirmRequest>
            #{transactionConfirmRequest}
            </tns:transactionConfirmRequest>
        </soapenv:Body>
        </soapenv:Envelope>"

    @

  handler: (params) ->
    paymentDetails =
      transactionID: params.transactionID
      timeStamp: params.timeStamp
      encryptedPassword: params.encryptedPassword
    payment = @buildSoapBody(paymentDetails)
    confirm = @soapRequest.construct(payment, @parser)
    # process ConfirmPayment response
    return confirm.post()

module.exports = new ConfirmPayment(soapRequest, parseResponse)
