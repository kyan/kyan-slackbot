chai = require "chai"
sinon = require "sinon"
sinonChai = require "sinon-chai"
expect = chai.expect
chai.use sinonChai
moment = require "moment-timezone"

process.env.NODE_ENV = 'test'

time_helper = require '../lib/harvest/time_helper'

describe 'time_helper', ->
  describe '#in_core_hours', ->
    it 'should return true during the morning', () ->
      now = moment({ year: 2016, month: 3, day: 15, hour: 10, minute: 10 })
      expect(time_helper.in_core_hours(now)).to.eql true

    it 'should return true during the afternoon', () ->
      now = moment({ year: 2016, month: 3, day: 15, hour: 15, minute: 10 })
      expect(time_helper.in_core_hours(now)).to.eql true

    it 'should return false during lunch', () ->
      now = moment({ year: 2016, month: 3, day: 15, hour: 12, minute: 10 })
      expect(time_helper.in_core_hours(now)).to.eql false

    it 'should return false after five', () ->
      now = moment({ year: 2016, month: 3, day: 15, hour: 17, minute: 10 })
      expect(time_helper.in_core_hours(now)).to.eql false

    it 'should return false on Saturday', () ->
      now = moment({ year: 2016, month: 3, day: 9, hour: 10, minute: 10 })
      expect(time_helper.in_core_hours(now)).to.eql false

    it 'should return false on Sunday', () ->
      now = moment({ year: 2016, month: 3, day: 10, hour: 10, minute: 10 })
      expect(time_helper.in_core_hours(now)).to.eql false
