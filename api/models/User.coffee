module.exports =
  url: '/users'

  schema: 
    email: 'string'
  
  initSchema: ->
    @plugin require('passport-local-mongoose'), usernameField: 'email'

    # BUG-FIX passport-local-mongoose
    @statics.registerUser = @statics.register
    delete @statics.register