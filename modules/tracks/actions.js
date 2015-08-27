var reactor = require('../../reactor');
var actionTypes = require('./actionTypes');
var getters = require('./getters');
var request = require('superagent-bluebird-promise');

module.exports = {
    playTrack: playTrack,
    playTrackSuccess: playTrackSuccess,
    next: next,
    pauseTrack: pauseTrack,
    pauseTrackSuccess: pauseTrackSuccess,
    trackProgress: trackProgress,
    seekTrack: seekTrack,
    seekTrackSuccess: seekTrackSuccess,
    blacklistTrack: blacklistTrack,
    saveTrack: saveTrack,
    fetchFeed: fetchFeed,
    initializeFeed: initializeFeed,
    initializeSavedTracks: initializeSavedTracks,
    setCurrentPlaylistId: setCurrentPlaylistId,
};

function playTrack(trackId) {
    var currentTrackId = reactor.evaluate(getters.currentTrackId);
    if (null !== currentTrackId) {
        pauseTrack(currentTrackId);
    }
    reactor.dispatch(actionTypes.PLAY_TRACK_REQUEST, { trackId: trackId });
    var currentPlaylistId = reactor.evaluate(getters.currentPlaylistId);
    var currentPlaylistTrackIds = reactor.evaluate(getters[currentPlaylistId]).get('tracks');
    var nextTrackId = currentPlaylistTrackIds.get(currentPlaylistTrackIds.indexOf(trackId) + 1);
    reactor.dispatch(actionTypes.SET_NEXT_TRACK_ID, { trackId: nextTrackId });
}

function setCurrentPlaylistId(playlistId) {
    reactor.dispatch(actionTypes.SET_CURRENT_PLAYLIST_ID, { playlistId: playlistId });
}

function next() {
    var nextTrackId = reactor.evaluate(getters.nextTrackId);
    if (null === nextTrackId) {
        return;
    }
    playTrack(nextTrackId);
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

function blacklistTrack(trackId) {
    var currentTrackId = reactor.evaluate(getters.currentTrackId);
    if (trackId === currentTrackId) {
        next();
    }
    reactor.dispatch(actionTypes.BLACKLIST_TRACK_REQUEST, { trackId: trackId });
    request
        .post(process.env.MUSICFEED_API_ROOT+'/blacklist')
        .send({ soundcloudTrackId: trackId})
        .then(
            function (response) {
                reactor.dispatch(actionTypes.BLACKLIST_TRACK_SUCCESS, { trackId: trackId });
            },
            function (error) {
                reactor.dispatch(actionTypes.BLACKLIST_TRACK_FAILURE, { trackId: trackId });
            }
        );
}

function saveTrack(trackId) {
    reactor.dispatch(actionTypes.SAVE_TRACK_REQUEST, { trackId: trackId });
    request
        .post(process.env.MUSICFEED_API_ROOT+'/save_track')
        .send({ soundcloudTrackId: trackId})
        .then(
            function (response) {
                reactor.dispatch(actionTypes.SAVE_TRACK_SUCCESS, { trackId: trackId });
            },
            function (error) {
                reactor.dispatch(actionTypes.SAVE_TRACK_FAILURE, { trackId: trackId });
            }
        );
}

function initializeFeed(feed) {
    reactor.dispatch(actionTypes.RECEIVE_FEED, feed);
}

function initializeSavedTracks(tracks) {
    reactor.dispatch(actionTypes.RECEIVE_SAVED_TRACKS, tracks);
}

function fetchFeed() {
    var nextLink = reactor.evaluate(getters.feed).get('nextLink');
    request
        .get(process.env.MUSICFEED_API_ROOT+'/feed')
        .query({ nextLink: nextLink})
        .then(function (response) {
            reactor.dispatch(actionTypes.RECEIVE_FEED, response.body);
        });
}
