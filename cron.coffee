cron = require 'cron'
sys = require 'sys'
queue = require './queue_settings'
_ = require 'underscore'
mongoose = require 'mongoose'
models = require './models'
config = require './config'

mongoose.connect "mongodb://#{config.db.host}/#{config.db.db}"


day = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
today = new Date()
week = 1

module.exports = new cron.CronJob '0 6,12,18,0 * * * *', () ->
	if (queue.status is false) or (queue.recurrence.biweekly and week % 2) or (queue.recurrence.monthly and week / 4 is 0) then return else

		if queue.day[day[today.getDay()]] and
			(queue.time.morning and today.getHours() is 6) or
			(queue.time.afternoon and today.getHours() is 12) or
			(queue.time.evening and today.getHours() is 18) or
			(queue.time.night and today.getHours() is 0) then () ->
				if week is 4 then week = 1 else week++
				models.Episode.findOne({release: 'queue'}).sort('published', 'ascending').execFind (err, doc) ->
					doc.published = Date.now()
					doc.release = 'published'
					doc.save()
					
					console.log 'another episode bites the dust!'
