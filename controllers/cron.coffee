cron = require 'cron'
sys = require 'sys'
mongoose = require 'mongoose'
config = require '../config'

mongoose.connect "mongodb://#{config.db.host}/#{config.db.db}"

EpisodeModel = require '../models/episode'
ConfigModel  = require '../models/config'


module.exports = (app) ->
	# This is a trick to turn the numeric days from `Date()`
	# into strings that are used in the config database.
	#
	# The same goes for time, but an object is used since the
	# index numbers aren't sequential.
	day = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
	time = 
		6: 'morning'
		13: 'afternoon'
		18: 'evening'
		23: 'night'
	
	# Initialize the week. Gotta start somewhere.
	week = 0

	ConfigModel.findOne {}, (err, config) ->
		queue = config.queue

		new cron.CronJob '5 6,13,18,23 * * * *', ->
			today = new Date()
			console.log "Cron Running... #{today}"

			# For simplicity sake, we assume a month is 4 weeks.
			#
			# This algorithm should be improved.
			week++
			if week is 5 then week = 0

			# These are all conditions that the cron **shouldn't**
			# run. It is split up just for clarity.
			if queue.enabled is false then return
			if queue.recurrence is 'biweekly' and week % 2 then return
			if queue.recurrence is 'monthly' and week / 4 is 0 then return
			unless day[today.getDay()] in queue.days then return
			unless time[today.getHours()] in queue.times then return

			# Finally, if we've reached here then cron should run.
			# 
			# Basically, find the oldest published episode marked for the queue
			# and mark it as published rather than queued.
			console.log "The time is now!"
			EpisodeModel.findOne({release: 'queue'}).sort('published', 'ascending').execFind (err, docs) ->
				episode = docs[0]
				
				# Update the published date otherwise users (and iTunes)
				# could get confused. "This just became available... why 
				# is it from the past?!"
				#
				# Up until now, the published date has just helped the
				# administrator(s) know when it was first published.
				episode.published = Date.now()
				episode.release = 'published'
				episode.save()
				
				console.log 'another episode bites the dust!'