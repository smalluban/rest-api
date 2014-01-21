module.exports =
  url: '/users'

  schema: 
    email: 'string'
  
  initSchema: ->
    @plugin require('passport-local-mongoose'), usernameField: 'email'