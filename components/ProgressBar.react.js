var React = require('react');
var PureRenderMixin = require('react/addons').addons.PureRenderMixin;
var moment = require('moment');
var actions = require('../modules/tracks').actions;

module.exports = React.createClass({
    mixins: [PureRenderMixin],

    seek: function (e) {
        var timeSeeked = (e.pageX - e.target.offsetLeft) / e.target.offsetWidth * this.props.duration;
        actions.seekTrack(this.props.trackId, timeSeeked);
    },

    render: function () {
        var progress = this.props.currentTime / this.props.duration * 100;
        var innerStyle = {
            width: progress + "%",
        };

        return (
            <div>
                <div className="progress-bar outer" onClick={this.seek}>
                    <div className="inner" style={innerStyle} />
                </div>
                <div className="timer">
                    {millisecondsToTime(this.props.currentTime)}
                    /
                    {millisecondsToTime(this.props.duration)}
                </div>
            </div>
        );
    }
});

function millisecondsToTime(milliseconds) {
    var time = moment.duration(milliseconds);
    var minutes = time.minutes();
    var seconds = time.seconds();

    return pad(minutes) + ':' + pad(seconds);
}

function pad(value) {
    if ((''+value).length > 1) {
        return value;
    }

    return '0' + value;
}
