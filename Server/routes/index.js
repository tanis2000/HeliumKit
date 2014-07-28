var express = require('express');
var fs = require('fs');
var router = express.Router();

router.get('/users', function(req, res) {
	fs.readFile('fixtures/users.json', function(err, data) {
		if (err) throw err;
		data = JSON.parse(data);
		res.json(data);
	});
});

router.post('/users', function(req, res) {
	fs.readFile('fixtures/users.json', function(err, data) {
		if (err) throw err;
		data = JSON.parse(data);
		res.json(data);
	});
});

module.exports = router;
