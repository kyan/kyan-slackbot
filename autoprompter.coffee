Botkit = require('botkit')
Tasks = require('./lib/harvest/tasks')
Timetastic = require('./lib/timetastic/index')
dotenv = require('dotenv')

ENV = process.env.NODE_ENV || 'development'
dotenv.load() if ENV == 'development'

# Check for ENV's
if not process.env.SLACK_TOKEN or not process.env.REDIS_URL or not process.env.SLACK_ADMIN_IDS
  console.log('Error: Specify SLACK_TOKEN, REDIS_URL and SLACK_ADMIN_IDS in environment')
  process.exit(1)

# check for additional Harvest ENV's
if not process.env.HARVEST_LOW_HOURS
  console.log('Harvest Error: Specify HARVEST_LOW_HOURS in environment')
  process.exit(1)

controller = Botkit.slackbot
  debug: true,
  log: true,
#  storage: redis_storage

# Chat
bot = controller.spawn(token: process.env.SLACK_TOKEN)

tasks = new Tasks('')
if true #tasks.in_core_hours(tasks.now_in_uk())
  tt = new Timetastic()
  tasks.auto_prompt bot, tt, (opts) ->
    console.log(opts)
    process.exit(1)
