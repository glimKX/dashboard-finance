/////////////////////
//alphavantage api
/////////////////////

/////////////////////
// API Version: 1.0
// Current Features
// - Builds query to run alphavantage api
// - Date based time series parser to convert to kdb table (need to be dynamic in future)
/////////////////////

\d .alphavantage

.log.out "Loading .alphavantage library";

//Globals to enable alphavantage queries
hookURL:";" vs getenv `ALPHAVANTAGE_URL;
apiKey:enlist getenv `ALPHAVANTAGEAPI;

//Alphavantage financial data schema
dailyFinData:flip `open`high`low`close`volume!"FFFFF"$\:();
metaData:flip `information`sym`lastUpdated!"*ST"$\:();

//Start of API
//Query builder then runs it - Takes 2 compulsory inputs
buildAndRunQuery:{[args]
	.log.out "In .alphavantage.buildQuery --- ",.Q.s1 args;
	if[not all `function`symbol in key args;'"Missing Inputs"];
	args:@[(enlist[(::)]!enlist[" "]),args;where 10h<>type each args;string];
	//TODO - Add options args here
	optArgs:`function`symbol _ 1 _ args;
	//Convoluted ifs, no validation of 1 letter options but that would type error
	optArgs:$[1 = count optArgs;
	    "&","=" sv raze (string key[optArgs];value[optArgs]);
	    1 < count optArgs;
        	"&","&" sv "=" sv' (string key[optArgs];value[optArgs]);
        	""
    	];
	args:args[`function`symbol],apiKey;
	query:":",("&" sv hookURL,'args),optArgs;
	.log.out .Q.s1 query;
	res:@[.Q.hg;
		query;
		{.log.err "Failed to run query --- ",x," due to ",y;'"Query Error"}[query]
	];
	:.j.k res
 };


//Data from Alphavantage is no schema compliant and needs to be parsed/cleaned
//Assumptions are made to be generic, if not true, needs config to improve ingestion flexibility
convertToTable:{[res]
	.log.out "In .alphavantage.convertToTable";
	if[99h <> type res;.log.err "Result is not a dictionary, unable to convert";'"Not dictionary"];
	mdata:res[key[res] 0];
	data:res[key[res] 1];
	//Assumption is that when we query for financial data, its always in the schema of OHLCV
	//TODO - To use dataTime instead to accomodate data coming in as timestamps
	data:([] date:"D"$string key[data]),'flip `open`high`low`close`volume!"FFFFF"$value flip value[data];
	mdataCols:cols .Q.id enlist mdata;
	mdataCols:mdataCols where any mdataCols like/: ("*Information*";"*Symbol*";"*Last*");
	mdata:cols[metaData] xcol mdataCols#.Q.id enlist mdata;	
	mdata:update `$sym, "P"$lastUpdated from mdata;
	data:update sym:count[i]#mdata[`sym] from data;
	:(mdata;data)
 };


.log.out "Loaded .alphavantage library";

\d .
