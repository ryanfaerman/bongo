bcrypt = require 'bcrypt'
_ = require 'underscore'
mongoose = require 'mongoose'

config = require '../config'

mongoose.connect "mongodb://#{config.db.host}/#{config.db.db}"

UserModel = require '../models/user'

module.exports = (app) ->

	# register
	app.get '/register', (req, res) ->
		# If open registration is disabled, the user is redirected
		# to /login, otherwise, don't mess with anything.
		unless app.set('config').site.open_registration
			req.flash 'info', 'Registration is disabled. If you have an account, log in.'
			res.redirect '/login'
		else
			res.render 'register', layout: 'bare-layout'
	
	app.post '/register', (req, res) ->
		console.log req.body

		user = _.extend new UserModel, req.body

		# bcrypt, bcrypt, bcrypt, bcrypt
		#
		# This helps keep passwords secure. Not because a podcast is
		# some incredibly sensitive information, but because
		# securing passwords is good practice **and**
		# because people often use the same passwords in
		# *other* places.
		bcrypt.gen_salt 10, (err, salt) ->
			bcrypt.encrypt req.body.password, salt, (err, hash) ->
				user.hash = hash
				user.save()
		
		req.flash 'success', "Registration Successful"
		res.redirect '/login'
	
	# login
	app.get '/login', (req, res) ->
		res.render 'login', layout: 'bare-layout'
	
	app.post '/login', (req, res) ->
		invalid = () ->
			req.flash 'danger', 'Invalid Username / Password Combination'
			res.render 'login', locals: req.body, layout: 'bare-layout'

		# Don't waste any cycles if the email and password 
		# weren't even submitted. While this maybe only save
		# a few cycles for the database - why waste time?
		#
		# Once the user is found, let him in. Otherwise, **GTFO**
		if req.body.email and req.body.password
			UserModel.findOne email: req.body.email, (err, doc) ->
				if doc
					console.log 'user found'
					bcrypt.compare req.body.password, doc.hash, (err, matched) ->
						if matched
							req.session.loggedIn = yes
							res.redirect '/admin'
						else
							invalid()
				else
					console.log 'invalid user'
					invalid()
		else
			invalid()
		
	
	# forgot password
	app.get '/login/forgot', (req, res) ->
		req.flash 'info', "Module Routes Work!"
		res.redirect '/'
	
	# logout
	app.get '/logout', (req, res) ->
		req.session.loggedIn = no
		req.flash 'info', "You've been signed out."
		res.redirect '/'

	## admin routes

	# admin auth check
	app.all '/admin*?', (req, res, next) ->
		unless req.session.loggedIn
			req.flash 'warning', "You're not signed in."
			res.redirect '/login'
		else
			next()
	
	# admin signout
	app.get '/admin/signout', (req, res) ->
		res.redirect '/logout'

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