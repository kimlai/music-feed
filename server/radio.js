var knexfile = require('../knexfile');
var knex = require('knex')(knexfile);

module.exports = function radioPlaylist(soundcloudUserId) {
    return knex.select('track', 'savedAt')
        .where({soundcloudUserId: soundcloudUserId})
        .orderByRaw('RANDOM()')
        .limit(100)
        .from('published_tracks')
        .then(function (rows) {
            return rows.map(function (row) {
                var track = row.track;
                track.created_at = row.savedAt;
                return track;
            });
        })
        .then(function (tracks) {
            return {
                tracks: tracks,
                next_href: "/radio_playlist"
            };
        });
};
