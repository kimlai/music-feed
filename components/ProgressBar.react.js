var React = require('react');
var PureRenderMixin = require('react/addons').addons.PureRenderMixin;
var moment = require('moment');

module.exports = React.createClass({
    mixins: [PureRenderMixin],

    render: function () {
        var progress = this.props.currentTime / this.props.duration * 100;
        var innerStyle = {
            width: progress + "%",
        };

        return (
            <div>
                <div className="progress-bar outer">
                    <div className="inner" style={innerStyle} />
                </div>
                <div>
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
