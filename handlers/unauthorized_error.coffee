UnauthorizedError = (code, error) ->
  Error.call this, error.message
  Error.captureStackTrace this, @constructor
  @name = 'UnauthorizedError'
  @message = error.message
  @code = code
  @status = 401
  @inner = error
  return

UnauthorizedError.prototype = Object.create(Error.prototype)
UnauthorizedError::constructor = UnauthorizedError

module.exports = UnauthorizedError
