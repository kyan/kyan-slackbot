# Kyan Slackbot

This is the office SlackBot.

## Development

If you want to add a new feature, you will need to create a new branch which
will a new PR can be created against on Github. You can run the bot locally
by changing into the route of the project and:

```
# install node.js
$ brew install node

# install npm's
$ npm install

# create .env using the .env.sample. You will need to fill in the ENV's
# start the app
$ heroku local web

```

## Deployment

The app currently runs on Heroku. Deployment is automatic when something is
merged into the ```master``` branch.

## Tests

Work in progress
