'use strict'
responseError = (error, res) ->
  descriptionExists = typeof error == 'object' and 'description' of error
  statusCodeExists = typeof error == 'object' and 'status_code' of error
  err = new Error(if descriptionExists then error.description else error)
  err.status = if statusCodeExists then error.status_code else 500
  res.status(err.status).json response: error

module.exports = responseError