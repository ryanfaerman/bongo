_ = require 'underscore'
mongoose = require 'mongoose'
config = require '../config'

mongoose.connect "mongodb://#{config.db.host}/#{config.db.db}"

ConfigModel = require '../models/config'

module.exports = (app) ->
	app.configure ->
		ConfigModel.findOne {}, (err, config) ->
			unless config
				console.log "nope"
				config = new ConfigModel
				config.save()
			
			app.set 'config', config
			console.log 'configuring it out'
	

	app.get '/admin/settings', (req, res) ->
		res.render 'admin/settings', layout: 'admin/layout'
	
	app.put '/admin/settings', (req, res) ->
		res.redirect '/admin/settings'
	
			