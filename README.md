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

### Debugging

You can debug the app whilst it's running. This is really helpful and uses the
Chrome devtools. You just need to start the app in a slightly different way.

Debugging uses the `node-inspector`. You first start the app with:

```
$ heroku local debug
```

In a seperate terminal window you should run:

```
$ node-inspector
Node Inspector v0.12.5
Visit http://127.0.0.1:8080/?ws=127.0.0.1:8080&port=5858 to start debugging.
```

If you visit the url in Chrome as requested you will see the devtools open and
ready to go with your app loaded. You can add break points etc. It's really smart.

### Tests

Work in progress

## Options

You can see what the bot can do once running useing the command:

```
help

```
