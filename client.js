var React = require('react');
var reactor = require('./reactor');
var Router = require('react-router');

var TracksModule = require('./modules/tracks');
TracksModule.register(reactor);

var App = require('./components/App.react');
var Player = require('./soundcloud/Player')(process.env.SOUNDCLOUD_CLIENT_ID);
var Routes = require('./components/Routes.react');

var context = JSON.parse(document.getElementById('context').textContent);
TracksModule.actions.initializeFeed(context.feed);
TracksModule.actions.initializeSavedTracks(context.savedTracks);
TracksModule.actions.initializePublishedTracks(context.publishedTracks);

Router.run(Routes, Router.HistoryLocation, function (Root) {
    React.render(<Root />, document.getElementById('app'));
});

reactor.observe(
    TracksModule.getters.playbackStatus,
    function (tracks) {
        tracks.forEach(function (track, trackId) {
            switch (track.get('playbackStatus')) {
                case 'play_requested':
                    return Player.play(trackId, track.get('stream_url'));
                case 'pause_requested':
                    return Player.pause(trackId);
                case 'seek_requested':
                    return Player.seek(trackId, track.get('seekedTime'));
            }
        });
    }
);

window.addEventListener('keypress', function (e) {
    e.preventDefault();
    if (e.keyCode === 32) {
        TracksModule.actions.toggleCurrentTrackPlayback();
    }
});
