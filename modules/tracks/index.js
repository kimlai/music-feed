var getters = require('./getters');
var actions = require('./actions');

var FeedStore = require('./stores/FeedStore');
var SavedTracksStore = require('./stores/SavedTracksStore');
var TrackStore = require('./stores/TrackStore');
var CurrentTrackIdStore = require('./stores/CurrentTrackIdStore');
var CurrentPlaylistIdStore = require('./stores/CurrentPlaylistIdStore');

module.exports = {
    actions: actions,
    getters: getters,
    register: function(reactor) {
        reactor.registerStores({
            'feed': FeedStore,
            'savedTracks': SavedTracksStore,
            'tracks': TrackStore,
            'currentTrackId': CurrentTrackIdStore,
            'currentPlaylistId': CurrentPlaylistIdStore,
        });
    }
};
