pg = require 'pg'
{dev} = require "#{__dirname}/../database"
devConfig = "postgres://#{dev.user}:#{dev.password}@localhost/#{dev.database}"

if process.env.NODE_ENV == 'production'
  constring = "postgres://postgres:@!_^%Mwakima@localhost/pewaa"
else
  constring = devConfig


{EventEmitter} = require 'events'

Database = (callback) ->
  pg.connect constring, callback

class Transaction extends EventEmitter
  constructor: ()->
    Database (err, client, done) =>
      if err
        @emit 'error', err
      else
        @client = client
        @done = done
        @begin()

  begin: ->
    @client.query 'BEGIN', (err)=>
      if err
        @emit 'error', err
      else
        @emit 'begin'

  query: (statement, cb)->
    statement = if typeof statement.toQuery is 'function' then statement.toQuery() else statement
    @client.query statement, (err, rows) =>
      if err
        @rollback()
      else
        cb rows

  rollback: () ->
    @client.query 'ROLLBACK', (err) =>
      @done err
      @emit 'rollback', err

  commit: (obj)->
    @client.query 'COMMIT', (err) =>
      @done()
      @emit 'commit', obj

module.exports = Database

module.exports.Transaction = Transaction
