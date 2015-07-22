var React = require('react');
var reactor = require('../reactor');
var TrackStore = require('../stores/TrackStore');
var CurrentTrackIdStore = require('../stores/CurrentTrackIdStore');
var App = require('../components/App.react');
var actions = require('../actions');
var getters = require('../getters');

reactor.registerStores({
    'tracks': TrackStore,
    'currentTrackId': CurrentTrackIdStore,
});

var tracks = JSON.parse(document.getElementById('context').textContent);
actions.fetchTracks(tracks);

React.render(
    React.createElement(App, null),
    document.getElementById('app')
);
