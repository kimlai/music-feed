var toImmutable = require('nuclear-js').toImmutable;
var Store = require('nuclear-js').Store;
var FETCH_TRACKS_REQUEST = require('../actionTypes').FETCH_TRACKS_REQUEST;
var FETCH_TRACKS_FAILURE = require('../actionTypes').FETCH_TRACKS_FAILURE;
var RECEIVE_TRACKS = require('../actionTypes').RECEIVE_TRACKS;
var PLAY_TRACK_REQUEST = require('../actionTypes').PLAY_TRACK_REQUEST;
var ADD_TRACK_TO_PLAYLIST_REQUEST = require('../actionTypes').ADD_TRACK_TO_PLAYLIST_REQUEST;
var ADD_TRACK_TO_PLAYLIST_SUCCESS = require('../actionTypes').ADD_TRACK_TO_PLAYLIST_SUCCESS;
var ADD_TRACK_TO_PLAYLIST_FAILURE = require('../actionTypes').ADD_TRACK_TO_PLAYLIST_FAILURE;

module.exports = new Store({
    getInitialState: function () {
        var emptyPlaylist = toImmutable({
            tracks: [],
            next_href: null,
            nextTrack: null,
            pendingTracks: [],
            fetchingStatus: 'idle',
        });

        return toImmutable({
            'feed': emptyPlaylist.set('id', 'feed'),
            'savedTracks': emptyPlaylist.set('id', 'savedTracks'),
            'publishedTracks': emptyPlaylist.set('id', 'publishedTracks'),
        });
    },

    initialize: function () {
        this.on(PLAY_TRACK_REQUEST, onPlayTrackRequest);
        this.on(FETCH_TRACKS_REQUEST, fetchTracksRequest);
        this.on(FETCH_TRACKS_FAILURE, fetchTracksFailure);
        this.on(RECEIVE_TRACKS, receiveTracks);
        this.on(ADD_TRACK_TO_PLAYLIST_REQUEST, addTrack);
        this.on(ADD_TRACK_TO_PLAYLIST_SUCCESS, addTrackSuccess);
        this.on(ADD_TRACK_TO_PLAYLIST_FAILURE, addTrackRollback);
    }
});

function fetchTracksRequest(state, payload) {
    return state.update(payload.playlistId, function (playlist) {
        return playlist.set('fetchingStatus', 'fetching');
    });
}

function fetchTracksFailure(state) {
    return state.update(payload.playlistId, function (playlist) {
        return playlist.set('fetchingStatus', 'failed');
    });
}

function receiveTracks(state, payload) {
    var newTracks = toImmutable(payload.playlist.tracks)
        .map(function (track) {
            return track.get('id');
        })
        .toList();

    return state.update(payload.playlistId, function (playlist) {
        return playlist
            .set('fetchingStatus', 'idle')
            .set('nextLink', payload.playlist.next_href)
            .updateIn(['tracks'], function (tracks) {
                return tracks.concat(newTracks);
            });
    });
}

function onPlayTrackRequest(state, payload) {
    var tracks = state.get(payload.playlistId).get('tracks');

    return state.update(payload.playlistId, function (playlist) {
        return playlist.set('nextTrack', tracks.get(tracks.indexOf(payload.trackId) + 1));
    });
}

function addTrack(state, payload) {
    return state.map(function (playlist, playlistId) {
        var currentTracks = playlist.get('tracks');
        if (playlistId === payload.playlistId) {
            return playlist.updateIn(['tracks'], function (tracks) {
                return toImmutable([payload.trackId]).concat(tracks);
            })
            .set('pendingTracks', currentTracks);
        } else {
            var nextTrack = playlist.get('nextTrack');

            if (state.get('nextTrack') === payload.trackId) {
                nextTrack = tracks.get(tracks.indexOf(payload.trackId) + 1);
            }

            return playlist.updateIn(['tracks'], function (tracks) {
                return tracks.filterNot(function (trackId) {
                    return trackId === payload.trackId;
                });
            })
            .set('pendingTracks', currentTracks)
            .set('nextTrack', nextTrack);
        }
    });
}

function addTrackSuccess(state, payload) {
    return state.map(function (playlist, playlistId) {
        return playlist.set('pendingTracks', toImmutable([]));
    });
}

function addTrackRollback(state, payload) {
    return state.map(function (playlist, playlistId) {
        return playlist
            .set('tracks', state.get('pendingTracks'))
            .set('pendingTracks', toImmutable([]));
    });
}
