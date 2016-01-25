chai = require "chai"
sinon = require "sinon"
sinonChai = require "sinon-chai"
expect = chai.expect
chai.use sinonChai
img_search = require '../lib/google/imagesearch'

process.env.NODE_ENV = 'test'

describe 'ImageSearch', ->
  describe '#search()', ->
    q = 'fish'
    imgsearch = new img_search(q)
    imgsearch.customsearch =
      cse:
        list: (ops, cb) ->
          return cb null,
            items: [{ link: 'link2' }]

    it 'should store the query passed in', ->
      expect(imgsearch.query).to.equal(q)

    it 'should return a random image', ->
      callback = sinon.spy()
      imgsearch.search(callback)
      expect(callback).to.have.been.calledWith('link2')

    it 'should correctly return an error', ->
      imgsearch.customsearch =
        cse:
          list: (ops, cb) ->
            return cb 'error', null

      callback = sinon.spy()
      imgsearch.search(callback)
      expect(callback.called).to.be.false
