exports.up = function(knex, Promise) {
    return knex.select('soundcloudTrackId', 'track')
        .from('published_tracks')
        .then(function (rows) {
            return Promise.all(
                rows.map(function (row) {
                    var trackInfo = row.track;
                    var trackId = row.soundcloudTrackId;
                    return knex('published_tracks')
                        .where('soundcloudTrackId', '=', trackId)
                        .update({
                            track: {
                                source: trackInfo.permalink_url,
                                artist: trackInfo.user.username,
                                title: trackInfo.title,
                                cover: trackInfo.artwork_url,
                                created_at: trackInfo.created_at,
                                soundcloud: {
                                    id: trackInfo.id,
                                    stream_url: trackInfo.stream_url
                                }
                            }
                        });
                })
            );
        });
};

exports.down = function(knex, Promise) {
    //there's no goiing back from this :)
};
