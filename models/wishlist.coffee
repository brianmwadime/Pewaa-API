BaseModel = require './base'
_ = require 'underscore'

class Wishlist extends BaseModel
  constructor: (props) ->
    super props
    @required = ['name', 'category','description', 'recipient', 'is_deleted']
    @public   = _.clone @required , 'avatar', 'created_on', 'updated_on'

    if !@avatar
      @avatar = null

    if !@is_deleted
      @is_deleted = false

module.exports = Wishlist
