var React = require('react');
var ProgressBar = require('./ProgressBar.react');
var actions = require('../modules/tracks').actions;

module.exports = React.createClass({
    togglePlayback: function () {
        var playbackStatus = this.props.track.get('playbackStatus');
        if (playbackStatus === 'playing') {
            actions.pauseTrack(this.props.track.get('id'));
        } else {
            actions.setCurrentPlaylistId(this.props.playlistId);
            actions.playTrack(this.props.track.get('id'));
        }
    },

    render: function () {
        return (
            <div className="track">
                <div className="track-info-container" onClick={this.togglePlayback}>
                    <img src={this.props.track.get('artwork_url')} />
                    <div className="track-info">
                        <div>{this.props.track.get('user').get('username')}</div>
                        <div>{this.props.track.get('title')}</div>
                    </div>
                </div>
                <ProgressBar
                    currentTime={this.props.track.get('currentTime')}
                    duration={this.props.track.get('duration')}
                    trackId={this.props.track.get('id')}
                />
            </div>
        );
    }
});
