chai = require "chai"
sinon = require "sinon"
sinonChai = require "sinon-chai"
expect = chai.expect
chai.use sinonChai

process.env.NODE_ENV = 'test'

timetastic = require '../lib/timetastic/index'

describe 'Timetastic', ->
  tt = new timetastic()

  describe '#date_plus_as_string()', ->
    it 'should return the date as a string plus days', ->
      date = new Date('Wed, 15 Oct 2014 10:13:00 GMT')
      expect(tt.date_plus_as_string(date, 2)).to.equal('2014-10-17')

    it 'should return the date as a string minus days', ->
      date = new Date('Wed, 15 Oct 2014 10:13:00 GMT')
      expect(tt.date_plus_as_string(date, -1)).to.equal('2014-10-14')

  describe '#user_output_string()', ->
    it 'should return output when person has 1/2 day AM', ->
      today = new Date('2016-02-05T00:00:00')
      user =
        userName: 'Jon Doe'
        leaveType: 'Holiday'
        duration: 0.5
        endType: 'Morning'
        startDate: "2016-02-05T00:00:00",
        endDate: "2016-02-05T00:00:00",
      expect(tt.user_output_string(user, today)).to.equal('*Jon Doe* _Holiday, 1/2 day (AM)_')

    it 'should return output when person has 1/2 day PM', ->
      today = new Date('2016-02-05T00:00:00')
      user =
        userName: 'Jon Doe'
        leaveType: 'Holiday'
        duration: 0.5
        endType: 'Afternoon'
        startDate: "2016-02-05T00:00:00",
        endDate: "2016-02-05T00:00:00",
      expect(tt.user_output_string(user, today)).to.equal('*Jon Doe* _Holiday, 1/2 day (PM)_')

    it 'should return output when person has 1 day remaining', ->
      today = new Date('2016-02-08T00:00:00')
      user =
        userName: 'Jon Doe'
        leaveType: 'Holiday'
        duration: 3
        endType: 'Afternoon'
        startDate: '2016-02-07T00:00:00'
        endDate: '2016-02-09T00:00:00'
      expect(tt.user_output_string(user, today)).to.equal('*Jon Doe* _Holiday, 1 day left_')

    it 'should return output when person has 0 days remaining', ->
      today = new Date('2016-02-09T00:00:00')
      user =
        userName: 'Jon Doe'
        leaveType: 'Holiday'
        duration: 3
        endType: 'Afternoon'
        startDate: '2016-02-07T00:00:00'
        endDate: '2016-02-09T00:00:00'
      expect(tt.user_output_string(user, today)).to.equal('*Jon Doe* _Holiday, no days left_')

    it 'should return output when person has 5 days remaining', ->
      today = new Date('2016-02-07T00:00:00')
      user =
        userName: 'Jon Doe'
        leaveType: 'Holiday'
        duration: 8
        endType: 'Afternoon'
        startDate: '2016-02-05T00:00:00'
        endDate: '2016-02-12T00:00:00'
      expect(tt.user_output_string(user, today)).to.equal('*Jon Doe* _Holiday, 5 days left_')

    it 'should return output when person has 8 days remaining', ->
      today = new Date('2016-01-28T00:00:00')
      user =
        userName: 'Jon Doe'
        leaveType: 'Holiday'
        duration: 11
        endType: 'Afternoon'
        startDate: '2016-01-25T00:00:00'
        endDate: '2016-02-05T00:00:00'
      expect(tt.user_output_string(user, today)).to.equal('*Jon Doe* _Holiday, 8 days left_')

  describe '#days_between()', ->
    it 'should return the days between', ->
      d1 = new Date('Sun, 15 Oct 2014 10:13:00 GMT')
      d2 = new Date('Wed, 19 Oct 2014 10:13:00 GMT')
      expect(tt.days_between(d1,d2)).to.equal(4)

      d1 = new Date('2016,5,10')
      d2 = new Date('2016,5,16')
      expect(tt.days_between(d1,d2)).to.equal(6)

      d1 = new Date('2016,5,16')
      d2 = new Date('2016,5,16')
      expect(tt.days_between(d1,d2)).to.equal(0)
