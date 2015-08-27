var Store = require('nuclear-js').Store;
var SET_CURRENT_PLAYLIST_ID = require('../actionTypes').SET_CURRENT_PLAYLIST_ID;

module.exports = new Store({
    getInitialState: function () {
        return null;
    },

    initialize: function () {
        this.on(SET_CURRENT_PLAYLIST_ID, setCurrentPlaylistId);
    }
});

function setCurrentPlaylistId(state, payload) {
    return payload.playlistId;
}
