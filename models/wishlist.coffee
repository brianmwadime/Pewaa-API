BaseModel = require './base'
_ = require 'underscore'

class Wishlist extends BaseModel
  constructor: (props) ->
    super props
    @required = ['name', 'category','description', 'is_deleted', 'flagged', 'flagged_description']
    @public   = ['name', 'category','description', 'avatar', 'created_on', 'updated_on']

    if !@avatar
      @avatar = null

    if !@is_deleted
      @is_deleted = false
    
    if !@flagged
      @flagged = false

    if !@flagged_description
      @flagged_description = null

module.exports = Wishlist
