bcrypt = require 'bcrypt'

module.exports = (app) ->

	# register
	app.get '/register', (req, res) ->
		res.render 'register'
	
	# login
	app.get '/login', (req, res) ->
		res.render 'register'
	
	# forgot password
	app.get '/login/forgot', (req, res) ->
		req.flash 'info', "Module Routes Work!"
		res.redirect '/'
	
	# logout
	app.get '/logout', (req, res) ->
		req.flash 'info', "Module Routes Work!"
		res.redirect '/'

	## admin routes

	# account
	app.get '/admin/account', (req, res) ->
		req.flash 'info', "Module Routes Work!"
		res.redirect '/'
	
	# edit account
	app.get '/admin/account/edit', (req, res) ->
		req.flash 'info', "Module Routes Work!"
		res.redirect '/'
	
	# delete account
	app.get '/admin/account/delete', (req, res) ->
		req.flash 'info', "Module Routes Work!"
		res.redirect '/'
	
	# create account
	app.get '/admin/account/create', (req, res) ->
		req.flash 'info', "Module Routes Work!"
		res.redirect '/'