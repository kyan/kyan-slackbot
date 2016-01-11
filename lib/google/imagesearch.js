var Google = require('googleapis');
var customsearch = Google.customsearch('v1');

module.exports = function(query) {
  this.query = query

  this.search = function (callback) {
    var params = {
      auth: process.env.GOOGLE_API_KEY,
      cx: process.env.GOOGLE_CX,
      q: this.query,
      fields: 'items(link)',
      searchType: 'image',
      safe: 'high',
      imgSize: 'medium'
    }

    customsearch.cse.list(params, function(err, resp) {
      if (err) {
        console.log('An error occured', err);
        return;
      }
      // Got the response from custom search
      if (resp.items && resp.items.length > 0) {
        var images = resp.items.map(function(item) {
          return item.link;
        });
        var image = images[Math.floor(Math.random()*images.length)];
        return callback(image);
      }
    });
  }
}
