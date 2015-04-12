/*
 * NRQL Grammar.
 * Derived from the NRQL reference at https://docs.newrelic.com/docs/insights/new-relic-insights/using-new-relic-query-language/nrql-reference
 *
 * Some parts of NRQL are not (yet) in this grammar:
 *   - funnel() syntax (with its WHERE clauses)
 *   - math in SELECT clauses (https://docs.newrelic.com/docs/insights/new-relic-insights/using-new-relic-query-language/nrql-math)
 *
 * NRQL syntax questions (some easy enough to verify with access to a NRQL
   interface, but I don't have one):
 * - Does LIMIT accept a decimal (syntax)? (And if yes, does it floor() it or round() it)
 * - Can decimals be used in Moments (e.g. '1.5 days ago'?)
 *
 */

_ = [ \t\n\r]*

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

InToken          = "IN"i !IdentifierPart
AndToken         = "AND"i !IdentifierPart
OrToken          = "OR"i !IdentifierPart
NotToken         = "NOT"i !IdentifierPart
LikeToken        = "LIKE"i !IdentifierPart
IsToken          = "IS"i !IdentifierPart
NullToken        = "NULL"i !IdentifierPart

MinutesToken      = ("MINUTES"i/"MINUTE"i) !IdentifierPart
HoursToken        = ("HOURS"i/"HOUR"i) !IdentifierPart
DaysToken         = ("DAYS"i/"DAY"i) !IdentifierPart
WeeksToken        = ("WEEKS"i/"WEEK"i) !IdentifierPart

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
  / AgoToken
  / YesterdayToken



Argument = Identifier / FloatLiteral

FunctionCall = Identifier '(' head:Argument tail:(_ ',' _ Argument)* ')' {
  var args = [head];
  for (var i = 0; i < tail.length; i++) {
     args.push(tail[i][3]);
  }
  return { type: "FunctionCall",
           arguments: args };
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

LiteralList = '(' head:Literal tail:(',' Literal)* ')' {
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


FunctionCalls = head:FunctionCall _ tail:(',' _ FunctionCall)* {
  var result = [head];
  for (var i = 0; i < tail.length; i++) {
     result.push(tail[i][2]);
  }

  return result;
}


Select = SelectToken _ selects:FunctionCalls _ from:FromClause
                     _ where:WhereClause? _ facet:FacetClause?
                     _ limit:LimitClause? _ since:SinceClause?
                     _ until:UntilClause? _ compare:CompareWithClause?
                     _ series:TimeseriesClause? {
  return { type: "Select",
           selects: selects,
           from: from,
           where: where,
           facet: facet,
           limit: limit,
           since: since,
           until: until,
           compare: compare,
           series: series
         };
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
