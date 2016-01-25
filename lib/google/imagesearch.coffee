Google = require('googleapis')

module.exports = (query) ->
  this.query = query
  this.customsearch = Google.customsearch('v1')

  this.search = (callback) =>
    params =
      auth: process.env.GOOGLE_API_KEY,
      cx: process.env.GOOGLE_CX,
      q: this.query,
      fields: 'items(link)',
      searchType: 'image',
      safe: 'high',
      imgSize: 'medium',
      imgType: 'photo'

    this.customsearch.cse.list params, (err, resp) =>
      return this._logme(err) if err

      # Got the response from custom search
      if resp.items && resp.items.length > 0
        images = resp.items.map (item) -> item.link
        callback images[Math.floor(Math.random()*images.length)]

  this._logme = (err) ->
    if process.env.NODE_ENV isnt 'test'
        console.log('An error occured', err)
  return
