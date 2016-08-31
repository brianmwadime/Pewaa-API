oauthServer = require('oauth2-server')
Request = oauthServer.Request
Response = oauthServer.Response

oauth = require("#{__dirname}/oauth")

module.exports = (options) ->
  #`var options`
  options = options or {}
  (req, res, next) ->
    request = new Request(
      headers: authorization: req.headers.authorization
      method: req.method
      query: req.query
      body: req.body)
    response = new Response(res)
    oauth.authenticate(request, response, options).then((token) ->
      # Request is authorized.
      req.user = token
      next()
      return
    ).catch (err) ->
      # Request is not authorized.
      res.status(err.code or 500).json err
      return
    return