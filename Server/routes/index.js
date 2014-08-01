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

router.get('/cachedusers', function(req, res) {
	//console.log(req);
	if (req.query.cacheKey == "CACHE1234") {
		fs.readFile('fixtures/cacheresponse.json', function(err, data) {
			if (err) throw err;
			data = JSON.parse(data);
			console.log(data);
			res.json(data);
		});
	} else {
		fs.readFile('fixtures/cachedusers.json', function(err, data) {
			if (err) throw err;
			data = JSON.parse(data);
			console.log(data);
			res.json(data);
		});
	}
});

router.get('/userswithrepo', function(req, res) {
	fs.readFile('fixtures/users_with_relations.json', function(err, data) {
		if (err) throw err;
		data = JSON.parse(data);
		res.json(data);
	});
});

module.exports = router;
