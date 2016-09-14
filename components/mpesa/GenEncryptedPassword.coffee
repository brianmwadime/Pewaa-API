'use strict'
# require("#{__dirname}/../../environment")
crypto = require 'crypto'

module.exports = class GenEncryptedPassword
  constructor: (@timeStamp) ->
    concatenatedString = [
        process.env.PAYBILL_NUMBER
        process.env.PASSKEY
        @timeStamp
    ].join('')
    hash = crypto.createHash 'sha256'
    @hashedPassword = hash.update(concatenatedString).digest 'hex' # or 'binary'
    @hashedPassword = new Buffer(@hashedPassword).toString 'base64'
    console.info 'hashedPassword ==> ', this.hashedPassword