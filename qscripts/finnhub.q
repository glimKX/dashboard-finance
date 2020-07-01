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
//Schema will be used for uj before saving down

//Finnhub mapping config
/.log.out "Loading in mapping config for ingestion";
mappingConfigDict:()!();
mappingConfigDir:hsym `$getenv[`MAPPINGCONFIG_DIR];
listOfConfig:key mappingConfigDir;
if[not () ~ listOfConfig;
	listOfConfigName:(` vs' listOfConfig)[;0];
	listOfConfig:` sv ' mappingConfigDir,/:listOfConfig;
	listOfConfigName set' ("SS*";enlist ",") 0:/:listOfConfig;
	{mappingConfigDict[x]: value x} each listOfConfigName;
 ];

typeMapping:"FJH"!`float`long`short;

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
	data:res[`data];
	distinctYears:exec distinct year from data;
	//Produce a table of BS data
	//Need to append symbol before saving down
	ingestBSReport[data] each distinctYears;
	ingestCFReport[data] each distinctYears;
	/ingestPLReport[data] each distinctYears;
	//Save down data
 };

ingestBSReport:{[data;yr]
	bsData:raze exec report[`bs] from data where year = yr;
	//fix value column
	bsData:update `$concept from removeNA .Q.id bsData;
	mappingConfigToUse:mappingConfigDict[`finnhubBSMapping];
	colsToIngest:mappingConfigToUse[`finnHubConceptName] inter bsData[`concept];
	bsDataToIngest:exec colsToIngest#concept!value1 from bsData;
	typeMappingForData:exec colsToIngest#finnHubConceptName!typ from mappingConfigToUse;	
	colNameMappingForData:value exec colsToIngest#finnHubConceptName!colName from mappingConfigToUse;
	data:enlist colNameMappingForData!(typeMapping raze value typeMappingForData)$'value bsDataToIngest;
	update year:yr from data
 };

ingestCFReport:{[data;yr]
 };

ingestPLReport:{[data;yr]
 };

removeNA:{[data]
	//This is required when there are NA in float expected columns
	//Assumes that value column was already sanitized
	update value1:0nf from res where (10 = type each res[`value1])
 };

/.log.out "Loaded .finnhub library";

\d .
