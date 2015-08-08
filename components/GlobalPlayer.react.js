var React = require('react');
var Track = require('./Track.react');
var TracksModule = require('../modules/tracks');

var reactor = require('../reactor');

var getters = TracksModule.getters;

module.exports = React.createClass({
    mixins: [reactor.ReactMixin],

    getDataBindings: function () {
        return {
            track: getters.currentTrack
        };
    },

    next: function () {
        TracksModule.actions.next();
    },

    render: function () {
        return (
            <div className="global-player">
                <Track track={this.state.track} />
                <div className="next-button" onClick={this.next}>Next</div>
            </div>
        );
    }
});
