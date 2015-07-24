var Player = require('../../soundcloud/Player')(process.env.SOUNDCLOUD_CLIENT_ID);
var reactor = require('../../reactor');
var actionTypes = require('./actionTypes');
var getters = require('./getters');

module.exports = {
    playTrack: playTrack,
    pauseTrack: pauseTrack,
    trackProgress: trackProgress,
    fetchTracks: fetchTracks,
};

function playTrack(trackId, streamUrl) {
    var currentTrackId = reactor.evaluate(getters.currentTrackId);
    if (null !== currentTrackId) {
        pauseTrack(currentTrackId);
    }
    reactor.dispatch(actionTypes.PLAY_TRACK_REQUEST, { trackId: trackId });
    Player.play(trackId, streamUrl, function (e) {
        var currentTime = e.target.currentTime;
        var duration = e.target.duration;
        trackProgress(trackId, parseFloat(currentTime/duration*100).toFixed(2));
    });
    reactor.dispatch(actionTypes.PLAY_TRACK_SUCCESS, { trackId: trackId });
}

function pauseTrack(trackId) {
    reactor.dispatch(actionTypes.PAUSE_TRACK_REQUEST, { trackId: trackId });
    Player.pause(trackId);
    reactor.dispatch(actionTypes.PAUSE_TRACK_SUCCESS, { trackId: trackId });
}

function trackProgress(trackId, progress) {
    reactor.dispatch(actionTypes.TRACK_PROGRESS, { trackId: trackId, progress: progress });
}

function fetchTracks(tracks) {
    reactor.dispatch(actionTypes.RECEIVE_TRACKS, tracks);
}
