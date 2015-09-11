var toImmutable = require('nuclear-js').toImmutable;
var Store = require('nuclear-js').Store;
var RECEIVE_TRACKS = require('../actionTypes').RECEIVE_TRACKS;
var PLAY_TRACK_REQUEST = require('../actionTypes').PLAY_TRACK_REQUEST;
var PLAY_TRACK_SUCCESS = require('../actionTypes').PLAY_TRACK_SUCCESS;
var PAUSE_TRACK_REQUEST = require('../actionTypes').PAUSE_TRACK_REQUEST;
var PAUSE_TRACK_SUCCESS = require('../actionTypes').PAUSE_TRACK_SUCCESS;
var SEEK_TRACK_REQUEST = require('../actionTypes').SEEK_TRACK_REQUEST;
var SEEK_TRACK_SUCCESS = require('../actionTypes').SEEK_TRACK_SUCCESS;

module.exports = new Store({
    getInitialState: function () {
        return toImmutable({});
    },

    initialize: function () {
        this.on(RECEIVE_TRACKS, receiveTracks);
        this.on(PLAY_TRACK_REQUEST, playTrackRequest);
        this.on(PLAY_TRACK_SUCCESS, playTrackSuccess);
        this.on(PAUSE_TRACK_REQUEST, pauseTrackRequest);
        this.on(PAUSE_TRACK_SUCCESS, pauseTrackSuccess);
        this.on(SEEK_TRACK_REQUEST, seekTrackRequest);
        this.on(SEEK_TRACK_SUCCESS, seekTrackSuccess);
    }
});

function receiveTracks(state, payload) {
    var newTracks = toImmutable(payload.playlist.tracks)
        .toMap()
        .mapKeys(function (k, v) {
            return v.get('id');
        }).map(function (track, trackId) {
            return toImmutable({
                'stream_url': track.get('stream_url'),
                'playbackStatus': 'stopped',
            });
        });

    return newTracks.merge(state);
}

function playTrackRequest(state, payload) {
    return state.update(payload.trackId, function (track) {
        return track.set('playbackStatus', 'play_requested');
    });
}

function seekTrackRequest(state, payload) {
    return state.update(payload.trackId, function (track) {
        var currentStatus = track.get('playbackStatus');
        return track
            .set('previousStatus', currentStatus)
            .set('playbackStatus', 'seek_requested')
            .set('seekedTime', payload.seekedTime);
    });
}

function seekTrackSuccess(state, payload) {
    return state.update(payload.trackId, function (track) {
        var previousStatus = track.get('previousStatus');
        return track
            .set('playbackStatus', previousStatus)
            .remove('previousStatus')
            .remove('seekedTime');
    });
}

function playTrackSuccess(state, payload) {
    return state.update(payload.trackId, function (track) {
        return track.set('playbackStatus', 'playing');
    });
}

function pauseTrackRequest(state, payload) {
    return state.update(payload.trackId, function (track) {
        return track.set('playbackStatus', 'pause_requested');
    });
}

function pauseTrackSuccess(state, payload) {
    return state.update(payload.trackId, function (track) {
        return track.set('playbackStatus', 'paused');
    });
}
