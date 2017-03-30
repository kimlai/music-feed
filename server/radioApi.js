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
router.post('/email-availability', checkEmailAvailabilty);
router.post('/login', login);
router.get('/me', jwt({ secret: process.env.JWT_SECRET }), me);
router.post('/likes', jwt({ secret: process.env.JWT_SECRET }), addLike);
router.get('/likes', jwt({ secret: process.env.JWT_SECRET }), likes);

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

    var userByEmail = yield knex('users')
        .first('*')
        .where('email', '=', submitted.email);

    var userByUsername = yield knex('users')
        .first('*')
        .where('username', '=', submitted.username);

    if (userByEmail || userByUsername) {
        this.status = 400;
        var errors = [];
        if (userByEmail) {
            errors = errors.concat({ field: 'email', error:  "Email is already taken" });
        }
        if (userByUsername) {
            errors = errors.concat({ field: 'username', error : "Username is already taken" });
        }
        this.body = errors;
        return;
    }

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

function *checkEmailAvailabilty() {
    var email = this.request.body.email;
    var username = this.request.body.username;

    var userByEmail = yield knex('users')
        .first('*')
        .where('email', '=', email);

    var userByUsername = yield knex('users')
        .first('*')
        .where('username', '=', username);

    this.status = 200;
    this.body = {
        email: !userByEmail,
        username: !userByUsername,
    };
}

function *login() {
    var submitted = this.request.body;

    var user = yield knex('users')
        .first('*')
        .where('email', '=', submitted.usernameOrEmail)
        .orWhere('username', '=', submitted.usernameOrEmail)

    if (!user) {
        this.status = 400;
        this.body = [{ field: 'emailOrUsername', error: 'Unkwown username or E-mail' }];
        return;
    }

    var match = yield bcrypt.compare(submitted.password, user.password);

    if (!match) {
        this.status = 400;
        this.body = [{ field: 'password', error: 'Invalid password' }];
        return;
    }

    var token = jwt.sign({ username: user.username, email: user.email, uuid: user.uuid }, process.env.JWT_SECRET);

    this.status = 200;
    this.body = { token: token };
}

function *me() {
    this.status = 200;
    this.body = this.state.user;
}

function *addLike() {
    var submitted = this.request.body;
    var userUuid = this.state.user.uuid;

    yield knex.insert({
        user_uuid: userUuid,
        track_id: submitted.trackId,
        created_at: new Date(),
    }).into('likes'),

    this.status = 201;
    this.body = {};
}

function *likes() {
    var userUuid = this.state.user.uuid;

    var likedTracks = yield knex.select('published_tracks.*', 'likes.created_at')
        .from('likes')
        .innerJoin('published_tracks', 'likes.track_id', 'published_tracks.soundcloudTrackId')
        .orderBy('likes.created_at', 'asc')
        .then(function (rows) {
            return _.map(rows, function (row) {
                console.log(row);
                var track = row.track;
                track.created_at = row.created_at;
                track.id = row.soundcloudTrackId;
                return track;
            });
        });

    this.body = {
        tracks: likedTracks,
        next_href: ''
    };
}

module.exports = app;
