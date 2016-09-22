var fetchPublishedTracks = require('./publishedTracks');
var fetchRadioPlaylist = require('./radio');
var koa = require('koa');
var router = require('koa-router')();

var app = koa();

router.get('/', radio);
router.get('/playlist', radioPlaylist);
router.get('/latest-tracks', latestTracks);

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
    this.body = yield fetchPublishedTracks(soundcloudUserId, this.request.query.offset);
}

module.exports = app;
