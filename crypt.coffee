###
bcrypt = require 'bcrypt'


bcrypt.gen_salt 10, (err, salt) ->
	bcrypt.encrypt 'bacon', salt, (err, hash) ->
		console.log "#{hash}\n"
		bcrypt.compare 'bacon', hash, (err, res) ->
			console.log "#{res}\n"
		bcrypt.compare 'not bacon', hash, (err, res) ->
			console.log "#{res}\n"
###
module.exports = 
	express: (app) ->
		app.get '/login2', (req, res) ->
			req.flash 'info', "Module Routes Work!"
			res.redirect '/'