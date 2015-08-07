var React = require('react');
var PlaybackButton = require('./PlaybackButton.react');
var ProgressBar = require('./ProgressBar.react');

module.exports = React.createClass({
    render: function () {
        return (
            <div className="track">
                <div>{this.props.track.get('title')} - {this.props.track.get('id')}</div>
                <PlaybackButton track={this.props.track.toJS()}  />
                <ProgressBar
                    currentTime={this.props.track.get('currentTime')}
                    duration={this.props.track.get('duration')}
                    trackId={this.props.track.get('id')}
                />
            </div>
        );
    }
});
