var React = require('react');
var Track = require('./Track.react');

var reactor = require('../reactor');
var getters = require('../getters');
var actions = require('../actions');

module.exports = React.createClass({
    mixins: [reactor.ReactMixin],

    getDataBindings: function () {
        return {
            tracks: getters.tracks
        };
    },

    render: function () {
        return (
            <div className="feed">
                {this.state.tracks.map(function (track) {
                    return (
                        <Track key={track.get('id')} track={track.toJS()} />
                    );
                }).toList()}
            </div>
        );
    }
});
