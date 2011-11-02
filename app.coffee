express	 = require 'express'
mongoose = require 'mongoose'

_ = require 'underscore'
form = require 'connect-form'
fs = require 'fs'
sys = require 'sys'
MongoStore = require('connect-mongo')
http = require 'http'
url = require 'url'
path = require 'path'
events = require 'events'

models = require './models'
config = require './config'
queueSettings = require './queue_settings'

mongoose.connect "mongodb://#{config.db.host}/#{config.db.db}"

cronTask = require './cron'

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
	#app.use app.router
	app.use express.static "#{__dirname}/public"
	
	app.use express.cookieParser()
	app.use express.session 
		secret: 'bingobongo'
		store: new MongoStore(db: config.db.db, host: config.db.host)
	

app.configure 'development', ->
	app.use express.errorHandler dumpExceptions: true, showStack: true

app.configure 'production', ->
	app.use express.errorHandler()

app.dynamicHelpers 
	flash: (req, res) ->
	  req.flash()
	site: (req, res) ->
		config.site
	feed: (req, res) ->
		config.feed


require('./controllers/auth')(app)		# Auth Routes
require('./controllers/episode')(app)	# Episode Routes

# Routes
app.get '/about', (req, res) ->
	res.render 'about'

app.get '/contact', (req, res) ->
	res.render 'contact'


# Admin Routes
app.get '/admin/queue', (req, res) ->
	models.Episode.find({release: 'queue'}).sort('published', 'ascending').execFind (err, docs) ->
		locals = 
			next_up: if docs.length > 0 then docs[0]
			episodes: if docs.length > 1 then _.rest(docs)
			has_episodes: docs.length
			settings: queueSettings
		
		res.render 'admin/queue', layout: 'admin/layout', locals: locals

app.put '/admin/queue', (req, res) ->
	queueSettings = req.body
	queueSettings.status = if req.body.status is 'active' then 'active' else false
	data = JSON.stringify queueSettings, null, 4
	
	fs.writeFile './queue_settings.js', "module.exports = #{data}"
	
	req.flash 'success', "Your queue settings were saved"
	res.redirect 'back'
	
	
app.get '/admin/account', (req, res) ->
	res.render 'admin/account', layout: 'admin/layout'	

app.get '/admin/pages', (req, res) ->
	res.render 'admin/pages', layout: 'admin/layout'




# Digustingly Generic Routes

app.get '/:url', (req, res) ->
	console.log req.params.url	

app.listen 3000
console.log "Express server listening on port #{app.address().port} in #{app.settings.env} mode"


