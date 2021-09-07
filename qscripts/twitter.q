//////////////////////////////////////////////////////////////////////////////////////////////////
//	twitter.q script is to be loaded as a separate process that pulls historical tweets against a ticker
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////
// Purpose
// To enable queries into twitter for historical data
// Note this does not support streams 
//////////////////////////

system "l ",getenv[`QSCRIPTS_DIR],"/log.q";
system "l ",getenv[`QSCRIPTS_DIR],"/cron.q";
@[system;"l p.q";{.log.err "p.q not loaded, embedPy functionality will have issues"}];
.log.out "Initial Init of Tweet Process";
\d .tweet

//Globals to enable Twitter Search Queries
hookURL:getenv `TWITTER_RECENT_URL;
apiKey:getenv `TWITTERAPI;

//Start of API
//tweetSearch - takes dictionary to manipulate query, cleans and sends to query builder
tweetSearch:{[dict]
	if[all null dict`hashtag;.log.out "In tweetSearch --- Proceeding without hashtag"];
	if[not[all null dict`hashtag] and not dict[`hashtag] like "#*";dict[`hashtag]:"#",except[dict`hashtag;"#"]];

	if[all null dict`includeRetweet;.log.out "Retweet boolean mssing, excluding retweets";dict[`includeRetweet]:0b];
	//check on search operator - ";" = "and", "," = "or"
	//example string "(happy,exciting,excited,favorite);NWSHouston"
	//remove "()" if no ","
	if[not all null dict`filter;.log.out "Filter operation present, running checks";
		interim:";" vs dict`filter;
		dict[`filter]:" " sv @[interim;where {not ("," in x) and x like "(*)"} each interim;{x except "()"}]
	];
	.log.out "TweetSearch Ready --- passing to query builder ",.Q.s1 dict;
	:queryBuilderAndRun dict
 };
//Querybuilder - takes cleaned args and construct url 
queryBuilderAndRun:{[args]
	//`hashtag`includeRetweet`filter
	.log.out "In .tweet.queryBuilder --- ",.Q.s1 args;
	if[$[`boolean;()] ~ raze null args`filter`hashtag;'"ERROR: Missing hash tag and filter"];
	$[args[`includeRetweet];args[`includeRetweet]:"";args[`includeRetweet]:"-is:retweet"];
	args:@[(enlist[(::)]!enlist[" "]),args;where 10h<>type each args;string];
	//nothing fancy because twitter takes 1 long string
	query:hookURL,"query=",.h.hu " " sv 1 _ value args;
	//-H is only available for curl, check how we can pass authorization header or we have to use curl
	query:"curl ",query," -H \"Authorization: Bearer ",apiKey,"\"";
	.log.out "Running tweet query --- ",query;
	res:@[system;
                query;
                {.log.err "Failed to run query --- ",x," due to ",y;'"Query Error"}[query]
        ];
	:queryFormatter res
 };

//QueryFormatter - Formats into desired shape to be visualised on kx db.
queryFormatter:{[res]
	//takes in json res and parse
	res:@[.j.k;raze res;{.log.err "Failed to parse res as json --- ",x;'y}[res]];
	//to find a point in tweet so that we can split it and create a url
	//This url can be used from the front end to navigate to the tweet
	:urlExtract res[`data]
 };

urlExtract:{[res]
	res:update url:{"https://t.co",vs[" ";("https://t.co" vs x)[1]][0]} each text from res;
	:res
 };
	

\d .

.log.out "End of Tweet Process Init";
