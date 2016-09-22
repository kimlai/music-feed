var _ = require('lodash');
var bodyParser = require('koa-bodyparser');
var fetchFeed = require('./feed');
var fetchPublishedTracks = require('./publishedTracks');
var fetchSavedTracks = require('./savedTracks');
var knexfile = require('../knexfile');
var knex = require('knex')(knexfile);
var koa = require('koa');
var request = require('co-request');
var router = require('koa-router')();
var soundcloud = require('../soundcloud/api-client');

var app = koa();

app.use(bodyParser());

router.get('/connect', connect);
router.get('/callback', callback);
router.get('/', requireAuthentication, index);
router.get('/feed', requireAuthentication, feed);
router.get('/saved_tracks', requireAuthentication, savedTracks);
router.get('/published_tracks', requireAuthentication, publishedTracks);
router.post('/blacklist', requireAuthentication, blacklist);
router.post('/save_track', requireAuthentication, saveTrack);
router.post('/publish_track', requireAuthentication, publishTrack);

app.use(router.routes());

app.use(function *redirectNotFoundToIndex(next) {
    yield next;

    if (this.status != 404) {
        return;
    }

    yield index.call(this, requireAuthentication.call(this));
});

function *requireAuthentication(next) {
    var token = this.cookies.get('access_token');
    try {
        this.state.user = yield soundcloud.me(token);
    } catch (error) {
        if (error.status === 401) {
            return this.redirect('/feed/connect');
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
        redirect_uri: process.env.MUSICFEED_API_ROOT + '/feed/callback',
        response_type: 'code'
    });
}

function *callback() {
    var code = this.query.code;
    var tokens = yield soundcloud.requestAccessToken(code);
    this.cookies.set('access_token', tokens.access_token, { httpOnly: false });
    this.redirect('/feed');
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

module.exports = app;