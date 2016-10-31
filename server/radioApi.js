var bodyParser = require('koa-bodyparser');
var fetchPublishedTracks = require('./publishedTracks');
var fetchRadioPlaylist = require('./radio');
var knexfile = require('../knexfile');
var knex = require('knex')(knexfile);
var koa = require('koa');
var router = require('koa-router')();
var soundcloud = require('../soundcloud/api-client');
var _ = require('lodash');
var bcrypt = require('co-bcrypt');
var uuid = require('node-uuid').v4;
var jwt = require('koa-jwt');

var app = koa();

app.use(bodyParser());

router.get('/playlist', radioPlaylist);
router.get('/latest-tracks', latestTracks);
router.post('/report-dead-track', reportDeadTrack);
router.post('/users', signup);
router.post('/login', login);
router.get('/protected', jwt({ secret: process.env.JWT_SECRET }), protectedRoute);

app.use(router.routes());

function *radioPlaylist() {
    var soundcloudUserId = process.env.ADMIN_SOUNDCLOUD_ID;
    this.body = yield fetchRadioPlaylist(soundcloudUserId);
}

function *latestTracks() {
    var soundcloudUserId = process.env.ADMIN_SOUNDCLOUD_ID;
    var offset = parseInt(this.request.query.offset, 0) || 0;
    var tracks = yield fetchPublishedTracks(soundcloudUserId, this.request.query.offset);
    this.body = {
        tracks: tracks,
        next_href: '/api/latest-tracks?offset=' + (offset + 20),
    };
}

function *reportDeadTrack() {
    var trackId = this.request.body.trackId;
    track = yield knex('published_tracks')
        .select('track')
        .where('soundcloudTrackId', '=', trackId)
        .then(function (rows) {
            return _.head(
                rows.map(function (row) {
                    return row.track;
                })
            );
        });

    if (track && track.soundcloud) {
        yield soundcloud.track(trackId)
            .catch(function (error) {
                if (error.status === 404 || error.status === 403) {
                    return knex('published_tracks')
                        .where('soundcloudTrackId', '=', trackId)
                        .update({ dead: true });
                }
            });
    }

    this.status = 201;
    this.body = "OK";
}

function *signup() {
    var submitted = this.request.body;
    var salt = yield bcrypt.genSalt()
    var hash = yield bcrypt.hash(submitted.password, salt)

    yield knex.insert({
        uuid: uuid(),
        username: submitted.username,
        email: submitted.email,
        password: hash,
    }).into('users'),

    this.status = 201;
    this.body = {};
}


function *login() {
    var submitted = this.request.body;

    var user = yield knex('users')
        .first('*')
        .where('email', '=', submitted.usernameOrEmail)
        .orWhere('username', '=', submitted.usernameOrEmail)

    this.assert(user, 400, 'non registered email');

    var match = yield bcrypt.compare(submitted.password, user.password);

    this.assert(match, 400, 'invalid password');

    var token = jwt.sign({ username: user.username, email: user.email, uuid: user.uuid }, process.env.JWT_SECRET);

    this.status = 200;
    this.body = { token: token };
}

function *protectedRoute() {
    this.status = 200;
    this.body = "Protected";
}

module.exports = app;
