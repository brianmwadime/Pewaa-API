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
os            = require 'os'
users         = require './routes/users'
wishlists     = require './routes/wishlists'
gifts         = require './routes/gifts'
contributors  = require './routes/contributors'
notifications = require './routes/notifications'
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
app.use bodyParser.urlencoded(extended: false)
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
io = require('socket.io').listen(server)

server.listen(process.env.PORT or 8080, ->
  # console.log 'Your secret session key is: ' + process.env.SESSION_SECRET_KEY
  console.log 'Express server listening on %d, in %s' + ' mode',
    server.address().port, app.get('env'), '\nPress Ctrl-C to terminate.'
  return
)


# Start the server
# server = app.listen(process.env.PORT or 8080, ->
#   console.log 'Your secret session key is: ' + process.env.SESSION_SECRET_KEY
#   console.log 'Express server listening on %d, in %s' + ' mode',
#     server.address().port, app.get('env'), '\nPress Ctrl-C to terminate.'
#   return
# )

users = []
global.socketIO = io

io.on 'connection', (socket) ->
  # Global Socket object
  # global.socketIO = socket
  # console.log global.socketIO
  ###************* Method for groups  ****************************************
  #
  # **************************************************************************
  ###

  ###*
  # method to check if  member of group  is start typing
  ###

  ###*
  # method to save message as waiting
  # @param data
  ###

  saveMessageGroupToDataBase = (data) ->
    http = require('http')
    queryString = require('querystring')
    qs = queryString.stringify(data)
    qslength = qs.length
    path = require('path').basename(__dirname)
    hostname = os.hostname()
    options =
      hostname: hostname
      port: port
      path: '/v#{apiVersion}/' + path + '/Groups/send'
      method: 'POST'
      type: 'json'
      headers:
        'Content-Type': 'application/x-www-form-urlencoded'
        'Content-Length': qslength
    buffer = ''
    req = http.request(options, (res) ->
      res.on 'data', (chunk) ->
        buffer += chunk
        return
      res.on 'end', ->
        io.sockets.emit 'group_delivered',
          groupId: data.groupID
          senderId: data.senderId
        return
      res.on 'error', (e) ->
        console.log 'Got error: ' + e.message
        return
      return
    )
    req.write qs
    req.end()
    return

  ###*
  # method to check if there is messages to sent
  # @param data
  ###

  CheckForUnsentMessages = (data) ->
    http = require('http')
    queryString = require('querystring')
    qs = queryString.stringify(data)
    qslength = qs.length
    path = require('path').basename(__dirname)
    hostname = os.hostname()
    options =
      hostname: hostname
      port: port
      path: '/v#{apiVersion}/' + path + '/Groups/checkUnsentMessageGroup'
      method: 'POST'
      type: 'json'
      headers:
        'Content-Type': 'application/x-www-form-urlencoded'
        'Content-Length': qslength
    body = ''
    req = http.request(options, (res) ->
      res.on 'data', (chunk) ->
        body += chunk
        return
      res.on 'end', ->
        obj = JSON.parse(body)
        i = 0
        while i < obj.length
          pingedData =
            recipientId: obj[i].recipientId
            messageId: obj[i].messageId
            messageBody: obj[i].messageBody
            senderId: obj[i].senderId
            phone: obj[i].phone
            senderName: obj[i].senderName
            GroupImage: obj[i].GroupImage
            GroupName: obj[i].GroupName
            groupID: obj[i].groupId
            date: obj[i].date
            isGroup: obj[i].isGroup
            image: obj[i].image
            video: obj[i].video
            audio: obj[i].audio
            document: obj[i].document
            thumbnail: obj[i].thumbnail
            pinged: obj[i].pinged
            pingedId: obj[i].pingedId
          io.sockets.emit 'user_pinged_group', pingedData
          i++
        return
      res.on 'error', (e) ->
        console.log 'Got error: ' + e.message
        return
      return
    )
    req.write qs
    req.end()
    return

  ###*
  # method to save message of user
  # @param data
  ###

  saveMessageToDataBase = (data) ->
    http = require('http')
    queryString = require('querystring')
    qs = queryString.stringify(data)
    qslength = qs.length
    path = require('path').basename(__dirname)
    hostname = os.hostname()
    options =
      hostname: hostname
      port: port
      path: '/v#{apiVersion}/' + path + '/Messages/send'
      method: 'POST'
      type: 'json'
      headers:
        'Content-Type': 'application/x-www-form-urlencoded'
        'Content-Length': qslength
    buffer = ''
    req = http.request(options, (res) ->
      res.on 'data', (chunk) ->
        buffer += chunk
        return
      res.on 'error', (e) ->
        console.log 'Got error: ' + e.message
        return
      return
    )
    req.write qs
    req.end()
    return

  socket.on 'member_typing', (data) ->
    io.sockets.emit 'member_typing',
      recipientId: data.recipientId
      groupId: data.groupId
      senderId: data.senderId
    return

  ###*
  # method to check if a member of group  is stop typing
  ###

  socket.on 'member_stop_typing', (data) ->
    io.sockets.emit 'member_stop_typing',
      recipientId: data.recipientId
      groupId: data.groupId
      senderId: data.senderId
    return

  ###*
  # method to check if u receive a new message
  ###

  socket.on 'new_group_message', (data) ->
    io.sockets.emit 'new_group_message',
      recipientId: data.recipientId
      messageId: data.messageId
      messageBody: data.messageBody
      senderId: data.senderId
      phone: data.phone
      senderName: data.senderName
      GroupImage: data.GroupImage
      GroupName: data.GroupName
      groupID: data.groupID
      date: data.date
      isGroup: data.isGroup
      image: data.image
      video: data.video
      audio: data.audio
      document: data.document
      thumbnail: data.thumbnail
    return

  ###*
  # mehtod to save firstly the message in the database
  ###

  socket.on 'save_group_message', (data, callback) ->
    http = require('http')
    queryString = require('querystring')
    qs = queryString.stringify(data)
    qslength = qs.length
    path = require('path').basename(__dirname)
    hostname = os.hostname()
    options =
      hostname: hostname
      port: port
      path: '/v#{apiVersion}/' + path + '/Groups/saveMessage'
      method: 'POST'
      type: 'json'
      headers:
        'Content-Type': 'application/x-www-form-urlencoded'
        'Content-Length': qslength
    buffer = ''
    req = http.request(options, (res) ->
      res.on 'data', (chunk) ->
        buffer += chunk
        return
      res.on 'end', ->
        messageData = messageId: buffer
        console.log messageData
        callback messageData
        io.sockets.emit 'group_sent',
          groupId: data.groupID
          senderId: data.senderId
        return
      res.on 'error', (e) ->
        console.log 'Got error: ' + e.message
        return
      return
    )
    req.write qs
    req.end()
    return

  ###*
  # method to ping and check if member of group is connected
  ###

  socket.on 'user_ping_group', (data) ->
    pingedData = undefined
    pingedData =
      recipientId: data.recipientId
      messageId: data.messageId
      messageBody: data.messageBody
      senderId: data.senderId
      phone: data.phone
      senderName: data.senderName
      GroupImage: data.GroupImage
      GroupName: data.GroupName
      groupID: data.groupID
      date: data.date
      isGroup: data.isGroup
      image: data.image
      video: data.video
      audio: data.audio
      document: data.document
      thumbnail: data.thumbnail
      pinged: data.pinged
      pingedId: data.pingedId
    io.sockets.emit 'user_pinged_group', pingedData
    return

  ###*
  # method to send message group
  ###

  socket.on 'send_group_message', (dataString) ->
    console.log dataString
    saveMessageGroupToDataBase dataString
    return

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
    CheckForUnsentMessages data
    #this just for groups
    return

  ###*
  # method to get response from recipient to update status (from waiting to sent)
  ###

  socket.on 'send_message', (dataString) ->
    messageID =
      messageId: dataString.messageId
      senderId: dataString.senderId
    io.sockets.emit 'send_message',
      messageId: messageID.messageId
      senderId: messageID.senderId
    return

  ###*
  # method to check if user disconnected  before send a message to him (do a ping and get a callback)
  ###

  socket.on 'user_ping', (data, callback) ->
    pingingData =
      pinged: data.pinged
      pingedId: data.pingedId
      socketId: data.socketId
    pingedData = undefined
    if pingingData.pingedId = data.recipientId and pingingData.pinged == true
      pingedData =
        messageId: data.messageId
        senderImage: data.senderImage
        pingedId: data.recipientId
        pinged: pingingData.pinged
        senderId: data.senderId
        recipientId: data.recipientId
        senderName: data.senderName
        messageBody: data.messageBody
        date: data.date
        isGroup: data.isGroup
        conversationId: data.conversationId
        image: data.image
        video: data.video
        audio: data.audio
        document: data.document
        thumbnail: data.thumbnail
        phone: data.phone
    else
      pingedData =
        messageId: data.messageId
        senderImage: data.senderImage
        pingedId: data.senderId
        pinged: pingingData.pinged
        senderId: data.senderId
        recipientId: data.recipientId
        senderName: data.senderName
        messageBody: data.messageBody
        date: data.date
        isGroup: data.isGroup
        conversationId: data.conversationId
        image: data.image
        video: data.video
        audio: data.audio
        document: data.document
        thumbnail: data.thumbnail
        phone: data.phone
    callback pingedData
    #return;
    return

  ###*
  # method to check if u receive a new message
  ###

  socket.on 'new_message', (data) ->
    io.sockets.emit 'new_message',
      messageId: data.messageId
      senderImage: data.senderImage
      senderId: data.senderId
      recipientId: data.recipientId
      senderName: data.senderName
      messageBody: data.messageBody
      date: data.date
      isGroup: data.isGroup
      conversationId: data.conversationId
      image: data.image
      video: data.video
      audio: data.audio
      document: data.document
      thumbnail: data.thumbnail
      phone: data.phone
    return

  ###*
  # method to save new message to database
  ###

  socket.on 'save_new_message', (data) ->
    saveMessageToDataBase data
    return

  ###*
  # method to check if user is start typing
  ###

  socket.on 'typing', (data) ->
    io.sockets.emit 'typing',
      recipientId: data.recipientId
      senderId: data.senderId
    return

  ###*
  # method to check if user is stop typing
  ###

  socket.on 'stop_typing', (data) ->
    io.sockets.emit 'stop_typing',
      recipientId: data.recipientId
      senderId: data.senderId
    return

  ###*
  # method to check status last seen
  ###

  socket.on 'last_seen', (data) ->
    io.sockets.emit 'last_seen',
      lastSeen: data.lastSeen
      senderId: data.senderId
      recipientId: data.recipientId
    return

  ###*
  # method to check if user is read (seen) a specific message
  ###

  socket.on 'seen', (data) ->
    io.sockets.emit 'seen',
      senderId: data.senderId
      recipientId: data.recipientId
    return

  ###*
  # method to check if a message is delivered to the recipient
  ###

  socket.on 'delivered', (data) ->
    io.sockets.emit 'delivered',
      messageId: data.messageId
      senderId: data.senderId
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
