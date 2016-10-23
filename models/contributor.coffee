BaseModel = require './base'
_ = require 'underscore'

class Contributor extends BaseModel
  constructor: (props) ->
    super props
    @required = ['user_id', 'wishlist_id', 'permissions']
    @public = _.clone @required

    if !@permissions
      @permissions = "CONTRIBUTOR"

module.exports = Contributor
