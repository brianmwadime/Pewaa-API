'use strict'
require("#{__dirname}/../../environment")
_ 						    = require 'underscore'
express 				  = require 'express'
UsersController 	= require '#{__dirname}/../../controllers/users'
User 					    = require '#{__dirname}/../../models/user'
validate          = require '#{__dirname}/../../validators/tokenValidator'
apiVersion 	      = process.env.API_VERSION

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

  app.post "/v#{apiVersion}/users/sendContacts", validate, (req, res) ->
    UsersController.comparePhoneNumbers req.body, (err, result)->
      if err
        res.send 400, err

      else
        res.send 200, result

  app.post "/v#{apiVersion}/users/deleteAccount", validate, (req, res) ->
    UsersController.prepareDeleteAccount req.body.phone, (err, result)->
      if err
        res.send 400, err

      else
        res.send 200, result

module.exports = handler
