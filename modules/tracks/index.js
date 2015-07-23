var getters = require('./getters');
var actions = require('./actions');

var TrackStore = require('./stores/TrackStore');
var CurrentTrackIdStore = require('./stores/CurrentTrackIdStore');

module.exports = {
    actions: actions,
    getters: getters,
    register: function(reactor) {
        reactor.registerStores({
            'tracks': TrackStore,
            'currentTrackId': CurrentTrackIdStore,
        });
    }
}
