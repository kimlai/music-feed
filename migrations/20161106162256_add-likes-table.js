
exports.up = function(knex, Promise) {
    return knex.schema
        .createTable('likes', function (table) {
            table.uuid('user_uuid').notNullable().references('users.uuid');
            table.string('track_id').notNullable().references('published_tracks.soundcloudTrackId');
            table.date('created_at').notNullable();
            table.primary(['user_uuid', 'track_id']);
        })
        .then(function () {
            console.log('the "likes" table has been created');
        });
};

exports.down = function(knex, Promise) {
    return knex.schema
        .dropTable('likes')
        .then(function () {
            console.log('the "likes" table has been dropped');
        });
};
