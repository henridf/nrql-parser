/*
 * NRQL Grammar.
 * Derived from the NRQL reference at https://docs.newrelic.com/docs/insights/new-relic-insights/using-new-relic-query-language/nrql-reference
 *
 * Some parts of NRQL are not (yet) in this grammar:
 *   - math in SELECT clauses (https://docs.newrelic.com/docs/insights/new-relic-insights/using-new-relic-query-language/nrql-math)
 *   - backtick-quoted custom attributes
 *   - flexible ordering of clauses: the informal grammar at
 *     https://docs.newrelic.com/docs/insights/new-relic-insights/using-new-relic-query-language/nrql-reference#syntax
 *     appears to say that clause order is fixed, but the example at
 *     https://discuss.newrelic.com/t/browser-version-percentage-report-by-geo-location/15311
 *     places a FACET in a different place. Need to un-hardcode the order of clauses in the 'Select' rule.
 *
 */

// Query tokens
SelectToken      = "SELECT"i !IdentifierPart
FromToken        = "FROM"i !IdentifierPart
WhereToken       = "WHERE"i !IdentifierPart
AsToken          = "AS"i !IdentifierPart
FacetToken       = "FACET"i !IdentifierPart
LimitToken       = "LIMIT"i !IdentifierPart
SinceToken       = "SINCE"i !IdentifierPart
UntilToken       = "UNTIL"i !IdentifierPart
CompareWithToken = "COMPARE WITH"i !IdentifierPart
TimeseriesToken  = "TIMESERIES"i !IdentifierPart
AutoToken        = "AUTO"i !IdentifierPart

// Aggregator tokens
ApdexToken       = "apdex" !IdentifierPart
AverageToken     = "average" !IdentifierPart
CountToken       = "count" !IdentifierPart
FilterToken      = "filter" !IdentifierPart
FunnelToken      = "funnel" !IdentifierPart
HistogramToken   = "histogram" !IdentifierPart
LatestToken      = "latest" !IdentifierPart
MaxToken         = "max" !IdentifierPart
MinToken         = "min" !IdentifierPart
PercentageToken  = "percentage" !IdentifierPart
PercentileToken  = "percentile" !IdentifierPart
SumToken         = "sum" !IdentifierPart
UniqueCountToken = "uniqueCount" !IdentifierPart
UniquesToken     = "uniques" !IdentifierPart


// Operator tokens
InToken          = "IN"i !IdentifierPart
AndToken         = "AND"i !IdentifierPart
OrToken          = "OR"i !IdentifierPart
NotToken         = "NOT"i !IdentifierPart
LikeToken        = "LIKE"i !IdentifierPart
IsToken          = "IS"i !IdentifierPart

// Value tokens
NullToken        = "NULL"i !IdentifierPart
StarToken        = "*" !IdentifierPart

// Date/time tokens
MinutesToken      = ("MINUTES"i/"MINUTE"i) !IdentifierPart
HoursToken        = ("HOURS"i/"HOUR"i) !IdentifierPart
DaysToken         = ("DAYS"i/"DAY"i) !IdentifierPart
WeeksToken        = ("WEEKS"i/"WEEK"i) !IdentifierPart
MonthsToken       = ("MONTHS"i/"MONTH"i) !IdentifierPart
AgoToken         = "AGO"i !IdentifierPart
YesterdayToken   = "YESTERDAY"i !IdentifierPart


KeyWord
    = SelectToken
    / AsToken
    / WhereToken
    / FromToken
    / FacetToken
    / LimitToken
    / SinceToken
    / UntilToken
    / CompareWithToken
    / TimeseriesToken
    / AutoToken
    / AndToken
    / OrToken
    / NotToken
    / LikeToken
    / NullToken
    / IsToken
    / InToken
    / MinutesToken
    / HoursToken
    / DaysToken
    / WeeksToken
    / MonthsToken
    / AgoToken
    / YesterdayToken
    / StarToken


_ = [ \t\n\r]*

ArgDelim = _ ',' _

Argument = Identifier / FloatLiteral

StarLiteral
    = StarToken {
        return { type: "StarLiteral", value: null };
    }

Query = _ select:Select _ {
    return select;
}

FromClause = FromToken _ table:Identifier {
    return table;
}

FacetClause = FacetToken _ attribute:Identifier {
    return attribute;
}

LimitClause = LimitToken _ count:FloatLiteral {
    return count;
}

SinceClause = SinceToken _ time:TimeAgo {
    return time;
}

UntilClause = UntilToken _ time:TimeAgo {
    return time;
}

CompareWithClause = CompareWithToken _ time:TimeAgo {
    return time;
}

DurationAuto
    = Duration
    / AutoToken { return {type: "Auto"}; }

TimeseriesClause = TimeseriesToken _ dur:(DurationAuto) {
    return dur;
}

WhereComparisonOp
    = "="
    / "!="
    / "<"
    / "<="
    / ">"
    / ">="
    / InToken

AndOperator = AndToken { return "and"; }
OrOperator = OrToken  { return "or"; }
NotOperator = NotToken { return "not"; }

DurationUnit
    = MinutesToken { return "m"; }
    / HoursToken { return "h"; }
    / DaysToken { return "d"; }
    / WeeksToken { return "w"; }
    / MonthsToken { return "M"; }


Duration
    = quantity:FloatLiteral _ unit:DurationUnit {
        return {
            type: "duration",
            quantity: quantity,
            unit: unit }
    }


TimeAgo
    = duration:Duration _ AgoToken {
        return { type: "TimeAgo",
                 duration: duration }
    }
    / YesterdayToken {
        return { type: "TimeAgo",
                 duration: {
                     type: "duration",
                     quantity: 24,
                     unit: "h"
                 }
               }
    }
    / date:StringLiteral {
        return { type: "DateString",
                 value: date }
    }


Literal
    = FloatLiteral
    / StringLiteral

NullLiteral
    = NullToken { return { type: "NullLiteral" }; }

LiteralList = '(' head:Literal tail:(',' _ Literal)* ')' {
    return [head].concat(tail);
}

WhereANDCondition = head:WhereCondition _ tail:(AndOperator _ WhereANDCondition _)* {
    var result = head;

    for (var i=0; i<tail.length; i++) {
        result = { type: "BinaryExpression",
                   op: tail[i][0],
                   left: result,
                   right: tail[i][2]
                 }
    }

    return result;
}

WhereORCondition = head:WhereANDCondition _ tail:(OrOperator _ WhereANDCondition _)* {
    var result = head;

    for (var i=0; i<tail.length; i++) {
        result = { type: "BinaryExpression",
                   op: tail[i][0],
                   left: result,
                   right: tail[i][2]
                 }
    }

    return result;
}

WhereClause = WhereToken _ cond:WhereORCondition {
    return cond;
}

WhereCondition
    = attribute:Identifier _ op:WhereComparisonOp _ right:Literal {
        return { type: "WhereCondition",
                 condition: { attribute: attribute,
                              op: op,
                              right: right }
               }
    }
    / attribute:Identifier _ InToken _ right:LiteralList {
        return { type: "WhereCondition",
                 condition: { attribute: attribute,
                              op: 'in',
                              right: right}
               }
    }
    / attribute:Identifier _ IsToken _ not:NotToken? _ right:NullLiteral  {
        return { type: "WhereCondition",
                 condition: { attribute: attribute,
                              op: not ? '!=' : '=',
                              right: right}
               }
    }
    / attribute:Identifier _ not:NotToken? _ LikeToken _ right:StringLiteral  {
        return { type: "WhereCondition",
                 condition: { attribute: attribute,
                              op: not ? '!~' : '=~',
                              right: right}
               }
    }



// Aggregators that take a single 'attribute' argument
SimpleAggrToken
    = AverageToken
    / LatestToken
    / MaxToken
    / MinToken
    / SumToken
    / UniqueCountToken
    / UniquesToken

SimpleAggrExpression = name:SimpleAggrToken _ '(' _ attr:Identifier _ ')' {
    return {
        type: "FunctionExpression",
        name: name[0],
        arguments: [attr]
    };
}

ApdexExpression = name:ApdexToken _ '(' _ attr:Identifier _ ',' _ 't:' _ thresh:FloatLiteral _ ')' {
    return {
        type: "FunctionExpression",
        name: name[0],
        arguments: [attr, thresh]
    };
}

CountExpression = name:CountToken _ '(' _ arg:(StarLiteral / Identifier) _ ')' {
    return {
        type: "FunctionExpression",
        name: name[0],
        arguments: [arg]
    };
}

// reference seems to say that WHERE token is mandatory, but other places
// (e.g. https://discuss.newrelic.com/t/facet-in-vs-filter/27676) show queries
// that omit it, hence the presence of 'WhereORCondition' in this rule
FilterExpression = name:FilterToken _ '(' expr:AggrExpression _ ',' _
                   where:(WhereClause / WhereORCondition ) _ ')' {
    return {
        type: "FunctionExpression",
        name: name[0],
        expr: expr,
        where: where
    }
}

FunnelExpression = name:FunnelToken _ '(' attr:Identifier _
                                          wheres:(',' _ WhereClause _
                                                  AsToken _ StringLiteral _ )* ')' {
    var args = [attr];
    for (var i = 0; i < wheres.length; i++) {
        args.push({where: wheres[i][2],
                   as: wheres[i][6]});
    }
    return {
        type: "FunctionExpression",
        name: name[0],
        arguments: args
    }
}

HistogramExpression = name:HistogramToken _ '(' attr:Identifier _ ',' _
                                                ceiling:FloatLiteral _
                                                buckets:(',' _ FloatLiteral _)? ')' {
    var args = [attr, ceiling];
    if (buckets) {
       args.push(buckets[2]);
    }
    return {
        type: "FunctionExpression",
        name: name[0],
        arguments: args
    };
}

PercentageExpression = name:PercentageToken _ '(' expr:AggrExpression _ ',' _
                                                  where:WhereClause _ ')' {
    return {
        type: "FunctionExpression",
        name: name[0],
        expr: expr,
        where: where
    }
}

PercentileExpression = name:PercentileToken _ '(' attr:Identifier _
                                                  percentiles:(',' _ FloatLiteral _)* ')' {
    var args = [attr];
    for (var i = 0; i < percentiles.length; i++) {
        args.push(percentiles[i][2]);
    }
    return {
        type: "FunctionExpression",
        name: name[0],
        arguments: args
    };
}

AggrExpression
    = ApdexExpression
    / CountExpression
    / FilterExpression
    / FunnelExpression
    / HistogramExpression
    / PercentageExpression
    / PercentileExpression
    / SimpleAggrExpression


SelectClauses = head: SelectClause _
                tail:(',' _ SelectClause)* {

  var result = [head];
  for (var i = 0; i < tail.length; i++) {
     result.push(tail[i][2]);
  }

  return result;
}

SelectClause =
    call:AggrExpression _ label:(AsToken _ StringLiteral)? {
        var clause = { type: "SelectClause",
                       value: call};
        if (label !== null) {
            clause.label = label[2];
        }
        return clause;
    }
    / attr:Identifier {
        return {type: "SelectClause",
                value: attr}
    }


Select = SelectToken _
         selects:SelectClauses _
         from:FromClause _
         where:WhereClause? _
         facet:FacetClause? _
         limit:LimitClause? _
         since:SinceClause? _
         until:UntilClause? _
         compare:CompareWithClause? _
         series:TimeseriesClause? {

   var res = { type: "Select",
               selects: selects,
               from: from };

   if (where) res.where = where;
   if (facet) res.facet = facet;
   if (limit) res.limit = limit;
   if (since) res.since = since;
   if (until) res.until = until;
   if (compare) res.compare = compare;
   if (series) res.series = series;

   return res;
}



/*
 * Everything below this comes from the javascript grammar in the
 * pegjs distribution (some parts adapted)
 */

Identifier
    = !KeyWord name:IdentifierName { return name; }

IdentifierName
    = first:IdentifierStart rest:IdentifierPart* {
        return {
            type: "Identifier",
            name: first + rest.join("")
        };
    }

IdentifierStart
    = IdentifierPart
    / "$"


IdentifierPart
    = [a-zA-Z_]


SourceCharacter
    = .

StringLiteral
    = '"' chars:DoubleStringCharacter* '"' {
        return { type: "StringLiteral", value: chars.join("") };
    }
    / "'" chars:SingleStringCharacter* "'" {
        return { type: "StringLiteral", value: chars.join("") };
    }

DoubleStringCharacter
    = !('"' / "\\" / LineTerminator) SourceCharacter { return text(); }

SingleStringCharacter
    = !("'" / "\\" / LineTerminator) SourceCharacter { return text(); }


FloatLiteral
    = DecimalDigit* "." DecimalDigit+ {
        return { type: "FloatLiteral", value: parseFloat(text()) };
    }
    / DecimalDigit+ {
        return { type: "FloatLiteral", value: parseFloat(text()) };
    }


DecimalDigit
  = [0-9]

LineTerminator
  = [\n\r\u2028\u2029]
