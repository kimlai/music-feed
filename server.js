var koa = require('koa');
var mount = require('koa-mount');
var radio = require('./server/radioApp');
var feed = require('./server/feedApp');
var serve = require('koa-static');
var views = require('koa-views');
var compress = require('koa-compress');
var forceSSL = require('./server/forceSSL');

var app = koa();

if (process.env.NODE_ENV === 'production') {
    app.use(forceSSL);
}
app.use(compress());
app.use(serve('./public'));

app.use(views('views', {
    map: {
        html: 'underscore',
    }
}));

app.use(mount('/', radio));
app.use(mount('/feed', feed));


app.listen(process.env.PORT || 3000);
