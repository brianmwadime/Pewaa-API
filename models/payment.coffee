BaseModel = require './base'
_ = require 'underscore'

class Payment extends BaseModel
  constructor: (props) ->
    super props
    @required = ['amount', 'reference', 'wishlist_item_id', 'status', 'user_id', 'description']
    @public = _.clone @required, 'created_on', 'updated_on'

module.exports = Payment