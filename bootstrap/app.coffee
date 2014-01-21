Config = require '../config'

express = require 'express'
restful = require 'node-restful'
mongoose = require('node-restful').mongoose
passport = require 'passport'

models = require('require-all')(dirname: process.cwd() + '/api/models', filter: /(.+)\.coffee$/)
controllers = require('require-all')(dirname: process.cwd() + '/api/controllers', filter: /(.+)\.coffee$/)
policies = require('require-all')(dirname: process.cwd() + '/api/policies', filter: /(.+)\.coffee$/)

# Connect to database
mongoose.connect "mongodb://#{Config.database.host}/#{Config.database.db}"

# Express settings
app = express()

app.use express.bodyParser()
app.use express.query()
app.use express.methodOverride()
app.use express.cookieParser()
app.use express.session(secret: Config.app.secret)

# Serving front app
app.use express.static(process.cwd() + Config.app.static) if Config.app.static

### LOAD MODELS ###

Models = {}

for modelName, model of models
  # Create schema
  schema = mongoose.Schema model.schema
  if typeof model.initSchema is 'function'
    model.initSchema.call schema

  # Set policies
  if model.policies isnt undefined
    if model.policies
      for type, func of model.policies
        if typeof func is 'string'
          app[type] Config.models.prefix + model.url, policies[func]
        else if func instanceof Array
          for f in func
            app[type] Config.models.prefix + model.url, policies[f]
        else if typeof func is 'object'
          app[type] Config.models.prefix + model.url + func.url, policies[func.police]
  else if Config.models.police
    app.all Config.models.prefix + model.url, policies[Config.models.police]

  # Create resource
  Models[modelName] = resource = restful.model(modelName, schema)
  
  # Add default routes
  resource.methods(model.methods or ['get', 'post', 'put', 'delete'])
  
  # Add model routes
  if model.routes
    for name, func of model.routes
      [type, path] = name.split(' ')
      unless path
        path = type
        type = 'get'
      if detail = path.substr(0,1) is '@'
        path = path.substr(1)
      resource.route path + '.' + type, 
        detail: !detail,
        handler: func

  if typeof model.initResource is 'function'
    model.initResource.call resource

  # Register resource
  resource.register(app, Config.models.prefix + model.url)

### LOAD CONTROLLERS ###

for name, controller of controllers
  url = controller.url or ''
  delete controller.url

  for name, func of controller
    [type, path] = name.split(' ')
    unless path
      path = type
      type = 'all'

    app[type] url + '/' + path, func

### LINK PASSPORT ###

# Passport setup
passport.use(Models.User.createStrategy())
passport.serializeUser(Models.User.serializeUser())
passport.deserializeUser(Models.User.deserializeUser())

# Passport link
app.use passport.initialize()
app.use passport.session()


### START APP ###

port = process.env.PORT or 3000
app.listen port, -> console.log "Listening on #{port}\nPress CTRL-C to stop server."

