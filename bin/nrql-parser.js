#!/usr/bin/env node

'use strict';

var parser = require('../lib/nrql.js');

var ast;

var query =
        'SELECT average(duration), percentile(duration, 50, 90)  FROM PageView SINCE 1 week AGO TIMESERIES AUTO';
//'SELECT uniqueCount(session), percentile(duration, 95)  FROM PageView WHERE userAgentOS = "Windows"   FACET countryCode LIMIT 20';

//'SELECT histogram(created_on_hour, origin) FROM PagerdutyIncident WHERE a = 1 OR b NOT LIKE "1" ';

try {
    ast = parser.parse(query);
} catch (e) {
    console.log("Syntax error at line", e.line, "column", e.column, ':', e.message);
    process.exit(-1);
}

console.log(JSON.stringify(ast, null, 4));
