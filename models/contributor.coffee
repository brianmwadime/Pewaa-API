BaseModel = require './base'
_ = require 'underscore'

class Contributor extends BaseModel
  constructor: (props) ->
    super props
    @required = ['user_id', 'wishlist_id', 'permissions', 'is_deleted']
    @public = _.clone @required

    if !@permissions
      @permissions = "CONTRIBUTOR"

    if !@is_deleted
      @is_deleted = false

module.exports = Contributor
