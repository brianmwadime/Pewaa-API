oauthServer = require('oauth2-server')
oauth = new oauthServer(model: require("#{__dirname}/../../models/session"))
module.exports = oauth