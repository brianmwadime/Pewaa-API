'use strict'

module.exports = (req, res, next) ->
  token = req.headers.token
  if token
    next()
  else
    return res.status(403).send
      success: false
      message: 'No authorization token was found.'
