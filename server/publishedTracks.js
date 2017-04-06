var soundcloud = require('../soundcloud/api-client');
var knexfile = require('../knexfile');
var knex = require('knex')(knexfile);
var _ = require('lodash');

module.exports = function fetchPublishedTracks(soundcloudUserId, before) {
    const query = knex.select('soundcloudTrackId', 'track', 'savedAt')
        .where({
            soundcloudUserId: soundcloudUserId,
            dead: false
        })
        .orderBy('savedAt', 'DESC')
        .limit(20)
        .from('published_tracks');

    console.log(before);

    if (before) {
        query.where('savedAt', '<', before);
    }

    return query.then(function (rows) {
            return _.map(rows, function (row) {
                var track = row.track;
                track.saved_at = row.savedAt;
                track.created_at = row.savedAt;
                track.id = row.soundcloudTrackId;
                return track;
            });
        });
};
