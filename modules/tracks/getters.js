exports.feed = ['feed'];
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
