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
        return (
            <div className="track">
                <div>{this.props.track.get('title')} - {this.props.track.get('id')}</div>
                <div onClick={this.blacklistTrack}>Blacklist</div>
                <div onClick={this.saveTrack}>Save</div>
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
