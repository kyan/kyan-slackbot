req = require('request')

class Timetastic
  request: req

  away: (opt, callback) ->
    cmd = opt.when or 'today'
    amt = 0
    amt = 1 if cmd is 'tomorrow'
    date_string = @today_and(amt).toISOString().split('T')[0]

    request_options =
      url: 'https://app.timetastic.co.uk/api/holidays'
      json: true
      headers:
        'Authorization': "Bearer #{process.env.TIMETASTIC_TOKEN}"
      qs:
        start: "#{date_string}T00:00:01Z"
        end: "#{date_string}T23:59:59Z"
        status: 'Approved'

    @request request_options, (err, response, body) ->
      if !err and response.statusCode is 200
        users = body.holidays.map (user) ->
          "*#{user.userName}* #{user.leaveType}"
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
        if err
          console.log 'error: '+ response.statusCode
          console.log body
    return

  today_and: (days) ->
    today = new Date()
    new Date(today.setDate(today.getDate() + days))

module.exports = Timetastic
