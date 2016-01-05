// Slack api token
if (!process.env.SLACK_TOKEN) {
  console.log('Error: missing SLACK_TOKEN environment variable.');
  process.exit(1);
}

// Redis connection string
if (!process.env.REDIS_URL) {
  console.log('Error: missing REDIS_URL environment variable.');
  process.exit(1);
}

// Configure storage
var redis_storage = require('./lib/storage/redis_storage')({
  url: process.env.REDIS_URL
});

// Bot
var Botkit = require('botkit');
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
