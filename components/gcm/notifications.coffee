'use strict'
gcm  = require "node-gcm"

module.exports = class GcmNotifications
  constructor: (gcmKey, dryrun) ->
    @sender = new (gcm.Sender)(gcmKey)
    @dryRun = dryrun
    @

  sendMessage: (text, data, ids) ->
    @message = new (gcm.Message)(
      collapseKey: 'View'
      priority: 'high'
      contentAvailable: true
      delayWhileIdle: true
      timeToLive: 3
      restrictedPackageName: process.env.ANDROID_PACKAGE
      dryRun: @dryRun
      data: data
      notification:
        title: 'Pewaa'
        icon: 'ic_launcher'
        body: text)

    @sender.send @message, { registrationTokens: ids }, (err, response) ->
      if err
        console.error "Notification(s) error ", err
        return false
      else
        console.log "Notification(s) sent successfully", response
        return true

    return
        
