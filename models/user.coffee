BaseModel = require './base'
_ = require 'underscore'
bcrypt = require 'bcrypt'

class User extends BaseModel
  constructor: (options) ->
    super options

    @required = ['phone']
    @public = ['description', 'avatar', 'created_on']
    @public = _.without @required, 'required', 'public'

    phonePattern = /// ^ #begin of line
      (\+254|^){1}[ ]?[7]{1}([0-3]{1}[0-9]{1})[ ]?[0-9]{3}[ ]?[0-9]{3}\z
      $ ///i

    # @validator =
    #   phone: ()=>
    #     matched = @phone.match phonePattern
    #     matched isnt null

    if @phone
      @makeCredentials @phone

  makeCredentials: (phone) ->
    @apikey = bcrypt.hashSync phone, bcrypt.genSaltSync(10)

module.exports = User