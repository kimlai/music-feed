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
    toggleCurrentTrackPlayback: toggleCurrentTrackPlayback,
    trackProgress: trackProgress,
    seekTrack: seekTrack,
    seekTrackSuccess: seekTrackSuccess,
    blacklistTrack: blacklistTrack,
    saveTrack: saveTrack,
    publishTrack: publishTrack,
    fetchMoreTracks: fetchMoreTracks,
    initializeFeed: initializeFeed,
    initializeSavedTracks: initializeSavedTracks,
    initializePublishedTracks: initializePublishedTracks,
    setCurrentPlaylistId: setCurrentPlaylistId,
};

function playTrack(trackId) {
    var currentTrackId = reactor.evaluate(getters.currentTrackId);
    var currentPlaylistId = reactor.evaluate(getters.currentPlaylistId);
    if (null !== currentTrackId) {
        pauseTrack(currentTrackId);
    }
    reactor.dispatch(actionTypes.PLAY_TRACK_REQUEST, {
        trackId: trackId,
        playlistId: currentPlaylistId,
    });
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

function toggleCurrentTrackPlayback() {
    var currentTrack = reactor.evaluate(getters.currentTrack);
    switch (currentTrack.get('playbackStatus')) {
        case 'playing':
            pauseTrack(currentTrack.get('id'));
            break;
        case 'paused':
            playTrack(currentTrack.get('id'));
            break;
    }
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
    addTrackToPlaylist(trackId, 'blacklist');
}

function saveTrack(trackId) {
    addTrackToPlaylist(trackId, 'savedTracks');
}

function publishTrack(trackId) {
    addTrackToPlaylist(trackId, 'publishedTracks');
}

function addTrackToPlaylist(trackId, playlistId) {
    var urls = {
        blacklist: '/blacklist',
        savedTracks: '/save_track',
        publishedTracks: '/publish_track',
    };
    reactor.dispatch(actionTypes.ADD_TRACK_TO_PLAYLIST_REQUEST, {
        trackId: trackId,
        playlistId: playlistId,
    });
    request
        .post(process.env.MUSICFEED_API_ROOT + urls[playlistId])
        .send({ soundcloudTrackId: trackId})
        .then(
            function (response) {
                reactor.dispatch(actionTypes.ADD_TRACK_TO_PLAYLIST_SUCCESS, {
                    trackId: trackId,
                    playlistId: playlistId,
                });
            },
            function (error) {
                reactor.dispatch(actionTypes.ADD_TRACK_TO_PLAYLIST_FAILURE, {
                    trackId: trackId,
                    playlistId: playlistId,
                });
            }
        );
}

function initializeFeed(feed) {
    reactor.dispatch(actionTypes.RECEIVE_TRACKS, {
        playlistId: 'feed',
        playlist: feed
    });
}

function initializeSavedTracks(tracks) {
    reactor.dispatch(actionTypes.RECEIVE_TRACKS, {
        playlistId: 'savedTracks',
        playlist: tracks
    });
}

function initializePublishedTracks(tracks) {
    reactor.dispatch(actionTypes.RECEIVE_TRACKS, {
        playlistId: 'publishedTracks',
        playlist: tracks
    });
}

function fetchMoreTracks(playlistId) {
    var nextLink = reactor.evaluate(['playlists']).get(playlistId).get('nextLink');
    reactor.dispatch(actionTypes.FETCH_TRACKS_REQUEST, { playlistId: playlistId });
    request
        .get(nextLink)
        .then(
            function (response) {
                reactor.dispatch(actionTypes.RECEIVE_TRACKS, {
                    playlistId: playlistId,
                    playlist: response.body,
                });
            },
            function (error) {
                reactor.dispatch(actionTypes.FETCH_TRACKS_FAILURE, { playlistId: playlistId });
            }
        );
}
