BaseModel = require './base'
_ = require 'underscore'

class PushCredential extends BaseModel
  constructor: (props) ->
    super props
    @required = ['platform', 'device_id', 'user_id']
    @public = _.clone @required

module.exports = PushCredential
