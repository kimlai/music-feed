var koa = require('koa');
var mount = require('koa-mount');
var radioApi = require('./radioApi');
var fetchRadioPlaylist = require('./radio');

var app = koa();

app.use(mount('/api', radioApi));

app.use(function *redirectNotFoundToIndex(next) {
    yield next;

    if (this.status != 404) {
        return;
    }

    var soundcloudUserId = process.env.ADMIN_SOUNDCLOUD_ID;
    var playlist = yield fetchRadioPlaylist(soundcloudUserId);
    yield this.render('radio', {
        client_id: process.env.SOUNDCLOUD_CLIENT_ID,
        playlist: JSON.stringify(playlist)
    });
});

module.exports = app;
