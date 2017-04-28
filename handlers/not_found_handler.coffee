handler = (req, res, next) ->
  es = "#{req.path} was not found"
  res.status(404).send(error: es)
module.exports = handler
