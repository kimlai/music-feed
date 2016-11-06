const assert = require('assert');
const request = require('supertest-as-promised');
var knexfile = require('../../../knexfile');
var knex = require('knex')(knexfile);
var uuid = require('node-uuid').v4;
var jwt = require('koa-jwt');

const app = require('../../radioApi').listen();

describe('likes', function () {
    var user = { username: 'foo', email: 'fee@example.org', uuid: uuid(), password: 'bar' };
    var track = {
        soundcloudTrackId: 'track1',
        soundcloudUserId: 'admin',
    };
    var token = jwt.sign(user, process.env.JWT_SECRET);

    beforeEach(function () {
        return knex.raw('TRUNCATE TABLE users, published_tracks, likes')
            .then(function () {
                return knex.insert(track).into('published_tracks');
            })
            .then(function () {
                return knex.insert(user).into('users');
            });
    });

    describe('POST /likes', function () {
        it('saves a like', function () {
            return request(app)
                .post('/likes')
                .set('Authorization', 'Bearer ' + token)
                .send({ trackId: 'track1' })
                .expect(201)
                .then(function (res) {
                    return knex('likes').select('user_uuid', 'track_id');
                })
                .then(function (queryResult) {
                    assert.equal(1, queryResult.length);
                    return queryResult[0];
                })
                .then(function (like) {
                    assert.deepEqual({ user_uuid: user.uuid, track_id: track.soundcloudTrackId }, like);
                });
        });
    });

    describe('GET /likes', function () {
        it('retrieves saved likes', function () {
            return request(app)
                .post('/likes')
                .set('Authorization', 'Bearer ' + token)
                .send({ trackId: 'track1' })
                .then(function () {
                    return request(app)
                        .get('/likes')
                        .set('Authorization', 'Bearer ' + token)
                        .expect(200)
                        .then(function (res) {
                            assert.equal(1, res.body.length);
                            assert.equal('track1', res.body[0].soundcloudTrackId);
                        });
                });
        });
    });
});
