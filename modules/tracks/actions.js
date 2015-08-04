var reactor = require('../../reactor');
var actionTypes = require('./actionTypes');
var getters = require('./getters');

module.exports = {
    playTrack: playTrack,
    playTrackSuccess: playTrackSuccess,
    pauseTrack: pauseTrack,
    pauseTrackSuccess: pauseTrackSuccess,
    trackProgress: trackProgress,
    fetchTracks: fetchTracks,
};

function playTrack(trackId, streamUrl) {
    var currentTrackId = reactor.evaluate(getters.currentTrackId);
    if (null !== currentTrackId) {
        pauseTrack(currentTrackId);
    }
    reactor.dispatch(actionTypes.PLAY_TRACK_REQUEST, { trackId: trackId });
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

function fetchTracks(tracks) {
    reactor.dispatch(actionTypes.RECEIVE_TRACKS, tracks);
}
