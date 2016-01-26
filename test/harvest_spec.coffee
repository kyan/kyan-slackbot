chai = require "chai"
sinon = require "sinon"
sinonChai = require "sinon-chai"
expect = chai.expect
chai.use sinonChai

process.env.NODE_ENV = 'test'
process.env.HARVEST_SUBDOMAIN = 'kyan'
process.env.HARVEST_EMAIL = 'a@b.com'
process.env.HARVEST_PASSWORD = 'password'

tasks = require '../lib/harvest/tasks'

describe 'Tasks', ->
  task = new tasks()

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
