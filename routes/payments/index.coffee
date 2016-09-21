'use strict'
require("#{__dirname}/../../environment")
Payment                 = require '#{__dirname}/../../models/payment'

PaymentRequest          = require '#{__dirname}/../../controllers/mpesa/PaymentRequest'
ConfirmPayment          = require '#{__dirname}/../../controllers/mpesa/ConfirmPayment'
PaymentStatus           = require '#{__dirname}/../../controllers/mpesa/PaymentStatus'
PaymentSuccess          = require '#{__dirname}/../../controllers/mpesa/PaymentSuccess'
checkForRequiredParams  = require '#{__dirname}/../../validators/checkForRequiredParams'
_                       = require 'underscore'
apiVersion 	            = process.env.API_VERSION

handler = (app) ->

  # check the status of the API system
  app.get "/v#{apiVersion}/status", (req, res) ->
    res.json({ status: 200 })

  app.post "/v#{apiVersion}/payments/request", checkForRequiredParams, (req, res) -> 
    PaymentRequest.handler(req, res)
  
  app.get "/v#{apiVersion}/payments/confirm/:id", (req, res) -> 
    ConfirmPayment.handler(req, res)

  app.get "/v#{apiVersion}/payments/status/:id", (req, res) -> 
    PaymentStatus.handler(req, res)

  app.all "/v#{apiVersion}/payments/success", (req, res) -> 
    PaymentSuccess.handler(req, res)

  # for testing last POST response
  # if MERCHANT_ENDPOINT has not been provided
  app.all "/v#{apiVersion}/thumbs/up", (req, res) -> 
    res.sendStatus(200)

module.exports = handler