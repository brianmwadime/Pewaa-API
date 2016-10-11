BaseModel = require './base'
_ = require 'underscore'

class Wishlist extends BaseModel
  constructor: (props) ->
    super props
    @required = ['name']
    @public   = ['name', 'description', 'avatar', 'created_on', 'updated_on']

module.exports = Wishlist
