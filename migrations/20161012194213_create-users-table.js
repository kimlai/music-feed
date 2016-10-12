
exports.up = function(knex, Promise) {
    return knex.schema
        .createTable('users', function (table) {
            table.uuid('uuid').notNullable();
            table.string('email').notNullable();
            table.string('password').notNullable();
            table.primary('uuid');
        })
        .then(function () {
            console.log('the "users" table has been created');
        });
};

exports.down = function(knex, Promise) {
    return knex.schema
        .dropTable('users')
        .then(function () {
            console.log('the "users" table has been dropped');
        });
};
