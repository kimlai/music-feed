const assert = require('assert');
const request = require('supertest-as-promised');
var knexfile = require('../../../knexfile');
var knex = require('knex')(knexfile);

const app = require('../../radioApi').listen();

describe('POST /users', function () {
    beforeEach(function () {
        return knex('users').truncate();
    });

    it('registers a new user', function () {
        return request(app)
            .post('/users')
            .send({ email: 'me@example.org', password: 'plain' })
            .expect(201)
            .then(function (res) {
                return knex('users').count('*');
            })
            .then(function (queryResult) {
                return queryResult[0].count;
            })
            .then(function (usersCount) {
                assert.equal(1, usersCount);
            });
    });
});

describe('POST /login', function () {
    beforeEach(function () {
        return knex('users').truncate()
            .then(function () {
                return request(app)
                .post('/users')
                .send({ email: 'me@example.org', password: 'plain' });
            });
    });

    it('logs a user in', function () {
        return request(app)
            .post('/login')
            .send({ email: 'me@example.org', password: 'plain' })
            .expect(200)
            .then(function (res) {
                return request(app)
                    .get('/protected')
                    .set('Authorization', 'Bearer ' + res.body.token)
                    .expect(200);
            });
    });

    it('does not log a user with the wrong password', function () {
        return request(app)
            .post('/login')
            .send({ email: 'me@example.org', password: 'wrong' })
            .expect(400)
    });

    it('does not log a user with a non registered email', function () {
        return request(app)
            .post('/login')
            .send({ email: 'unknown@example.org', password: 'plain' })
            .expect(400)
    });
});
