'use strict'
require("#{__dirname}/../../environment")
Payment                 = require "#{__dirname}/../../models/payment"
PaymentRequest          = require "#{__dirname}/../../controllers/mpesa/PaymentRequest"
PaymentStatus           = require "#{__dirname}/../../controllers/mpesa/PaymentStatus"
PaymentSuccess          = require "#{__dirname}/../../controllers/mpesa/PaymentSuccess"
checkForRequiredParams  = require "#{__dirname}/../../validators/checkForRequiredParams"
UsersController 	      = require "#{__dirname}/../../controllers/users"
ContributorsController 	= require "#{__dirname}/../../controllers/contributors"
validate                = require "#{__dirname}/../../validators/tokenValidator"
_                       = require 'underscore'
apiVersion 	            = process.env.API_VERSION

handler = (app) ->
  paymentRequestHandler = (req, res) -> PaymentRequest.handler(req, res)

  # check the status of the API system
  app.get "/v#{apiVersion}/status", (req, res) ->
    res.json({ status: 200 })

  app.post "/v#{apiVersion}/payments/request", [validate({secret: 'pewaa'}), checkForRequiredParams], paymentRequestHandler

  app.get "/v#{apiVersion}/payments/status/:trx_id", (req, res) ->
    PaymentStatus.handler(req, res)

  app.all "/v#{apiVersion}/payments/complete", (req, res) ->
    PaymentSuccess.handler(req, res)

  app.post "/v#{apiVersion}/payments/create", validate({secret: 'pewaa'}), (req, res) ->
    req.body.user_id = req.userId
    payment = new Payment req.body
    if payment.validate()
      UsersController.createPayment payment, (err, result)->
        if err
          res.status(400).send(err)
        else
          res.status(200).send(result)
    else
      res.status(400).json({error: "Invalid parameters."})

  app.post "/v#{apiVersion}/payments/update/:trx_id", validate({secret: 'pewaa'}), (req, res) ->
    ContributorsController.updatePayment {status:req.body.status, userId:req.userId, trx_id:req.param.trx_id}, (err, result) ->
      if err
        res.status(400).send(err)
      else
        res.status(200).send(result)

  # for testing last POST response
  # if MERCHANT_ENDPOINT has not been provided
  app.all "/v#{apiVersion}/mpesa/payment", (req, res) ->
    trx_status = "Pending"
    if req.body.response.status_code == 200
      trx_status = "Success"
    else
      trx_status = "Failed"

    ContributorsController.updatePayment {status:trx_status, trx_id:req.body.response.request_id}, (err, result) ->
      if err
        res.status(400).send(err)
      else
        res.status(200).send(result)

module.exports = handler
