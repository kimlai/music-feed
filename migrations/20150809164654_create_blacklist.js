exports.up = function(knex, Promise) {
    return knex.schema
        .createTable('blacklist', function (table) {
            table.string('soundcloudUserId');
            table.string('soundcloudTrackId');
        })
        .then(function () {
            console.log('the "blacklist" table has been created');
        });
};

exports.down = function(knex, Promise) {
    return knex.schema
        .dropTable('backlist')
        .then(function () {
            console.log('the "blacklist" table has been dropped');
        });
};
