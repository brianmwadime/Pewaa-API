'use strict'
require("#{__dirname}/../../environment")
WishlistsController = require "#{__dirname}/../../controllers/wishlists"
gcm                 = require "node-gcm"
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
        res.status(400).send(err)
      else
        res.status(200).send(wishlists)

  app.post "/v#{apiVersion}/wishlists", validate({secret: 'pewaa'}), (req, res) ->
    wishlist = new Wishlist req.body
    wishlist.userId = req.userId
    if wishlist.validate()
      WishlistsController.create wishlist, (err, result) ->
        if err
          res.status(400).send(err)
        else
          res.status(200).send(result)
    else
      res.status(400).send('Invalid Parameters')

  app.get "/v#{apiVersion}/wishlists/:id", validate({secret: 'pewaa'}), (req, res) ->
    WishlistsController.getOne req.params.id, (err, wishlist)->
      if err or not wishlist.validate()
        res.status(404).send(err)
      else
        res.status(200).send(wishlist.publicObject())

  app.put "/v#{apiVersion}/wishlists/:id", validate({secret: 'pewaa'}), (req, res) ->
    wishlist = new Wishlist req.body
    wishlist.wishlistId = req.params.id
    WishlistsController.update wishlist, (err, wishlist)->
      if err or not wishlist.validate()
        res.status(404).send(err)
      else
        res.status(200).send(wishlist.publicObject())

  app.post "/v#{apiVersion}/wishlists/:id/report", validate({secret: 'pewaa'}), (req, res) ->
    wishlist = {}
    wishlist.id = req.params.id
    wishlist.flagged = req.body.flagged
    wishlist.flagged_description = req.body.flagged_description

    WishlistsController.report wishlist, (err, result)->
      if err
        res.status(404).send(err)
      else
        res.status(200).send(result)

  app.delete "/v#{apiVersion}/wishlists/:id", validate({secret: 'pewaa'}), (req, res) ->
    WishlistsController.deleteOne req.params.id, (err) ->
      if err
        res.status(404).send(err)
      else
        GiftsController.deleteForWishlist req.params.id, (err)->
          if err
            res.status(400).send(err)
          else
            res.status(200).send('OK')

  app.get "/v#{apiVersion}/wishlists/:id/gifts", validate({secret: 'pewaa'}), (req, res) ->
    wishlistId = req.params.id
    WishlistsController.exists wishlistId, (err, exists) ->
      if err
        res.status(400).send(err)
      else
        GiftsController.getForWishlist wishlistId, (err, gifts) ->
          if err
            res.status(400).send(err)
          else
            res.status(200).send(gifts)

module.exports = handler
