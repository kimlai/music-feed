exports.feed = ['feed'];
exports.savedTracks = ['savedTracks'];
exports.tracks = ['tracks'];
exports.currentTrackId = ['currentTrackId'];

exports.feedTracks = [
    ['tracks'],
    ['feed', 'tracks'],
    function (tracks, feedTracks) {
        return feedTracks.map(function (trackId) {
            return tracks.get(trackId);
        });
    }
];

exports.savedTracks = [
    ['tracks'],
    ['savedTracks', 'tracks'],
    function (tracks, savedTracks) {
        return savedTracks.map(function (trackId) {
            return tracks.get(trackId);
        });
    }
];
