/////////////////////
//finnhub api
/////////////////////

/////////////////////
// API Version: 0.1
// Current Features
// - Builds query to run alphavantage api
// - Support Following capability
// 	- Peers
//	- Basic Financials
//  	- Financials As Reported
/////////////////////

\d .finnhub

/.log.out "Loading .finnhub library";

//Globals to enable finnhub queries
hookURL:enlist getenv `FINNHUB_URL;
apiKey:enlist getenv `FINNHUBAPI;

//Finnhub schemas

//Start of API
//Query builder, takes two compulsory input (the function to run and symbol)
buildAndRunQuery:{[args]
	/.log.out "In .finnhub.buildQuery --- ",.Q.s1 args;
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
	query:(,/)hookURL,args[`function],"?symbol=",args[`symbol];
	query:(,/)":",query,optArgs,"&token=",apiKey;
	/.log.out .Q.s1 query;
	res:@[.Q.hg;
		query;
		{.log.err "Failed to run query --- ",x," due to ",y;'"Query Error"}[query]
	];
	:.j.k res
 };


//Data from finnHub is no schema compliant and needs to be parsed/cleaned
//Assumptions are made to be generic, if not true, needs config to improve ingestion flexibility
convertToTable:{[res]
	/.log.out "In .alphavantage.convertToTable";
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

ingestReportedFinancial:{[res]
	//Note that this uses financials-report hook
	//This has the following structure
	//res[`data] -> Year -> report -> Balance Sheet, CF, PL
	distinctYears:exec distinct year from res[`data];
	ingestBSReport[res] each distinctYears;
	ingestCFReport[res] each distinctYears;
	ingestPLReport[res] each distinctYears;
 };

ingestBSReport:{[res;yr]
 };

ingestCFReport:{[res;yr]
 };

ingestPLReport:{[res;yr]
 };

removeNA:{[res]
	//This is required when there are NA in float expected columns
	//Assumes that value column was already sanitized
	update value1:0nf from res where (10 = type each res[`value1])
 };

/.log.out "Loaded .finnhub library";

\d .
