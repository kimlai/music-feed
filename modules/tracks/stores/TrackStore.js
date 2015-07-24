var toImmutable = require('nuclear-js').toImmutable;
var Store = require('nuclear-js').Store;
var RECEIVE_TRACKS = require('../actionTypes').RECEIVE_TRACKS;
var TRACK_PROGRESS = require('../actionTypes').TRACK_PROGRESS;
var PLAY_TRACK_SUCCESS = require('../actionTypes').PLAY_TRACK_SUCCESS;
var PAUSE_TRACK_SUCCESS = require('../actionTypes').PAUSE_TRACK_SUCCESS;

module.exports = new Store({
    getInitialState: function () {
        return toImmutable({});
    },

    initialize: function () {
        this.on(RECEIVE_TRACKS, receiveTracks);
        this.on(TRACK_PROGRESS, trackProgress);
        this.on(PLAY_TRACK_SUCCESS, playTrackSuccess);
        this.on(PAUSE_TRACK_SUCCESS, pauseTrackSuccess);
    }
});

function receiveTracks(state, tracks) {
    var newTracks = toImmutable(tracks)
        .toMap()
        .mapKeys(function (k, v) {
            return v.get('id');
        }).map(function (track, trackId) {
            return track
                .set('progress', 0)
                .set('isPlaying', false);
        });
    return newTracks.merge(state);
}

function trackProgress(state, payload) {
    return state.update(payload.trackId, function (track) {
        return track.set('progress', payload.progress);
    });
}

function playTrackSuccess(state, payload) {
    return state.update(payload.trackId, function (track) {
        return track.set('isPlaying', true);
    });
}

function pauseTrackSuccess(state, payload) {
    return state.update(payload.trackId, function (track) {
        return track.set('isPlaying', false);
    });
}
