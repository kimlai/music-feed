var soundcloud = require('../soundcloud/api-client');
var knexfile = require('../knexfile');
var knex = require('knex')(knexfile);
var _ = require('lodash');

module.exports = function fetchPublishedTracks(soundcloudUserId, offset) {
    offset = offset || 0;
    offset = parseInt(offset, 10);
    return knex.select('soundcloudTrackId', 'track', 'savedAt')
        .where({
            soundcloudUserId: soundcloudUserId,
            dead: false
        })
        .orderBy('savedAt', 'DESC')
        .offset(offset)
        .limit(20)
        .from('published_tracks')
        .then(function (rows) {
            return _.map(rows, function (row) {
                var track = row.track;
                track.saved_at = row.savedAt;
                track.id = row.soundcloudTrackId;
                return track;
            });
        });
};
