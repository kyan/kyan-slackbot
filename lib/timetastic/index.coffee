req = require('request')

class Timetastic
  request: req

  users_away_today: (callback) ->
    date_string = @date_plus_as_string(new Date(), 0)
    find_holidays_on(date_string, callback)

  away: (opt, callback) ->
    cmd = opt.when or 'today'
    amt = 0
    amt = 1 if cmd is 'tomorrow'
    today = new Date()
    date_string = @date_plus_as_string(today, amt)

    @find_holidays_on date_string, (err, users) ->
      if !err
        attachments = []
        status = ":party: Everyone is here #{cmd}! :party:"

        attachments.push
          color: '#FFCC99',
          fields: [],
          mrkdwn_in: ['text'],
          text: users.join('\n'),

        if users.length > 0
          status = "These staff are away #{cmd}:"

        return callback
          text: status,
          attachments: attachments,
      else
        console.log 'error: '+ response.statusCode
        console.log body
    return

  find_holidays_on: (date_string, callback) ->
    request_options =
      url: 'https://app.timetastic.co.uk/api/holidays'
      json: true
      headers:
        'Authorization': "Bearer #{process.env.TIMETASTIC_TOKEN}"
      qs:
        start: "#{date_string}T00:00:01Z"
        end: "#{date_string}T23:59:59Z"
        status: 'Approved'

    @request request_options, (err, response, body) =>
      if !err and response.statusCode is 200
        users = body.holidays.map (user) => @user_output_string(user, today)
        callback(err, users)
      else
        callback(err, null)
    return

  date_plus_as_string: (date, days) ->
    new_day = new Date(date.setDate(date.getDate() + days))
    new_day.toISOString().split('T')[0]

  treat_as_utc: (date) ->
    result = new Date(date)
    result.setMinutes(result.getMinutes() - result.getTimezoneOffset())

  days_between: (startDate, endDate) ->
    millisecondsPerDay = 24 * 60 * 60 * 1000
    (@treat_as_utc(endDate) - @treat_as_utc(startDate)) / millisecondsPerDay

  user_output_string: (user, today) ->
    extended = ''
    if user.duration <= 0.5
      extended = '1/2 day'
      extended += ' (AM)'  if user.endType is 'Morning'
      extended += ' (PM)'  if user.endType is 'Afternoon'
    else
      to = new Date(user.endDate)
      remaining = Math.round(@days_between(today, to))
      remaining = 'no' if remaining is 0
      pluralize = if remaining is 1 then 'day' else 'days'
      extended += "#{remaining} #{pluralize} left"

    "*#{user.userName}* _#{user.leaveType}, #{extended}_"

module.exports = Timetastic
