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
models = require './models'

# Routes

app.get '/', (req, res) ->
	models.Site
		.findOne(domains: req.headers.host.split(':')[0])
		.populate('pages').run (err, doc) ->
			if doc then p = doc.pages
			res.render 'index', locals: pages: p	
	

app.get '/sites', (req, res) ->
	models.Site.find {}, (err, docs) ->	
		res.render 'site-list', locals: sites: docs, has_sites: docs.length

app.get '/sites/modify', (req, res) ->
	res.render 'site-modify'

app.post '/sites/modify', (req, res) ->
	res.redirect '/sites'
	site = _.extend new models.Site, req.body
	site.save()

app.get '/sites/modify/:id', (req, res) ->
	models.Site.findById req.params.id, (err, doc) ->
		res.render 'site-modify', locals: _.extend(doc, method: 'put')

app.put '/sites/modify/:id', (req, res) ->
	res.redirect '/sites'
	models.Site.findById req.params.id, (err, doc) ->
		_.extend(doc, req.body)
		doc.save()

app.get '/write', (req, res) ->
	res.render 'write'

app.post '/write', (req, res) -> 
	console.log req.headers.host.split(':')[0]
	models.Site.findOne domains: req.headers.host.split(':')[0], (err, doc) ->
		console.log doc
		page = _.extend new models.Page, req.body
		page.tags = req.body.tags.split ','
		page.sites.push doc._id
		
		if page.release_date then page.published = require('./strtotime').parse page.release_date
		
		page.save()
		res.redirect "/read/#{page._id}"
		
		doc.pages.push page._id
		doc.save()
	


app.get '/read/:id', (req, res) ->
	models.Page.findById req.params.id, (err, doc) ->
		res.render 'read', locals: doc

app.listen 3000
console.log "Express server listening on port #{app.address().port} in #{app.settings.env} mode"


