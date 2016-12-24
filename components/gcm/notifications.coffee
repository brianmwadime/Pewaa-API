'use strict'
gcm  = require "node-gcm"

module.exports = class GcmNotifications
  constructor: (gcmKey, dryrun) ->
    # @gcmKey = gcmKey
    @sender = new (gcm.Sender)(gcmKey)
    @dryRun = dryrun
    @

  sendMessage: (text, ids) ->
    @message = new (gcm.Message)(
      collapseKey: 'View'
      priority: 'high'
      contentAvailable: true
      delayWhileIdle: true
      timeToLive: 3
      restrictedPackageName: process.env.ANDROID_PACKAGE
      dryRun: @dryRun
      data:
        key1: 'message1'
        key2: 'message2'
      notification:
        title: 'Pewaa'
        icon: 'ic_launcher'
        body: text)

    @sender.send @message, { registrationTokens: ids }, (err, response) ->
      if err
        console.error "Notify error ", err
        return false
      else
        console.log "Notify success", response
        return true

    return
        
