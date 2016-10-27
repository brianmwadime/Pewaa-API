'use strict'
require("#{__dirname}/../../environment")
GiftsController     = require "#{__dirname}/../../controllers/gifts"
Gift                = require "#{__dirname}/../../models/gift"
crypto              = require "crypto"
mime                = require "mime"
_                   = require 'underscore'
validate            = require "#{__dirname}/../../validators/tokenValidator"
multer              = require "multer"
apiVersion 	        = process.env.API_VERSION

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
        res.send _.map gifts, (t) -> (new Gift t).publicObject()
    else
      res.send 404

  app.get "/v#{apiVersion}/gifts/:id/contributors", validate({secret: 'pewaa'}), (req, res) ->
    GiftsController.getForWishlist req.params.id, (err, wishlists) ->
      if err
        res.send 400, err
      else
        res.send _.map wishlists, (p) -> (new Wishlist p).publicObject()

  app.post "/v#{apiVersion}/gifts", validate({secret: 'pewaa'}), (req, res) ->
    upload req, res, (err) ->
      if err
        # An error occurred when uploading
        failed =
          'success' : false,
          'message' : 'Oops! Something went wrong'
        res.send 400, failed
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
            res.send 400, failed
          else
            res.send result
      else
        res.send 400, 'some error'
    return

  app.get "/v#{apiVersion}/gifts/:id", validate({secret: 'pewaa'}), (req, res) ->
    GiftsController.getOne req.params.id, (err, gift)->
      if err or not gift.validate()
        res.send 404, "#{req.params.id} not found"
      else
        res.send gift.publicObject()

  app.delete "/v#{apiVersion}/gifts/:id", validate({secret: 'pewaa'}), (req, res) ->
    GiftsController.deleteOne req.params.id, (err)->
      if err
        res.send 404, "#{req.params.id} not found"
      else
        res.send 200

module.exports = handler
