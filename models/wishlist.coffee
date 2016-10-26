BaseModel = require './base'
_ = require 'underscore'

class Wishlist extends BaseModel
  constructor: (props) ->
    super props
    @required = ['name','description', 'avatar', 'recipient']
    @public   = ['name', 'description', 'avatar', 'recipient', 'created_on', 'updated_on']


    if !@avatar
      @avatar = null

module.exports = Wishlist
