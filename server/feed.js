var soundcloud = require('../soundcloud/api-client');
var knexfile = require('../knexfile');
var knex = require('knex')(knexfile);
var _ = require('lodash');

module.exports = function fetchFeedApi(soundcloudUserId, token, nextLink) {
    return Promise.all([
            fetchSoundcloudFeed(token, nextLink),
            fetchBlacklist(soundcloudUserId),
        ])
        .then(function (results) {
            var feed = results[0];
            var blacklist =  results[1];
            feed.tracks = _.filter(feed.tracks, function (track) {
                return typeof track !== 'undefined' && !_.includes(blacklist, track.id);
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

function parseSoundcloudActivities(activities) {
    var tracks = activities.collection.map(function (activity) {
        return activity.origin;
    });

    return {
        tracks: tracks,
        next_href: activities.next_href,
    };
}

