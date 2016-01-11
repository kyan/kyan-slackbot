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

    self.user(function(_user) {
      self.daily(_user, function(_tasks) {
        return callback('Now: ('+ self.fullname(_user) +')\n' + _tasks.join('\n'));
      });
    });
  };

  this.user = function(callback) {
    var self = this;

    People = harvest.People;
    People.list({}, function(err, peoples) {
      console.log(JSON.stringify(peoples));

      if (err) {
        console.log('An error occured', err);
        return;
      }

      for (var i = 0; i < peoples.length; i++) {
        var user = peoples[i].user;
        if (user.email.toLowerCase() === self.email && user.is_active && !user.is_admin) {
          return callback(user);
        }
      }

      if (user == undefined) {
        callback('Oops, user not found!');
        return;
      }
    });
  };

  this.daily = function(user, callback) {
    var self = this;

    TimeTracking = harvest.TimeTracking;
    TimeTracking.daily({of_user: user.id}, function(err, tasks) {
      if (err) {
        console.log('An error occured', err);
        return;
      }

      var entries = tasks.day_entries;
      var tasks = entries.map(function(entry) {
        return entry.hours + ' : ' + entry.client + ' - ' + entry.notes;
      });

      var not_running = [];
      for (var i = 0, len = entries.length; i < len; i++) {
        if (entries[i].timer_started_at) {
          not_running.push(true);
        }
      }
      if (not_running.length == 0) {
        tasks.push('\n_There is no timer currently running._');
      }

      return callback(tasks);
    });
  };

  this.fullname = function(user) {
    return user.first_name + ' ' + user.last_name;
  };

  this.decical_to_hours = function(str) {
    var h,m = str.split(':');
    var min = Math.floor(Math.abs(str))
    var sec = Math.floor((Math.abs(str) * 60) % 60);
    return (min < 10 ? "0" : "") + min + ":" + (sec < 10 ? "0" : "") + sec;
  };
}
