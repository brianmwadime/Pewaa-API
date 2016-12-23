'use strict'
gcm  = require "node-gcm"

module.exports = class GcmNotifications
  constructor: (gcmKey, dryrun) ->
    # @gcmKey = gcmKey
    console.log "GCM Key", gcmKey
    @sender = new (gcm.Sender)(gcmKey)
    @dryRun = @dryrun
    @

  sendMessage: (text, ids) ->
    @message = new (gcm.Message)(
      collapseKey: 'View'
      priority: 'high'
      contentAvailable: true
      delayWhileIdle: true
      timeToLive: 3
      restrictedPackageName: 'com.fortunekidew.pewaa'
      dryRun: @dryRun
      data:
        key1: 'message1'
        key2: 'message2'
      notification:
        title: 'Pewaa'
        icon: 'ic_launcher'
        body: text)
    
    @sender.send @message, { registrationTokens: ids }, (err, response) ->
      # console.log "Here man!"
      if err
        # console.error err
        false
        return
      else
        # console.log response
        true
        return
