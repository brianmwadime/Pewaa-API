require "#{__dirname}/../../environment"
request = require "request"
ParseResponse   = require "#{__dirname}/../../components/mpesa/ParseResponse"
requestOptions = {}
parser = {}

module.exports = class SOAPRequest
  construct: (payment, parserd) ->
    # @request = request
    parser = parserd
    requestOptions =
      method: 'POST'
      uri: process.env.ENDPOINT
      rejectUnauthorized: false
      body: payment.body
      headers: 'content-type': 'application/xml; charset=utf-8'

    this

  post: () ->
    new Promise((resolve, reject) ->
      # Make the soap request to the SAG URI
        request requestOptions, (error, response, body) ->
          # console.info body
          if error
            reject description: error.message
            return

          parsedResponse = parser.parse(body)

          json = parsedResponse.toJSON()
          # Anything that is not "00" as the
          # SOAP response code is a Failure
          if json and json.status_code != 200
            reject json
            return
          # Else everything went well
          resolve json
          return
        return
  )