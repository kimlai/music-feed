
exports.up = function(knex, Promise) {
    return knex.schema
        .table('users', function(table) {
            table
                .unique('email')
                .unique('username');
        })
        .then(function () {
            console.log('unique indexes have been added on users.email and users.username');
        });
};

exports.down = function(knex, Promise) {
    return knex.schema.
        table('users', function(table) {
            table
                .dropUnique('email')
                .dropUnique('username');
        })
        .then(function () {
            console.log('unique indexes have been dropped on users.email and users.username');
        });
};
