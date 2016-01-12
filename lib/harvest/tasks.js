var Harvest = require('harvest');
var harvest = new Harvest({
  subdomain: process.env.HARVEST_SUBDOMAIN,
  email: process.env.HARVEST_EMAIL,
  password: process.env.HARVEST_PASSWORD
});

module.exports = function(cmd, email, date) {
  this.cmd = cmd;
  this.email = email;
  this.date = date;

  this.search = function(callback) {
    var self = this;
    var opts = {};

    self.user(function(user) {
      self.daily(user, opts, function(_u, _tasks) {
        return callback('Now: ('+ self.fullname(_u) +')\n' + _tasks.join('\n'));
      });
    });
  };

  this.user = function(callback) {
    var self = this;

    self.users(function(_peoples) {
      for (var i = 0; i < _peoples.length; i++) {
        var user = _peoples[i].user;
        if (user.email.toLowerCase() === self.email && user.is_active) {
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
      var not_running = [];
      for (var i = 0, len = entries.length; i < len; i++) {
        if (entries[i].timer_started_at) {
          not_running.push(entries[i]);
        }
      }

      if (opts.hasOwnProperty('running')) {
        var _msg;

        if (opts.running === false && not_running.length == 0) {
          _msg = '*NOT RUNNING!*';
        } else {
          _msg = 'Ok';
        }
        return callback(user, [_msg]);
      }

      var tasks = entries.map(function(entry) {
        return self.decical_to_hours(entry.hours) + ' : ' + entry.client + ' - ' + entry.notes;
      });

      if (not_running.length == 0) {
        tasks.push('\n_There is no timer currently running._');
      }

      return callback(user, tasks);
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
}
