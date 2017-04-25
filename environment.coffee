'use strict'
fs              = require('fs')
yaml            = require('js-yaml')
uuid            = require('node-uuid')
yamlConfigFile  = 'app.yaml'

# default configuration
process.env.API_VERSION = 1
process.env.ENDPOINT = 'https://safaricom.co.ke/mpesa_online/lnmo_checkout_server.php?wsdl'
process.env.MERCHANT_ENDPOINT = 'http://api.pewaa.com/v1/mpesa/payment'
process.env.SESSION_SECRET_KEY = uuid.v4()
process.env.PAYBILL_NUMBER='866069'
process.env.PASSKEY='aa0986a3784875583199c78a9db6c4c0e76f02b4611bc90dc3c6359ae3b2f209'
process.env.MERCHANT_ENDPOINT='http://api.pewaa.com/v1/payments/complete'
process.env.ANDROID_PACKAGE='com.fortunekidew.pewaad'
process.env.GCM_KEY='AIzaSyA6aHF1DOgiopy7KauoaxVHj0N29-ITcjo'
process.env.API_DOMAIN='api.pewaa.com'

# if an env has not been provided, default to development
if !('NODE_ENV' of process.env)
  process.env.NODE_ENV = 'development'


if process.env.NODE_ENV == 'development'
  requiredEnvVariables = [
    'PAYBILL_NUMBER'
    'PASSKEY'
    'MERCHANT_ENDPOINT'
  ]
  envKeys = Object.keys(process.env)
  requiredEnvVariablesExist = requiredEnvVariables.every (variable) -> envKeys.indexOf(variable) != -1

  #  if the requiredEnvVariables have not been added
  #  maybe by GAE or Heroku ENV settings
  if !requiredEnvVariablesExist
    if fs.existsSync(yamlConfigFile)
      #  Get the rest of the config from app.yaml config file
      config = yaml.safeLoad(fs.readFileSync(yamlConfigFile, 'utf8'))
      Object.keys(config.env_variables).forEach (key) ->
        process.env[key] = config.env_variables[key]
      
    else
      throw new Error("
      Missing app.yaml config file used while in development mode
      It should have contents similar to the example below:
      app.yaml
      -------------------------
      env_variables:
        PAYBILL_NUMBER: '000000'
        PASSKEY: 'a8eac82d7ac1461ba0348b0cb24d3f8140d3afb9be864e56a10d7e8026eaed66'
        MERCHANT_ENDPOINT: 'http://merchant-endpoint.com/mpesa/payment/complete'
      # Everything below from this point onwards are only relevant
      # if you are looking to deploy Project Mulla to Google App Engine.
      runtime: nodejs
      vm: true
      skip_files:
        - ^(.*/)?.*/node_modules/.*$
      -------------------------
    ")

