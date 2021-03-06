'use strict'
require("#{__dirname}/../../environment")
ContributorsController = require "#{__dirname}/../../controllers/contributors"
Contributor            = require "#{__dirname}/../../models/contributor"
GiftsController        = require "#{__dirname}/../../controllers/gifts"
_                      = require 'underscore'
authenticate 		       = require "#{__dirname}/../../components/oauth/authenticate"
validate               = require '#{__dirname}/../../validators/tokenValidator'
apiVersion 	           = process.env.API_VERSION

handler = (app) ->

  app.get "/v#{apiVersion}/contributors", validate({secret: 'pewaa'}), (req, res) ->
    ContributorsController.getWishlistContributors req.body.wishlist_id, (err, wishlists) ->
      if err
        res.send 400, err
      else
        res.send _.map wishlists, (p) -> (new Wishlist p).publicObject()

  app.post "/v#{apiVersion}/contributors", validate({secret: 'pewaa'}), (req, res) ->
    contributor = new Contributor req.body
    if contributor.validate()
      ContributorsController.create contributor, (err, result) ->
        if err
          res.send 400, err
        else
          res.send 200, result
    else
      res.send 400, 'Invalid parameters'

  app.get "/v#{apiVersion}/contributors/:id", validate({secret: 'pewaa'}), (req, res) ->
    ContributorsController.getOne req.params.id, (err, wishlist)->
      if err or not wishlist.validate()
        res.send 404, err
      else
        res.send 200, wishlist.publicObject()

  app.put "/v#{apiVersion}/contributors/:id", validate({secret: 'pewaa'}), (req, res) ->
    contributor = new Contributor req.body
    if contributor.validate()
      ContributorsController.update contributor, (err, result) ->
        if err
          res.send 400, err
        else
          res.send 200, result
    else
      res.send 400, 'Invalid parameters'
  app.post "/v#{apiVersion}/contributors/addContributors", validate({secret: 'pewaa'}), (req, res) ->
    ContributorsController.addContributors req.body, (err, result)->
      if err
        res.send 400, err

      else
        res.send 200, result
  app.delete "/v#{apiVersion}/contributors/:id", validate({secret: 'pewaa'}), (req, res) ->
    WishlistsController.deleteOne req.params.id, (err) ->
      if err
        res.send 404, err
      else
        GiftsController.deleteForWishlist req.params.id, (err)->
          if err
            res.send 400, err
          else
            res.send 200

  app.delete "/v#{apiVersion}/wishlists/:wishlist_id/contributors/:contributor_id", validate({secret: 'pewaa'}), (req, res) ->
    deleteParams =
      wishlist_id: req.params.wishlist_id
      contributor_id: req.params.contributor_id

    ContributorsController.deleteContributor deleteParams, (err, result) ->
      if err
        res.send 404, err
      else
        res.send 200, result

module.exports = handler
