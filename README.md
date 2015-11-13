# NRQL Parser

Peg grammar (using [pegjs](https://github.com/pegjs/pegjs)) for New Relic
Insight's query language.


```
$ ./bin/nrql-parse -e "SELECT uniqueCount(user) FROM  PageView WHERE userAgentOS = 'Mac' FACET countryCode LIMIT 20 SINCE 1 day ago" 


{
  "type": "Select",
  "selects": [
    {
      "type": "SelectClause",
      "value": {
        "type": "FunctionExpression",
        "name": "uniqueCount",
        "arguments": [
          {
            "type": "Identifier",
            "name": "user"
          }
        ]
      }
    }
  ],
  "from": {
    "type": "Identifier",
    "name": "PageView"
  },
  "where": {
    "type": "WhereCondition",
    "condition": {
      "attribute": {
        "type": "Identifier",
        "name": "userAgentOS"
      },
      "op": "=",
      "right": {
        "type": "StringLiteral",
        "value": "Mac"
      }
    }
  },
  "facet": {
    "type": "Identifier",
    "name": "countryCode"
  },
  "limit": {
    "type": "FloatLiteral",
    "value": 20
  },
  "since": {
    "type": "TimeAgo",
    "duration": {
      "type": "duration",
      "quantity": {
        "type": "FloatLiteral",
        "value": 1
      },
      "unit": "d"
    }
  }
}
```
