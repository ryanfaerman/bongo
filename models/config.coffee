# Generic requirements
mongoose = require 'mongoose'

# Convenience Variables
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
	queue:
		enabled: 
			type: Boolean
			default: no
		recurrence:
			type: String
			enum: ['weekly', 'biweekly', 'monthly']
			default: 'weekly'
		times: 
			[
				type: String
				enum: ['morning', 'afternoon', 'evening', 'night']
				default: 'afternoon'
			]
		days:
			[
				type: String
				enum: ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
				default: 'tuesday'
			]
		


module.exports = mongoose.model 'Config', ConfigSchema