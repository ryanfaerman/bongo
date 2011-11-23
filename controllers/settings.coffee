_ = require 'underscore'
mongoose = require 'mongoose'
config = require '../config'

mongoose.connect "mongodb://#{config.db.host}/#{config.db.db}"

ConfigModel = require '../models/config'
EpisodeModel = require '../models/episode'

module.exports = (app) ->
	app.configure ->
		ConfigModel.findOne {}, (err, config) ->
			unless config
				config = new ConfigModel
				config.queue.days = ['tuesday']
				config.queue.times = ['afternoon']
				config.save()
			
			app.set 'config', config
	

	app.get '/admin/settings', (req, res) ->
		ConfigModel.findOne {domain: req.headers.host}, (err, config) ->
			unless config
				config = new ConfigModel
				config.domain = req.headers.host
				config.queue.days = ['tuesday']
				config.queue.times = ['afternoon']
				config.save()
			
			res.render 'admin/settings', layout: 'admin/layout', locals: config
		
	
	app.put '/admin/settings', (req, res) ->
		res.redirect '/admin/settings'
	
	# Queue Manager Routes
	app.get '/admin/queue', (req, res) ->
		queueSettings = app.set('config').queue

		EpisodeModel.find({release: 'queue'}).sort('published', 'ascending').execFind (err, docs) ->
			_.each queueSettings.days, (e) ->
				queueSettings[e] = yes
			
			_.each queueSettings.times, (e) ->
				queueSettings[e] = yes

			queueSettings[queueSettings.recurrence] = yes

			locals = 
				next_up: if docs.length > 0 then docs[0]
				episodes: if docs.length > 1 then _.rest(docs)
				has_episodes: docs.length
				settings: queueSettings
			
			res.render 'admin/queue', layout: 'admin/layout', locals: locals

	app.put '/admin/queue', (req, res) ->
		
		ConfigModel.findOne {}, (err, config) ->
			config.queue.recurrence	= req.body.recurrence
			config.queue.days		= _.keys req.body.days
			config.queue.times		= _.keys req.body.times
			config.queue.enabled	= if req.body.enabled is 'true' then yes else no
			config.save()

			app.set 'config', config

		req.flash 'success', "Your queue settings were saved"
		res.redirect 'back'

	
	