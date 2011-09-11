express	 = require 'express'
mongoose = require 'mongoose'
mongooseAuth = require 'mongoose-auth'
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
		res.render 'admin/manager', layout: 'admin/layout', locals: episodes: docs, flash: req.flash(), has_episodes: docs.length

app.get '/admin/publish', (req, res) ->
	res.render 'admin/publish', layout: 'admin/layout'

app.post '/admin/publish', (req, res, next) -> 
	req.form.complete (err, fields, files) ->
		if err
			next(err)
		else
			episode = _.extend new models.Episode, fields
			
			episode.save()
						
			if fields.use_remote is 'yes'
				host = url.parse(fields.remote_file).hostname
				episode.file = url.parse(fields.remote_file).pathname.split("/").pop()

				client = http.createClient 80, host

				request = client.request 'GET', fields.remote_file, host: host
				request.end()

				request.addListener 'response', (response) ->
					downloadfile = fs.createWriteStream "./public/uploads/#{episode.file}", flags: 'a'
					episode.size = response.headers['content-length']
					episode.type = response.headers['content-type']

					episode.save()

					response.addListener 'data', (chunk) ->
						downloadfile.write chunk, encoding='binary'	

					response.addListener 'end', () ->
						downloadfile.end()
						console.log "Finished downloading #{episode.file}"
						episode.processed = true
						episode.save()


			unless _.size(files) is 0
				console.log "Uploaded #{files.audio.filename} to #{files.audio.path}"
				fs.rename files.audio.path, "./public/uploads/#{files.audio.filename}"
				
				

				console.log files.audio
				episode.file = files.audio.filename
				episode.size = files.audio.size
				episode.type = files.audio.type
				episode.processed = true
				episode.save()

			req.form.on 'progress', (bytesReceived, bytesExpected) ->
				percent = (bytesReceived / bytesExpected) * 100 or 0
				console.log "Uploading: #{percent}%"
			
			req.flash 'success', "The episode \"#{episode.title}\" is processing."
			res.redirect '/admin'

app.get '/admin/episode/:_id', (req, res) ->
	models.Episode.findById req.params._id, (err, doc) ->
		res.render 'admin/publish', layout: 'admin/layout', locals: _.extend(doc, method: 'put')
		
app.post '/admin/episode/:_id', (req, res, next) -> 
	req.form.complete (err, fields, files) ->
		if err
			next(err)
		else
			models.Episode.findById req.params._id, (err, doc) ->
				
				episode = _.extend doc, fields
				
				episode.save()
						
				if fields.use_remote is 'yes'
					episode.processed = false
					episode.save()
					
					host = url.parse(fields.remote_file).hostname
					episode.file = url.parse(fields.remote_file).pathname.split("/").pop()

					client = http.createClient 80, host

					request = client.request 'GET', fields.remote_file, host: host
					request.end()

					request.addListener 'response', (response) ->
						downloadfile = fs.createWriteStream "./public/uploads/#{episode.file}", flags: 'a'
						episode.size = response.headers['content-length']
						episode.type = response.headers['content-type']

						episode.save()

						response.addListener 'data', (chunk) ->
							downloadfile.write chunk, encoding='binary'	

						response.addListener 'end', () ->
							downloadfile.end()
							console.log "Finished downloading #{episode.file}"
							episode.processed = true
							episode.save()


				unless _.size(files) is 0
					console.log "Uploaded #{files.audio.filename} to #{files.audio.path}"
					fs.rename files.audio.path, "./public/uploads/#{files.audio.filename}"
				
				

					console.log files.audio
					episode.file = files.audio.filename
					episode.size = files.audio.size
					episode.type = files.audio.type
					episode.processed = true
					episode.save()

				req.form.on 'progress', (bytesReceived, bytesExpected) ->
					percent = (bytesReceived / bytesExpected) * 100 or 0
					console.log "Uploading: #{percent}%"
			
				req.flash 'success', "The episode \"#{episode.title}\" is processing."
				res.redirect '/admin'

app.post '/admin/episode/delete', (req, res) ->
	episodes = []
	_.each req.body.episode, (i,e) ->
		episodes.push i
	res.render 'admin/confirm_delete', layout: 'admin/layout', locals: episodes: episodes
	
app.delete '/admin/episode/delete', (req, res) ->
		req.flash 'info', "You're episodes have been removed."
		res.redirect '/admin/manager'
		
		_.each req.body.episode, (i, e) ->
			models.Episode.remove _id: i, (r,d) ->
				console.log d
		


	

app.listen 3000
console.log "Express server listening on port #{app.address().port} in #{app.settings.env} mode"


