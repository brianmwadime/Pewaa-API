require('./environment')
express     	= require 'express'
_             = require 'underscore'
# routes        = require './routes'
Request       = require('oauth2-server').Request
config      	= require './config/database' # get db config file
bodyParser  	= require 'body-parser'
OAuthServer   = require 'oauth2-server'
morgan 		    = require 'morgan'
http          = require 'http'
cors 			    = require 'cors'
port        	= process.env.PORT or 8080
info          = require './package'
apiVersion 	  = process.env.API_VERSION

users         = require './routes/users'
wishlists     = require './routes/wishlists'
{
    not_found_handler
    uncaught_error_handler
} = require './handlers'

done = null

app = express()

#   body parsers
app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: true)
app.use cors()

# get our request parameters
app.oauth = new OAuthServer({
  model: require "#{__dirname}/models/session", # See https://github.com/thomseddon/node-oauth2-server for specification
});

# Log requests to console
app.use morgan 'dev'
# get an instance of the router for api routes

app.get "/api/v${apiVersion}", (req, res)-> res.send version:info.version

_.each [users, wishlists], (s) ->
  s app

app.use app.router

app.use not_found_handler
app.use uncaught_error_handler

# app.all '/*', (req, res) ->
#   res.send 'Hello! The API is at http://localhost:' + port + '/api'
#   return

# Server Route (GET http://localhost:8080)
# app.get('/', function(req, res) {
#    res.send('Hello! The API is at http://localhost:' + port + '/api');
# });
# app.get '/', (req, res) ->
#   res.send 'Hello! The API is at http://localhost:' + port + '/api'
#   return

# Get secret.
# app.get('/secret', app.oauth.authorize(), function(req, res) {
#   # Will require a valid access_token.
#   res.send('Secret area');
# });

# app.use oauth.errorHandler()

# Start the server
# app.listen port
# console.log 'There will be dragons: http://localhost:' + port
server = http.createServer app

server.listen port, ->
  console.log "Listening on #{port}"
  done() if done?

module.exports = (ready) -> done = ready
