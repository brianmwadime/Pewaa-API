'use strict'
fs              = require('fs')
yaml            = require('js-yaml')
uuid            = require('node-uuid')
yamlConfigFile  = 'app.yaml'

# default configuration
process.env.API_VERSION = 1
process.env.ENDPOINT = 'https://safaricom.co.ke/mpesa_online/lnmo_checkout_server.php?wsdl';
process.env.SESSION_SECRET_KEY = uuid.v4()
process.env.PAYBILL_NUMBER = '902500'
process.env.PASSKEY = '49e99cf128400555c760436fb4211890d53a4df633f0c2c80540cab2033b6d00'
process.env.GCM_KEY = "AIzaSyA6aHF1DOgiopy7KauoaxVHj0N29-ITcjo"

# if an env has not been provided, default to development
if !('NODE_ENV' of process.env)
  process.env.NODE_ENV = 'development'
