var React = require('react');
var PlaylistTrack = require('./PlaylistTrack.react');
var TracksModule = require('../modules/tracks');

var reactor = require('../reactor');

var getters = TracksModule.getters;
var actions = TracksModule.actions;

module.exports = React.createClass({
    mixins: [reactor.ReactMixin],

    getDataBindings: function () {
        return {
            feed: getters.feedWithTrackInfo
        };
    },

    fetchFeed: function () {
        actions.fetchFeed();
    },

    render: function () {
        var moreButton;

        switch (this.state.feed.get('fetchingStatus')) {
            case 'fetching':
                moreButton = <PlaylistLoader />;
                break;
            case 'failed':
                moreButton =
                    <div className="more-button" onClick={this.fetchFeed}>
                        It looks like something went wrong. Retry ?
                    </div>;
                break;
            default:
                moreButton = <div className="more-button" onClick={this.fetchFeed}>More</div>;
                break;
        }
        return (
            <div className="feed">
                {this.state.feed.get('tracks').map(function (track) {
                    return (
                        <PlaylistTrack key={track.get('id')} track={track} playlistId={'feed'} />
                    );
                }).toList()}
                {moreButton}
            </div>
        );
    }
});

var PlaylistLoader = React.createClass({
    render: function () {
        var placeholders = [];
        for (var i=0; i < 10; i++) {
            placeholders.push(
                <div className="track" key={i}>
                    <div className="track-info-container">
                        <img src="/images/placeholder.jpg" />
                    </div>
                    <div className="progress-bar">
                        <div className="outer" />
                    </div>
                </div>
            );
        }

        return (
            <div>
                {placeholders}
            </div>
        );
    }
});
