BaseModel = require './base'
_ = require 'underscore'

class Gift extends BaseModel
  constructor: (props) ->
    super props
    @required = ['name', 'price', 'wishlist_id', 'user_id', 'code', 'is_deleted', 'avatar', 'description']
    @public = _.clone @required, 'created_on', 'updated_on'

    if !@code
      @code = null

    if !@avatar
      @avatar = null

    if !@is_deleted
      @is_deleted = false

    if !@description
      @description = null

module.exports = Gift
