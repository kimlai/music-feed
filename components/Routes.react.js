var React = require('react');
var Router = require('react-router');
var Route = Router.Route;
var DefaultRoute = Router.DefaultRoute;

var TracksModule = require('../modules/tracks');
var getters = TracksModule.getters;

var App = require('./App.react');
var Feed = require('./Playlist.react')(getters.feedWithTrackInfo);
var SavedTracks = require('./Playlist.react')(getters.savedTracksWithTrackInfo);
var PublishedTracks = require('./Playlist.react')(getters.publishedTracksWithTrackInfo);

module.exports = (
    <Route handler={App}>
        <DefaultRoute name="feed" handler={Feed} />
        <Route name="saved-tracks" path="saved-tracks" handler={SavedTracks} />
        <Route name="published-tracks" path="published-tracks" handler={PublishedTracks} />
    </Route>
);
