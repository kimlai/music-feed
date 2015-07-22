var React = require('react');
var PlaybackButton = require('./PlaybackButton.react');
var ProgressBar = require('./ProgressBar.react');

module.exports = React.createClass({
    render: function () {
        return (
            <div className="track">
                <div>{this.props.track.title} - {this.props.track.id}</div>
                <PlaybackButton track={this.props.track}  />
                <ProgressBar progress={this.props.track.progress} />
            </div>
        );
    }
});
