var toImmutable = require('nuclear-js').toImmutable;
var Store = require('nuclear-js').Store;
var RECEIVE_FEED = require('../actionTypes').RECEIVE_FEED;
var RECEIVE_SAVED_TRACKS = require('../actionTypes').RECEIVE_SAVED_TRACKS;
var TRACK_PROGRESS = require('../actionTypes').TRACK_PROGRESS;
var SEEK_TRACK_REQUEST = require('../actionTypes').SEEK_TRACK_REQUEST;

module.exports = new Store({
    getInitialState: function () {
        return toImmutable({});
    },

    initialize: function () {
        this.on(RECEIVE_FEED, receiveFeed);
        this.on(RECEIVE_SAVED_TRACKS, receiveSavedTracks);
        this.on(TRACK_PROGRESS, trackProgress);
        this.on(SEEK_TRACK_REQUEST, seekTrackRequest);
    }
});

function receiveFeed(state, feed) {
    var newTracks = toImmutable(feed.tracks)
        .toMap()
        .mapKeys(function (k, v) {
            return v.get('id');
        }).map(function (track, trackId) {
            return track
                .set('currentTime', 0);
        });

    return newTracks.merge(state);
}

function receiveSavedTracks(state, tracks) {
    var newTracks = toImmutable(tracks)
        .toMap()
        .mapKeys(function (k, v) {
            return v.get('id');
        }).map(function (track, trackId) {
            return track
                .set('currentTime', 0);
        });

    return newTracks.merge(state);
}

function trackProgress(state, payload) {
    return state.update(payload.trackId, function (track) {
        return track.set('currentTime', payload.currentTime);
    });
}

function seekTrackRequest(state, payload) {
    return state.update(payload.trackId, function (track) {
        var currentStatus = track.get('playbackStatus');
        return track
            .set('currentTime', payload.seekedTime);
    });
}
