exports.feed = ['feed'];
exports.savedTracks = ['savedTracks'];
exports.tracks = ['tracks'];
exports.currentTrackId = ['currentTrackId'];
exports.currentPlaylistId = ['currentPlaylistId'];

exports.feedTracks = [
    ['tracks'],
    ['feed', 'tracks'],
    function (tracks, feedTracks) {
        return feedTracks.map(function (trackId) {
            return tracks.get(trackId);
        });
    }
];

exports.savedTracksWithTrackInfo = [
    ['tracks'],
    ['savedTracks', 'tracks'],
    function (tracks, savedTracks) {
        return savedTracks.map(function (trackId) {
            return tracks.get(trackId);
        });
    }
];

exports.nextTrackId = [
    ['currentPlaylistId'],
    ['feed'],
    ['savedTracks'],
    function (currentPlaylistId, feed, savedTracks) {
        switch (currentPlaylistId) {
            case 'feed':
                return feed.get('nextTrack');
            case 'savedTracks':
                return feed.get('nextTrack');
        }
    }
];
