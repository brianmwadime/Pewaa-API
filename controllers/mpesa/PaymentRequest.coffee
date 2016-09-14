'use strict'
uuid            = require "node-uuid"
ParseResponse   = require "#{__dirname}/../../components/mpesa/ParseResponse"
SOAPRequest     = require "#{__dirname}/../../components/mpesa/SOAPRequest"
responseError   = require "#{__dirname}/../../handlers/mpesa_error_handler"
parseResponse   = new ParseResponse("processcheckoutresponse")
soapRequest     = new SOAPRequest()

class PaymentRequest
    constructor: (request, parser) ->
        @parser = parser
        @soapRequest = request
        @callbackMethod = 'POST';

    buildSoapBody: (data) ->
        @body = "<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:tns='tns:ns'>
      <soapenv:Header>
        <tns:CheckOutHeader>
          <MERCHANT_ID>#{process.env.PAYBILL_NUMBER}</MERCHANT_ID>
          <PASSWORD>#{data.encryptedPassword}</PASSWORD>
          <TIMESTAMP>#{data.timeStamp}</TIMESTAMP>
        </tns:CheckOutHeader>
      </soapenv:Header>
      <soapenv:Body>
        <tns:processCheckOutRequest>
          <MERCHANT_TRANSACTION_ID>#{data.merchantTransactionID}
          </MERCHANT_TRANSACTION_ID>
          <REFERENCE_ID>#{String(data.referenceID).slice(0, 8)}</REFERENCE_ID>
          <AMOUNT>#{data.amountInDoubleFloat}</AMOUNT>
          <MSISDN>#{data.clientPhoneNumber}</MSISDN>
          <ENC_PARAMS>#{JSON.stringify(data.extraPayload)}</ENC_PARAMS>
          <CALL_BACK_URL>#{data.callbackURL}</CALL_BACK_URL>
          <CALL_BACK_METHOD>#{@callbackMethod}</CALL_BACK_METHOD>
          <TIMESTAMP>#{data.timeStamp}</TIMESTAMP>
        </tns:processCheckOutRequest>
      </soapenv:Body>
    </soapenv:Envelope>"
        this

    handler: (req, res) ->
        paymentDetails = 
            referenceID: req.body.referenceID or uuid.v4()
            merchantTransactionID: req.body.merchantTransactionID or uuid.v1()
            amountInDoubleFloat: req.body.totalAmount
            clientPhoneNumber: req.body.phoneNumber
            extraPayload: req.body.extraPayload
            timeStamp: req.timeStamp
            encryptedPassword: req.encryptedPassword
            callbackURL: "#{req.protocol}://#{req.hostname}/api/v#{process.env.API_VERSION}/payment/success"

        payment = @buildSoapBody(paymentDetails)
        
        request = @soapRequest.construct(payment, @parser)

        # remove encryptedPassword
        delete paymentDetails.encryptedPassword
        # convert paymentDetails properties to underscore notation
        returnThesePaymentDetails = {}
        for key in Object.keys(paymentDetails)
            newkey = key.replace /[A-Z]{1,}/g, (match) -> '_' + match.toLowerCase()
            returnThesePaymentDetails[newkey] = paymentDetails[key]
            delete paymentDetails[key]

        # make the payment requets and process response
        request.post()
            .then (result) ->
                res.status(200).json response: Object.assign({}, result, returnThesePaymentDetails)
                return
            
            .catch (error) ->
                responseError error, res
                return
        
module.exports = new PaymentRequest(soapRequest, parseResponse)