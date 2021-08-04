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
hookURL:enlist getenv `TWITTER_RECENT_URL;
apiKey:enlist getenv `TWITTERAPI;

//Start of API
//tweetSearch - takes dictionary to manipulate query, cleans and sends to query builder

//Querybuilder - takes cleaned args and construct url 

//QueryRunner - Runs query and parse res

//QueryFormatter - Formats into desired shape to be visualised on kx db.


\d .

.log.out "End of Tweet Process Init";
