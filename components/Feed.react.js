var React = require('react');
var PlaylistTrack = require('./PlaylistTrack.react');
var PlaylistLoader = require('./PlaylistLoader.react');
var TracksModule = require('../modules/tracks');

var reactor = require('../reactor');

var getters = TracksModule.getters;
var actions = TracksModule.actions;

module.exports = React.createClass({
    mixins: [reactor.ReactMixin],

    getDataBindings: function () {
        return {
            playlist: getters.feedWithTrackInfo
        };
    },

    fetchFeed: function () {
        actions.fetchFeed();
    },

    render: function () {
        var moreButton;
        switch (this.state.playlist.get('fetchingStatus')) {
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
            <div>
                {this.state.playlist.get('tracks').map(function (track) {
                    return (
                        <PlaylistTrack key={track.get('id')} track={track} playlistId={'feed'} />
                    );
                }).toList()}
                {moreButton}
            </div>
        );
    }
});
