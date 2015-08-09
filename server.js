var koa = require('koa');
var router = require('koa-route');
var views = require('koa-views');
var request = require('co-request');
var serve = require('koa-static');
var soundcloud = require('./soundcloud/api-client');

var app = koa();

app.use(serve('./public'));

app.use(views('views', {
    map: {
        html: 'underscore',
    }
}));

app.use(router.get('/', index));
app.use(router.get('/feed', feed));
app.use(router.get('/connect', connect));
app.use(router.get('/callback', callback));

function *index() {
    var token = this.cookies.get('access_token');
    var response = yield soundcloud.fetchActivities(token);
    if (response.statusCode === 401) {
        return this.redirect('/connect');
    }
    var result = parseSoundcloudActivities(JSON.parse(response.body));
    yield this.render('feed', {context: JSON.stringify(result)});
}

function *feed() {
    var token = this.cookies.get('access_token');
    var response = yield request(this.request.query.nextLink+'&oauth_token='+token);
    if (response.statusCode === 401) {
        return this.redirect('/connect');
    }
    this.body = parseSoundcloudActivities(JSON.parse(response.body));
}

function parseSoundcloudActivities(activities) {
    var tracks = activities.collection.map(function (activity) {
        return activity.origin;
    });

    return {
        tracks: tracks,
        next_href: activities.next_href,
    };
}

function *connect() {
    yield this.render('connect', {
        client_id: process.env.SOUNDCLOUD_CLIENT_ID,
        redirect_uri: process.env.MUSICFEED_API_ROOT + '/callback',
        response_type: 'code'
    });
}

function *callback() {
    var code = this.query.code;
    var response = yield soundcloud.requestAccessToken(code);
    this.cookies.set('access_token', response.body.access_token, { httpOnly: false });
    this.redirect('/');
}

app.listen(process.env.PORT || 3000);
