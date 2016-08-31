uuid = require 'uuid'

# default configuration
process.env.API_VERSION = 1
process.env.ENDPOINT = ''
process.env.SESSION_SECRET_KEY = uuid.v4()