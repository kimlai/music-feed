
exports.up = function(knex, Promise) {
    return knex.schema
        .table('published_tracks', function (table) {
            table.boolean('dead').defaultTo(false);
        })
        .then(function () {
            console.log('the column published_tracks.dead has been added.');
        });
};

exports.down = function(knex, Promise) {
    return knex.schema
        .table('published_tracks', function (table) {
            table.dropColumn('dead');
        })
        .then(function () {
            console.log('the column published_tracks.dead has been dropped.');
        });
};
