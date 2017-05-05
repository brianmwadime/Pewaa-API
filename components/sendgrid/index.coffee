'use strict'
gcm  = require "node-gcm"
helper = require('sendgrid').mail
sg = require('sendgrid')(process.env.SENDGRID_API_KEY)

module.exports = class SendGrid
  constructor: () ->
    @

  sendEmail: (from, to, subject, message) ->
    mail = new (helper.Mail)(new helper.Email(from), subject, new helper.Email(to), new helper.Content('text/html',message))
    request = sg.emptyRequest(
      method: 'POST'
      path: '/v3/mail/send'
      body: mail.toJSON())

    sg.API request, (error, response) ->
      if error
        console.log 'Error response received'
        console.log response.statusCode
        console.log response.body
        console.log response.headers
        return false
      else
        console.log "Email sent successfully", response.statusCode
        return true

    return