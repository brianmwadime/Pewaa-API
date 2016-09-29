BaseModel = require './base'
crypto = require 'crypto'
uuid = require 'uuid'
_ = require 'underscore'

class SmsCode extends BaseModel
  constructor: (options) ->
    super options

    @required = ['code', 'user_id']

module.exports = SmsCode