BaseModel = require './base'
_ = require 'underscore'
bcrypt = require 'bcrypt'

class User extends BaseModel
  constructor: (options) ->
    super options

    @required = ['username', 'name', 'email', 'hash']
    @public = ['description', 'avatar', 'created_on']
    @public = _.without @required, 'required', 'hash', 'required', 'public'

    emailPattern = /// ^ #begin of line
      ([\w.-]+)         #one or more letters, numbers, _ . or -
      @                 #followed by an @ sign
      ([\w.-]+)         #then one or more letters, numbers, _ . or -
      \.                #followed by a period
      ([a-zA-Z.]{2,6})  #followed by 2 to 6 letters or periods
      $ ///i

    @validator =
      email: ()=>
        matched = @email.match emailPattern
        matched isnt null

    if @password
      @makeCredentials @password
      delete @password

  makeCredentials: (password) ->
    @hash = bcrypt.hashSync password, bcrypt.genSaltSync(10)

module.exports = User