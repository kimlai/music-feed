var React = require('react');
var reactor = require('./reactor');

var TracksModule = require('./modules/tracks');
TracksModule.register(reactor);

var App = require('./components/App.react');
var Player = require('./soundcloud/Player')(process.env.SOUNDCLOUD_CLIENT_ID);

var tracks = JSON.parse(document.getElementById('context').textContent);
TracksModule.actions.fetchTracks(tracks);

React.render(
    React.createElement(App, null),
    document.getElementById('app')
);

reactor.observe(
    TracksModule.getters.tracks,
    function (tracks) {
        tracks.forEach(function (track) {
            switch (track.get('playbackStatus')) {
                case 'play_requested':
                    return Player.play(track.get('id'), track.get('stream_url'));
                case 'pause_requested':
                    return Player.pause(track.get('id'), track.get('stream_url'));
                case 'seek_requested':
                    return Player.seek(track.get('id'), track.get('currentTime'));
            }
        });
    }
);
