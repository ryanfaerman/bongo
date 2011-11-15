express	 = require 'express'
form = require 'connect-form'
MongoStore = require('connect-mongo')
config = require './config'

# Create the Express Server and active some middleware
app = module.exports = express.createServer(
	form keepExtensions: true 	
)

# Configuration
app.configure ->
	app.set 'views', "#{__dirname}/views"
	app.set 'view engine', 'mustache'
	app.register '.mustache', require 'stache'
	app.use express.bodyParser()
	app.use express.methodOverride()
	app.use express.static "#{__dirname}/public"
	
	app.use express.cookieParser()
	app.use express.session 
		secret: 'bingobongo'
		store: new MongoStore(db: config.db.db, host: config.db.host)
	
app.configure 'development', ->
	app.use express.errorHandler dumpExceptions: true, showStack: true

app.configure 'production', ->
	app.use express.errorHandler()

# The dynamic helpers give system-level variables to the views
# so each route doesn't need to mess with all that noise.
app.dynamicHelpers 
	flash: (req, res) ->
	  req.flash()
	site: (req, res) ->
		app.set('config').site
	feed: (req, res) ->
		app.set('config').feed

# Now we go ahead and get all our controllers rolling.
#
# Notice that settings comes first. The idea is the get
# the config for the site before everything else. It works
# *okay*, but another method that works better needs
# to be found.
require('./controllers/settings')(app)	# System Settings
require('./controllers/auth')(app)		# Auth Routes
require('./controllers/episode')(app)	# Episode Routes
require('./controllers/cron')(app)		# Queue Processor

# These just haven't been folded into controllers yet.
app.get '/about', (req, res) ->
	res.render 'about'
	


app.get '/contact', (req, res) ->
	res.render 'contact'

app.get '/admin/account', (req, res) ->
	res.render 'admin/account', layout: 'admin/layout'	

app.get '/admin/pages', (req, res) ->
	res.render 'admin/pages', layout: 'admin/layout'


# Finally, after everything else, start up the server.
app.listen 3000
console.log "Express server listening on port #{app.address().port} in #{app.settings.env} mode"


