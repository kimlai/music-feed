var koa = require('koa');
var router = require('koa-router')();
var views = require('koa-views');
var request = require('co-request');
var serve = require('koa-static');
var soundcloud = require('./soundcloud/api-client');
var knexfile = require('./knexfile');
var knex = require('knex')(knexfile);
var bodyParser = require('koa-bodyparser');
var fetchFeed = require('./server/feed');
var fetchSavedTracks = require('./server/savedTracks');
var fetchPublishedTracks = require('./server/publishedTracks');
var fetchRadioPlaylist = require('./server/radio');
var _ = require('lodash');

var app = koa();

app.use(serve('./public'));

app.use(views('views', {
    map: {
        html: 'underscore',
    }
}));

app.use(bodyParser());

router.get('/connect', connect);
router.get('/callback', callback);
router.get('/radio', radio);
router.get('/radio_playlist', radioPlaylist);
router.get('/', requireAuthentication, index);
router.get('/feed', requireAuthentication, feed);
router.get('/saved_tracks', requireAuthentication, savedTracks);
router.get('/published_tracks', requireAuthentication, publishedTracks);
router.post('/blacklist', requireAuthentication, blacklist);
router.post('/save_track', requireAuthentication, saveTrack);
router.post('/publish_track', requireAuthentication, publishTrack);

app.use(router.routes());

app.use(function *(next) {
    yield next;
    yield index.call(this, requireAuthentication.call(this));
});

function *requireAuthentication(next) {
    var token = this.cookies.get('access_token');
    try {
        this.state.user = yield soundcloud.me(token);
    } catch (error) {
        if (error.status === 401) {
            return this.redirect('/connect');
        }
    }
    this.state.token = token;
    yield next;
}

function *index() {
    yield this.render('feed', {
        client_id: process.env.SOUNDCLOUD_CLIENT_ID,
    });
}

function *radio() {
    var soundcloudUserId = process.env.ADMIN_SOUNDCLOUD_ID;
    var playlist = yield fetchRadioPlaylist(soundcloudUserId);
    yield this.render('radio', {
        client_id: process.env.SOUNDCLOUD_CLIENT_ID,
        playlist: JSON.stringify(playlist)
    });
}

function *radioPlaylist() {
    var soundcloudUserId = process.env.ADMIN_SOUNDCLOUD_ID;
    this.body = yield fetchRadioPlaylist(soundcloudUserId);
}

function *feed() {
    var token = this.state.token;
    var soundcloudUserId = this.state.user.id;
    this.body = yield fetchFeed(soundcloudUserId, token, this.request.query.nextLink);
}

function *savedTracks() {
    var token = this.state.token;
    var soundcloudUserId = this.state.user.id;
    this.body = yield fetchSavedTracks(soundcloudUserId, this.request.query.offset);
}

function *publishedTracks() {
    var token = this.state.token;
    var soundcloudUserId = this.state.user.id;
    this.body = yield fetchPublishedTracks(soundcloudUserId, this.request.query.offset);
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

function *blacklist() {
    var token = this.state.token;
    var soundcloudUserId = this.state.user.id;
    var soundcloudTrackId = this.request.body.soundcloudTrackId;
    yield Promise.all([
        knex.insert({
            soundcloudUserId: soundcloudUserId,
            soundcloudTrackId: soundcloudTrackId,
        }).into('blacklist'),
        knex.del()
            .where({
                soundcloudUserId: soundcloudUserId,
                soundcloudTrackId: soundcloudTrackId,
            })
            .from('saved_tracks'),
        knex.del()
            .where({
                soundcloudUserId: soundcloudUserId,
                soundcloudTrackId: soundcloudTrackId,
            })
            .from('published_tracks')
    ]);
    this.status = 201;
    this.body = "OK";
}

function *saveTrack() {
    var token = this.state.token;
    var soundcloudUserId = this.state.user.id;
    var soundcloudTrackId = this.request.body.soundcloudTrackId;
    yield Promise.all([
        soundcloud.track(soundcloudTrackId)
        .then(function (track) {
            return knex.insert({
                soundcloudUserId: soundcloudUserId,
                soundcloudTrackId: soundcloudTrackId,
                track : track,
                savedAt: new Date(),
            }).into('saved_tracks');
        }),
        knex.del()
            .where({
                soundcloudUserId: soundcloudUserId,
                soundcloudTrackId: soundcloudTrackId,
            })
            .from('published_tracks')
    ]);
    this.status = 201;
    this.body = "OK";
}

function *publishTrack() {
    var token = this.state.token;
    var soundcloudUserId = this.state.user.id;
    var soundcloudTrackId = this.request.body.soundcloudTrackId;
    yield Promise.all([
        soundcloud.track(soundcloudTrackId)
        .then(function (track) {
            return knex.insert({
                soundcloudUserId: soundcloudUserId,
                soundcloudTrackId: soundcloudTrackId,
                track : track,
                savedAt: new Date(),
            }).into('published_tracks');
        }),
        knex.del()
            .where({
                soundcloudUserId: soundcloudUserId,
                soundcloudTrackId: soundcloudTrackId,
            })
            .from('saved_tracks')
    ]);
    this.status = 201;
    this.body = "OK";
}

app.listen(process.env.PORT || 3000);
