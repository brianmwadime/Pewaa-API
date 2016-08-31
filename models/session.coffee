{dev} = require "#{__dirname}/../database"
pgp  = require('pg-promise')()
devConfig = "postgres://#{dev.user}:#{dev.password}@localhost/#{dev.database}"
constring = devConfig
bcrypt = require 'bcrypt'

pg =  pgp constring

# Get Access Token

module.exports.getAccessToken = (bearerToken) ->
  pg.query('SELECT access_token, access_token_expires_on, client_id, refresh_token, refresh_token_expires_on, user_id FROM oauth_tokens WHERE access_token = $1', [ bearerToken ]).then (result) ->
    token = result[0]
    {
      accessToken: token.access_token
      clientId: token.client_id
      expires: token.access_token_expires_on
      user: {
        id: token.user_id
      }
    }



authorizedClientIds = [
  's6BhdRkqt3'
]

module.exports.grantTypeAllowed = (clientId, grantType, callback) ->  
  if grantType == 'password'
    return callback(false, authorizedClientIds.indexOf(clientId.toLowerCase()) >= 0)
  callback false, true
  return

# Get client.

module.exports.getClient = (clientId, clientSecret) ->
  pg.query('SELECT client_id, client_secret, redirect_uri, grants FROM oauth_clients WHERE client_id = $1 AND client_secret = $2', [
    clientId
    clientSecret
  ]).then (result) ->
    oAuthClient = result[0]
    if !oAuthClient
      return
    {
      clientId: oAuthClient.client_id
      clientSecret: oAuthClient.client_secret
      grants: oAuthClient.grants
    }

# Get refresh token.

module.exports.getRefreshToken = (bearerToken) ->
  pg.query('SELECT access_token, access_token_expires_on, client_id, refresh_token, refresh_token_expires_on, user_id FROM oauth_tokens WHERE refresh_token = $1', [ bearerToken ]).then (result) ->
    # if result.rowCount then result[0] else false
    if result then result[0] else false

# Get user.

module.exports.getUser = (username, password) ->
  pg.query('SELECT id, hash FROM users WHERE username = $1', [
    username
  ]).then (result) ->
    if result
      matched = bcrypt.compareSync password, result[0].hash
      if matched then return result[0] else return false
    else
      return false

# Save token.

module.exports.saveToken = (token, client, user) ->
  pg.query('INSERT INTO oauth_tokens(access_token, access_token_expires_on, client_id, refresh_token, refresh_token_expires_on, user_id) VALUES ($1, $2, $3, $4, $5, $6) RETURNING access_token AS "accessToken", client_id AS client, user_id AS user', [
    token.accessToken
    token.accessTokenExpiresAt
    client.clientId
    token.refreshToken
    token.refreshTokenExpiresAt
    user.id
  ]).then (result) ->
    if result then result[0] else false