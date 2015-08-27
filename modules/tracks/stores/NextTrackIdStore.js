var Store = require('nuclear-js').Store;
var SET_NEXT_TRACK_ID = require('../actionTypes').SET_NEXT_TRACK_ID;

module.exports = new Store({
    getInitialState: function () {
        return null;
    },

    initialize: function () {
        this.on(SET_NEXT_TRACK_ID, setNextTrackId);
    }
});

function setNextTrackId(state, payload) {
    return payload.trackId;
}
