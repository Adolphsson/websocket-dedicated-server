const express = require('express');

const app = express();

//setting middleware
app.use ('/healthcheck', require ('express-healthcheck') ());
app.use(express.static(__dirname + '/game', {
  setHeaders: (res) => {
    res.set('Cross-Origin-Opener-Policy', 'same-origin');
    res.set('Cross-Origin-Embedder-Policy', 'require-corp');
  },
  dotfiles: 'allow'
})); //Serves resources from game folder

var server = app.listen(8000);