var toImmutable = require('nuclear-js').toImmutable;
var Store = require('nuclear-js').Store;
var RECEIVE_FEED = require('../actionTypes').RECEIVE_FEED;
var BLACKLIST_TRACK_REQUEST = require('../actionTypes').BLACKLIST_TRACK_REQUEST;
var BLACKLIST_TRACK_SUCCESS = require('../actionTypes').BLACKLIST_TRACK_SUCCESS;
var BLACKLIST_TRACK_FAILURE = require('../actionTypes').BLACKLIST_TRACK_FAILURE;

module.exports = new Store({
    getInitialState: function () {
        return toImmutable({
            tracks: [],
            nextLink: null,
            pendingTracks: []
        });
    },

    initialize: function () {
        this.on(RECEIVE_FEED, receiveFeed);
        this.on(BLACKLIST_TRACK_REQUEST, blacklistTrack);
        this.on(BLACKLIST_TRACK_FAILURE, blacklistTrackRollback);
        this.on(BLACKLIST_TRACK_SUCCESS, blacklistTrackSuccess);
    }
});

function receiveFeed(state, feed) {
    var newTracks = toImmutable(feed.tracks)
        .map(function (track) {
            return track.get('id');
        })
        .toList();

    return state
        .set('nextLink', feed.next_href)
        .updateIn(['tracks'], function (tracks) {
            return tracks.concat(newTracks);
        });
}

function blacklistTrack(state, payload) {
    var currentTracks = state.get('tracks');
    return state.updateIn(['tracks'], function (tracks) {
        return tracks.filterNot(function (trackId) {
            return trackId === payload.trackId;
        });
    })
    .set('pendingTracks', currentTracks);
}

function blacklistTrackSuccess(state, payload) {
    return state.set('pendingTracks', toImmutable([]));
}

function blacklistTrackRollback(state, payload) {
    return state
        .set('tracks', state.get('pendingTracks'))
        .set('pendingTracks', toImmutable([]));
}
