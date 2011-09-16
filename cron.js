(function() {
  var config, cron, day, models, mongoose, queue, sys, today, week, _;
  cron = require('cron');
  sys = require('sys');
  queue = require('./queue_settings');
  _ = require('underscore');
  mongoose = require('mongoose');
  models = require('./models');
  config = require('./config');
  mongoose.connect("mongodb://" + config.db.host + "/" + config.db.db);
  day = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
  today = new Date();
  week = 1;
  module.exports = new cron.CronJob('5 6,13,18,23 * * * *', function() {
    console.log("Cron Running... " + today);
    if ((queue.status === false) || (queue.recurrence.biweekly && week % 2) || (queue.recurrence.monthly && week / 4 === 0)) {} else {
      console.log("We are active and the recurrence settings match, looks good so far");
      if (queue.day[day[today.getDay()]] && (queue.time.morning && today.getHours() === 6) || (queue.time.afternoon && today.getHours() === 11) || (queue.time.evening && today.getHours() === 18) || (queue.time.night && today.getHours() === 23)) {
        console.log("The time is now!");
        if (week === 4) {
          week = 1;
        } else {
          week++;
        }
        console.log("This week is week " + week);
        return models.Episode.findOne({
          release: 'queue'
        }).sort('published', 'ascending').execFind(function(err, docs) {
          var episode;
          episode = docs[0];
          episode.published = Date.now();
          episode.release = 'published';
          episode.save();
          return console.log('another episode bites the dust!');
        });
      }
    }
  });
}).call(this);
