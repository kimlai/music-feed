var Youtube = function(app) {
    this.currentTrackId = null;
    this.updateTrackProgress = null;
    this.waitingTrack = null;

    this.onPlayerReady = function() {
        var waitingTrack = this.waitingTrack;
        if (waitingTrack !== null) {
            this.play(waitingTrack);
            waitingTrack = null;
        }
        var _this = this;
        window.setInterval(function () {
            if (_this.currentTrackId !== null) {
                var currentTime = _this.video.getCurrentTime();
                var duration = _this.video.getDuration();
                app.ports.trackProgress.send([
                    _this.currentTrackId,
                    currentTime / duration * 100,
                    currentTime
                ]);
            }},
            500
        );
    };

    this.onPlayerError = function () {
        app.ports.trackError.send(this.currentTrackId);
    };

    this.video = new YT.Player('player', {
        height: '390',
        width: '620',
        events: {
            'onStateChange': function (e) {
                if (e.data == YT.PlayerState.ENDED) {
                    app.ports.trackEnd.send(this.currentTrackId);
                }
            },
            'onError': this.onPlayerError.bind(this),
            'onReady': this.onPlayerReady.bind(this),
        }
    });

    this.play = function(track) {
        if (this.currentTrackId === track.id) {
            this.video.playVideo();
            return;
        }
        if (this.video.loadVideoById) {
            this.currentTrackId = track.id;
            this.video.loadVideoById(track.youtubeId, track.currentTime);
        } else {
            this.waitingTrack = track;
        }
    };

    this.pause = function(track) {
        if (this.video.pauseVideo) this.video.pauseVideo();
    };

    this.seek = function(amount) {
        if (this.video.seekTo) this.video.seekTo(this.video.getCurrentTime() + amount);
    };
};
