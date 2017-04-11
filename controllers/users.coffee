BaseController  = require "#{__dirname}/base"
sql             = require 'sql'
async           = require('async-if-else')(require('async'))
User            = require "#{__dirname}/../models/user"
Payment         = require "#{__dirname}/../models/payment"
SmsCode         = require "#{__dirname}/../models/sms_code"
twilio          = require "#{__dirname}/../config/twilio"
client          = require('twilio')(twilio.ACCOUNT_SID, twilio.AUTH_TOKEN)

class UsersController extends BaseController

  user: sql.define
    name: 'users'
    columns: (new User).columns()

  payment: sql.define
    name: 'payments'
    columns: (new Payment).columns()

  smscode: sql.define
    name: 'sms_codes'
    columns: (new SmsCode).columns()

  bind: (fn, scope) ->
    ->
      fn.apply scope, arguments

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
        userRecord =
          'id': rows[0].id
          'Linked': if rows[0].is_activated then true else false
          'status': rows[0].phone
          'status_date': rows[0].created_on
          'phone': rows[0].phone
          'username': rows[0].username
          'name': rows[0].name
          'image': rows[0].avatar
        callback err, userRecord

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
    bind = @bind
    self = @
    code = Math.floor(Math.random() * 999999 + 111111)
    user = null
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
        body: "Hello, Welcome to PEWAA. Your verification code is : #{code}"
      }, (err, responseData) ->
        # this function is executed when a response is received from Twilio
        if !err
          result =
            'success'         : true,
            'message'         : 'SMS verification request initiated! You will be receiving it shortly.'
            'mobile'          : user.phone,
            'smsVerification' : true,
            'code'            : code

          callback null, result
        else
          error =
            'success' : false,
            'message' : 'Sorry! Error occurred.'

          callback error

    t.on 'rollback', ->
      statement = self.user.select(self.user.star())
                  .where(self.user.phone.equals(userParam.phone)).limit(1)
      self.query statement, (err, rows) ->
        if err or rows.length isnt 1
          error =
            'success' : false,
            'message' : 'Could not create account. Please contact Administrator.'
          callback error
        else
          self.reCreateCode rows[0], callback

  changeName: (params, callback) ->
    statement = (@user.update {username:params.name})
                  .where @user.id.equals params.userId
    @query statement, (err)->
      if err
        error =
          'success' : false,
          'message' : 'Failed to update profile image.'

        callback error
      else
        done =
          'success' : true,
          'message' : 'Profile image updated successfully.'

        callback null, done

  createPayment: (params, callback) ->

    statement = @payment.insert(params.requiredObject()).returning '*'
    @query statement, (err)->
      if err
        error =
          'success' : false,
          'message' : 'Failed to create payment.',
          'error' : err

        callback error
      else
        done =
          'success' : true,
          'message' : 'Payment created successfully.'

        callback null, done

  updatePayment: (params, callback) ->
    statement = (@payment.update {status:params.status})
                  .where @payment.reference.equals params.trx_id
    @query statement, (err)->
      if err
        error =
          'success' : false,
          'message' : 'Failed to update payment.'

        callback error
      else
        done =
          'success' : true,
          'message' : 'Payment updated successfully.'

        callback null, done
  
  updateName: (params, callback) ->
    statement = (@user.update {name:params.name})
                          .where @user.id.equals params.userId
    @query statement, (err) ->
      if err
        error =
          'success' : false,
          'message' : 'Failed to update profile.'

        callback error
      else
        done =
          'success' : true,
          'message' : 'Profile updated successfully.'

        callback null, done

  saveAvatar: (params, callback) ->
    statement = (@user.update {avatar:params.avatar})
                  .where @user.id.equals params.userId
    @query statement, (err)->
      if err
        error =
          'success' : false,
          'message' : 'Failed to update profile image.'

        callback error
      else
        done =
          'success' : true,
          'message' : 'Profile image updated successfully.'

        callback null, done

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
        body: "Hello, Welcome to PEWAA! Your verification code is : #{code}"
      }, (err, responseData) ->
        if !err
          result =
            'success'         : true,
            'message'         : 'SMS verification request initiated! You will be receiving it shortly.'
            'mobile'          : user.phone,
            'smsVerification' : true,
            'code'            : code

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
    self = @
    @query statement, (err, rows) ->
      if err
        callback err
      else
        statementDeleteCode = self.smscode.delete()
                            .where(self.smscode.user_id.equals(rows[0].id))

        self.query statementDeleteCode, (err) ->
          if err
            callback err
          else
            code = Math.floor(Math.random() * 999999 + 111111)
            statementVerifyCode = (self.smscode.insert {user_id:rows[0].id, code: code})

            self.query statementVerifyCode, (err, rows) ->
              if err
                error =
                  'success' : false,
                  'message' : 'Sorry! Error occurred.'
                callback error
              else
                client.sendMessage {
                  to: phone
                  from: '+12132925019'
                  body: "Hello, Welcome to PEWAA! Your verification code is : #{code}"
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
              .select @smscode.star(), @user.apikey, @user.phone
              .where(@smscode.code.equals code)
              .from(
                @smscode
                  .join @user
                  .on @smscode.user_id.equals @user.id
              )

  verify: (code, callback)->
    self = @
    statement = @smscodeSql code
    @query statement, (err, rows)->
      if err
        callback err
      else
        updateUser = (self.user.update {is_activated:true})
                          .where self.user.id.equals rows[0].user_id
        self.query updateUser, (err)->
          if err
            result =
              'success' : false,
              'message' : 'Failed to activate your account try again or resend sms to get new code.',
              'userID'  : null,
              'token'   : null
            callback result
          else
            verifyCode = (self.smscode.update {status:true})
                          .where self.smscode.id.equals rows[0].id
            self.query verifyCode, (err)->
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
                'mobile'  : rows[0].phone,
                'token'   : rows[0].apikey

              callback null, result

  getUserByToken:(token, callback) ->
    statement = @user.select(@user.id)
                  .where(@user.apikey.equals(token)).limit(1)
    @query statement, (err, rows) ->
      if err or rows.length isnt 1
        callback "#{token} not found"
      else
        callback null, rows[0].id

  exists: (phone, callback) ->
    statement = @user.select(@user.id)
                  .where(@user.phone.equals(phone)).limit(1)
    @query statement, (err, rows) ->
      if err or rows.length isnt 1
        callback "#{phone} not found"
      else
        callback null, rows[0].id # yes

  comparePhoneNumbers: (phoneNumbers, callback) ->
    results = []
    self = @
    async.each phoneNumbers.contactsModelList, ((contact, callback) ->
      # Call an asynchronous function, often a save() to DB
      # console.info contact
      statement = self.user.select(self.user.star())
                    .where(self.user.phone.equals(contact.phone), self.user.is_activated.equals(true))
                    .limit(1)

      self.query statement, (err, rows) ->
        if err or rows.length isnt 1
          matched =
            'id': contact.contactID
            'contactID': contact.contactID
            'Linked': false
            'Activate': false
            'Exist': true
            'status': contact.phone
            'phone': contact.phone
            'username': contact.username
            'image': contact.image

          results.push matched
        else
          matched =
            'id': rows[0].id
            'contactID': contact.contactID
            'Linked': true
            'Activate': true
            'Exist': true
            'status': contact.phone
            'phone': contact.phone
            'username': rows[0].username
            'avatar': rows[0].avatar
            'image': rows[0].avatar

          results.push matched

        callback null, results

    ), (err) ->
      if err
        callback err
      else
        callback null, results

  deleteAccount: (phone, callback) ->
    deleteAccount = @user.delete().
                      where(@user.phone.equals(phone))
    @query deleteAccount, (err) ->
      if err
        result =
          'success' : false
          'message' : "Could not delete account. Please try again."
        callback result
      else
        result =
          'success' : true
          'message' : 'Your account is deleted successfully.'

        callback null, result

  prepareDeleteAccount: (phone, callback) ->
    async.waterfall [
      async.constant(phone)
      async.if((@bind @exists, @), (@bind @deleteAccount, @))
    ], (error, success) ->
      if error
        callback error
      else
        callback null, success

module.exports = UsersController.get()
