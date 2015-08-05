var actions = require('../modules/tracks/actions');

module.exports = function(clientId) {
    var _tracks = {};

    return {
        play: function (trackId, streamUrl) {
            if (typeof _tracks[trackId] === "undefined") {
                var audio = document.createElement('audio');
                audio.src = streamUrl + '?client_id=' + clientId;
                audio.addEventListener('playing', function (e) {
                    actions.playTrackSuccess(trackId);
                });
                audio.addEventListener('ended', function (e) {
                    actions.next();
                });
                audio.addEventListener('timeupdate', function (e) {
                    actions.trackProgress(trackId, e.target.currentTime*1000);
                });
                audio.addEventListener('pause', function (e) {
                    actions.pauseTrackSuccess(trackId);
                });
                _tracks[trackId] = audio;
            }
            _tracks[trackId].play();
        },

        pause: function (trackId) {
            audio = _tracks[trackId];
            audio.pause();
        }
    };
};
