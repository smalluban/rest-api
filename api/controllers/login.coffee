passport = require 'passport'

module.exports = 

  "post login": (req, res)->
    passport.authenticate('local', (err, user, info)->
      
      if err or !user
        return res.send 403, 'login failed'

      req.logIn user, (err)->
        if err then res.send(err)
        res.send(req.user)

    )(req, res)

  "post logout": (req, res)->
    req.logout()
    res.send('logout successful')