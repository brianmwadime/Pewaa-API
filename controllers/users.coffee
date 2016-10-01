BaseController  = require "#{__dirname}/base"
sql             = require 'sql'
async           = require 'async'
User            = require "#{__dirname}/../models/user"
SmsCode         = require "#{__dirname}/../models/sms_code"
twilio          = require "#{__dirname}/../config/twilio"
client          = require('twilio')(twilio.ACCOUNT_SID, twilio.AUTH_TOKEN)

class UsersController extends BaseController

  user: sql.define
    name: 'users'
    columns: (new User).columns()

  smscode: sql.define
    name: 'sms_codes'
    columns: (new SmsCode).columns()

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
        statementVerifyCode = (@smscode.insert {user_id:user.id, code: code})
        t.query statementVerifyCode, ()->
          t.commit user

    t.on 'begin', start
    t.on 'error', (err)->
      error =
        'success' : false,
        'message' : 'Sorry! Error occurred.',
      callback error
    t.on 'commit', (user)->
      client.sendMessage {
        to: user.phone
        from: '+12132925019'
        body: "Hello, Welcome to PEWAA. Your Verification code is #{code}"
      }, (err, responseData) ->
        # this function is executed when a response is received from Twilio
        if !err
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

  reCreateCode: (user, callback) ->
    statementDeleteCode = @smscode.delete()
                            .where(@smscode.user_id.equals(user.id))

    code = Math.floor(Math.random() * 999999 + 111111)
    statementVerifyCode = (@smscode.insert {user_id:user.id, code: code})

    t = @transaction()
    start = ->
      async.eachSeries [statementDeleteCode, statementVerifyCode],
        (s, cb)->
          t.query s, ()->
            cb()
        , ->
          t.commit()

    t.on 'begin', start
    t.on 'error', callback
    t.on 'commit', ->
      client.sendMessage {
        to: user.phone
        from: '+12132925019'
        body: "Hello, Welcome to PEWAA. Your Verification code is #{code}"
      }, (err, responseData) ->
        # this function is executed when a response is received from Twilio
        if !err
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
      error =
        'success' : false,
        'message' : 'Sorry! Error occurred.'
      callback error

  getUserbyPhone: (phone, callback)->
    statement = @user.select(@user.star()).from(@user)
      .where(@user.phone.equals phone)
    @query statement, (err, rows) ->
      if err
        callback err
      else
        callback err, new User rows[0]

  resend: (phone, callback)->
    statement = @user.select(@user.star()).from(@user)
      .where(@user.phone.equals phone)
    smscode = @smscode
    resendQuery = @query
    @query statement, (err, rows) ->
      if err
        callback err
      else
        statementDeleteCode = smscode.delete()
                            .where(smscode.user_id.equals(rows[0].id))

        resendQuery statementDeleteCode, (err) ->
          if err
            callback err
          else
            code = Math.floor(Math.random() * 999999 + 111111)
            statementVerifyCode = (smscode.insert {user_id:rows[0].id, code: code})

            resendQuery statementVerifyCode, (err, rows) ->
              if err
                error =
                  'success' : false,
                  'message' : 'Sorry! Error occurred.'
                callback error
              else
                client.sendMessage {
                  to: phone
                  from: '+12132925019'
                  body: "Hello, Welcome to PEWAA. Your Verification code is #{code}"
                }, (err, responseData) ->
                  if !err
                    result =
                      'success' : true,
                      'message' : 'SMS request is sent! You will be receiving it shortly.'

                    callback null, result
                  else
                    error =
                      'success' : false,
                      'message' : 'Sorry! Error occurred.'
                    callback error

  smscodeSql: (code)->
    statement = @smscode
              .select @smscode.star(), @user.apikey
              .where(@smscode.code.equals code)
              .from(
                @smscode
                  .join @user
                  .on @smscode.user_id.equals @user.id
              )

  verify: (code, callback)->

    userTable = @user
    smsTable = @smscode

    statement = @smscodeSql code
    updateQuery = @query
    @query statement, (err, rows)->
      if err
        callback err
      else
        console.info "user to verify", rows[0]
        # start = =>
        updateUser = (userTable.update {is_activated:true})
                          .where userTable.id.equals rows[0].user_id
        updateQuery updateUser, (err)->
          if err
            result =
              'success' : false,
              'message' : 'Failed to activate your account try again or resend sms to get new code.',
              'userID'  : null,
              'token'   : null
            callback result
          else
            verifyCode = (smsTable.update {status:true})
                          .where smsTable.id.equals rows[0].id
            updateQuery verifyCode, (err)->
            if err
              result =
                'success' : false,
                'message' : 'Failed to activate your account try again or resend sms to get new code.',
                'userID'  : null,
                'token'   : null
              callback result
            else
              result =
                'success' : true,
                'message' : 'Your account has been created successfully.',
                'userID'  : rows[0].user_id,
                'token'   : rows[0].apikey

              callback null, result

module.exports = UsersController.get()
