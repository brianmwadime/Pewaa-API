BaseModel = require './base'
_ = require 'underscore'

class Gift extends BaseModel
  constructor: (props) ->
    super props
    @required = ['name', 'price', 'wishlist_id', 'description', 'user_id', 'avatar', 'code', 'is_deleted', 'cashout_status']
    @public = _.clone @required, 'created_on', 'updated_on'

    if !@code
      @code = null

    if !@avatar
      @avatar = null

    if !@is_deleted
      @is_deleted = false

    if !@description
      @description = null

    if !@cashout_status
      @cashout_status = null

module.exports = Gift
