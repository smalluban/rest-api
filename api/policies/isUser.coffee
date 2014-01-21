module.exports = (req, res, next)->
  if req.isAuthenticated()
    return next()
  res.send 403, "Access forbidden"