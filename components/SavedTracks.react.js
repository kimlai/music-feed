var React = require('react');
var Track = require('./Track.react');
var TracksModule = require('../modules/tracks');

var reactor = require('../reactor');

var getters = TracksModule.getters;
var actions = TracksModule.actions;

module.exports = React.createClass({
    mixins: [reactor.ReactMixin],

    getDataBindings: function () {
        return {
            tracks: getters.savedTracks
        };
    },

    render: function () {
        return (
            <div className="saved-tracks">
                {this.state.tracks.map(function (track) {
                    return (
                        <Track key={track.get('id')} track={track} />
                    );
                }).toList()}
            </div>
        );
    }
});
