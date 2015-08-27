var React = require('react');
var Feed = require('./Feed.react');
var SavedTracks = require('./SavedTracks.react');

module.exports = React.createClass({
    render: function () {
        return (
            <div className="playlists-container">
                <Feed />
                <SavedTracks />
            </div>
        );
    }
});
