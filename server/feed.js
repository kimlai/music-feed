var soundcloud = require('../soundcloud/api-client');
var knexfile = require('../knexfile');
var knex = require('knex')(knexfile);
var _ = require('lodash');

module.exports = function fetchFeedApi(soundcloudUserId, token, nextLink) {
    return Promise.all([
            fetchSoundcloudFeed(token, nextLink),
            fetchBlacklist(soundcloudUserId),
            fetchSavedTracks(soundcloudUserId),
        ])
        .then(function (results) {
            var feed = results[0];
            var blacklist =  results[1];
            var savedTracks =  results[2];
            feed.tracks = _.filter(feed.tracks, function (track) {
                return !_.includes(blacklist, track.id) && !_.includes(savedTracks, track.id);
            });
            return feed;
        });
};

function fetchSoundcloudFeed(token, nextLink) {
    return soundcloud
        .fetchActivities(token, nextLink)
        .then(parseSoundcloudActivities);
}

function fetchBlacklist(soundcloudUserId) {
    return knex
        .select('soundcloudTrackId')
        .from('blacklist')
        .where({soundcloudUserId: soundcloudUserId})
        .then(function (rows) {
            return _.map(rows, function (row) {
                return parseInt(row.soundcloudTrackId, 10);
            });
        });
}

function fetchSavedTracks(soundcloudUserId) {
    return knex
        .select('soundcloudTrackId')
        .from('saved_tracks')
        .where({soundcloudUserId: soundcloudUserId})
        .then(function (rows) {
            return _.map(rows, function (row) {
                return parseInt(row.soundcloudTrackId, 10);
            });
        });
}

function parseSoundcloudActivities(activities) {
    var tracks = activities.collection.map(function (activity) {
        return activity.origin;
    });

    return {
        tracks: tracks,
        next_href: activities.next_href,
    };
}

