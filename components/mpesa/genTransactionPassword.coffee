'use strict'
moment                = require "moment"
GenEncryptedPassword  = require "#{__dirname}/GenEncryptedPassword"

genTransactionPassword = (req, res, next) ->
  req.timeStamp = moment().format "YYYYMMDDHHmmss"
  # In PHP => "YmdHis"
  req.encryptedPassword = new GenEncryptedPassword(req.timeStamp).hashedPassword
  # console.info 'encryptedPassword:', req.encryptedPassword
  next()
  # return

module.exports = genTransactionPassword