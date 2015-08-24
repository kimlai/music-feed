var React = require('react');
var Feed = require('./Feed.react');
var SavedTracks = require('./SavedTracks.react');

module.exports = React.createClass({
    render: function () {
        return (
            <div>
                <h1>Feed</h1>
                <Feed />
                <h1>Saved Tracks</h1>
                <SavedTracks />
            </div>
        );
    }
});
