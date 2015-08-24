var request = require('superagent-bluebird-promise');

module.exports = {
    fetchActivities: function (token, nextHref) {
        var link = nextHref ? nextHref + '&' : 'https://api.soundcloud.com/me/activities/tracks/affiliated?';
        return request
            .get(link+'oauth_token='+token)
            .accept('json')
            .then(function (response) {
                return response.body;
            });
    },

    requestAccessToken: function (code) {
        return request
            .post('https://api.soundcloud.com/oauth2/token')
            .send({
                client_id: process.env.SOUNDCLOUD_CLIENT_ID,
                client_secret: process.env.SOUNDCLOUD_SECRET,
                grant_type: 'authorization_code',
                redirect_uri: process.env.MUSICFEED_API_ROOT + '/callback',
                code: code
            })
            .then(function (response) {
                return response.body;
            });
    },

    me: function (token) {
        return request
            .get('https://api.soundcloud.com/me?oauth_token='+token)
            .accept('json')
            .then(function (response) {
                return response.body;
            });
    },

    track: function (trackId) {
        return request
            .get('https://api.soundcloud.com/tracks/' + trackId +'?client_id=' + process.env.SOUNDCLOUD_CLIENT_ID)
            .accept('json')
            .then(function (response) {
                return response.body;
            });
    }
};
