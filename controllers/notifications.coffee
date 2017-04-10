BaseController  = require "#{__dirname}/base"
Notification    = require "#{__dirname}/../models/push_credential"
gcm             = require('node-gcm')
sql             = require 'sql'
async           = require 'async'

class NotificationsController extends BaseController
  notification: sql.define
    name: 'push_credentials'
    columns: (new Notification).columns()

  getAll: (callback)->
    statement = @notification.select(@notification.star()).from(@notification)
    @query statement, callback

  getUserNotifications: (user_id, callback) ->
    statement = @notification
                .select @notification.star() #, @userswishlists.star()
                .where(@notification.user_id.equals user_id)
                .from(@notification)
    @query statement, (err, rows)->
      if err
        callback err
      else
        callback err, rows

  getOne: (key, callback)->
    statement = @notification.select(@notification.star()).from(@notification)
      .where(@notification.id.equals key)
    @query statement, (err, rows)->
      if err
        callback err
      else
        callback err, new Notification rows[0]

  create: (notification, callback)->
    if notification.validate()
      statement = @notification.insert notification.requiredObject()
                  .returning '*'
      @query statement, (err, rows)->
        if err
          error =
            'success': false,
            'message': "Could not add push credentials.",
            'error': err
          callback error
        else
          done =
            'success' : true,
            'id': rows[0].id,
            'platform': rows[0].platform,
            'user_id': rows[0].user_id,
            'device_id': rows[0].device_id,
            'message' : 'device added successfully.'

          callback null, done
    else
      callback new Error "Invalid parameters"

  deleteOne: (device_id, callback)->
    statement = @notification.delete()
                .from @notification
                .where @notification.device_id.equals device_id
    @query statement, (err)->
      callback err

  exists: (key, callback) ->
    findNotification = @notification.select(@notification.device_id)
                        .where(@notification.id.equals(key)).limit(1)
    @query findNotification, (err, rows) ->
      if err or rows.length isnt 1
        callback new Error "#{key} not found"
      else
        callback null, yes


module.exports = NotificationsController.get()
