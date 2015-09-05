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
            tracks: getters.publishedTracksWithTrackInfo
        };
    },

    render: function () {
        return (
            <div className="published-tracks">
                {this.state.tracks.map(function (track) {
                    return (
                        <PlaylistTrack key={track.get('id')} track={track} playlistId={'publishedTracks'} />
                    );
                }).toList()}
            </div>
        );
    }
});
