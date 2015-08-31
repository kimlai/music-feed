var React = require('react');
var PlaybackButton = require('./PlaybackButton.react');
var ProgressBar = require('./ProgressBar.react');
var actions = require('../modules/tracks').actions;

module.exports = React.createClass({
    blacklistTrack: function () {
        actions.blacklistTrack(this.props.track.get('id'));
    },

    saveTrack: function () {
        actions.saveTrack(this.props.track.get('id'));
    },

    render: function () {
        var artist = '';
        if (this.props.track.has('user')) {
            artist = this.props.track.get('user').get('username');
        }
        return (
            <div className="track">
                <div>{artist} - {this.props.track.get('title')}</div>
                <div className="blacklist-button" onClick={this.blacklistTrack}>Blacklist</div>
                <div className="save-button" onClick={this.saveTrack}>Save</div>
                <PlaybackButton track={this.props.track.toJS()} playlistId={this.props.playlistId}  />
                <ProgressBar
                    currentTime={this.props.track.get('currentTime')}
                    duration={this.props.track.get('duration')}
                    trackId={this.props.track.get('id')}
                />
            </div>
        );
    }
});
