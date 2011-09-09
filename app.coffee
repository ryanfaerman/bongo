express	 = require 'express'
mongoose = require 'mongoose'
mongooseAuth = require 'mongoose-auth'
_ = require 'underscore'
form = require 'connect-form'
fs = require 'fs'
sys = require 'sys'
MongoStore = require('connect-mongo')

models = require './models'
config = require './config'

mongoose.connect "mongodb://#{config.db.host}/#{config.db.db}"
User = models.User


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
	app.use mongooseAuth.middleware()
	

app.configure 'development', ->
	app.use express.errorHandler dumpExceptions: true, showStack: true

app.configure 'production', ->
	app.use express.errorHandler()


# mongoose-auth dynamic view helpers
mongooseAuth.helpExpress app




# Routes

app.get '/', (req, res) ->
	models.Episode.find().limit(5).sort('published', 'descending').execFind (err, docs) ->
		res.render 'list', locals: episodes: docs

app.get '/episode/:id', (req, res) ->
	models.Episode.findById req.params.id, (err, doc) ->
		res.render 'episode', locals: doc

app.get '/episode/:id', (req, res) ->
	models.Page.findById req.params.id, (err, doc) ->
		res.render 'read', locals: doc


# Admin Routes

app.all '/admin*?', (req, res, next) ->
	unless req.loggedIn 
		res.redirect '/'
		req.flash 'info', 'Not logged in'
	else
		next()

app.get '/admin', (req, res) -> 
	res.redirect '/admin/manager'
	
app.get '/admin/manager', (req, res) ->
	models.Episode.find().sort('published', 'descending').execFind (err, docs) ->
		res.render 'admin/manager', layout: 'admin/layout', locals: episodes: docs

app.get '/admin/publish', (req, res) ->
	res.render 'admin/publish', layout: 'admin/layout'

app.post '/publish', (req, res, next) -> 
	req.form.complete (err, fields, files) ->
		if err
			next(err)
		else
			episode = _.extend new models.Episode, fields

			unless _.size(files) is 0
				console.log "Uploaded #{files.audio.filename} to #{files.audio.path}"
				fs.rename files.audio.path, "./public/audio/#{files.audio.filename}"

				console.log files.audio
				episode.file = files.audio.filename
				episode.size = files.audio.size
				episode.type = files.audio.type

			episode.save()
			console.log episode

			res.redirect 'back'

	req.form.on 'progress', (bytesReceived, bytesExpected) ->
		percent = (bytesReceived / bytesExpected) * 100 or 0
		console.log "Uploading: #{percent}%"


app.listen 3000
console.log "Express server listening on port #{app.address().port} in #{app.settings.env} mode"


