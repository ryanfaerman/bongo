_ = require 'underscore'
mongoose = require 'mongoose'
url = require 'url'
http = require 'http'
form = require 'connect-form'
fs = require 'fs'
events = require 'events'

config = require '../config'

mongoose.connect "mongodb://#{config.db.host}/#{config.db.db}"

EpisodeModel = require '../models/episode'

module.exports = (app) ->

	# list
	app.get '/', (req, res) ->
		query =
			release: 'published'
			published: 
				$lte: Date.now()
		EpisodeModel.find(query).limit(5).sort('published', 'descending').execFind (err, docs) ->
			res.render 'list', locals: episodes: docs
	
	# view
	app.get '/episode/:id', (req, res) ->
		EpisodeModel.findById req.params.id, (err, doc) ->
			res.render 'episode', locals: doc

	# feed
	app.get '/feed', (req, res) ->
		query =
			release: 'published'
			published: 
				$lte: Date.now()
		EpisodeModel.find(query).limit(5).sort('published', 'descending').execFind (err, docs) ->
			res.render 'rss', layout: null, locals: episodes: docs

	## admin routes

	# list
	app.get '/admin', (req, res) -> 
		res.redirect '/admin/manager'

	app.get '/admin/manager', (req, res) ->
		EpisodeModel.count {}, (err, count) ->
			EpisodeModel.find().sort('published', 'descending').execFind (err, docs) ->
				locals = 
					episodes: docs
					has_episodes: docs.length
				
				res.render 'admin/manager', layout: 'admin/layout', locals: locals

	# publish
	app.get '/admin/publish', (req, res) ->
		res.render 'admin/publish', layout: 'admin/layout'

	app.post '/admin/publish', (req, res, next) -> 
		req.form.on 'progress', (bytesReceived, bytesExpected) ->
			percent = (bytesReceived / bytesExpected) * 100 or 0
			console.log "Uploading: #{percent}%"
		
		req.form.complete (err, fields, files) ->
			if err
				next(err)
			else
				episode = _.extend new EpisodeModel, fields
				
				if fields.release is 'date'
					episode.published = new Date require('./strtotime').parse(fields.release_date)
					console.log episode.published
					episode.release = "published"
				
				
				episode.save()
							
				if fields.use_remote is 'yes'
					host = url.parse(fields.remote_file).hostname
					episode.file = url.parse(fields.remote_file).pathname.split("/").pop()

					client = http.createClient 80, host

					request = client.request 'GET', fields.remote_file, host: host
					request.end()

					request.addListener 'response', (response) ->
						downloadfile = fs.createWriteStream "./public/uploads/#{episode.file}".replace(/\s+/g, '-'), flags: 'a'
						episode.size = response.headers['content-length']
						episode.type = response.headers['content-type']
						episode.file = episode.file.replace(/\s+/g,'-')

						episode.save()

						response.addListener 'data', (chunk) ->
							downloadfile.write chunk, encoding='binary'	

						response.addListener 'end', () ->
							downloadfile.end()
							console.log "Finished downloading #{episode.file}"
							episode.processed = true
							episode.save()


				unless _.size(files) is 0
					target = files.audio.filename.replace /\s+/g, '-'
					console.log "Uploaded #{files.audio.filename} to #{files.audio.path}"
					
					fs.rename files.audio.path, "./public/uploads/#{target}"
					
					

					console.log files.audio
					episode.file = files.audio.filename.replace(/\s+/g,'-')
					episode.size = files.audio.size
					episode.type = files.audio.type
					episode.processed = true
					episode.save()


				
				req.flash 'success', "The episode \"#{episode.title}\" is processing."
				res.redirect '/admin'
	

	# edit
	app.get '/admin/episode/:_id', (req, res) ->
		EpisodeModel.findById req.params._id, (err, doc) ->
			res.render 'admin/publish', layout: 'admin/layout', locals: _.extend(doc, method: 'put')
			
	app.post '/admin/episode/:id', (req, res, next) -> 
		req.form.complete (err, fields, files) ->
			if err
				next(err)
			else
				EpisodeModel.findById req.params.id, (err, doc) ->
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


	# delete
	app.post '/admin/delete/episode', (req, res) ->
		episodes = []
		console.log req.body
		_.each req.body.episode, (i,e) ->
			episodes.push i
		res.render 'admin/confirm_delete', layout: 'admin/layout', locals: episodes: episodes

	app.delete '/admin/delete/episode', (req, res) ->
		req.flash 'info', "You're episodes have been removed."
		res.redirect '/admin/manager'

		_.each req.body.episode, (i, e) ->
			EpisodeModel.remove _id: i, (r,d) ->
				console.log d

