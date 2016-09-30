BaseController  = require "#{__dirname}/base"
sql             = require 'sql'
async           = require 'async'
User            = require "#{__dirname}/../models/user"
SmsCode         = require "#{__dirname}/../models/sms_code"
twilio          = require "#{__dirname}/../config/twilio" # get twilio config file
client          = require('twilio')(twilio.ACCOUNT_SID, twilio.AUTH_TOKEN)

class UsersController extends BaseController

  user: sql.define
    name: 'users'
    columns: (new User).columns()

  smscode: sql.define
    name: 'sms_codes'
    columns: ['code', 'user_id', 'status', 'id']

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
    code = Math.floor(Math.random() * 999999 + 111111)
    t = @transaction()
    start = =>
      statementNewUser = @user.insert(userParam.requiredObject()).returning '*'
      t.query statementNewUser, (results) =>
        user = new User results?.rows[0]
        
        statementNewUsersVerifyCode = (@smscode.insert {user_id:user.id, code: code})
        t.query statementNewUsersVerifyCode, ()->
          t.commit user

    t.on 'begin', start
    t.on 'error', (err)->
      console.info "Failed to create user", err
      error = 
        'success' : false,
        'message' : 'Sorry! Error occurred .',
      callback error
    t.on 'commit', (user)->
      console.info "Created", user
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
            'message' : 'SMS request is sent! You will be receiving it shortly.'
          
          callback null, result
        else
          error = 
            'success' : false,
            'message' : 'Sorry! Error occurred.'

          callback error

    t.on 'rollback', ->
      callback "Couldn't create new user"

  verify: (code, callback)->

    userTable = @user
    smsCodeTable = @smscode

    statement = @smscode
                .select @smscode.star(), @user.apikey
                .where(@smscode.code.equals code)
                .from(
                  @smscode
                    .join @user
                    .on @smscode.user_id.equals @user.id
                )

    t = @transaction()
    @query statement, (err, rows)->
      if err
        callback err
      else
        updateSmsCode = smsCodeTable.update({status: true}).where smsCodeTable.id.equals new SmsCode rows[0].id
        updateUser    = userTable.update({is_activated: true}).where userTable.id.equals new SmsCode rows[0].user_id
        start = ->
          async.eachSeries [updateUser, updateSmsCode],
            (s, cb)->
              t.query s, () ->
                cb()
            , ->
              t.commit()

        t.on 'begin', start
        t.on 'error', (err)->
          error = 
            'success' : false,
            'message' : 'Sorry! Error occurred.',
          callback error
        t.on 'commit', (result)->
          results = 
            'success' : true,
            'message' : 'Your account has been created successfully.',
          callback null, results
        t.on 'rollback', ->
          callback "Couldn't update user details"

module.exports = UsersController.get()