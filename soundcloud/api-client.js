var request = require('co-request');

module.exports = {
    fetchActivities: function (token) {
        return request.get('https://api.soundcloud.com/me/activities/tracks/affiliated?oauth_token='+token);
    },

    requestAccessToken: function (code) {
        return request.post({
            uri: 'https://api.soundcloud.com/oauth2/token',
            json: {
                client_id: process.env.SOUNDCLOUD_CLIENT_ID,
                client_secret: process.env.SOUNDCLOUD_SECRET,
                grant_type: 'authorization_code',
                redirect_uri: process.env.MUSICFEED_API_ROOT + '/callback',
                code: code
            }
        });
    }
};
