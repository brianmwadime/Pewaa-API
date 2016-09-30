BaseModel = require './base'
_ = require 'underscore'
bcrypt = require 'bcrypt'

class User extends BaseModel
  constructor: (options) ->
    super options

    @required = ['phone', 'apikey', 'is_activated']
    @public = ['description', 'avatar', 'created_on', 'is_activated']
    @public = _.without @required, 'required', 'public', 'is_activated'

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
    @apikey = bcrypt.hashSync phone, bcrypt.genSaltSync(10)

module.exports = User