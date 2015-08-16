var koa = require('koa');
var router = require('koa-router')();
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

router.get('/connect', connect);
router.get('/callback', callback);
router.get('/', requireAuthentication, index);
router.get('/feed', requireAuthentication, feed);

app.use(router.routes());

function *requireAuthentication(next) {
    var token = this.cookies.get('access_token');
    var response = yield soundcloud.me(token);
    if (response.statusCode === 401) {
        return this.redirect('/connect');
    }
    this.state.token = token;
    yield next;
}

function *index() {
    var token = this.state.token;
    var response = yield soundcloud.fetchActivities(token);
    var result = parseSoundcloudActivities(JSON.parse(response.body));
    yield this.render('feed', {context: JSON.stringify(result)});
}

function *feed() {
    var token = this.state.token;
    var response = yield request(this.request.query.nextLink+'&oauth_token='+token);
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
