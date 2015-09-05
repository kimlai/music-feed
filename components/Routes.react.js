var React = require('react');
var Router = require('react-router');
var Route = Router.Route;
var DefaultRoute = Router.DefaultRoute;

var App = require('./App.react');
var Feed = require('./Feed.react');
var SavedTracks = require('./SavedTracks.react');
var PublishedTracks = require('./PublishedTracks.react');

module.exports = (
    <Route handler={App}>
        <DefaultRoute name="feed" handler={Feed} />
        <Route name="saved-tracks" path="saved-tracks" handler={SavedTracks} />
        <Route name="published-tracks" path="published-tracks" handler={PublishedTracks} />
    </Route>
);
