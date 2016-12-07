'use strict'
request = require "request"
statusCodes = require "#{__dirname}/../../config/statusCodes"

class PaymentSuccess
  constructor: () ->
    @request = request

  handler: (req, res, next) ->
    response = {}
    baseURL = "#{req.protocol}://#{process.env.API_DOMAIN}"
    endpoint = "#{baseURL}/v1/mpesa/payment"
    if 'MERCHANT_ENDPOINT' of process.env
      endpoint = process.env.MERCHANT_ENDPOINT
    else
      if process.env.NODE_ENV != 'development'
        next new Error('MERCHANT_ENDPOINT has not been provided in environment configuration')
        return

    for key in Object.keys(req.body)
      prop = key.toLowerCase().replace(/\-/g, '')
      response[prop] = req.body[key]

    if 'enc_params' in response
      # decrypted encrypted extra parameters provided in ENC_PARAMS
      response.extra_payload = JSON.parse(new Buffer(response.enc_params, 'base64').toString())
      delete response.enc_params

    extractCode = statusCodes.find((stc) ->
      stc.return_code == parseInt(response.return_code, 10)
    )

    Object.assign response, extractCode
    requestParams =
        method: 'POST'
        uri: endpoint
        rejectUnauthorized: false
        body: JSON.stringify(response: response)
        headers: 'content-type': 'application/json; charset=utf-8'

    console.log "Final", JSON.stringify(response: response)
    # make a request to the merchant's endpoint
    @request requestParams, (error) ->
      if error
        res.status(500)
        return

      res.send(200)
      return

    return

module.exports = new PaymentSuccess
