'use strict'
require("#{__dirname}/../../environment")
PaymentsController     = require "#{__dirname}/../../controllers/payments"
Payment                = require "#{__dirname}/../../models/payment"

_                   = require 'underscore'
apiVersion 	        = process.env.API_VERSION

handler = (app) ->

  app.get "/api/v#{apiVersion}/payments", authenticate(), (req, res) ->
    if typeof req.query.wishlistId isnt 'undefined'
      PaymentsController.getForWishlist req.query.wishlistId, (err, gifts)->
        res.send _.map gifts, (t) -> (new Payment t).publicObject()
    else
      res.send 404

  app.post "/api/v#{apiVersion}/payments", authenticate(), (req, res) ->
    req.body.userId = req.user.user.id
    te = new Payment req.body
    if te.validate()
      PaymentsController.create te, (err, gift)->
        if err
          res.send 400, error: 'some error'
        else
          res.send gift.publicObject()
    else
      res.send 400, error: 'some error'

  app.get "/api/v#{apiVersion}/payments/:id", authenticate(), (req, res) ->
    PaymentsController.getOne req.params.id, (err, gift)->
      if err or not gift.validate()
        res.send 404, error: "#{req.params.id} not found"
      else
        res.send gift.publicObject()

  app.delete "/api/v#{apiVersion}/payments/:id", authenticate(), (req, res) ->
    PaymentsController.deleteOne req.params.id, (err)->
      if err
        res.send 404, error: "#{req.params.id} not found"
      else
        res.send 200

module.exports = handler