var toImmutable = require('nuclear-js').toImmutable;
var Store = require('nuclear-js').Store;
var RECEIVE_SAVED_TRACKS = require('../actionTypes').RECEIVE_SAVED_TRACKS;
var BLACKLIST_TRACK_REQUEST = require('../actionTypes').BLACKLIST_TRACK_REQUEST;
var BLACKLIST_TRACK_SUCCESS = require('../actionTypes').BLACKLIST_TRACK_SUCCESS;
var BLACKLIST_TRACK_FAILURE = require('../actionTypes').BLACKLIST_TRACK_FAILURE;

module.exports = new Store({
    getInitialState: function () {
        return toImmutable({
            tracks: [],
            pendingTracks: []
        });
    },

    initialize: function () {
        this.on(RECEIVE_SAVED_TRACKS, receiveSavedTracks);
        this.on(BLACKLIST_TRACK_REQUEST, blacklistTrack);
        this.on(BLACKLIST_TRACK_FAILURE, blacklistTrackRollback);
        this.on(BLACKLIST_TRACK_SUCCESS, blacklistTrackSuccess);
    }
});

function receiveSavedTracks(state, tracks) {
    var newTracks = toImmutable(tracks)
        .map(function (track) {
            return track.get('id');
        })
        .toList();

    return state.updateIn(['tracks'], function (tracks) {
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
