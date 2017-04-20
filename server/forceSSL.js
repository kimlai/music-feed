module.exports = function *forceSSL(next) {
    const request = this.request;
    if (request.get('x-forwarded-proto') === 'https') {
        yield next;
        return;
    }
    if (this.method === 'GET') {
        this.status = 301;
        this.redirect(`https://${request.host}${request.url}`);
        return;
    }
    this.status = 405;
    this.body = 'SSL required';
}
