var React = require('react');
var reactor = require('./reactor');

var TracksModule = require('./modules/tracks');
TracksModule.register(reactor);

var App = require('./components/App.react');

var tracks = JSON.parse(document.getElementById('context').textContent);
TracksModule.actions.fetchTracks(tracks);

React.render(
    React.createElement(App, null),
    document.getElementById('app')
);
