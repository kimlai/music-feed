var reactor = require('../../reactor');
var actionTypes = require('./actionTypes');
var getters = require('./getters');

module.exports = {
    playTrack: playTrack,
    playTrackSuccess: playTrackSuccess,
    next: next,
    pauseTrack: pauseTrack,
    pauseTrackSuccess: pauseTrackSuccess,
    trackProgress: trackProgress,
    seekTrack: seekTrack,
    seekTrackSuccess: seekTrackSuccess,
    fetchTracks: fetchTracks,
};

function playTrack(trackId, streamUrl) {
    var currentTrackId = reactor.evaluate(getters.currentTrackId);
    if (null !== currentTrackId) {
        pauseTrack(currentTrackId);
    }
    reactor.dispatch(actionTypes.PLAY_TRACK_REQUEST, { trackId: trackId });
}

function next() {
    var currentTrackId = reactor.evaluate(getters.currentTrackId);
    if (null === currentTrackId) {
        return;
    }
    tracks = reactor.evaluate(getters.tracks);
    var keys = tracks.keySeq().toArray();
    var nextTrack = tracks.get(keys[keys.indexOf(currentTrackId) + 1]);
    playTrack(nextTrack.get('id'), nextTrack.get('stream_url'));
}

function playTrackSuccess(trackId) {
    reactor.dispatch(actionTypes.PLAY_TRACK_SUCCESS, { trackId: trackId });
}

function pauseTrack(trackId) {
    reactor.dispatch(actionTypes.PAUSE_TRACK_REQUEST, { trackId: trackId });
}

function pauseTrackSuccess(trackId) {
    reactor.dispatch(actionTypes.PAUSE_TRACK_SUCCESS, { trackId: trackId });
}

function trackProgress(trackId, currentTime) {
    reactor.dispatch(actionTypes.TRACK_PROGRESS, { trackId: trackId, currentTime: currentTime });
}

function seekTrack(trackId, seekedTime) {
    var currentTrackId = reactor.evaluate(getters.currentTrackId);
    if (trackId !== currentTrackId) {
        return;
    }
    reactor.dispatch(actionTypes.SEEK_TRACK_REQUEST, { trackId: trackId, seekedTime: seekedTime });
}

function seekTrackSuccess(trackId) {
    reactor.dispatch(actionTypes.SEEK_TRACK_SUCCESS, { trackId: trackId });
}

function fetchTracks(tracks) {
    reactor.dispatch(actionTypes.RECEIVE_TRACKS, tracks);
}
