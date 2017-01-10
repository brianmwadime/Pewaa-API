BaseModel = require './base'
_ = require 'underscore'

class Wishlist extends BaseModel
  constructor: (props) ->
    super props
    @required = ['name','description', 'recipient', 'category', 'is_deleted']
    @public   = _.clone @required , 'avatar', 'created_on', 'updated_on'

    if !@avatar
      @avatar = null

    if !@is_deleted
      @is_deleted = false

    if !@recipient
      @recipient = null

module.exports = Wishlist
