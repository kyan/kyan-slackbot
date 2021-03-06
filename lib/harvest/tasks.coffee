Harvest = require('harvest')
_ = require('underscore')

module.exports = ->
  this.harvest = new Harvest(
    subdomain: process.env.HARVEST_SUBDOMAIN,
    email: process.env.HARVEST_EMAIL,
    password: process.env.HARVEST_PASSWORD
  )

  this.search = (cmd, email, callback) ->
    opts = {}

    this.user email, (user) =>
      switch cmd
        when 'today'
          break
        when 'last'
          date = new Date()
          opts.date = this._yesterday_as_date(date)
          break
        else
          parts = cmd.split('-')
          date = new Date(parts[2], parts[1]-1, parts[0])

          if Object::toString.call(date) is "[object Date]"
            invalidTime = date.getTime()
            if invalidTime is invalidTime
              opts.date = date

      this.daily user, opts, (_u, _tasks) =>
        sum = _.reduce(_tasks, ((m,n) -> return m + n.hours), 0)
        attachments = []
        attachment =
          pretext: "Total hours: *#{this._decical_to_hours(sum)}*",
          color: '#FFCC99',
          fields: [],
          mrkdwn_in: ['fields', 'pretext'],

        if _tasks.length > 0
          for _task in _tasks
            attachment.fields.push
              value: this._format_task_entry(_task),
              short: false,
        else
          attachment.fields.push
            value: 'No information found!',
            short: false,
        attachments.push attachment

        callback(
          text: "*#{this._fullname(_u)} (#{cmd})*",
          attachments: attachments,
        )

  this.user = (email, callback) =>
    this.users (_peoples) ->
      user

      for _person in _peoples
        user = _person.user
        if user.email.toLowerCase() is email and user.is_active
          return callback(user)

      return callback('Oops, user not found!') if user is undefined

  this.users = (callback) ->
    People = this.harvest.People
    People.list {}, (err, peoples) ->
      console.log('An error occured', err) if err
      callback(peoples)

  this.user_ids = (callback) =>
    this.users (_peoples) ->
      attachments = []
      text = []
      for _person in _peoples
        user = _person.user
        if user.is_active
          text.push("*#{user.id}* => #{user.email}")

      attachments.push
        color: '#FFCC99',
        fields: [],
        mrkdwn_in: ['text'],
        text: text.join('\n'),

      return callback
        text: 'Harvest harvestid => email',
        attachments: attachments,

  this.hours = (opts, callback) =>
    global_opts = opts

    this.users (_peoples) =>
      hours_cnt = []
      hours_str = []
      peoples = _.filter _peoples, (u) ->
        u.user.is_active && not u.user.is_admin

      for _person in peoples
        user = _person.user
        date = new Date()
        yesterday = this._yesterday_as_str(date)
        opts = from: yesterday, to: yesterday
        opts.user_id = user.id

        this.entries_per_user user, opts, (_user, _hours) =>
          hours_cnt.push(_hours)
          hours_str.push("*#{_hours.toFixed(2)}* : #{this._fullname(_user)}")

          if global_opts.min_hours and _hours >= parseInt(Number(global_opts.min_hours))
            hours_str.pop()

          if hours_cnt.length is peoples.length
            sum = _.reduce(hours_cnt, ((m,n) -> m + n), 0)
            attachments = []
            attachment =
              color: '#FFCC99',
              fields: [],
              mrkdwn_in: ['fields', 'text']
            sorted = _.sortBy hours_str, (n) -> n.split(':')[1]
            title = "Total hours logged (#{yesterday})"

            _.each sorted, (_str) ->
              attachment.fields.push
                value: _str,
                short: false
            attachments.push attachment

            if global_opts.min_hours
              title += " under #{global_opts.min_hours}"
            else
              title += ": *#{sum.toFixed(2).toString()}*"

            callback
              text: title,
              attachments: attachments

  this.entries_per_user = (user, opts, callback) ->
    Reports = this.harvest.Reports
    Reports.timeEntriesByUser opts, (err, _data) ->
      hours = _data.map((item) -> item.day_entry.hours)
      sum = _.reduce(hours, ((m,n) -> m + n), 0)
      callback(user, sum)

  this.timers = (callback) =>
    opts = running: false

    this.users (_peoples) =>
      for _person in _peoples
        user = _person.user

        if user.is_active and not user.is_admin
          this.daily user, opts, (_task) =>
            callback(this._format_task_entry(_task))

  this.daily = (user, opts, callback) =>
    harvest_opts = of_user: user.id
    harvest_opts.date = opts.date if opts.date

    TimeTracking = this.harvest.TimeTracking
    TimeTracking.daily harvest_opts, (err, tasks) =>
      return console.log('An error occured', err) if err

      entries = tasks.day_entries
      task = this._currently_running_task(entries)

      if opts.hasOwnProperty('running')
        fn = this._fullname(user)

        if task is undefined
          task = fullname: fn, not_running: true
        else
          task.fullname = this._fullname(user)
        return callback(task)

      callback(user, entries)

  this.prompt = (userid, bot, callback) ->
    bot.api.im.open { user: userid }, (err,response) ->
      channelid = response.channel.id
      text = "Hey. It looks like you're not recording any hours at the moment?"
      opts =
        channel: channelid,
        text: text,
        icon_emoji: ':sadsmile:',
        username: 'HarvestBot'

      callback(opts)

  this._fullname = (user) ->
    "#{user.first_name} #{user.last_name}"

  this._decical_to_hours = (str) ->
    info = str.toString().replace(/:/g, '.')
    hrs = parseInt(Number(info)).toString()
    min = Math.round((Number(info)-hrs) * 60).toString()
    min = "0#{min}" if min.length < 2
    "#{hrs}:#{min}"

  this._format_task_entry = (entry) ->
    msg = ''

    if entry.hasOwnProperty 'not_running'
      msg += ":ZZZ: : *#{entry.fullname}*"
    else
      msg += "*#{this._decical_to_hours(entry.hours)}*"
      msg += " : #{entry.fullname} |" if entry.hasOwnProperty 'fullname'
      msg += " - #{entry.client}"

      if not entry.hasOwnProperty 'fullname'
        msg += " - #{entry.task}" if entry.task isnt ''
        msg += " - #{entry.project}" if entry.project isnt ''
      msg += " - _#{entry.notes}_" if entry.notes isnt ''
    msg

  this._currently_running_task = (entries) ->
    _.find entries, (e) -> e.timer_started_at

  this._yesterday_as_date = (date) ->
    daysback = if date.getDay() is 1 then 3 else 1
    new Date(date.setDate(date.getDate() - daysback))

  this._yesterday_as_str = (date) ->
    this._yesterday_as_date(date).toISOString()
      .split('T')[0]
      .replace(/-/g, '')
  return
