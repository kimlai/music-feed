var koa = require('koa');
var router = require('koa-route');
var views = require('koa-views');
var request = require('co-request');
var JSX = require('node-jsx').install();
var React = require('react');
var Feed = require('./components/Feed.react');
var serve = require('koa-static');

var app = koa();

app.use(serve('./public'));

app.use(views('views', {
    map: {
        html: 'underscore',
    }
}));

app.use(router.get('/', feed));
app.use(router.get('/connect', connect));
app.use(router.get('/callback', callback));

function *feed() {
    var token = this.cookies.get('access_token');
    var response = yield request('https://api.soundcloud.com/me/activities/tracks/affiliated?oauth_token='+token);
    if (response.statusCode === 401) {
        return this.redirect('/connect');
    }
    var tracks = JSON.parse(response.body).collection.map(function (activity) {
        return activity.origin;
    });
    var feedHtml = '';
//    var feedHtml = React.renderToString(
//        React.createElement(Feed, {
//            tracks: tracks
//        })
//    );

    yield this.render('feed', {feedHtml: feedHtml, context: JSON.stringify(tracks)});
}

function *connect() {
    yield this.render('connect', {
        client_id: process.env.SOUNDCLOUD_CLIENT_ID,
        redirect_uri: 'http://localhost:3000/callback',
        response_type: 'code'
    });
}

function *callback() {
    var code = this.query.code;
    var response = yield request.post({
        uri: 'https://api.soundcloud.com/oauth2/token',
        json: {
            client_id: process.env.SOUNDCLOUD_CLIENT_ID,
            client_secret: process.env.SOUNDCLOUD_SECRET,
            grant_type: 'authorization_code',
            redirect_uri: 'http://localhost:3000/callback',
            code: code
        }
    });
    this.cookies.set('access_token', response.body.access_token, { httpOnly: false });
    this.redirect('/');
}

app.listen(3000);
