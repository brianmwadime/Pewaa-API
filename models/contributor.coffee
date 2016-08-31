BaseModel = require './base'
_ = require 'underscore'

class Contributor extends BaseModel
  constructor: (props) ->
    super props
    @required = ['user_id', 'wishlist_id']
    @public = _.clone @required, 'permissions'

module.exports = Contributor