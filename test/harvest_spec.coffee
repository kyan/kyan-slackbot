chai = require "chai"
sinon = require "sinon"
sinonChai = require "sinon-chai"
expect = chai.expect
chai.use sinonChai

process.env.NODE_ENV = 'test'
process.env.HARVEST_SUBDOMAIN = 'kyan'
process.env.HARVEST_EMAIL = 'a@b.com'
process.env.HARVEST_PASSWORD = 'password'

Tasks = require '../lib/harvest/tasks'

describe 'Tasks', ->
  task = new Tasks()

  describe '#_fullname()', ->
    it 'should return the fullname of the user', ->
      user =
        first_name: 'John'
        last_name: 'Doe'
      expect(task._fullname(user)).to.equal('John Doe')

  describe '#_decical_to_hours()', ->
    it 'should return a hours:min string', ->
      expect(task._decical_to_hours(1.5)).to.equal('1:30')
      expect(task._decical_to_hours(1)).to.equal('1:00')
      expect(task._decical_to_hours(0.5)).to.equal('0:30')
      expect(task._decical_to_hours(11.25)).to.equal('11:15')

  describe '#_format_task_entry()', ->
    it 'should correctly format a full message', ->
      entry =
        fullname: 'John Doe'
        hours: 1.5
        client: 'Client'
        task: 'A Task'
        project: 'A Project'
        notes: 'A Note'

      expect(task._format_task_entry(entry)).to
        .equal('*1:30* : John Doe | - Client - _A Note_')

    it 'should correctly format a partial message', ->
      entry =
        hours: 1.5
        client: 'Client'
        task: 'A Task'
        project: ''
        notes: 'A Note'

      expect(task._format_task_entry(entry)).to
        .equal('*1:30* - Client - A Task - _A Note_')

    it 'should correctly format a partial message for not running', ->
      entry =
        not_running: true
        fullname: 'John Doe'
        hours: 1.5

      expect(task._format_task_entry(entry)).to
        .equal(':ZZZ: : *John Doe*')

  describe '#_currently_running_task()', ->
    it 'should return the currently running task', ->
      e1 = name: 'e1'
      e2 = name: 'e2', timer_started_at: true
      e3 = name: 'e3'
      entries = [ e1, e2, e3 ]
      expect(task._currently_running_task(entries)).to.equal(e2)

  describe '#_yesterday_as_date()', ->
    it 'should return fri as date when mon', ->
      date = new Date('Mon, 13 Oct 2014 10:13:00 GMT')
      expect(task._yesterday_as_date(date).toUTCString()).to
        .equal('Fri, 10 Oct 2014 10:13:00 GMT')

    it 'should return tue as date when wed', ->
      date = new Date('Wed, 15 Oct 2014 10:13:00 GMT')
      expect(task._yesterday_as_date(date).toUTCString()).to
        .equal('Tue, 14 Oct 2014 10:13:00 GMT')

  describe '#_yesterday_as_str()', ->
    it 'should return fri as date when mon', ->
      date = new Date('Mon, 13 Oct 2014 10:13:00 GMT')
      expect(task._yesterday_as_str(date)).to
        .equal('20141010')

    it 'should return tue as date when wed', ->
      date = new Date('Wed, 15 Oct 2014 10:13:00 GMT')
      expect(task._yesterday_as_str(date)).to
        .equal('20141014')

  describe '#prompt()', ->
    it 'should prompt the user', ->
      response =
        channel:
          id: 'channel1'
      userid = 'x1234'
      bot =
        api:
          im:
            open: (ops, cb) ->
              return cb null, response
      callback = sinon.spy()
      task.prompt(userid, bot, callback)

      expect(callback.called).to.be.true
      expect(callback).to.have.been.calledWith(
        channel: "channel1"
        icon_emoji: ":sadsmile:"
        text: "Hey. It looks like you're not recording any hours at the moment?"
        username: "HarvestBot"
      )

  describe '#daily()', ->
    it 'should return a tasks when opt[running] pass in', ->
      e1 = name: 'e1'
      e2 = name: 'e2', timer_started_at: true
      e3 = name: 'e3'
      user = id: 'abc123', first_name: 'John', last_name: 'Doe'
      opts = { running: true }
      tasks =
        tasks:
          day_entries: [ e1, e2, e3 ]
      task.harvest =
        TimeTracking:
          daily: (h_opts, cb) ->
              return cb null, tasks
      callback = sinon.spy()
      task.daily(user, opts, callback)

      expect(callback.called).to.be.true

  describe '#_is_user_online', ->
    it 'should return true if the user is active in Slack', (done) ->
      bot =
        api:
          users:
            getPresence: (ops, callback) ->
              callback(null, { presence: 'active' })
      user =
        first_name: 'John'
        last_name: 'Doe'
      task._is_user_online user, bot, (err, result) ->
        expect(result).to.be.true
        done()

    it 'should return false if the user is inactive in Slack', (done) ->
      bot =
        api:
          users:
            getPresence: (ops, callback) ->
              callback(null, { presence: 'inactive' })
      user =
        first_name: 'John'
        last_name: 'Doe'
      task._is_user_online user, bot, (err, result) ->
        expect(result).to.be.false
        done()

  describe '#_is_user_away', ->
    json = '{"U0HLJHWJW":{"email":"alice@example.com","tt":"234567"},"U0HLGQMBK":{"email":"bob@example.com","tt":"123456"}}'
    process.env.SLACK_HARVEST_MAPPER = json
    user =
      id: 456789
      email: 'bob@example.com'

    it 'should return true if the user is on the holiday list', () ->
      expect(task._is_user_away user, [123456, 234567]).to.be.true

    it 'should return false if the user is unknown', () ->
      expect(task._is_user_away user, [123456, 234567]).to.be.true

    it 'should return false if the user is NOT on the holiday list', () ->
      expect(task._is_user_away user, [345678, 456789]).to.be.false
