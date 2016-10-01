BaseModel = require './base'
_ = require 'underscore'

class SmsCode extends BaseModel
  constructor: (options) ->
    super options

    @required = ['code', 'user_id', 'status']
    @public = ['status','code', 'user_id']
    @public = _.without @required

module.exports = SmsCode