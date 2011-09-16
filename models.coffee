mongoose = require 'mongoose'
_ = require 'underscore'
mongooseAuth = require 'mongoose-auth'

Schema = mongoose.Schema
ObjectId = Schema.ObjectId


EpisodeSchema = new Schema
	title: 
		type: String
		required: false
	episode: 
		type: Number
		index: true
		
	published: 
		type: Date
		default: Date.now()	# can be in the future, aka "Publish on Date"
		index: true
	file: String
	length: Number
	size: 
		type: Number
	type: String			# mp3, mp4, m4v, etc.
	summary: String			# Markdown text
	links: String			# Markdown Text
	release:
		type: String
		enum: ['published', 'queue', 'date', 'draft', 'offline']
		index: true
	processed: 
		type: Boolean
		default: false
		index: true
	meta:
		views: Number
		plays: Number
		downloads: Number

# Convert Markdown Text to HTML
EpisodeSchema.virtual('summary_html').get ->
	require('markdown').parse this.summary
	
EpisodeSchema.virtual('size_mb').get ->
	(this.size/1048576).toFixed 2

EpisodeSchema.virtual('links_html').get ->
	lines = _.compact this.links.split '\r\n'		
	cols = [[],[]]
	
	_.each lines, (line, index) ->
		l = if line.indexOf('[') is -1 then "[#{line}](#{line})" else line	
		n = if index < (lines.length/2) then 0 else 1
		cols[n].push " * #{l}"
				
	_.each cols, (col, index) ->
		cols[index] = require('markdown').parse col.join '\n'
		
	return cols



UserSchema = new Schema()

UserSchema.plugin mongooseAuth,
	everymodule:
		everyauth:
			User: -> 
				return models.User
	password:
		loginWith: 'email'
		everyauth:
			getLoginPath: '/login'
			postLoginPath: '/login'
			loginView: 'login'
			getRegisterPath: '/register'
			postRegisterPath: '/register'
			registerView: 'register'
			loginSuccessRedirect: '/admin'
			registerSuccessRedirect: '/admin'
	

module.exports = models =
	Episode:	mongoose.model 'Episode', EpisodeSchema
	User:		mongoose.model 'User', UserSchema