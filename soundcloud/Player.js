var actions = require('../modules/tracks/actions');

module.exports = function(clientId) {
    var _tracks = {};

    return {
        play: function (trackId, streamUrl) {
            if (typeof _tracks[trackId] === "undefined") {
                var audio = document.createElement('audio');
                audio.src = streamUrl + '?client_id=' + clientId;
                audio.addEventListener('timeupdate', function (e) {
                    actions.trackProgress(trackId, e.target.currentTime*1000);
                });
                _tracks[trackId] = audio;
            }
            _tracks[trackId].play();
            actions.playTrackSuccess(trackId);
        },

        pause: function (trackId) {
            _tracks[trackId].pause();
            actions.pauseTrackSuccess(trackId);
        }
    };
};

