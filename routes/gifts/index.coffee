'use strict'
require("#{__dirname}/../../environment")
GiftsController     = require "#{__dirname}/../../controllers/gifts"
Gift                = require "#{__dirname}/../../models/gift"

_                   = require 'underscore'
authenticate 		    = require "#{__dirname}/../../components/oauth/authenticate"
apiVersion 	        = process.env.API_VERSION

handler = (app) ->

  app.get "/api/v#{apiVersion}/gifts", authenticate(), (req, res) ->
    if typeof req.query.wishlistId isnt 'undefined'
      GiftsController.getForWishlist req.query.wishlistId, (err, gifts)->
        res.send _.map gifts, (t) -> (new Gift t).publicObject()
    else
      res.send 404

  app.post "/api/v#{apiVersion}/gifts", authenticate(), (req, res) ->
    req.body.userId = req.user.user.id
    te = new Gift req.body
    if te.validate()
      GiftsController.create te, (err, gift)->
        if err
          res.send 400, error: 'some error'
        else
          res.send gift.publicObject()
    else
      res.send 400, error: 'some error'

  app.get "/api/v#{apiVersion}/gifts/:id", authenticate(), (req, res) ->
    GiftsController.getOne req.params.id, (err, gift)->
      if err or not gift.validate()
        res.send 404, error: "#{req.params.id} not found"
      else
        res.send gift.publicObject()

  app.delete "/api/v#{apiVersion}/gifts/:id", authenticate(), (req, res) ->
    GiftsController.deleteOne req.params.id, (err)->
      if err
        res.send 404, error: "#{req.params.id} not found"
      else
        res.send 200

module.exports = handler