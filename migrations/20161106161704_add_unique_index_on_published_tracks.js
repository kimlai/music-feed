
exports.up = function(knex, Promise) {
    return knex.schema
        .table('published_tracks', function(table) {
            table.unique('soundcloudTrackId');
        })
        .then(function () {
            console.log('A unique index has been added on published_tracks.soundcloudTrackId');
        });
};

exports.down = function(knex, Promise) {
    return knex.schema.
        table('published_tracks', function(table) {
            table.dropUnique('soundcloudTrackId')
        })
        .then(function () {
            console.log(' unique index has been dropped on published_tracks.soundcloudTrackId');
        });
};
