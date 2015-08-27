var React = require('react');
var actions = require('../modules/tracks').actions;

module.exports = React.createClass({
    getInitialState: function () {
        return {};
    },

    togglePlayback: function () {
        var playbackStatus = this.props.track.playbackStatus;
        if (playbackStatus === 'playing') {
            actions.pauseTrack(this.props.track.id);
        } else {
            actions.playTrack(this.props.track.id);
        }
    },

    render: function () {
        var text = this.props.track.playbackStatus === 'playing' ? 'Pause' : 'Play';
        return (
            <div className="playback-button" onClick={this.togglePlayback}>{text}</div>
        );
    }
});
