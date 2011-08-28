mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId


SiteSchema = new Schema
	domains: [
		type: String
		set: (d) -> d.toLowerCase()
		]
	title: 
		type: String
		default: 'Untitled Site'
	active: Boolean
	pages: [
		type: ObjectId
		ref: 'Page'
		]
PageSchema = new Schema
	sites: [
		type: ObjectId
		ref: 'Page'
		]
	title: String
	content: String
	paths: [
		type: String
		set: (d) -> d.toLowerCase()
		]
	published:
		type: Date
		default: Date.now
	release:
		type: String
		enum: ['published', 'queue', 'date', 'draft', 'private', 'offline']
		index: true


module.exports = models =
	Site: mongoose.model 'Site', SiteSchema
	Page: mongoose.model 'Page', PageSchema