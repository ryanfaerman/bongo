(function() {
  var MongoStore, User, app, config, cronTask, events, express, form, fs, http, models, mongoose, mongooseAuth, path, queueSettings, sys, url, _;
  express = require('express');
  mongoose = require('mongoose');
  mongooseAuth = require('mongoose-auth');
  _ = require('underscore');
  form = require('connect-form');
  fs = require('fs');
  sys = require('sys');
  MongoStore = require('connect-mongo');
  http = require('http');
  url = require('url');
  path = require('path');
  events = require('events');
  models = require('./models');
  config = require('./config');
  queueSettings = require('./queue_settings');
  mongoose.connect("mongodb://" + config.db.host + "/" + config.db.db);
  User = models.User;
  cronTask = require('./cron');
  app = module.exports = express.createServer(form({
    keepExtensions: true
  }));
  app.configure(function() {
    app.set('views', "" + __dirname + "/views");
    app.set('view engine', 'mustache');
    app.register('.mustache', require('stache'));
    app.use(express.bodyParser());
    app.use(express.methodOverride());
    app.use(express.static("" + __dirname + "/public"));
    app.use(express.cookieParser());
    app.use(express.session({
      secret: 'bingobongo',
      store: new MongoStore({
        db: config.db.db,
        host: config.db.host
      })
    }));
    return app.use(mongooseAuth.middleware());
  });
  app.configure('development', function() {
    return app.use(express.errorHandler({
      dumpExceptions: true,
      showStack: true
    }));
  });
  app.configure('production', function() {
    return app.use(express.errorHandler());
  });
  mongooseAuth.helpExpress(app);
  app.dynamicHelpers({
    flash: function(req, res) {
      return req.flash();
    },
    site: function(req, res) {
      return config.site;
    },
    feed: function(req, res) {
      return config.feed;
    }
  });
  app.get('/', function(req, res) {
    var query;
    query = {
      release: 'published',
      published: {
        $lte: Date.now()
      }
    };
    return models.Episode.find(query).limit(5).sort('published', 'descending').execFind(function(err, docs) {
      return res.render('list', {
        locals: {
          episodes: docs
        }
      });
    });
  });
  app.get('/episode/:id', function(req, res) {
    return models.Episode.findById(req.params.id, function(err, doc) {
      return res.render('episode', {
        locals: doc
      });
    });
  });
  app.get('/feed', function(req, res) {
    var query;
    query = {
      release: 'published',
      published: {
        $lte: Date.now()
      }
    };
    return models.Episode.find(query).limit(5).sort('published', 'descending').execFind(function(err, docs) {
      return res.render('rss', {
        layout: null,
        locals: {
          episodes: docs
        }
      });
    });
  });
  app.all('/admin*?', function(req, res, next) {
    if (!req.loggedIn) {
      res.redirect('/');
      return req.flash('warning', "You're not signed in.");
    } else {
      return next();
    }
  });
  app.get('/admin', function(req, res) {
    return res.redirect('/admin/manager');
  });
  app.get('/admin/signout', function(req, res) {
    req.logout();
    req.flash('warning', "You've been signed out");
    return res.redirect('/login');
  });
  app.get('/admin/manager', function(req, res) {
    return models.Episode.count({}, function(err, count) {
      return models.Episode.find().sort('published', 'descending').execFind(function(err, docs) {
        var locals;
        locals = {
          episodes: docs,
          has_episodes: docs.length
        };
        return res.render('admin/manager', {
          layout: 'admin/layout',
          locals: locals
        });
      });
    });
  });
  app.get('/admin/publish', function(req, res) {
    return res.render('admin/publish', {
      layout: 'admin/layout'
    });
  });
  app.post('/admin/publish', function(req, res, next) {
    req.form.on('progress', function(bytesReceived, bytesExpected) {
      var percent;
      percent = (bytesReceived / bytesExpected) * 100 || 0;
      return console.log("Uploading: " + percent + "%");
    });
    return req.form.complete(function(err, fields, files) {
      var client, episode, host, request, target;
      if (err) {
        return next(err);
      } else {
        episode = _.extend(new models.Episode, fields);
        if (fields.release === 'date') {
          episode.published = new Date(require('./strtotime').parse(fields.release_date));
          console.log(episode.published);
          episode.release = "published";
        }
        episode.save();
        if (fields.use_remote === 'yes') {
          host = url.parse(fields.remote_file).hostname;
          episode.file = url.parse(fields.remote_file).pathname.split("/").pop();
          client = http.createClient(80, host);
          request = client.request('GET', fields.remote_file, {
            host: host
          });
          request.end();
          request.addListener('response', function(response) {
            var downloadfile;
            downloadfile = fs.createWriteStream(("./public/uploads/" + episode.file).replace(/\s+/g, '-'), {
              flags: 'a'
            });
            episode.size = response.headers['content-length'];
            episode.type = response.headers['content-type'];
            episode.file = episode.file.replace(/\s+/g, '-');
            episode.save();
            response.addListener('data', function(chunk) {
              var encoding;
              return downloadfile.write(chunk, encoding = 'binary');
            });
            return response.addListener('end', function() {
              downloadfile.end();
              console.log("Finished downloading " + episode.file);
              episode.processed = true;
              return episode.save();
            });
          });
        }
        if (_.size(files) !== 0) {
          target = files.audio.filename.replace(/\s+/g, '-');
          console.log("Uploaded " + files.audio.filename + " to " + files.audio.path);
          fs.rename(files.audio.path, "./public/uploads/" + target);
          console.log(files.audio);
          episode.file = files.audio.filename.replace(/\s+/g, '-');
          episode.size = files.audio.size;
          episode.type = files.audio.type;
          episode.processed = true;
          episode.save();
        }
        req.flash('success', "The episode \"" + episode.title + "\" is processing.");
        return res.redirect('/admin');
      }
    });
  });
  app.get('/admin/episode/:_id', function(req, res) {
    return models.Episode.findById(req.params._id, function(err, doc) {
      return res.render('admin/publish', {
        layout: 'admin/layout',
        locals: _.extend(doc, {
          method: 'put'
        })
      });
    });
  });
  app.post('/admin/episode/:id', function(req, res, next) {
    return req.form.complete(function(err, fields, files) {
      if (err) {
        return next(err);
      } else {
        return models.Episode.findById(req.params.id, function(err, doc) {
          var client, episode, host, request;
          episode = _.extend(doc, fields);
          episode.save();
          if (fields.use_remote === 'yes') {
            episode.processed = false;
            episode.save();
            host = url.parse(fields.remote_file).hostname;
            episode.file = url.parse(fields.remote_file).pathname.split("/").pop();
            client = http.createClient(80, host);
            request = client.request('GET', fields.remote_file, {
              host: host
            });
            request.end();
            request.addListener('response', function(response) {
              var downloadfile;
              downloadfile = fs.createWriteStream("./public/uploads/" + episode.file, {
                flags: 'a'
              });
              episode.size = response.headers['content-length'];
              episode.type = response.headers['content-type'];
              episode.save();
              response.addListener('data', function(chunk) {
                var encoding;
                return downloadfile.write(chunk, encoding = 'binary');
              });
              return response.addListener('end', function() {
                downloadfile.end();
                console.log("Finished downloading " + episode.file);
                episode.processed = true;
                return episode.save();
              });
            });
          }
          if (_.size(files) !== 0) {
            console.log("Uploaded " + files.audio.filename + " to " + files.audio.path);
            fs.rename(files.audio.path, "./public/uploads/" + files.audio.filename);
            console.log(files.audio);
            episode.file = files.audio.filename;
            episode.size = files.audio.size;
            episode.type = files.audio.type;
            episode.processed = true;
            episode.save();
          }
          req.form.on('progress', function(bytesReceived, bytesExpected) {
            var percent;
            percent = (bytesReceived / bytesExpected) * 100 || 0;
            return console.log("Uploading: " + percent + "%");
          });
          req.flash('success', "The episode \"" + episode.title + "\" is processing.");
          return res.redirect('/admin');
        });
      }
    });
  });
  app.post('/admin/delete/episode', function(req, res) {
    var episodes;
    episodes = [];
    console.log(req.body);
    _.each(req.body.episode, function(i, e) {
      return episodes.push(i);
    });
    return res.render('admin/confirm_delete', {
      layout: 'admin/layout',
      locals: {
        episodes: episodes
      }
    });
  });
  app["delete"]('/admin/delete/episode', function(req, res) {
    req.flash('info', "You're episodes have been removed.");
    res.redirect('/admin/manager');
    return _.each(req.body.episode, function(i, e) {
      return models.Episode.remove({
        _id: i
      }, function(r, d) {
        return console.log(d);
      });
    });
  });
  app.get('/admin/queue', function(req, res) {
    return models.Episode.find({
      release: 'queue'
    }).sort('published', 'ascending').execFind(function(err, docs) {
      var locals;
      locals = {
        next_up: docs.length > 0 ? docs[0] : void 0,
        episodes: docs.length > 1 ? _.rest(docs) : void 0,
        has_episodes: docs.length,
        settings: queueSettings
      };
      return res.render('admin/queue', {
        layout: 'admin/layout',
        locals: locals
      });
    });
  });
  app.put('/admin/queue', function(req, res) {
    var data;
    queueSettings = req.body;
    queueSettings.status = req.body.status === 'active' ? 'active' : false;
    data = JSON.stringify(queueSettings, null, 4);
    fs.writeFile('./queue_settings.js', "module.exports = " + data);
    req.flash('success', "Your queue settings were saved");
    return res.redirect('back');
  });
  app.get('/admin/account', function(req, res) {
    return res.render('admin/account', {
      layout: 'admin/layout'
    });
  });
  app.listen(3000);
  console.log("Express server listening on port " + (app.address().port) + " in " + app.settings.env + " mode");
}).call(this);
