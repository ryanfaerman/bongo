_ = require 'underscore'
mongoose = require 'mongoose'
url = require 'url'
http = require 'http'
form = require 'connect-form'
fs = require 'fs'
events = require 'events'
mongo = require 'mongodb'

config = require '../config'

mongoose.connect "mongodb://#{config.db.host}/#{config.db.db}"

server = new mongo.Server config.db.host, 27017, auto_reconnect: true
db = new mongo.Db config.db.db, server

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
			console.log doc
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
					
					db.open (err, db) ->
						unless err
							gs = new mongo.GridStore db, files.audio.name, 'w', content_type: file.type
							gs.writeFile files.audio.path, (err, gs2) ->
								console.log gs2
								episode.processed = true
								episode.file = gs._id
								console.log files.audio
								#episode.file = files.audio.filename.replace(/\s+/g,'-')
								episode.size = files.audio.size
								episode.type = files.audio.type
								#episode.processed = true
								episode.save()
					

					


				
				req.flash 'success', "The episode \"#{episode.title}\" is processing."
				res.redirect '/admin'
	
	# test upload gridfs
	app.get '/upload', (req, res) ->
		res.render 'admin/upload', layout: 'bare-layout'

	app.post '/upload', (req, res) ->
		


		req.form.on 'progress', (bytesReceived, bytesExpected) ->
			percent = (bytesReceived / bytesExpected) * 100 or 0
			console.log "Uploading: #{percent}%"
		
		req.form.complete (err, fields, files) ->
			unless err
				file = files.audio
				console.log file

				db.open (err, db) ->
					unless err
						console.log file.name
						gs = new mongo.GridStore db, file.name, 'w', content_type: file.type
						gs.writeFile file.path, (err, gs2) ->
							console.log gs2
							db.close ->
								console.log 'closed'
							res.redirect "/grid/#{gs2._id}"
	
	app.get '/grid/:_id', (req, res) ->
		db.open (err, db) ->
			unless err
				_id = db.bson_serializer.ObjectID.createFromHexString req.params._id

				gs = new mongo.GridStore db, _id, 'r'
				gs.open (err, gs) ->
					gs.readBuffer (err, data) ->
						#console.log data
						console.log gs

						res.header 'Content-Disposition', "filename=#{gs.filename}"
						res.contentType gs.contentType
						#res.send data
						gs.close (a) ->
							console.log 'closed'
							db.close()


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

