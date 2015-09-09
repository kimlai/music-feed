var React = require('react');
var PlaylistTrack = require('./PlaylistTrack.react');
var PlaylistLoader = require('./PlaylistLoader.react');

var TracksModule = require('../modules/tracks');
var actions = TracksModule.actions;
var reactor = require('../reactor');

module.exports = function (getter) {
    return React.createClass({
        mixins: [reactor.ReactMixin],

           getDataBindings: function () {
               return {
                   playlist: getter
               };
           },

           fetchFeed: function () {
               actions.fetchMoreTracks(this.state.playlist.get('id'));
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
               var _self = this;
               return (
                   <div>
                       {this.state.playlist.get('tracks').map(function (track) {
                            return (
                                <PlaylistTrack
                                    key={track.get('id')}
                                    track={track}
                                    playlistId={_self.state.playlist.get('id')}
                                />
                            );
                       }).toList()}
                       {moreButton}
                   </div>
              );
           }
    });
};
