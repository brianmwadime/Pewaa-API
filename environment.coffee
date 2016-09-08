'use strict'
fs              = require('fs')
yaml            = require('js-yaml')
uuid            = require('node-uuid')
yamlConfigFile  = 'app.yaml'

# default configuration
process.env.API_VERSION = 1
process.env.ENDPOINT = 'https://safaricom.co.ke/mpesa_online/lnmo_checkout_server.php?wsdl';
process.env.SESSION_SECRET_KEY = uuid.v4()
process.env.PAYBILL_NUMBER = '000000'
process.env.PASSKEY = 'a8eac82d7ac1461ba0348b0cb24d3f8140d3afb9be864e56a10d7e8026eaed66'

# if an env has not been provided, default to development
if !('NODE_ENV' of process.env)
  process.env.NODE_ENV = 'development'