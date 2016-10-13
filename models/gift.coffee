BaseModel = require './base'
_ = require 'underscore'

class Gift extends BaseModel
  constructor: (props) ->
    super props
    @required = ['name', 'price', 'wishlist_id', 'description', 'avatar', 'code']
    @public = _.clone @required, 'created_on', 'updated_on'

module.exports = Gift
