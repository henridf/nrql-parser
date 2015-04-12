var expect = require('chai').expect;
var withData = require('leche').withData;
var samples = require('./samples');

var parser = require('../lib/nrql.js');

describe('Parses valid queries without error', function() {
    withData(samples, function(query) {
        it(query, function() { parser.parse(query); });
    });
});

