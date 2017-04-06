var knexfile = require('../knexfile');
var knex = require('knex')(knexfile);
const R = require('ramda');

module.exports = function fetchRadioPlaylist(soundcloudUserId, userUuid) {
    return knex.select('soundcloudTrackId', 'track', 'savedAt')
        .where({soundcloudUserId: soundcloudUserId})
        .orderByRaw('RANDOM()')
        .limit(100)
        .from('published_tracks')
        .then(function (rows) {
            return rows.map(function (row) {
                var track = row.track;
                track.created_at = row.savedAt;
                track.id = row.soundcloudTrackId;
                track.liked = false;
                return track;
            });
        }).then(tracks => {
            if (!userUuid) {
                return tracks;
            } else {
                return knex.select('likes.track_id')
                    .from('likes')
                    .whereIn('track_id', R.pluck('id', tracks))
                    .andWhere('user_uuid', userUuid)
                    .then(R.pluck('track_id'))
                    .then(likedTracksIds => {
                        const isLiked = track => R.contains(track.id, likedTracksIds);
                        return tracks.map(R.when(isLiked, R.assoc('liked', true)));
                    });
            }
        })
        .then(function (tracks) {
            return {
                tracks: tracks,
                next_href: "/radio_playlist"
            };
        });
};
