var soundcloud = require('../soundcloud/api-client');
var knexfile = require('../knexfile');
var knex = require('knex')(knexfile);
var _ = require('lodash');

module.exports = function fetchFeedApi(soundcloudUserId, token, nextSoundcloudLink) {
    return Promise.all([
            fetchSoundcloudFeed(token, nextSoundcloudLink),
            fetchBlacklist(soundcloudUserId),
            fetchSavedTracks(soundcloudUserId),
            fetchPublishedTracks(soundcloudUserId),
        ])
        .then(function (results) {
            var feed = results[0];
            var blacklist =  results[1];
            var savedTracks =  results[2];
            var publishedTracks =  results[3];
            feed.tracks = _.filter(feed.tracks, function (track) {
                return !_.includes(blacklist.concat(savedTracks, publishedTracks), track.id);
            });
            feed.next_href = '/feed?nextLink=' + encodeURIComponent(feed.next_href);

            return feed;
        });
};

function fetchSoundcloudFeed(token, nextSoundcloudLink) {
    return soundcloud
        .fetchActivities(token, nextSoundcloudLink)
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

function fetchPublishedTracks(soundcloudUserId) {
    return knex
        .select('soundcloudTrackId')
        .from('published_tracks')
        .where({soundcloudUserId: soundcloudUserId})
        .then(function (rows) {
            return _.map(rows, function (row) {
                return parseInt(row.soundcloudTrackId, 10);
            });
        }).then(function (tracks) {
            return tracks;
        });
}

function parseSoundcloudActivities(activities) {
    var tracks = activities.collection.map(function (activity) {
        var track = activity.origin;
        if (activity.type === 'track-repost') {
            track.created_at = activity.created_at;
        }

        return track;
    }).filter(function (feedItem) {
        return feedItem && feedItem.kind === "track";
    });

    return {
        tracks: tracks,
        next_href: activities.next_href,
    };
}

