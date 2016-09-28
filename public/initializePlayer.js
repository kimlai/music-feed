function initializePlayer(soundcloudClientId, app) {
    var soundcloud = new Soundcloud(soundcloudClientId, app);
    var youtube = new Youtube(app);

    app.ports.playSoundcloudTrack.subscribe(function(track) {
        youtube.pause();
        soundcloud.play(track);
    });

    app.ports.changeSoundcloudCurrentTime.subscribe(function(amount) {
        soundcloud.seek(amount);
    });

    app.ports.seekSoundcloudToPercentage.subscribe(function(position) {
        soundcloud.seekTo(position);
    });

    app.ports.changeYoutubeCurrentTime.subscribe(function(amount) {
        youtube.seek(amount);
    });

    app.ports.seekYoutubeToPercentage.subscribe(function(position) {
        youtube.seekTo(position);
    });

    app.ports.pause.subscribe(function(trackId) {
        soundcloud.pause();
        youtube.pause();
    });

    app.ports.playYoutubeTrack.subscribe(function(track) {
        soundcloud.pause();
        youtube.play(track);
    });

    return app;
}
