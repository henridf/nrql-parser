// helper script that used to extract nrqls from
// https://github.com/tmartin14/spring-travel/tree/ebda4409af140d997358206c15028f8498e99f3c/Insights-Dashboards
// (they're in queries.txt in this dir)

var fs = require('fs');
var _ = require('lodash');

function go(filename) {
    var s = fs.readFileSync(filename).toString();
    var o = JSON.parse(s);
    return  _.map(o.widgets, function(widget) {
        return widget.nrql;
    });
}


if (process.argv.length !== 3) {
    console.log(process.argv);
    console.log("Usage: parse-spring-travel-json.js <filename>")
    process.exit(-1);
}

var nrqls = go(process.argv[2]);

console.log("-- ", process.argv[2] + '\n');
_.each(nrqls, function(nrql) { console.log(nrql +'\n')});
console.log('\n');
