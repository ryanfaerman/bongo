(function() {
  var EpisodeSchema, ObjectId, Schema, UserSchema, models, mongoose, mongooseAuth, _;
  mongoose = require('mongoose');
  _ = require('underscore');
  mongooseAuth = require('mongoose-auth');
  Schema = mongoose.Schema;
  ObjectId = Schema.ObjectId;
  EpisodeSchema = new Schema({
    title: {
      type: String,
      required: false
    },
    episode: {
      type: Number,
      index: true
    },
    published: {
      type: Date,
      "default": Date.now(),
      index: true
    },
    file: String,
    length: Number,
    size: {
      type: Number
    },
    type: String,
    summary: String,
    links: String,
    release: {
      type: String,
      "enum": ['published', 'queue', 'date', 'draft', 'offline'],
      index: true
    },
    processed: {
      type: Boolean,
      "default": false,
      index: true
    },
    meta: {
      views: Number,
      plays: Number,
      downloads: Number
    }
  });
  EpisodeSchema.virtual('summary_html').get(function() {
    return require('markdown').parse(this.summary);
  });
  EpisodeSchema.virtual('size_mb').get(function() {
    return (this.size / 1048576).toFixed(2);
  });
  EpisodeSchema.virtual('links_html').get(function() {
    var cols, lines;
    lines = _.compact(this.links.split('\r\n'));
    cols = [[], []];
    _.each(lines, function(line, index) {
      var l, n;
      l = line.indexOf('[') === -1 ? "[" + line + "](" + line + ")" : line;
      n = index < (lines.length / 2) ? 0 : 1;
      return cols[n].push(" * " + l);
    });
    _.each(cols, function(col, index) {
      return cols[index] = require('markdown').parse(col.join('\n'));
    });
    return cols;
  });
  UserSchema = new Schema();
  UserSchema.plugin(mongooseAuth, {
    everymodule: {
      everyauth: {
        User: function() {
          return models.User;
        }
      }
    },
    password: {
      loginWith: 'email',
      everyauth: {
        getLoginPath: '/login',
        postLoginPath: '/login',
        loginView: 'login',
        getRegisterPath: '/register',
        postRegisterPath: '/register',
        registerView: 'register',
        loginSuccessRedirect: '/admin',
        registerSuccessRedirect: '/admin'
      }
    }
  });
  module.exports = models = {
    Episode: mongoose.model('Episode', EpisodeSchema),
    User: mongoose.model('User', UserSchema)
  };
}).call(this);
