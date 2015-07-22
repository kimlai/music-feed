module.exports = function(clientId) {
    var _tracks = {};

    return {
        play: function (trackId, streamUrl, onTimeUpdate) {
            if (typeof _tracks[trackId] === "undefined") {
                var audio = document.createElement('audio');
                audio.src = streamUrl + '?client_id=' + clientId;
                audio.addEventListener('timeupdate', onTimeUpdate);
                _tracks[trackId] = audio;
            }
            _tracks[trackId].play();
        },

        pause: function (trackId) {
            _tracks[trackId].pause();
        }
    };
};
