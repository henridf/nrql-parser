// From https://docs.newrelic.com/docs/insights/new-relic-insights/using-new-relic-query-language/nrql-reference

module.exports = [
    // This query returns the average response time since last week
    "SELECT average(duration) FROM PageView SINCE 1 week ago",

    // This query returns a count of all APM transactions over the last three
    // days
    "SELECT count(*) FROM Transaction SINCE 3 days ago",

    // This query returns information over the past 24 hours for Safari users
    // in the United States and Canada.
    "SELECT histogram(duration, 50, 20) FROM PageView\n" +
        "  WHERE countryCode IN ('CA', 'US') AND userAgentName='Safari'\n" +
        "  SINCE 1 day ago",

    "SELECT uniqueCount(USER) FROM  PageView WHERE userAgentOS = 'Mac' FACET countryCode LIMIT 20 SINCE 1 DAY ago",
    // read -last :1d: -source_type 'PageView' userAgentOS = 'Mac' | reduce
    // unique_count(user) by CountryCode | sort user | tail 20 (?)

    // This query returns a count of people who have visited both the main page
    // and the careers page of a site over the past week
    // "SELECT funnel(SESSION,\n" +
    //     "  WHERE name='Controller/about/main' AS 'Step 1',\n" +
    //     "  WHERE name = 'Controller/about/careers' AS 'Step 2')\n" +
    //     "  FROM PageView SINCE 1 week ago",

    // This query returns the number of pageviews per session:
    "SELECT count(*)/uniqueCount(session) AS 'Pageviews per Session'" +
        "  FROM PageView",

    // This query shows the top 20 countries by session count and provides
    // 95th percentile of response time for each country for Windows users
    // only.
    "SELECT uniqueCount(session), percentile(duration, 95)\n" +
        " FROM PageView WHERE userAgentOS = 'Windows'\n" +
        "  FACET countryCode LIMIT 20 SINCE YESTERDAY\n",

    // These queries provide a chart comparing the 50th, 95th, and 99%
    // percentile of average response time
    "SELECT percentile(duration, 50, 95, 99)\n" +
       "  FROM PageView SINCE '2014-02-14 00:00:00'",

    // These queries provide a chart comparing the 50th, 95th, and 99%
    // percentile of average response time for a specified time period not
    // ending today.
    "SELECT percentile(duration, 50, 95, 99)\n" +
        "  FROM PageView SINCE '2014-02-14 00:00:00' UNTIL '2014-02-20 00:00:00'",

    "SELECT percentile(duration, 50, 95, 99)\n" +
      "  FROM PageView SINCE 1 week AGO UNTIL 2 days ago",


    // This query returns data as a line chart showing the 95th percentile for
    // the past hour compared to the same range one week ago. First as a
    // single value, then as a line chart
    "SELECT percentile(duration) FROM PageView\n" +
        "  SINCE 1 week ago COMPARE WITH 1 week AGO",

    "SELECT percentile(duration) FROM PageView\n" +
        "  SINCE 1 week ago COMPARE WITH 1 week AGO TIMESERIES AUTO",

    // This query returns data as a line chart showing the 50th and 90th
    // percentile of client-side transaction time for one week with a data
    // point every 6 hours.
    "SELECT average(duration), percentile(duration, 50, 90)\n" +
        "  FROM PageView SINCE 1 week AGO TIMESERIES AUTO",

    // This query returns the minimum, average, and maximum duration for
    // Browser events over the last week
    "SELECT min(duration), max(duration), average(duration)\n" +
        "  FROM PageView SINCE 1 week ago",

    // A histogram of response times ranging up to 10000 milliseconds over 20
    // buckets.
    "SELECT histogram(duration, 10000, 20) FROM PageView SINCE 1 week ago"
];
