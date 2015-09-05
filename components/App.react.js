var React = require('react');
var Router = require('react-router');
var RouteHandler = Router.RouteHandler;
var Navigation = require('./Navigation.react');
var GlobalPlayer = require('./GlobalPlayer.react');

module.exports = React.createClass({
    render: function () {
        return (
            <div>
                <GlobalPlayer />
                <Navigation />
                <div className="playlist-container">
                    <RouteHandler />
                </div>
            </div>
        );
    }
});
