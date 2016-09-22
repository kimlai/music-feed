var fetchRadioPlaylist = require('./radio');
var koa = require('koa');
var router = require('koa-router')();

var app = koa();

router.get('/', radio);
router.get('/playlist', radioPlaylist);

app.use(router.routes());

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

module.exports = app;
