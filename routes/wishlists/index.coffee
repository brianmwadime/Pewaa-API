'use strict'
require("#{__dirname}/../../environment")
WishlistsController = require "#{__dirname}/../../controllers/wishlists"
GiftsController     = require "#{__dirname}/../../controllers/gifts"
Wishlist            = require "#{__dirname}/../../models/wishlist"
_                   = require 'underscore'
authenticate 		    = require "#{__dirname}/../../components/oauth/authenticate"
apiVersion 	        = process.env.API_VERSION



handler = (app) ->
  
  app.get "/v#{apiVersion}/wishlists", authenticate(), (req, res) ->
    WishlistsController.getWishlistsForUser req.user.user.id, (err, wishlists) ->
      if err
        res.send 400, error: 'Error'
      else
        res.send _.map wishlists, (p) -> (new Wishlist p).publicObject()

  app.post "/v#{apiVersion}/wishlists", authenticate(), (req, res) ->
    wishlist = new Wishlist req.body
    wishlist.userId = req.user.user.id
    if wishlist.validate()
      console.info req.user.user
      WishlistsController.create wishlist, (err, wishlist) ->
        if err
          res.send 400, error: err
        else
          res.send wishlist.publicObject()
    else
      res.send 400, error: 'Invalid parameters'

  app.get "/v#{apiVersion}/wishlists/:id", authenticate(), (req, res) ->
    WishlistsController.getOne req.params.id, (err, wishlist)->
      if err or not wishlist.validate()
        res.send 404, error: 'Error'
      else
        res.send wishlist.publicObject()

  app.delete "/v#{apiVersion}/wishlists/:id", authenticate(), (req, res) ->
    WishlistsController.deleteOne req.params.id, (err) ->
      if err
        res.send 404, error: "Wishlist with id #{req.params.id} not found"
      else
        GiftsController.deleteForWishlist req.params.id, (err)->
          if err
            res.send 400, error: "Couldn't delete gifts"
          else
            res.send 200

  app.get "/v#{apiVersion}/wishlists/:id/gifts", authenticate(), (req, res) ->
    wishlistId = req.params.id
    WishlistsController.exists wishlistId, (err, exists) ->
      if err
        res.send 404, error: "Wishlist #{wishlistId} not found"
      else
        GiftsController.getForWishlist wishlistId, (err, gifts) ->
          if err
            res.send 400, error: 'Error'
          else
            res.send gifts


module.exports = handler