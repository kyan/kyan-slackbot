moment = require('moment-timezone')

module.exports = {
  now_in_tz: (timezone) ->
    moment().tz(timezone)

  now_in_uk: () ->
    moment().tz('Europe/London')

  in_core_hours: (now) ->
    (now.isoWeekday() < 6) && ((now.hour() >= 9 && now.hour() < 12) || (now.hour() >= 14 && now.hour() < 17))
}
