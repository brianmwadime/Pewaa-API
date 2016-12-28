'use strict'
fs              = require('fs')
yaml            = require('js-yaml')
uuid            = require('node-uuid')
yamlConfigFile  = 'app.yaml'

# default configuration
process.env.API_VERSION = 1
process.env.ENDPOINT = 'https://safaricom.co.ke/mpesa_online/lnmo_checkout_server.php?wsdl'
process.env.MERCHANT_ENDPOINT = 'http://api.pewaa.com/v1/payments/complete'
process.env.SESSION_SECRET_KEY = uuid.v4()
process.env.PAYBILL_NUMBER = '866069'
process.env.ANDROID_PACKAGE = 'com.fortunekidew.pewaad'
process.env.PASSKEY = 'aa0986a3784875583199c78a9db6c4c0e76f02b4611bc90dc3c6359ae3b2f209'
process.env.GCM_KEY = 'AIzaSyA6aHF1DOgiopy7KauoaxVHj0N29-ITcjo'
process.env.API_DOMAIN = 'api.pewaa.com'

# if an env has not been provided, default to development
if !('NODE_ENV' of process.env)
  process.env.NODE_ENV = 'development'
