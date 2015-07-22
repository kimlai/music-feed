var React = require('react');
var actions = require('../actions');

module.exports = React.createClass({
    getInitialState: function () {
        return {};
    },

    togglePlayback: function () {
        var isPlaying = this.props.track.isPlaying;
        if (isPlaying) {
            actions.pauseTrack(this.props.track.id);
        } else {
            actions.playTrack(this.props.track.id, this.props.track.stream_url);
        }
    },

    render: function () {
        var text = this.props.track.isPlaying ? 'Pause' : 'Play';
        return (
            <div className="playback-button" onClick={this.togglePlayback}>{text}</div>
        );
    }
});
