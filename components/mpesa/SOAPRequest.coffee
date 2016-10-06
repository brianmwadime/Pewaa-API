request = require "request"

module.exports = class SOAPRequest
  construct: (payment, parser) ->
    @request  = request
    @parser   = parser
    @requestOptions =
      method: 'POST'
      uri: process.env.ENDPOINT
      rejectUnauthorized: false
      body: payment.body
      headers: 'content-type': 'application/xml; charset=utf-8'

    @

  post: () ->
    request = @request
    parser  = @parser
    requestOptions = @requestOptions
    new Promise((resolve, reject) ->
      # Make the soap request to the SAG URI
      request requestOptions, (error, response, body) ->
        if error
          reject description: error.message
          return

        parsedResponse = parser.parse(body)
        json = parsedResponse.toJSON()
        # Anything that is not "00" as the
        # SOAP response code is a Failure
        # if json and json.status_code != 200
        if json and json.return_code != "00"
          reject json
          return
        # Else everything went well
        resolve json
        return
      return
  )
