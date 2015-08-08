var toImmutable = require('nuclear-js').toImmutable;
var Store = require('nuclear-js').Store;
var RECEIVE_FEED = require('../actionTypes').RECEIVE_FEED;

module.exports = new Store({
    getInitialState: function () {
        return toImmutable({
            tracks: [],
            nextLink: null,
        });
    },

    initialize: function () {
        this.on(RECEIVE_FEED, receiveFeed);
    }
});

function receiveFeed(state, feed) {
    var newTracks = toImmutable(feed.tracks)
        .map(function (track) {
            return track.get('id');
        })
        .toList();

    return state
        .set('nextLink', feed.next_href)
        .updateIn(['tracks'], function (tracks) {
            return tracks.concat(newTracks);
        });
}
