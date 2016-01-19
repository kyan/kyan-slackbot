var Botkit = require('botkit');
var Tasks = require('./lib/harvest/tasks');

// Check for ENV's
if (!process.env.SLACK_TOKEN || !process.env.REDIS_URL || !process.env.PORT || !process.env.SLACK_ADMIN_IDS) {
  console.log('Error: Specify SLACK_TOKEN, REDIS_URL, SLACK_ADMIN_IDS and port in environment');
  process.exit(1);
}

// Configure storage
var redis_storage = require('./lib/storage/redis_storage')({
  url: process.env.REDIS_URL
});

// admin ids
var admin_ids = process.env.SLACK_ADMIN_IDS.split(',');

// Slack harvest mapper
var slack_harvest_mapper = JSON.parse(process.env.SLACK_HARVEST_MAPPER);

// Bot
var controller = Botkit.slackbot({
 debug: true,
 log: true,
 storage: redis_storage
});

// Chat
controller.spawn({
  token: process.env.SLACK_TOKEN
}).startRTM(function(err) {
  if (err) {
    throw new Error(err);
  }
});

controller.hears('(image|img)( me)? (.*)',['direct_message','direct_mention'], function(bot,message) {
  var ImgSearch = require('./lib/google/imagesearch');
  var query = message.match[3];

  var imgsearch = new ImgSearch(query);
  imgsearch.search(function(msg) {
    bot.reply(message, msg);
  });
});

controller.hears('kyan team', 'direct_message', function(bot,message) {
  bot.api.users.list({},function(err, resp) {
    if (err) {
      console.log('An error occured', err);
      return;
    }

    var attachments = [];
    var text = [];
    for (var i = 0; i < resp.members.length; i++) {
      var user = resp.members[i];
      if (user.name != 'slackbot' && user.deleted != true && user.is_bot == false) {
        text.push('*' + user.id + '* => ' + user.profile.email + ' => <@' + user.id + '>');
      }
    }
    var attachment = {
      color: '#AFDC19',
      fields: [],
      mrkdwn_in: ['text'],
      text: text.join('\n'),
    };
    attachments.push(attachment);

    bot.reply(message, {
      text: 'Slack Users slackid => email => username',
      attachments: attachments,
    });
  });
});

controller.hears('hv timers', 'direct_message', function(bot,message) {
  if (admin_ids.indexOf(message.user) == -1) {
    bot.reply(message, 'Sorry, permssion denied.');
    return;
  }

  var tasks = new Tasks('');
  bot.startConversation(message,function(err,convo) {
    tasks.timers(function(msg) {
      convo.say(msg);
    });
  });
});

controller.hears('hv hours', 'direct_message', function(bot,message) {
  if (admin_ids.indexOf(message.user) == -1) {
    bot.reply(message, 'Sorry, permssion denied.');
    return;
  }

  var tasks = new Tasks('');
  bot.startConversation(message,function(err,convo) {
    tasks.hours(function(msg) {
      convo.say(msg);
    });
  });
});

controller.hears('hv (today|\\d{1,2}-\\d{1,2}-\\d{4}) (.*)', 'direct_message', function(bot,message) {
  var username = message.match[2];
  var userid = username.match(/<@(.*)>/i)[1];
  var email = slack_harvest_mapper[userid];
  var datestr = message.match[1];

  if (admin_ids.indexOf(message.user) == -1) {
    bot.reply(message, 'Sorry, permssion denied.');
    return;
  }

  var tasks = new Tasks(email);
  tasks.search(datestr, email, function(msg) {
    bot.reply(message, msg);
  });
});

controller.hears('hv prompt (.*)', 'direct_message', function(bot,message) {
  var username = message.match[1];
  var userid = username.match(/<@(.*)>/i)[1];

  if (admin_ids.indexOf(message.user) == -1) {
    bot.reply(message, 'Sorry, permssion denied.');
    return;
  }

  var tasks = new Tasks('');
  tasks.prompt(userid, bot, function(msg) {
    bot.reply(message, username + ' has been gently prompted.');
  });
});

controller.hears('hv userids', 'direct_message', function(bot,message) {
  if (admin_ids.indexOf(message.user) == -1) {
    bot.reply(message, 'Sorry, permssion denied.');
    return;
  }

  var tasks = new Tasks('');
  tasks.user_ids(function(msg) {
    bot.reply(message, msg);
  });
});

controller.hears('help', 'direct_message', function(bot,message) {
  var attachments = [];

  var attachment = {
    color: '#33FF00',
    fields: [],
    title: 'General',
    text: 'The commands below allow general interaction.',
    mrkdwn_in: ['fields'],
  };
  attachment.fields.push({
    title: 'img|image (me) query',
    value: 'Fetches a random image from Google matching the _query_.',
    short: false,
  });
  attachment.fields.push({
    title: 'kyan team',
    value: 'Shows all Slack users, _slackid_ => _email_ => _username_',
    short: false,
  });
  attachments.push(attachment);

  if (admin_ids.indexOf(message.user) != -1) {
    var attachment = {
      color: '#FFCC99',
      fields: [],
      title: 'Harvest',
      text: 'The commands below allow you to interact with Harvest.',
      mrkdwn_in: ['fields'],
    };
    attachment.fields.push({
      title: 'hv timers',
      value: 'Shows all the users and whether their timer is running.',
      short: false,
    });
    attachment.fields.push({
      title: 'hv today|dd-mm-yyyy @user',
      value: 'Shows what Harvest _@user_ is working on.',
      short: false,
    });
    attachment.fields.push({
      title: 'hv hours',
      value: 'Shows total hours for the previous working day',
      short: false,
    });
    attachment.fields.push({
      title: 'hv prompt @user',
      value: 'Sends a message to _@user_ letting them know their timer is not running.',
      short: false,
    });
    attachment.fields.push({
      title: 'hv userids',
      value: 'Shows all Harvest users, harvestid => email',
      short: false,
    });
    attachments.push(attachment);
  }

  var _msg = {
    text: 'Help Menu:',
    attachments: attachments,
  };

  bot.reply(message, _msg);
});

// Needed to stop Heroku bailing
controller.setupWebserver(process.env.PORT,function(err,webserver) {
  // controller.createWebhookEndpoints(controller.webserver);
});
