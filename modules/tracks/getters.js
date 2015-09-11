var toImmutable = require('nuclear-js').toImmutable;

exports.tracks = ['tracks'];
exports.playbackStatus = ['playbackStatus'];
exports.currentTrackId = ['currentTrackId'];
exports.currentPlaylistId = ['currentPlaylistId'];
exports.playlists = ['playlists'];

exports.feedWithTrackInfo = [
    ['tracks'],
    ['playbackStatus'],
    ['playlists'],
    function (tracks, playbackStatus, playlists) {
        return playlists.get('feed').update('tracks', function (trackIds) {
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
    ['playlists'],
    function (tracks, playbackStatus, playlists) {
        return playlists.get('savedTracks').update('tracks', function (trackIds) {
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
    ['playlists'],
    function (tracks, playbackStatus, playlists) {
        return playlists.get('publishedTracks').update('tracks', function (trackIds) {
            return trackIds.map(function (trackId) {
                return tracks
                    .get(trackId)
                    .merge(playbackStatus.get(trackId));
            });
        });
    }
];

exports.nextTrackId = [
    ['currentPlaylistId'],
    ['playlists'],
    function (currentPlaylistId, playlists) {
        return playlists.get(currentPlaylistId).get('nextTrack');
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
