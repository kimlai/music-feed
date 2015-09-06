var React = require('react');
var Link = require('react-router').Link;
var TracksModule = require('../modules/tracks');

var reactor = require('../reactor');

var getters = TracksModule.getters;

module.exports = React.createClass({
    mixins: [reactor.ReactMixin],

    getDataBindings: function () {
        return {
            playlistId: getters.currentPlaylistId
        };
    },

    render: function () {
        var navItems = [
            { path: 'feed', displayName: 'Feed', playlistId: 'feed' },
            { path: 'saved-tracks', displayName: 'Saved Tracks', playlistId: 'savedTracks' },
            { path: 'published-tracks', displayName: 'Published Tracks', playlistId: 'publishedTracks' },
        ];
        var _self = this;
        return (
            <nav className="navigation">
                <ul>
                    {navItems.map(function (navItem) {
                        var className = (navItem.playlistId === _self.state.playlistId) ? "playing": "";
                        return (
                            <li key={navItem.path}>
                                <Link className={className} to={navItem.path}>{navItem.displayName}</Link>
                            </li>
                        );
                    })}
                </ul>
            </nav>
        );
    }
});
