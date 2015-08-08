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
            tracks: getters.feedTracks
        };
    },

    fetchFeed: function () {
        actions.fetchFeed();
    },

    render: function () {
        return (
            <div className="feed">
                {this.state.tracks.map(function (track) {
                    return (
                        <Track key={track.get('id')} track={track} />
                    );
                }).toList()}
                <div onClick={this.fetchFeed}>More</div>
            </div>
        );
    }
});
