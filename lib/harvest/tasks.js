var _ = require('underscore');
var Harvest = require('harvest');
var harvest = new Harvest({
  subdomain: process.env.HARVEST_SUBDOMAIN,
  email: process.env.HARVEST_EMAIL,
  password: process.env.HARVEST_PASSWORD
});

module.exports = function() {
  this.search = function(datestr, email, callback) {
    var self = this;
    var opts = {};
    var context = 'today';


    self.user(email, function(user) {
      var parts = datestr.split('-');
      var date = new Date(parts[2], parts[1]-1, parts[0]);

      if (date) {
        context = datestr;
        opts.date = date;
      }

      self.daily(user, opts, function(_u, _tasks) {
        var attachments = [];
        var attachment = {
          color: '#FFCC99',
          fields: [],
          mrkdwn_in: ['fields'],
        };

        if (_tasks.length > 0) {
          for (var i = 0; i < _tasks.length; i++) {
            attachment.fields.push({
              value: self._format_task_entry(_tasks[i]),
              short: false,
            });
          }
        } else {
          attachment.fields.push({
            value: 'No information found!',
            short: false,
          });
        }
        attachments.push(attachment);

        return callback({
          text: '*' + self._fullname(_u) + ' ('+context+')*',
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

  this.user_ids = function(callback) {
    var self = this;

    self.users(function(_peoples) {
      var attachments = [];
      var text = [];
      for (var i = 0; i < _peoples.length; i++) {
        var user = _peoples[i].user;
        if (user.is_active) {
          text.push('*' + user.id + '* => ' + user.email);
        }
      }
      var attachment = {
        color: '#FFCC99',
        fields: [],
        mrkdwn_in: ['text'],
        text: text.join('\n'),
      };
      attachments.push(attachment);

      return callback({
        text: 'Harvest harvestid => email',
        attachments: attachments,
      });
    });
  }

  this.hours = function(callback) {
    var self = this;

    self.users(function(_peoples) {
      var hours_cnt = [];
      var hours_str = [];
      var peoples = _.filter(_peoples, function(u){ return (!u.user.is_admin && u.user.is_active); });

      _.each(peoples, function(_person) {
        var user = _person.user;
        var yesterday = self._yesterday_as_str();
        var opts = { from: yesterday, to: yesterday };

        opts.user_id = user.id
        self.entries_per_user(user, opts, function(_user, _hours) {
          hours_cnt.push(_hours);
          hours_str.push(self._fullname(_user)+': *'+_hours.toFixed(2)+'*');

          if (hours_cnt.length === peoples.length) {
            var sum = _.reduce(hours_cnt, function(m,n){ return m + n; }, 0);
            var attachments = [];
            var attachment = {
              color: '#FFCC99',
              fields: [],
              mrkdwn_in: ['fields', 'text'],
            };

            _.each(hours_str, function(_str) {
              attachment.fields.push({
                value: _str,
                short: false,
              });
            });
            attachments.push(attachment);

            return callback({
              text: 'Total hours ('+yesterday+'): *' + sum.toFixed(2).toString() + '*',
              attachments: attachments,
            });
          }
        });
      });
    });
  };

  this.entries_per_user = function(user, opts, callback) {
    var self = this;

    Reports = harvest.Reports;
    Reports.timeEntriesByUser(opts, function(err, _data) {
      var hours = _data.map(function(item) { return item.day_entry.hours });
      var sum = _.reduce(hours, function(m,n){ return m + n; }, 0);
      return callback(user, sum);
    });
  };

  this.timers = function(callback) {
    var self = this;
    var opts = { running: false };

    self.users(function(_peoples) {
      _.each(_peoples, function(_person) {
        var user = _person.user;

        if (user.is_active && !user.is_admin) {
          self.daily(user, opts, function(_user, _tasks) {
            return callback(self._fullname(_user) +': ' + _tasks[0]);
          });
        }
      });
    });
  };

  this.daily = function(user, opts, callback) {
    var self = this;
    var harvest_opts = {of_user: user.id};

    if (opts.date) {
      harvest_opts.date = opts.date;
    }

    TimeTracking = harvest.TimeTracking;
    TimeTracking.daily(harvest_opts, function(err, tasks) {
      if (err) {
        console.log('An error occured', err);
        return;
      }

      var entries = tasks.day_entries;
      var not_running = self._calc_not_running(entries);

      if (opts.hasOwnProperty('running')) {
        var msg;

        if (opts.running === false && not_running.length == 0) {
          msg = '*NOT RUNNING!*';
        } else {
          msg = self._format_task_entry(not_running[0]);
        }
        return callback(user, [msg]);
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

  this._fullname = function(user) {
    return user.first_name + ' ' + user.last_name;
  };

  this._decical_to_hours = function(str) {
    var info = str.toString().replace(/:/g, '.');
    var hrs = parseInt(Number(info));
    var min = Math.round((Number(info)-hrs) * 60);
    return hrs+':'+min;
  };

   this._format_task_entry = function(entry) {
    var msg = '';
    msg += '*' + this._decical_to_hours(entry.hours) + '*';
    msg += ' ' + entry.client;

    if (entry.notes && entry.notes != '') {
      msg += ' - _' + entry.notes + '_';
    }
    return msg;
  }

  this._calc_not_running = function(entries) {
    var not_running = [];
    for (var i = 0, len = entries.length; i < len; i++) {
      if (entries[i].timer_started_at) {
        not_running.push(entries[i]);
      }
    }
    return not_running;
  };

  this._yesterday_as_str = function() {
    var date = new Date();
    var daysback = date.getDay() == 1 ? 2 : 1;
    var yesterday = new Date(date.setDate(date.getDate() - daysback));
    return yesterday.toISOString()
      .split('T')[0]
      .replace(/-/g, '');
  }
}
