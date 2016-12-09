'use strict'
require("#{__dirname}/../../environment")
NotificationsController = require "#{__dirname}/../../controllers/notifications"
Notification            = require "#{__dirname}/../../models/push_credential"
_                       = require 'underscore'
validate                = require '#{__dirname}/../../validators/tokenValidator'
apiVersion 	            = process.env.API_VERSION

handler = (app) ->

  app.get "/v#{apiVersion}/devices", validate({secret: 'pewaa'}), (req, res) ->
    NotificationsController.getUserNotifications req.userId, (err, notifications) ->
      if err
        res.send 400, err
      else
        res.send _.map notifications, (p) -> (new Notification p).publicObject()

  app.post "/v#{apiVersion}/devices", validate({secret: 'pewaa'}), (req, res) ->
    notification = new Notification req.body
    notification.user_id = req.userId
    if notification.validate()
      NotificationsController.create notification, (err, result) ->
        if err
          res.send 400, err
        else
          res.send result
    else
      res.send 400, 'Invalid parameters'

  app.get "/v#{apiVersion}/devices/:id", validate({secret: 'pewaa'}), (req, res) ->
    NotificationsController.getOne req.params.id, (err, notification)->
      if err or not notification.validate()
        res.send 404, err
      else
        res.send notification.publicObject()

  app.delete "/v#{apiVersion}/devices/:id", validate({secret: 'pewaa'}), (req, res) ->
    NotificationsController.deleteOne req.params.id, (err) ->
      if err
        res.send 404, err
      else
        res.send 200

module.exports = handler
