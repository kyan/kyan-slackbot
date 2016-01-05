var Botkit = require('botkit');

// Check for ENV's
if (!process.env.SLACK_TOKEN || !process.env.REDIS_URL || !process.env.PORT) {
  console.log('Error: Specify SLACK_TOKEN, REDIS_URL and port in environment');
  process.exit(1);
}

// Configure storage
var redis_storage = require('./lib/storage/redis_storage')({
  url: process.env.REDIS_URL
});

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

// Simple listener (reply to IM containing hello or hi.)
controller.hears(['hello','hi','yo'],'direct_message', function(bot,message) {
  bot.reply(message,"Hello from BRH.");
});

// Needed to stop Heroku bailing
controller.setupWebserver(process.env.PORT,function(err,webserver) {
  // do nothing yet
});
