exports.up = function(knex, Promise) {
    return knex.schema
        .createTable('saved_tracks', function (table) {
            table.string('soundcloudUserId');
            table.string('soundcloudTrackId');
            table.json('track', true); // true means jsonb instead of json
            table.dateTime('savedAt');
        })
        .then(function () {
            console.log('the "saved_tracks" table has been created');
        });
};

exports.down = function(knex, Promise) {
    return knex.schema
        .dropTable('saved_tracks')
        .then(function () {
            console.log('the "saved_tracks" table has been dropped');
        });
};
