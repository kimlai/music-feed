const assert = require('assert');
const request = require('supertest-as-promised');
var knexfile = require('../../../knexfile');
var knex = require('knex')(knexfile);

const app = require('../../radioApi').listen();

describe('POST /users', function () {
    beforeEach(function () {
        return knex.raw('TRUNCATE TABLE users CASCADE');
    });

    it('registers a new user', function () {
        return request(app)
            .post('/users')
            .send({ username: 'foo', email: 'me@example.org', password: 'plain' })
            .expect(201)
            .then(function (res) {
                return knex('users').select('email', 'username');
            })
            .then(function (queryResult) {
                assert.equal(1, queryResult.length);
                return queryResult[0];
            })
            .then(function (user) {
                assert.deepEqual({ email: 'me@example.org', username: 'foo' }, user);
            });
    });

    describe('prevent account duplication', function () {
        beforeEach(function () {
            return knex.raw('TRUNCATE TABLE users CASCADE')
                .then(function () {
                    return request(app)
                    .post('/users')
                    .send({ username: 'foo', email: 'me@example.org', password: 'plain' });
                });
        });

        it('returns a 400 response if the email is already taken', function () {
            return request(app)
                .post('/users')
                .send({ username: 'bar', email: 'me@example.org', password: 'plain' })
                .expect(400)
                .then(function (res) {
                    assert.deepEqual([{ field: 'email', error: 'Email is already taken' }], res.body);
                });
        });

        it('returns a 400 response if the username is already taken', function () {
            return request(app)
                .post('/users')
                .send({ username: 'foo', email: 'you@example.org', password: 'plain' })
                .expect(400)
                .then(function (res) {
                    assert.deepEqual([{ field: 'username', error: 'Username is already taken' }], res.body);
                });
        });
    });
});

describe('POST /login', function () {
    beforeEach(function () {
        return knex.raw('TRUNCATE TABLE users CASCADE')
            .then(function () {
                return request(app)
                .post('/users')
                .send({ username: 'foo', email: 'me@example.org', password: 'plain' });
            });
    });

    it('logs a user in with their email', function () {
        return request(app)
            .post('/login')
            .send({ usernameOrEmail: 'me@example.org', password: 'plain' })
            .expect(200)
            .then(function (res) {
                return request(app)
                    .get('/me')
                    .set('Authorization', 'Bearer ' + res.body.token)
                    .expect(200);
            });
    });

    it('logs a user in with their username', function () {
        return request(app)
            .post('/login')
            .send({ usernameOrEmail: 'foo', password: 'plain' })
            .expect(200)
            .then(function (res) {
                return request(app)
                    .get('/me')
                    .set('Authorization', 'Bearer ' + res.body.token)
                    .expect(200);
            });
    });

    it('stores information about the user in a token', function () {
        return request(app)
            .post('/login')
            .send({ usernameOrEmail: 'foo', password: 'plain' })
            .expect(200)
            .then(function (res) {
                return request(app)
                    .get('/me')
                    .set('Authorization', 'Bearer ' + res.body.token)
                    .expect(200)
                    .then(function (response) {
                        assert.equal('foo', response.body.username);
                        assert.equal('me@example.org', response.body.email);
                        assert.ok(response.body.uuid);
                    });
            });
    });

    it('does not log a user with the wrong password', function () {
        return request(app)
            .post('/login')
            .send({ usernameOrEmail: 'me@example.org', password: 'wrong' })
            .expect(400)
    });

    it('does not log a user with a non registered email', function () {
        return request(app)
            .post('/login')
            .send({ usernameOrEmail: 'unknown@example.org', password: 'plain' })
            .expect(400)
    });
});
