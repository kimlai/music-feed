var toImmutable = require('nuclear-js').toImmutable;
var Store = require('nuclear-js').Store;
var RECEIVE_TRACKS = require('../actionTypes').RECEIVE_TRACKS;
var TRACK_PROGRESS = require('../actionTypes').TRACK_PROGRESS;
var PLAY_TRACK = require('../actionTypes').PLAY_TRACK;
var PAUSE_TRACK = require('../actionTypes').PAUSE_TRACK;

module.exports = new Store({
    getInitialState: function () {
        return toImmutable({});
    },

    initialize: function () {
        this.on(RECEIVE_TRACKS, receiveTracks);
        this.on(TRACK_PROGRESS, trackProgress);
        this.on(PLAY_TRACK, playTrack);
        this.on(PAUSE_TRACK, pauseTrack);
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

function playTrack(state, payload) {
    return state.update(payload.trackId, function (track) {
        return track.set('isPlaying', true);
    });
}

function pauseTrack(state, payload) {
    return state.update(payload.trackId, function (track) {
        return track.set('isPlaying', false);
    });
}
