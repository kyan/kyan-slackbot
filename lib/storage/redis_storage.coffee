redis = require('redis') #https://github.com/NodeRedis/node_redis

module.exports = (config) ->
  config = config || {};
  config.namespace = config.namespace or 'botkit:store'

  storage = {}
  client = redis.createClient(config) # could pass specific redis config here
  methods = config.methods or ['teams', 'users', 'channels']

  # Implements required API methods
  for method in methods
    storage[method] = ((hash) ->
      get: (id, cb) ->
        client.hget config.namespace + ':' + hash, id, (err, res) ->
          cb err, JSON.parse(res)
      save: (object, cb) ->
        if !object.id # Silently catch this error?
          return cb new Error('The given object must have an id property', {})
        client.hset config.namespace + ':' + hash, object.id, JSON.stringify(object), cb
      all: (cb, options) ->
        client.hgetall config.namespace + ':' + hash, (err, res) ->
          return cb(err, {}) if err
          return cb(err, res) if null is res

          parsed
          array = []

          for item in res
            parsed = JSON.parse(item)
            item = parsed
            array.push(parsed)

          cb(err, options and options.type is 'object' ? res : array);
      allById: (cb) ->
        this.all cb, {type: 'object'}
    )(method)
  return storage
