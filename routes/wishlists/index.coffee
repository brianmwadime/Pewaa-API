'use strict'
require("#{__dirname}/../../environment")
WishlistsController = require "#{__dirname}/../../controllers/wishlists"
GiftsController     = require "#{__dirname}/../../controllers/gifts"
Wishlist            = require "#{__dirname}/../../models/wishlist"
_                   = require 'underscore'
authenticate 		    = require "#{__dirname}/../../components/oauth/authenticate"
validate            = require '#{__dirname}/../../validators/tokenValidator'
apiVersion 	        = process.env.API_VERSION

handler = (app) ->

  app.get "/v#{apiVersion}/wishlists", validate({secret: 'pewaa'}), (req, res) ->
    WishlistsController.getWishlistsForUser req.userId, (err, wishlists) ->
      if err
        res.send 400, err
      else
        res.send _.map wishlists, (p) -> (new Wishlist p).publicObject()

  app.post "/v#{apiVersion}/wishlists", validate({secret: 'pewaa'}), (req, res) ->
    wishlist = new Wishlist req.body
    # wishlist.userId = req.userId
    if wishlist.validate()
      WishlistsController.create wishlist, (err, result) ->
        if err
          res.send 400, err
        else
          res.send result
    else
      res.send 400, 'Invalid parameters'

  app.get "/v#{apiVersion}/wishlists/:id", validate({secret: 'pewaa'}), (req, res) ->
    WishlistsController.getOne req.params.id, (err, wishlist)->
      if err or not wishlist.validate()
        res.send 404, err
      else
        res.send wishlist.publicObject()

  app.put "/v#{apiVersion}/wishlists/:id", validate({secret: 'pewaa'}), (req, res) ->
    wishlist = new Wishlist req.body
    wishlist.wishlistId = req.params.id
    WishlistsController.update wishlist, (err, wishlist)->
      if err or not wishlist.validate()
        res.send 404, err
      else
        res.send wishlist.publicObject()

  app.delete "/v#{apiVersion}/wishlists/:id", validate({secret: 'pewaa'}), (req, res) ->
    WishlistsController.deleteOne req.params.id, (err) ->
      if err
        res.send 404, err
      else
        GiftsController.deleteForWishlist req.params.id, (err)->
          if err
            res.send 400, err
          else
            res.send 200

  app.get "/v#{apiVersion}/wishlists/:id/gifts", validate({secret: 'pewaa'}), (req, res) ->
    wishlistId = req.params.id
    WishlistsController.exists wishlistId, (err, exists) ->
      if err
        res.send 404, err
      else
        GiftsController.getForWishlist wishlistId, (err, gifts) ->
          if err
            res.send 400, err
          else
            res.send gifts

module.exports = handler
