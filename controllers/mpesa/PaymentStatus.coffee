ParseResponse = require "#{__dirname}/../../components/mpesa/ParseResponse"
SOAPRequest = require "#{__dirname}/../../components/mpesa/SOAPRequest"
responseError = require "#{__dirname}/../../handlers/mpesa_error_handler"
parseResponse = new ParseResponse("transactionstatusresponse")
soapRequest = new SOAPRequest()

class PaymentStatus
    constructor: (@request, @parser) ->
        # @parser = @parser
        @soapRequest = @request

    buildSoapBody: (data) ->
        transactionStatusRequest = if typeof data.transactionID != 'undefined' then '<TRX_ID>' + data.transactionID + '</TRX_ID>' else '<MERCHANT_TRANSACTION_ID>' + data.merchantTransactionID + '</MERCHANT_TRANSACTION_ID>'
        @body = "<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:tns='tns:ns'>
            <soapenv:Header>
                <tns:CheckOutHeader>
                <MERCHANT_ID>#{process.env.PAYBILL_NUMBER}</MERCHANT_ID>
                <PASSWORD>#{data.encryptedPassword}</PASSWORD>
                <TIMESTAMP>#{data.timeStamp}</TIMESTAMP>
                </tns:CheckOutHeader>
            </soapenv:Header>
            <soapenv:Body>
                <tns:transactionStatusRequest>
                #{transactionStatusRequest}
                </tns:transactionStatusRequest>
            </soapenv:Body>
            </soapenv:Envelope>"
        this

    handler: (req, res) ->
        paymentDetails = 
            transactionID: req.params.id
            timeStamp: req.timeStamp
            encryptedPassword: req.encryptedPassword
        payment = @buildSoapBody(paymentDetails)
        status = @soapRequest.construct(payment, @parser)
        # process PaymentStatus response
        status.post().then((response) ->
            res.status(200).json response: response
            return

        ).catch(error) ->
            responseError error, res
            return

module.exports = new PaymentStatus(soapRequest, parseResponse)