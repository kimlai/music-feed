var Store = require('nuclear-js').Store;
var PLAY_TRACK_REQUEST = require('../actionTypes').PLAY_TRACK_REQUEST;

module.exports = new Store({
    getInitialState: function () {
        return null;
    },

    initialize: function () {
        this.on(PLAY_TRACK_REQUEST, setCurrentTrackId);
    }
});

function setCurrentTrackId(state, payload) {
    return payload.trackId;
}
