var Store = require('nuclear-js').Store;
var PLAY_TRACK = require('../actionTypes').PLAY_TRACK;

module.exports = new Store({
    getInitialState: function () {
        return null;
    },

    initialize: function () {
        this.on(PLAY_TRACK, setCurrentTrackId);
    }
});

function setCurrentTrackId(state, payload) {
    return payload.trackId;
}
