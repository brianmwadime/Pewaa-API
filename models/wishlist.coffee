BaseModel = require './base'
_ = require 'underscore'

class Wishlist extends BaseModel
  constructor: (props) ->
    super props
    @required = ['name','description', 'avatar', 'recipient', 'category']
    @public   = ['name', 'description', 'avatar', 'recipient', 'category', 'created_on', 'updated_on']


    if !@avatar
      @avatar = null

module.exports = Wishlist
