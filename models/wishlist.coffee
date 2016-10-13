BaseModel = require './base'
_ = require 'underscore'

class Wishlist extends BaseModel
  constructor: (props) ->
    super props
    @required = ['name','description', 'avatar']
    @public   = ['name', 'description', 'avatar', 'created_on', 'updated_on']

module.exports = Wishlist
