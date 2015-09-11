var getters = require('./getters');
var actions = require('./actions');

var PlaylistStore = require('./stores/PlaylistStore');
var TrackStore = require('./stores/TrackStore');
var PlaybackStatusStore = require('./stores/PlaybackStatusStore');
var CurrentTrackIdStore = require('./stores/CurrentTrackIdStore');
var CurrentPlaylistIdStore = require('./stores/CurrentPlaylistIdStore');

module.exports = {
    actions: actions,
    getters: getters,
    register: function(reactor) {
        reactor.registerStores({
            'playlists': PlaylistStore,
            'tracks': TrackStore,
            'playbackStatus': PlaybackStatusStore,
            'currentTrackId': CurrentTrackIdStore,
            'currentPlaylistId': CurrentPlaylistIdStore,
        });
    }
};
