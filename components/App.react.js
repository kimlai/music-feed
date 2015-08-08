var React = require('react');
var Feed = require('./Feed.react');
var GlobalPlayer = require('./GlobalPlayer.react');
var SavedTracks = require('./SavedTracks.react');

module.exports = React.createClass({
    render: function () {
        return (
            <div>
                <GlobalPlayer />
                <div className="playlists-container">
                    <Feed />
                    <SavedTracks />
                </div>
            </div>
        );
    }
});
