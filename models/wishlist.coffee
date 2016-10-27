BaseModel = require './base'
_ = require 'underscore'

class Wishlist extends BaseModel
  constructor: (props) ->
    super props
    @required = ['name','description', 'recipient', 'category']
    @public   = _.clone @required , 'avatar', 'created_on', 'updated_on'


    if !@avatar
      @avatar = null

module.exports = Wishlist
