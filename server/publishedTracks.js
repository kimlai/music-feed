var soundcloud = require('../soundcloud/api-client');
var knexfile = require('../knexfile');
var knex = require('knex')(knexfile);
var _ = require('lodash');

module.exports = function fetchSavedTracksApi(soundcloudUserId, offset) {
    offset = parseInt(offset, 10);
    return knex.select('track', 'savedAt')
        .where({soundcloudUserId: soundcloudUserId})
        .orderBy('savedAt', 'DESC')
        .offset(offset)
        .limit(10)
        .from('published_tracks')
        .then(function (rows) {
            return _.map(rows, function (row) {
                var track = row.track;
                track.saved_at = row.savedAt;
                return track;
            });
        })
        .then(function (tracks) {
            var nextOffset = offset+10;
            return {
                tracks: tracks,
                next_href: '/published_tracks?offset=' + nextOffset,
            };
        });
};
