BaseModel = require './base'
_ = require 'underscore'

class Payment extends BaseModel
  constructor: (props) ->
    super props
    @required = ['amount', 'price', 'reference', 'wishlist_item_id', 'user_id']
    @public = _.clone @required, 'description', 'status', 'user_id', 'created_on', 'updated_on'

module.exports = Payment