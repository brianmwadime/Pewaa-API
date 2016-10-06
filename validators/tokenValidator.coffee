'use strict'
set               = require('lodash.set')
UsersController 	= require "#{__dirname}/../controllers/users"
UnauthorizedError = require "#{__dirname}/../handlers/unauthorized_error"

module.exports = (options) ->
  if !options or !options.secret
    throw new Error('secret should be set')

  _requestProperty = options.userProperty or options.requestProperty or 'userId'
  credentialsRequired = if typeof options.credentialsRequired == 'undefined' then true else options.credentialsRequired

  middleware = (req, res, next) ->
    token = undefined
    if options.getToken and typeof options.getToken == 'function'
      try
        token = options.getToken(req)
      catch e
        return next(e)
    else if req.headers and req.headers.token
      token = req.headers.token
      if !token
        return next(new UnauthorizedError('credentials_required', message: 'No authorization token was found'))

    UsersController.getUserByToken token, (err, result)->
      if err
        return next(new UnauthorizedError('invalid_token', message: 'Invalid authorization token'))

      else
        set req, _requestProperty, result
        next()
        return

    return

  middleware.UnauthorizedError = UnauthorizedError
  middleware

