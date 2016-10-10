BaseModel = require './base'
_ = require 'underscore'
bcrypt = require 'bcrypt'

class User extends BaseModel
  constructor: (options) ->
    super options

    @required = ['phone', 'apikey', 'is_activated', 'avatar', 'description', 'email']
    @public   = ['created_on']
    @public   = _.without @required

    phonePattern = /// ^ #begin of line
      (0|\+?254)7([0-3|7])(\d){7}
      $ ///i

    @validator =
      phone: ()=>
        matched = @phone.match phonePattern
        matched isnt null

    if @phone
      @makeCredentials @phone

  makeCredentials: (phone) ->
    @apikey       = bcrypt.hashSync phone, bcrypt.genSaltSync(10)
    @is_activated = false
    @avatar       = null
    @description  = null
    @email        = null

module.exports = User
