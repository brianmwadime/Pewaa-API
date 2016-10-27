BaseModel = require './base'
_ = require 'underscore'

class Gift extends BaseModel
  constructor: (props) ->
    super props
    @required = ['name', 'price', 'wishlist_id', 'description', 'user_id', 'avatar', 'code']
    @public = _.clone @required, 'created_on', 'updated_on'

    if !@code
      @code = null

    if !@avatar
      @avatar = null

module.exports = Gift
