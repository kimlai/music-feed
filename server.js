var koa = require('koa');
var mount = require('koa-mount');
var radio = require('./server/radioApp');
var feed = require('./server/feedApp');
var serve = require('koa-static');
var views = require('koa-views');

var app = koa();

app.use(serve('./public'));

app.use(views('views', {
    map: {
        html: 'underscore',
    }
}));

app.use(mount('/', radio));
app.use(mount('/feed', feed));

app.listen(process.env.PORT || 3000);
