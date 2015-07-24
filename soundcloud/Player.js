var actions = require('../modules/tracks/actions');

module.exports = function(clientId) {
    var _tracks = {};

    return {
        play: function (trackId, streamUrl) {
            if (typeof _tracks[trackId] === "undefined") {
                var audio = document.createElement('audio');
                audio.src = streamUrl + '?client_id=' + clientId;
                audio.addEventListener('timeupdate', function (e) {
                    var currentTime = e.target.currentTime;
                    var duration = e.target.duration;
                    actions.trackProgress(trackId, parseFloat(currentTime/duration*100).toFixed(2));
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

