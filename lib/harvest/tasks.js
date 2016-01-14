var Harvest = require('harvest');
var harvest = new Harvest({
  subdomain: process.env.HARVEST_SUBDOMAIN,
  email: process.env.HARVEST_EMAIL,
  password: process.env.HARVEST_PASSWORD
});

module.exports = function() {
  this.search = function(callback) {
    var self = this;
    var opts = {};

    self.user(function(user) {
      self.daily(user, opts, function(_u, _tasks) {
        var attachments = [];
        var attachment = {
          color: '#FFCC99',
          fields: [],
          mrkdwn_in: ['fields'],
        };

        for (var i = 0; i < _tasks.length; i++) {
          attachment.fields.push({
            label: 'Field',
            value: self.format_task_entry(_tasks[i]),
            short: false,
          });
        }
        attachments.push(attachment);

        return callback({
          text: '*' + self.fullname(_u) + ' (Today)*',
          attachments: attachments,
        });
      });
    });
  };

  this.user = function(email, callback) {
    var self = this;

    self.users(function(_peoples) {
      for (var i = 0; i < _peoples.length; i++) {
        var user = _peoples[i].user;
        if (user.email.toLowerCase() === email && user.is_active) {
          return callback(user);
        }
      }

      if (user == undefined) {
        callback('Oops, user not found!');
        return;
      }
    });
  };

  this.users = function(callback) {
    var self = this;

    People = harvest.People;
    People.list({}, function(err, peoples) {
      if (err) {
        console.log('An error occured', err);
        return;
      }

      return callback(peoples);
    })
  }

  this.timers = function(callback) {
    var self = this;
    var opts = { running: false };

    self.users(function(_peoples) {
      for (var i = 0; i < _peoples.length; i++) {
        var user = _peoples[i].user;

        if (user.is_active && !user.is_admin) {
          self.daily(user, opts, function(_user, _tasks) {
            return callback(self.fullname(_user) +': ' + _tasks[0]);
          });
        }
      }
    });
  };

  this.daily = function(user, opts, callback) {
    var self = this;

    TimeTracking = harvest.TimeTracking;
    TimeTracking.daily({of_user: user.id}, function(err, tasks) {
      if (err) {
        console.log('An error occured', err);
        return;
      }

      var entries = tasks.day_entries;
      var not_running = self.calc_not_running(entries);

      if (opts.hasOwnProperty('running')) {
        var _msg;

        if (opts.running === false && not_running.length == 0) {
          _msg = '*NOT RUNNING!*';
        } else {
          _msg = self.format_task_entry(not_running[0]);
        }
        return callback(user, [_msg]);
      }

      return callback(user, entries);
    });
  };

  this.prompt = function(userid, bot, callback) {
    var self = this;

    bot.api.im.open({ user: userid },function(err,response) {
      var channelid = response.channel.id;
      var text = "Hey. It looks like you're not recording any hours at the moment?";
      var opts = {
        channel: channelid,
        text: text,
        icon_emoji: ':sadsmile:',
        username: 'HarvestBot',
      };

      bot.api.chat.postMessage(opts ,function(err,response) {
        if (err) {
          console.log('An error occured', err);
          return;
        }

        return callback(userid);
      });
    });
  };

  this.fullname = function(user) {
    return user.first_name + ' ' + user.last_name;
  };

  this.decical_to_hours = function(str) {
    var info = str.toString().replace(/:/g, '.');
    var hrs = parseInt(Number(info));
    var min = Math.round((Number(info)-hrs) * 60);
    return hrs+':'+min;
  };

  this.format_task_entry = function(entry) {
    var _msg = '';
    _msg += '*' + this.decical_to_hours(entry.hours) + '*';
    _msg += ' ' + entry.client;

    if (entry.notes && entry.notes != '') {
      _msg += ' - _' + entry.notes + '_';
    }
    return _msg;
  }

  this.calc_not_running = function(entries) {
    var not_running = [];
    for (var i = 0, len = entries.length; i < len; i++) {
      if (entries[i].timer_started_at) {
        not_running.push(entries[i]);
      }
    }
    return not_running;
  };
}
