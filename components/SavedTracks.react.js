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
            tracks: getters.savedTracksWithTrackInfo
        };
    },

    render: function () {
        return (
            <div className="saved-tracks">
                <h1>Saved Tracks</h1>
                {this.state.tracks.map(function (track) {
                    return (
                        <PlaylistTrack key={track.get('id')} track={track} playlistId={'savedTracks'} />
                    );
                }).toList()}
            </div>
        );
    }
});
