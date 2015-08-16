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
    try {
        var user = yield soundcloud.me(token);
    } catch (error) {
        if (error.status === 401) {
            return this.redirect('/connect');
        }
    }
    this.state.token = token;
    yield next;
}

function *index() {
    var token = this.state.token;
    var feed = yield soundcloud
        .fetchActivities(token)
        .then(parseSoundcloudActivities);

    yield this.render('feed', {context: JSON.stringify(feed)});
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
    var tokens = yield soundcloud.requestAccessToken(code);
    this.cookies.set('access_token', tokens.access_token, { httpOnly: false });
    this.redirect('/');
}

app.listen(process.env.PORT || 3000);
