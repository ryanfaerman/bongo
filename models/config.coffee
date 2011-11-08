mongoose = require 'mongoose'

Schema = mongoose.Schema
ObjectId = Schema.ObjectId

ConfigSchema = new Schema
	site:
		domain: String
		open_registration:
			type: Boolean
			default: yes
		name: String
		about:
			type: String
			default: "Welcome to my lovely podcast"
	feed:	
		explicit: 
			type: Boolean
			default: no
		keywords: [String]
		category: String
		subcategory: String
	analytics:
		google: String
	cover_art: String



module.exports = mongoose.model 'Config', ConfigSchema