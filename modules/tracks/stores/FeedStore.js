var toImmutable = require('nuclear-js').toImmutable;
var Store = require('nuclear-js').Store;
var RECEIVE_FEED = require('../actionTypes').RECEIVE_FEED;
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
            tracks: [],
            nextLink: null,
            nextTrack: null,
            pendingTracks: []
        });
    },

    initialize: function () {
        this.on(RECEIVE_FEED, receiveFeed);
        this.on(PLAY_TRACK_REQUEST, onPlayTrackRequest);
        this.on(BLACKLIST_TRACK_REQUEST, removeTrack);
        this.on(BLACKLIST_TRACK_FAILURE, removeTrackRollback);
        this.on(BLACKLIST_TRACK_SUCCESS, removeTrackSuccess);
        this.on(SAVE_TRACK_REQUEST, removeTrack);
        this.on(SAVE_TRACK_FAILURE, removeTrackRollback);
        this.on(SAVE_TRACK_SUCCESS, removeTrackSuccess);
        this.on(PUBLISH_TRACK_REQUEST, removeTrack);
        this.on(PUBLISH_TRACK_FAILURE, removeTrackRollback);
        this.on(PUBLISH_TRACK_SUCCESS, removeTrackSuccess);
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
