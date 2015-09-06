var React = require('react');
var ProgressBar = require('./ProgressBar.react');
var actions = require('../modules/tracks').actions;
var moment = require('moment');

moment.locale('en', {
    relativeTime : {
        future: "in %s",
        past:   "%s ago",
        s:  "a few seconds",
        m:  "1 minute",
        mm: "%d minutes",
        h:  "1 hour",
        hh: "%d hours",
        d:  "1 day",
        dd: "%d days",
        M:  "1 month",
        MM: "%d months",
        y:  "1 year",
        yy: "%d years"
    }
});

module.exports = React.createClass({
    getInitialState: function () {
        return { timeAgo: '' };
    },

    componentDidMount: function () {
        var timestamp;
        if (this.props.track.has('saved_at')) {
            timestamp = moment(this.props.track.get('saved_at'));
        } else {
            timestamp = moment(this.props.track.get('created_at'), 'YYYY/MM/DD HH:mm:ss Z');
        }
        this.setState({timeAgo: timestamp.fromNow(true)});
        var _self = this;
        this.timer = setInterval(function () {
            _self.setState({timeAgo: timestamp.fromNow(true)});
        }, 60000);
    },

    componentWillUnmount: function () {
        clearInterval(this.timer);
    },

    togglePlayback: function () {
        var playbackStatus = this.props.track.get('playbackStatus');
        if (playbackStatus === 'playing') {
            actions.pauseTrack(this.props.track.get('id'));
        } else {
            actions.setCurrentPlaylistId(this.props.playlistId);
            actions.playTrack(this.props.track.get('id'));
        }
    },

    blacklistTrack: function () {
        actions.blacklistTrack(this.props.track.get('id'));
    },

    saveTrack: function () {
        actions.saveTrack(this.props.track.get('id'));
    },

    publishTrack: function () {
        actions.publishTrack(this.props.track.get('id'));
    },

    render: function () {
        var coverUrl = this.props.track.get('artwork_url') || '/images/placeholder.jpg';
        return (
            <div className="track">
                <div className="track-info-container">
                    <img src={coverUrl} onClick={this.togglePlayback}/>
                    <div>
                        <div className="track-info" onClick={this.togglePlayback}>
                            <div>{this.props.track.get('user').get('username')}</div>
                            <div>{this.props.track.get('title')}</div>
                        </div>
                        <div className="actions">
                            <div onClick={this.blacklistTrack}>Blacklist</div>
                            <div onClick={this.saveTrack}>Save</div>
                            <div onClick={this.publishTrack}>Publish</div>
                        </div>
                    </div>
                    <div className="time-ago">{this.state.timeAgo}</div>
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
