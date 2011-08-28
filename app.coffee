express	 = require 'express'
mongoose = require 'mongoose'
_ = require 'underscore'

app = module.exports = express.createServer()

# Configuration

app.configure ->
	app.set 'views', "#{__dirname}/views"
	app.set 'view engine', 'mustache'
	app.register '.mustache', require 'stache'
	app.use express.bodyParser()
	app.use express.methodOverride()
	app.use app.router
	app.use express.static "#{__dirname}/public"

app.configure 'development', ->
	app.use express.errorHandler dumpExceptions: true, showStack: true

app.configure 'production', ->
	app.use express.errorHandler()



mongoose.connect 'mongodb://localhost/bongo'

# Routes

app.get '/', (req, res, next) ->
	res.render 'index', locals: title: 'Express'	


app.listen 3000
console.log "Express server listening on port #{app.address().port} in #{app.settings.env} mode"


