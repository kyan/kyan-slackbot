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

// Polite
controller.hears(['hello','hi','yo'],'direct_message', function(bot,message) {
  bot.reply(message,"Hello!");
});

//
// image me <string>
// Finds images using Google Web Search API
//
controller.hears('(image|img)( me)? (.*)',['direct_message','direct_mention'], function(bot,message) {
  var google = require('googleapis');
  var customsearch = google.customsearch('v1');
  var params = {
    auth: process.env.GOOGLE_API_KEY,
    cx: process.env.GOOGLE_CX,
    q: message.match[3],
    fields: 'items(link)',
    searchType: 'image',
    safe: 'high',
    imgSize: 'medium'
  }

  customsearch.cse.list(params, function(err, resp) {
    if (err) {
      console.log('An error occured', err);
      return;
    }
    // Got the response from custom search
    if (resp.items && resp.items.length > 0) {
      var images = resp.items.map(function(item) {
        return item.link;
      });
      var image = images[Math.floor(Math.random()*images.length)];
      bot.reply(message, image);
    }
  });
});

// Needed to stop Heroku bailing
controller.setupWebserver(process.env.PORT,function(err,webserver) {
  // do nothing yet
});
