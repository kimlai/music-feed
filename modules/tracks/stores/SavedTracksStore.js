var toImmutable = require('nuclear-js').toImmutable;
var Store = require('nuclear-js').Store;
var FETCH_SAVED_TRACKS_REQUEST = require('../actionTypes').FETCH_SAVED_TRACKS_REQUEST;
var FETCH_SAVED_TRACKS_FAILURE = require('../actionTypes').FETCH_SAVED_TRACKS_FAILURE;
var RECEIVE_SAVED_TRACKS = require('../actionTypes').RECEIVE_SAVED_TRACKS;
var PLAY_TRACK_REQUEST = require('../actionTypes').PLAY_TRACK_REQUEST;
var BLACKLIST_TRACK_REQUEST = require('../actionTypes').BLACKLIST_TRACK_REQUEST;
var BLACKLIST_TRACK_SUCCESS = require('../actionTypes').BLACKLIST_TRACK_SUCCESS;
var BLACKLIST_TRACK_FAILURE = require('../actionTypes').BLACKLIST_TRACK_FAILURE;
var SAVE_TRACK_REQUEST = require('../actionTypes').SAVE_TRACK_REQUEST;
var SAVE_TRACK_SUCCESS = require('../actionTypes').SAVE_TRACK_SUCCESS;
var SAVE_TRACK_FAILURE = require('../actionTypes').SAVE_TRACK_FAILURE;
var PUBLISH_TRACK_REQUEST = require('../actionTypes').PUBLISH_TRACK_REQUEST;
var PUBLISH_TRACK_SUCCESS = require('../actionTypes').PUBLISH_TRACK_SUCCESS;
var PUBLISH_TRACK_FAILURE = require('../actionTypes').PUBLISH_TRACK_FAILURE;

module.exports = new Store({
    getInitialState: function () {
        return toImmutable({
            id: 'savedTracks',
            tracks: [],
            nextTrack: null,
            pendingTracks: [],
            fetchingStatus: 'idle',
        });
    },

    initialize: function () {
        this.on(FETCH_SAVED_TRACKS_REQUEST, fetchTracksRequest);
        this.on(FETCH_SAVED_TRACKS_FAILURE, fetchTracksFailure);
        this.on(RECEIVE_SAVED_TRACKS, receiveTracks);
        this.on(PLAY_TRACK_REQUEST, onPlayTrackRequest);
        this.on(BLACKLIST_TRACK_REQUEST, removeTrack);
        this.on(BLACKLIST_TRACK_FAILURE, removeTrackRollback);
        this.on(BLACKLIST_TRACK_SUCCESS, removeTrackSuccess);
        this.on(SAVE_TRACK_REQUEST, addTrack);
        this.on(SAVE_TRACK_FAILURE, addTrackRollback);
        this.on(SAVE_TRACK_SUCCESS, addTrackSuccess);
        this.on(PUBLISH_TRACK_REQUEST, removeTrack);
        this.on(PUBLISH_TRACK_FAILURE, removeTrackRollback);
        this.on(PUBLISH_TRACK_SUCCESS, removeTrackSuccess);
    }
});

function fetchTracksRequest(state) {
    return state.set('fetchingStatus', 'fetching');
}

function fetchTracksFailure(state) {
    return state.set('fetchingStatus', 'failed');
}

function receiveTracks(state, playlist) {
    var newTracks = toImmutable(playlist.tracks)
        .map(function (track) {
            return track.get('id');
        })
        .toList();

    return state
        .set('fetchingStatus', 'idle')
        .set('nextLink', playlist.next_href)
        .updateIn(['tracks'], function (tracks) {
            return tracks.concat(newTracks);
        });
}

function onPlayTrackRequest(state, payload) {
    var tracks = state.get('tracks');
    return state.set('nextTrack', tracks.get(tracks.indexOf(payload.trackId) + 1));
}

function removeTrack(state, payload) {
    var tracks = state.get('tracks');
    var nextTrack = state.get('nextTrack');

    if (state.get('nextTrack') === payload.trackId) {
        nextTrack = tracks.get(tracks.indexOf(payload.trackId) + 1);
    }

    return state.updateIn(['tracks'], function (tracks) {
        return tracks.filterNot(function (trackId) {
            return trackId === payload.trackId;
        });
    })
    .set('pendingTracks', tracks)
    .set('nextTrack', nextTrack);
}

function removeTrackSuccess(state, payload) {
    return state.set('pendingTracks', toImmutable([]));
}

function removeTrackRollback(state, payload) {
    return state
        .set('tracks', state.get('pendingTracks'))
        .set('pendingTracks', toImmutable([]));
}

function addTrack(state, payload) {
    var currentTracks = state.get('tracks');
    return state.updateIn(['tracks'], function (tracks) {
        return toImmutable([payload.trackId]).concat(tracks);
    })
    .set('pendingTracks', currentTracks);
}

function addTrackSuccess(state, payload) {
    return state.set('pendingTracks', toImmutable([]));
}

function addTrackRollback(state, payload) {
    return state
        .set('tracks', state.get('pendingTracks'))
        .set('pendingTracks', toImmutable([]));
}
