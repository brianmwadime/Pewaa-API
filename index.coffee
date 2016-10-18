require('./environment')
express     	= require 'express'
_             = require 'underscore'
Request       = require('oauth2-server').Request
config      	= require './config/database' # get db config file
bodyParser  	= require 'body-parser'
OAuthServer   = require 'oauth2-server'
cookieParser  = require 'cookie-parser'
session       = require 'express-session'
morgan 		    = require 'morgan'
http          = require 'http'
cors 			    = require 'cors'
port        	= process.env.PORT or 8080
info          = require './package'
apiVersion 	  = process.env.API_VERSION

users         = require './routes/users'
wishlists     = require './routes/wishlists'
gifts         = require './routes/gifts'
{
  not_found_handler
  uncaught_error_handler
} = require './handlers'

payments      = require './routes/payments'
genTransactionPassword = require './components/mpesa/genTransactionPassword'
apiVersion 	  = process.env.API_VERSION

done = null

app = express()

# Log requests to console
app.use morgan 'dev'
#   body parsers
app.use bodyParser(limit: '10mb')
app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: true)
app.use cookieParser()
app.use cors()

# memory based session
app.use session(
  secret: process.env.SESSION_SECRET_KEY
  resave: false
  saveUninitialized: true)

app.disable 'x-powered-by'

app.use "/static", express.static(__dirname + "/uploads")
# on payment transaction requests,
# generate and password to req object
app.use "/v#{apiVersion}/payments/", genTransactionPassword

# get our request parameters
app.oauth = new OAuthServer({
  model: require "#{__dirname}/models/session"
})

_.each [users, wishlists, gifts, payments], (s) ->
  s app


app.use app.router

# use this prettify the error stack string into an array of stack traces

# prettifyStackTrace = (stackTrace) ->
#   stackTrace.replace(/\s{2,}/g, ' ').trim()
#   return

# Authorization errors
app.use (err, req, res, next) ->
  if err.name == 'UnauthorizedError'
    result =
      'success' : false
      'message' : err.message
    res.status(401).send result
  return

# catch 404 and forward to error handler
app.use not_found_handler
app.use uncaught_error_handler

  # errorResponse =
  #   status_code: err.statusCode
  #   request_url: req.originalUrl
  #   message: err.message
  # # Only send back the error stack if it's on development mode
  # if process.env.NODE_ENV == 'development'
  #   stack = err.stack.split(/\n/).map(prettifyStackTrace)
  #   errorResponse.stack_trace = stack
  # res.status(err.statusCode or 500).json()

# Start the server
server = app.listen(process.env.PORT or 8080, ->
  console.log 'Your secret session key is: ' + process.env.SESSION_SECRET_KEY
  console.log 'Express server listening on %d, in %s' + ' mode', server.address().port, app.get('env')
  return
)

module.exports = app
