'use strict'
require("#{__dirname}/../../environment")
gcm                     = require "node-gcm"
GiftsController         = require "#{__dirname}/../../controllers/gifts"
ContributorsController  = require "#{__dirname}/../../controllers/contributors"
Gift                    = require "#{__dirname}/../../models/gift"
Contributor             = require "#{__dirname}/../../models/contributor"
crypto                  = require "crypto"
mime                    = require "mime"
_                       = require 'underscore'
validate                = require "#{__dirname}/../../validators/tokenValidator"
multer                  = require "multer"
apiVersion 	            = process.env.API_VERSION

storage = multer.diskStorage(
  destination: (req, file, cb) ->
    cb null, "#{__dirname}/../../uploads/"
    return
  filename: (req, file, cb) ->
    crypto.pseudoRandomBytes 16, (err, raw) ->
      cb null, raw.toString('hex') + Date.now() + '.' + mime.extension("image/jpeg")
      return
    return
)
upload = multer(storage: storage).single('image')

handler = (app) ->

  app.get "/v#{apiVersion}/gifts", validate({secret: 'pewaa'}), (req, res) ->
    if typeof req.query.wishlistId isnt 'undefined'
      GiftsController.getForWishlist req.query.wishlistId, (err, gifts)->
        res.status(200).send(_.map gifts, (t) -> (new Gift t).publicObject())
    else
      res.status(400).send(err)

  app.get "/v#{apiVersion}/gifts/:id/contributors", validate({secret: 'pewaa'}), (req, res) ->
    ContributorsController.getContributors req.params.id, (err, contributors) ->
      if err
        res.status(400).send(err)
      else
        res.status(200).send(contributors) # _.map contributors, (p) -> (new Wishlist p).publicObject()

  app.post "/v#{apiVersion}/gifts", validate({secret: 'pewaa'}), (req, res) ->
    upload req, res, (err) ->
      if err
        # An error occurred when uploading
        failed =
          'success' : false,
          'message' : 'Oops! Something went wrong'
        res.status(404).send(failed)
      # Gift avatar uploaded successfully
      req.body.user_id = req.userId
      if req.file
        req.body.avatar = req.file.filename

      gift = new Gift req.body
      if gift.validate()
        GiftsController.create gift, (err, result)->
          if err
            failed =
              'success' : false,
              'message' : err
            res.status(404).send(failed)
          else
            res.status(200).send(result)
      else
        res.status(404).send("Please contact Pewaa! support.")
    return

  app.post "/v#{apiVersion}/gifts/:id/cashout", validate({secret: 'pewaa'}), (req, res) ->
    gift = req.body
    gift.user_id = req.userId
    gift.gift_id = req.params.id

    GiftsController.cashoutRequest gift, (err, result)->
      if err
        failed =
          'success' : false,
          'message' : err
        res.status(404).send(failed)
      else
        res.status(200).send(result)
    return

  app.get "/v#{apiVersion}/gifts/:id", validate({secret: 'pewaa'}), (req, res) ->
    GiftsController.getOne req.params.id, (err, gift)->
      if err
        res.status(404).send("#{req.params.id} not found")
      else
        res.status(200).send(gift)

  app.post "/v#{apiVersion}/gifts/:id/report", validate({secret: 'pewaa'}), (req, res) ->
    gift = {}
    gift.id = req.params.id
    gift.flagged = req.body.flagged
    gift.flagged_description = req.body.flagged_description
    GiftsController.report gift, (err, result)->
      if err
        res.status(404).send(err)
      else
        res.status(200).send(result)

  app.delete "/v#{apiVersion}/gifts/:id", validate({secret: 'pewaa'}), (req, res) ->
    GiftsController.deleteOne req.params.id, (err)->
      if err
        res.status(404).send("#{req.params.id} not found")
      else
        res.status(200).send("OK")

module.exports = handler
