var Soundcloud = function (soundcloudClientId, app) {
    var currentTrackId = null;

    var audio = new Audio();
    audio.addEventListener('timeupdate', function (e) {
        app.ports.trackProgress.send([
            currentTrackId,
            e.target.currentTime / e.target.duration * 100,
            e.target.currentTime
        ]);
    });
    audio.addEventListener('ended', function (e) {
        app.ports.trackEnd.send(currentTrackId);
    });
    audio.addEventListener('error', function (e) {
        app.ports.trackError.send(currentTrackId);
    });

    return {
        play: function(track) {
            currentTrackId = track.id;
            audio.src = track.streamUrl + '?client_id=' + soundcloudClientId;
            audio.currentTime = track.currentTime;
            audio.play();
        },

        pause: function() {
            audio.pause();
        },

        seek: function (amount) {
            audio.currentTime = audio.currentTime + amount;
        },

        seekTo: function (positionInPercentage) {
            audio.currentTime = audio.duration * positionInPercentage / 100;
        },
    };
};
