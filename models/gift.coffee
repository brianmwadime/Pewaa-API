BaseModel = require './base'
_ = require 'underscore'

class Gift extends BaseModel
  constructor: (props) ->
    super props
    @required = ['name', 'price', 'wishlist_id']
    @public = _.clone @required, 'description', 'avatar', 'code', 'created_on', 'updated_on'

module.exports = Gift