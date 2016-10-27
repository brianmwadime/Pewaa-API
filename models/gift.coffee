BaseModel = require './base'
_ = require 'underscore'

class Gift extends BaseModel
  constructor: (props) ->
    super props
    @required = ['name', 'price', 'wishlist_id', 'description', 'avatar', 'code', 'user_id']
    @public = _.clone @required, 'created_on', 'updated_on'

    if !@code
      @code = null

    if !@avatar
      @avatar = null

    if !@user_id
      @user_id = null

module.exports = Gift
