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
    fetchFeed: fetchFeed,
    initializeFeed: initializeFeed,
    initializeSavedTracks: initializeSavedTracks,
};

function playTrack(trackId) {
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
    feedTracksIds = reactor.evaluate(getters.feed).get('tracks');
    var nextTrackId = feedTracksIds.get(feedTracksIds.indexOf(currentTrackId) + 1);
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
