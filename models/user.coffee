mongoose = require 'mongoose'
bcrypt = require 'bcrypt'

Schema = mongoose.Schema
ObjectId = Schema.ObjectId


UserSchema = new Schema
	email:
		type: String
		require: yes
		index: true
		unique: true
	name: String
	hash: String
	salt: String

UserSchema.path('email').validate (v) ->
	return true
, 'invalid email'

module.exports = mongoose.model 'User', UserSchema