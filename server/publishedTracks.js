var soundcloud = require('../soundcloud/api-client');
var knexfile = require('../knexfile');
var knex = require('knex')(knexfile);
var _ = require('lodash');
const R = require('ramda');

module.exports = function fetchPublishedTracks(soundcloudUserId, before, userUuid) {
    const query = knex.select('soundcloudTrackId', 'track', 'savedAt')
        .where({
            soundcloudUserId: soundcloudUserId,
            dead: false
        })
        .orderBy('savedAt', 'DESC')
        .limit(20)
        .from('published_tracks');

    if (before) {
        query.where('savedAt', '<', before);
    }

    return query.then(function (rows) {
        return _.map(rows, function (row) {
            var track = row.track;
            track.saved_at = row.savedAt;
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
    });
};
