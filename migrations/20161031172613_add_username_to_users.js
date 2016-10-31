
exports.up = function(knex, Promise) {
    return knex.schema
        .table('users', function (table) {
            table.string('username').notNullable();
        })
        .then(function () {
            console.log('the column users.username has been added.');
        });
};

exports.down = function(knex, Promise) {
    return knex.schema
        .table('users', function (table) {
            table.dropColumn('username');
        })
        .then(function () {
            console.log('the column users.username has been dropped.');
        });
};
