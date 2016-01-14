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

controller.hears(['hello','hi','yo'],'direct_message', function(bot,message) {
  bot.reply(message,"Hello!");
});

controller.hears('(image|img)( me)? (.*)',['direct_message','direct_mention'], function(bot,message) {
  var ImgSearch = require('./lib/google/imagesearch');
  var query = message.match[3];

  var imgsearch = new ImgSearch(query);
  imgsearch.search(function(msg) {
    bot.reply(message, msg);
  });
});

controller.hears('hv timers', 'direct_message', function(bot,message) {
  var cmd = message.match[1];

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

controller.hears('hv today (.*)', 'direct_message', function(bot,message) {
  var email = message.match[1].match(/\|(.*)>/i)[1].trim().toLowerCase();

  if (admin_ids.indexOf(message.user) == -1) {
    bot.reply(message, 'Sorry, permssion denied.');
    return;
  }

  var tasks = new Tasks(email);
  tasks.search(email, function(msg) {
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

controller.hears('hv help', 'direct_message', function(bot,message) {
  var attachments = [];
  var attachment = {
    color: '#FFCC99',
    fields: [],
  };

  attachment.fields.push({
    title: 'hv timers',
    value: 'Shows all the users and whether their timer is running.',
    short: false,
  });
  attachment.fields.push({
    title: 'hv today <user_email>',
    value: 'Shows what Harvest <user_email> is working on.',
    short: false,
  });
  attachment.fields.push({
    title: 'hv prompt @user',
    value: 'Sends a message to @user letting them know their timer is not running.',
    short: false,
  });
  attachments.push(attachment);

  var _msg = {
    text: 'Harvest Commands',
    attachments: attachments,
  };

  bot.reply(message, _msg);
});

// Needed to stop Heroku bailing
controller.setupWebserver(process.env.PORT,function(err,webserver) {
  // controller.createWebhookEndpoints(controller.webserver);
});
