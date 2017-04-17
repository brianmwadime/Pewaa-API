'use strict'
require("#{__dirname}/../../environment")
_ 						    = require "underscore"
express 				  = require "express"
gcm               = require "node-gcm"
crypto            = require "crypto"
mime              = require "mime"
UsersController 	= require "#{__dirname}/../../controllers/users"
User 					    = require "#{__dirname}/../../models/user"
validate          = require "#{__dirname}/../../validators/tokenValidator"
multer            = require "multer"
apiVersion 	      = process.env.API_VERSION

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

  app.post "/v#{apiVersion}/users/join", (req, res) ->
    user = new User req.body
    if user.validate()
      UsersController.create user, (err, result)->
        if err
          res.send 400, err
        else
          res.send 200, result
    else
      res.json 400, error: "Invalid parameters."

  app.post "/v#{apiVersion}/users/avatar", validate({secret: 'pewaa'}), (req, res) ->
    upload req, res, (err) ->
      if err
        # An error occurred when uploading
        failed =
          'success' : false,
          'message' : 'Oops! Something went wrong. Please try again later'
        res.send 400, failed
      # Profile avatar uploaded successfully
      UsersController.saveAvatar {avatar:req.file.filename, userId:req.userId}, (error, result) ->
        if err
          res.send 400, err
        else
          res.send 200, result
    return

  app.get "/v#{apiVersion}/users/:id", validate({secret: 'pewaa'}), (req, res) ->
    UsersController.getOne req.params.id, (err, result)->
      if err
        res.send 400, err
      else
        res.send 200, result

  app.post "/v#{apiVersion}/users/verify", (req, res) ->
    UsersController.verify req.body.code, (err, result)->
      if err
        res.json 400, err
      else
        res.json 200, result

  app.post "/v#{apiVersion}/users/resend", (req, res) ->
    UsersController.resend req.body.phone, (err, result)->
      if err
        res.send 400, err
      else
        res.send 200, result

  app.post "/v#{apiVersion}/users/changeUsername", validate({secret: 'pewaa'}), (req, res)->
    params =
      name: req.body.name
      userId: req.userId

    UsersController.updateName params, (err, result)->
      if err
        res.send 400, err
      else
        res.send 200, result

  app.post "/v#{apiVersion}/users/sendContacts", validate({secret: 'pewaa'}), (req, res) ->
    UsersController.comparePhoneNumbers req.body, (err, result)->
      if err
        res.send 400, err
      else
        res.send 200, result

  app.post "/v#{apiVersion}/users/deleteAccount", validate({secret: 'pewaa'}), (req, res) ->
    UsersController.prepareDeleteAccount req.body.phone, (err, result)->
      if err
        res.send 400, err
      else
        res.send 200, result

  app.post "/v#{apiVersion}/users/testNotification", validate({secret: 'pewaa'}), (req, res) ->
    console.info "Query param: ", req.userId
    # sendNotifications
    UsersController.testNotification req.userId, (err, result)->
      if err
        res.send 400, err
      else
        res.send 200, result

module.exports = handler
