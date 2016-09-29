BaseController  = require "#{__dirname}/base"
sql             = require 'sql'
async           = require 'async'
User            = require "#{__dirname}/../models/user"
twilio          = require './config/twilio' # get db config file
client          = require('twilio')(twilio.ACCOUNT_SID, twilio.AUTH_TOKEN)
# UserCredentialsController = require "#{__dirname}/../controllers/user_credentials"

class UsersController extends BaseController

  user: sql.define
    name: 'users'
    columns: (new User).columns()

  smscodes: sql.define
    name: 'sms_codes'
    columns: ['code', 'user_id']

  getAll: (callback)->
    statement = @user.select(@user.star()).from(@user)
    @query statement, callback

  getOne: (key, callback)->
    statement = @user.select(@user.star()).from(@user)
      .where(@user.id.equals key)
    @query statement, (err, rows)->
      if err
        callback err
      else
        callback err, new User rows[0]

#   getOneWithCredentials: (key, callback)->
#     {user_credential} = UserCredentialsController
#     statement = @user
#       .select @user.star(), user_credential.star()
#       .where user_credential.userId.equals key
#       .from(
#         @user
#           .join user_credential
#           .on @user.id.equals user_credential.userId
#       )
#     @query statement, (err, rows)->
#       if err
#         callback err
#       else
#         callback err, new User rows[0]

  getOneWithCredentials: (key, callback)->
    {user_credential} = UserCredentialsController
    statement = @user
      .select @user.star(), user_credential.star()
      .where user_credential.userId.equals key
      .from(
        @user
          .join user_credential
          .on @user.id.equals user_credential.userId
      )
    @query statement, (err, rows)->
      if err
        callback err
      else
        callback err, new User rows[0]

  create: (userParam, callback)->
    statement = (@user.insert userParam.requiredObject()).returning '*'
    @query statement, (err, rows)->
      if err
        callback err
      else
        callback err, new User rows[0]

    t = @transaction()
    start = =>
      statementNewProject = (@project.insert spec.requiredObject()).returning '*'
      statementNewUser = (@user.insert userParam.requiredObject()).returning '*'
      t.query statementNewUser, (results) =>
        user = new User results?.rows[0]
        code = Math.floor(Math.random() * 999999 + 111111)
        statementNewUsersVerifyCode = (@smscodes.insert {user_id:userId, code: code})
        t.query statementNewUsersVerifyCode, ()->
          t.commit user

    t.on 'begin', start
    t.on 'error', (err)->
      error = 
        'success' => false,
        'message' => 'Sorry! Error occurred .',
      callback error
    t.on 'commit', (user)->
      client.sendMessage {
        to: user.phone
        from: '+12132925019'
        body: "Hello, Welcome to PEWAA. Your Verification code is #{code}"
      }, (err, responseData) ->
        #this function is executed when a response is received from Twilio
        if !err
          console.info responseData.from
          console.info responseData.body
          # outputs "word to your mother."
          result = 
            'success' : true,
            'message' : 'SMS request is Resend! You will be receiving it shortly.',
          
          callback null, result
        else
          error = 
            'success' : false,
            'message' : 'Sorry! Error occurred.',
          callback error

    t.on 'rollback', ->
      callback new Error "Couldn't create new user"

  

#   deleteOne: (key, callback)->
#     t = @transaction()
#     deleteUser = @user.delete()
#       .where @user.id.equals key
#     deleteUserCredentials = UserCredentialsController.deleteSql key
#     start = ->
#       async.eachSeries [deleteUserCredentials, deleteUser],
#         (s, cb)->
#           t.query s, () ->
#             cb()
#         , ->
#           t.commit()

#     t.on 'begin', start
#     t.on 'error', console.log
#     t.on 'commit', ->
#       callback()
#     t.on 'rollback', ->
#       callback new Error "Could not delete user with id #{key}"


module.exports = UsersController.get()