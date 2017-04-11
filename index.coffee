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
port        	= process.env.PORT or 3030
info          = require './package'
apiVersion 	  = process.env.API_VERSION
os            = require 'os'
users         = require './routes/users'
wishlists     = require './routes/wishlists'
gifts         = require './routes/gifts'
contributors  = require './routes/contributors'
notifications = require './routes/notifications'
pingInterval  = 30 * 1000
Socket        = require 'socket.io'

{
  not_found_handler
  uncaught_error_handler
} = require './handlers'

payments      = require './routes/payments'
genTransactionPassword = require './components/mpesa/genTransactionPassword'
apiVersion 	  = process.env.API_VERSION

debugging_mode = false
done = null
app = express()

app_key_secret = "7d3d3b6c5d3683bf25bbb51533ec6dac"

# Log requests to console
app.use morgan 'dev'
#   body parsers
app.use bodyParser(limit: '10mb')
app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: false)
app.use cookieParser()
app.use cors()

# memory based session
# app.use session(
#   secret: process.env.SESSION_SECRET_KEY
#   resave: false
#   saveUninitialized: true)

app.disable 'x-powered-by'

app.use "/static", express.static(__dirname + "/uploads")
# on payment transaction requests,
# generate and password to req object
app.use "/v#{apiVersion}/payments/", genTransactionPassword

# get our request parameters
app.oauth = new OAuthServer({
  model: require "#{__dirname}/models/session"
})

_.each [users, wishlists, gifts, payments, contributors, notifications], (s) ->
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


server = http.createServer(app)
# io = require('socket.io').listen(server)
io = Socket(server,
  'pingInterval': pingInterval
  'pingTimeout': 6000)

server.listen(process.env.PORT or 3030, ->
  # console.log 'Your secret session key is: ' + process.env.SESSION_SECRET_KEY
  console.log 'Express server listening on %d, in %s' + ' mode',
    server.address().port, app.get('env'), '\nPress Ctrl-C to terminate.'
  return
)

io.use (socket, next) ->
  token = socket.handshake.query.token
  if token == app_key_secret
    if debugging_mode
      console.log 'token valid  authorized', token
    next()
  else
    if debugging_mode
      console.log 'not a valid token Unauthorized to access'
    next new Error('not valid token')
  return

users = []
global.socketIO = io

io.on 'connection', (socket) ->
  # Global Socket object
  # global.socketIO = socket
  # console.log global.socketIO

  ###************ Method for a single user ***************************
  #
  # *********************************************************************
  ###

  ###*
  # method to check if user is connected or not
  ###

  socket.on 'user_connect', (data) ->
    console.log 'user with id ' + data.connectedId
    console.log 'user with boolean ' + data.connected
    user =
      id: data.connectedId
      socketID: socket.id
    users.push user
    io.sockets.emit 'user_connect',
      connectedId: data.connectedId
      connected: data.connected
      socketId: socket.id
    return

  ###*
  # method to check if recipient is Online
  ###

  socket.on 'is_online', (data) ->
    io.sockets.emit 'is_online',
      senderId: data.senderId
      connected: data.connected
    return

  ###*
  # method if a user is disconnect from sockets
  # and then remove him from array of current users connected
  ###

  socket.on 'disconnect', ->
    i = 0
    while i < users.length
      user = users[i]
      console.log 'this user is disconnect' + user.id
      io.sockets.emit 'user_connect',
        connectedId: user.id
        connected: false
        socketId: socket.id
      if user.socketID == socket.id
        users.splice i, 1
        break
      ++i
    return
  return

module.exports = app
