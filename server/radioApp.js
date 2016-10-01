var bodyParser = require('koa-bodyparser');
var fetchPublishedTracks = require('./publishedTracks');
var fetchRadioPlaylist = require('./radio');
var knexfile = require('../knexfile');
var knex = require('knex')(knexfile);
var koa = require('koa');
var router = require('koa-router')();
var soundcloud = require('../soundcloud/api-client');
var _ = require('lodash');

var app = koa();

app.use(bodyParser());

router.get('/', radio);
router.get('/playlist', radioPlaylist);
router.get('/latest-tracks', latestTracks);
router.post('/report-dead-track', reportDeadTrack);

app.use(router.routes());

app.use(function *redirectNotFoundToRadio(next) {
    yield next;

    if (this.status != 404) {
        return;
    }

    yield radio.call(this);
});

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

function *latestTracks() {
    var soundcloudUserId = process.env.ADMIN_SOUNDCLOUD_ID;
    var offset = parseInt(this.request.query.offset, 0) || 0;
    var tracks = yield fetchPublishedTracks(soundcloudUserId, this.request.query.offset);
    this.body = {
        tracks: tracks,
        next_href: '/latest-tracks?offset=' + (offset + 20),
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

module.exports = app;
