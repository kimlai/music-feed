var toImmutable = require('nuclear-js').toImmutable;

exports.feed = ['feed'];
exports.savedTracks = ['savedTracks'];
exports.publishedTracks = ['publishedTracks'];
exports.tracks = ['tracks'];
exports.playbackStatus = ['playbackStatus'];
exports.currentTrackId = ['currentTrackId'];
exports.currentPlaylistId = ['currentPlaylistId'];

exports.feedWithTrackInfo = [
    ['tracks'],
    ['playbackStatus'],
    ['feed'],
    function (tracks, playbackStatus, feed) {
        return feed.update('tracks', function (trackIds) {
            return trackIds.map(function (trackId) {
                return tracks
                    .get(trackId)
                    .merge(playbackStatus.get(trackId));
            });
        });
    }
];

exports.savedTracksWithTrackInfo = [
    ['tracks'],
    ['playbackStatus'],
    ['savedTracks'],
    function (tracks, playbackStatus, savedTracks) {
        return savedTracks.update('tracks', function (trackIds) {
            return trackIds.map(function (trackId) {
                return tracks
                    .get(trackId)
                    .merge(playbackStatus.get(trackId));
            });
        });
    }
];

exports.publishedTracksWithTrackInfo = [
    ['tracks'],
    ['playbackStatus'],
    ['publishedTracks', 'tracks'],
    function (tracks, playbackStatus, publishedTracks) {
        return publishedTracks.map(function (trackId) {
            return tracks
                .get(trackId)
                .merge(playbackStatus.get(trackId));
        });
    }
];

exports.nextTrackId = [
    ['currentPlaylistId'],
    ['feed'],
    ['savedTracks'],
    ['publishedTracks'],
    function (currentPlaylistId, feed, savedTracks, publishedTracks) {
        switch (currentPlaylistId) {
            case 'feed':
                return feed.get('nextTrack');
            case 'savedTracks':
                return savedTracks.get('nextTrack');
            case 'publishedTracks':
                return publishedTracks.get('nextTrack');
        }
    }
];

exports.currentTrack = [
    ['tracks'],
    ['playbackStatus'],
    ['currentTrackId'],
    function (tracks, playbackStatus, currentTrackId) {
        if (!tracks.has(currentTrackId)) {
            return toImmutable({
                title: '',
                currentTime: 0,
                duration: 1,
            });
        }
        return tracks
            .get(currentTrackId)
            .merge(playbackStatus.get(currentTrackId));
    }
];
