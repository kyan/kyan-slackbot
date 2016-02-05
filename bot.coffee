Botkit = require('botkit')
Tasks = require('./lib/harvest/tasks')

# Check for ENV's
if not process.env.SLACK_TOKEN or not process.env.REDIS_URL or not process.env.PORT or not process.env.SLACK_ADMIN_IDS
  console.log('Error: Specify SLACK_TOKEN, REDIS_URL, SLACK_ADMIN_IDS and port in environment')
  process.exit(1)

# check for additional Harvest ENV's
if not process.env.HARVEST_LOW_HOURS
  console.log('Harvest Error: Specify HARVEST_LOW_HOURS in environment')
  process.exit(1)

# permissions
Permission = (ids) ->
  admin_ids = ids.split(',')

  this.admin_reply = (bot, message, reply) ->
    if admin_ids.indexOf(message.user) is -1
      bot.reply message, 'Sorry, permssion denied.'
      return false
    true
  this.admin = (bot, message, reply) ->
    return false if admin_ids.indexOf(message.user) is -1
    true
  return
permissions = new Permission(process.env.SLACK_ADMIN_IDS)

# Slack harvest mapper
slack_harvest_mapper = JSON.parse process.env.SLACK_HARVEST_MAPPER

# Configure storage
# Switched OFF as NOT used currently
#redis_storage = require('./lib/storage/redis_storage')
#  url: process.env.REDIS_URL

# Bot
controller = Botkit.slackbot
  debug: true,
  log: true,
#  storage: redis_storage

# Chat
controller.spawn(token: process.env.SLACK_TOKEN).startRTM (err)->
  throw new Error(err) if err

controller.hears '(tt|who is off|whos off|who\'s off) (today|tomorrow)', ['direct_message','direct_mention'], (bot,message) ->
  Timetastic = require('./lib/timetastic/index')
  cmd = message.match[2]
  tt = new Timetastic()
  tt.away { when: cmd }, (msg) -> bot.reply message, msg

controller.hears '(image|img)( me)? (.*)',['direct_message','direct_mention'], (bot,message) ->
  ImgSearch = require('./lib/google/imagesearch')
  query = message.match[3]

  img_search = new ImgSearch(query)
  img_search.search (msg) -> bot.reply message, msg

controller.hears 'kyan team', 'direct_message', (bot,message) ->
  bot.api.users.list {}, (err, resp) ->
    return console.log('An error occured', err) if err

    attachments = []
    text = []
    for user in resp.members
      if user.name isnt 'slackbot' and user.deleted isnt true and user.is_bot is false
        text.push("*#{user.id}* => #{user.profile.email} => <@#{user.id}>")

    attachment =
      color: '#AFDC19',
      fields: [],
      mrkdwn_in: ['text'],
      text: text.join('\n')
    attachments.push attachment

    bot.reply message,
      text: 'Slack Users slackid => email => username',
      attachments: attachments,

controller.hears 'hv hours( all)?', 'direct_message', (bot,message) ->
  return if not permissions.admin_reply bot, message
  filter = message.match[1]
  tasks = new Tasks('')
  opts = {}

  if filter is undefined
    opts.min_hours = process.env.HARVEST_LOW_HOURS

  bot.startConversation message, (err,convo) ->
    tasks.hours opts, (msg) -> convo.say msg

controller.hears 'hv (t|timers)', 'direct_message', (bot,message) ->
  return if not permissions.admin_reply bot, message
  tasks = new Tasks('')

  bot.startConversation message, (err,convo) ->
    tasks.timers (msg) -> convo.say msg

controller.hears 'hv (today|last|\\d{1,2}-\\d{1,2}-\\d{4}) (.*)', 'direct_message', (bot,message) ->
  return if not permissions.admin_reply bot, message
  username = message.match[2]
  userid = username.match(/<@(.*)>/i)[1]
  email = slack_harvest_mapper[userid]
  datestr = message.match[1]
  tasks = new Tasks(email)

  tasks.search datestr, email, (msg) -> bot.reply message, msg

controller.hears 'hv (p|prompt) (.*)', 'direct_message', (bot,message) ->
  return if not permissions.admin_reply bot, message
  username = message.match[2]
  userid = username.match(/<@(.*)>/i)[1]
  tasks = new Tasks('')

  tasks.prompt userid, bot, (_opts) ->
    bot.api.chat.postMessage _opts , (err,response) ->
      return console.log 'An error occured', err if err
      bot.reply message, "#{username} has been gently prompted."

controller.hears 'hv userids', 'direct_message', (bot,message) ->
  return if not permissions.admin_reply bot,message
  tasks = new Tasks('')

  tasks.user_ids (msg) -> bot.reply message, msg

controller.hears 'help', 'direct_message', (bot,message) ->
  attachments = []

  attachment =
    color: '#33FF00',
    fields: [],
    title: 'General',
    text: 'The commands below allow general interaction.',
    mrkdwn_in: ['fields']
  attachment.fields.push
    title: 'img|image (me) query',
    value: 'Fetches a random image from Google matching the _query_.',
    short: false
  attachment.fields.push
    title: 'kyan team',
    value: 'Shows all Slack users, _slackid_ => _email_ => _username_',
    short: false
  attachments.push attachment

  attachment =
    color: '#00c2ff',
    fields: [],
    title: 'Timetastic',
    text: 'The commands below allow you to interact with Timetastic.',
    mrkdwn_in: ['fields']
  attachment.fields.push
    title: "tt|who is off|whos off|who's off today|tomorrow",
    value: 'Shows who is in on the specified day.',
    short: false
  attachments.push attachment

  if permissions.admin bot, message
    attachment =
      color: '#FFCC99',
      fields: [],
      title: 'Harvest',
      text: 'The commands below allow you to interact with Harvest.',
      mrkdwn_in: ['fields']
    attachment.fields.push
      title: 'hv timers|t',
      value: 'Shows all the users and whether their timer is running.',
      short: false
    attachment.fields.push
      title: 'hv today|last|dd-mm-yyyy @user',
      value: 'Shows what Harvest _@user_ is working on.',
      short: false
    attachment.fields.push
      title: 'hv hours (all)',
      value: "Shows total hours for the previous working day only showing < #{process.env.HARVEST_LOW_HOURS} hours. If *all* is used all users are shown",
      short: false
    attachment.fields.push
      title: 'hv prompt|p @user',
      value: 'Sends a message to _@user_ letting them know their timer is not running.',
      short: false
    attachment.fields.push
      title: 'hv userids',
      value: 'Shows all Harvest users, harvestid => email',
      short: false
    attachments.push attachment

  bot.reply message,
    text: 'Help Menu:',
    attachments: attachments

# Needed to stop Heroku bailing
controller.setupWebserver process.env.PORT, (err,webserver) ->
  # controller.createWebhookEndpoints(controller.webserver)
