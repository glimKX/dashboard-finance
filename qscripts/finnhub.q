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

//Finnhub schemas
//Schema will be used for uj before saving down
base:`year`sym!"FS"$\:();
schemaDict:()!();
if[count mappingConfigDict;
	schemaDict:{schema:exec colName, raze[typ] from x;
		flip base,schema[`colName]!schema[`typ]$\:()
	} each mappingConfigDict
 ];
	

//Start of API
//Query builder, takes two compulsory input (the function to run and symbol)
buildAndRunQuery:{[args]
	/.log.out "In .finnhub.buildQuery --- ",.Q.s1 args;
	if[not all `function`symbol in key args;'"Missing Inputs"];
	args:@[(enlist[(::)]!enlist[" "]),args;where 10h<>type each args;string];
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
//buildAndRunQuery `function`symbol!("financials-reported";`AAPL)
ingestReportedFinancial:{[res]
	//Note that this uses financials-report hook
	//This has the following structure
	//res[`data] -> Year -> report -> Balance Sheet, CF, PL
	data:res[`data];
	symbol:`$res[`symbol];
	distinctYears:exec distinct year from data;
	//Produce a table of BS data
	//Need to append symbol before saving down
	BSReport: raze ingestBSReport[data;symbol] each distinctYears;
	CFReport: raze ingestCFReport[data;symbol] each distinctYears;
	ICReport: raze ingestICReport[data;symbol] each distinctYears;
	//Output data
	`finnhubBSReport`finnhubCFReport`finnhubICReport!(BSReport;CFReport;ICReport)
 };

mapData:{[data;symbol;yr;reportType]
	mappingConfigToUse:mappingConfigDict[reportType];
	colsToIngest:mappingConfigToUse[`finnHubConceptName] inter data[`concept];
	dataToIngest:exec colsToIngest#concept!value1 from data;
	if[not count dataToIngest;.log.out "In .finnhub.mapData --- Data is empty, skipping ingestion";:schemaDict[reportType]];
	typeMappingForData:exec colsToIngest#finnHubConceptName!typ from mappingConfigToUse;
	colNameMappingForData:value exec colsToIngest#finnHubConceptName!colName from mappingConfigToUse;
	data:enlist colNameMappingForData!(typeMapping raze value typeMappingForData)$'value dataToIngest;
	schemaDict[reportType] uj update year:yr, sym:symbol from data
 };

ingestBSReport:{[data;symbol;yr]
	bsData:raze exec report[`bs] from data where year = yr;
	//stop ingestion if data is empty
	if[() ~  bsData;:schemaDict[`finnhubBSMapping]];
	//fix value column
	bsData:update `$concept from removeNA .Q.id bsData;
	mapData[bsData;symbol;yr;`finnhubBSMapping]
 };

ingestCFReport:{[data;symbol;yr]
	cfData:raze exec report[`cf] from data where year = yr;
	//stop ingestion if data is empty
	if[() ~ cfData;:schemaDict[`finnhubCFMapping]];
	//fix value column
	cfData:update `$concept from removeNA .Q.id cfData;
	mapData[cfData;symbol;yr;`finnhubCFMapping]
 };

ingestICReport:{[data;symbol;yr]
	icData:raze exec report[`ic] from data where year = yr;
	if[() ~ icData;:schemaDict[`finnhubICMapping]];
	//fix value column
        icData:update `$concept from removeNA .Q.id icData;
        mapData[icData;symbol;yr;`finnhubICMapping]
 };

removeNA:{[data]
	//This is required when there are NA in float expected columns
	//Assumes that value column was already sanitized
	update value1:0nf from data where (10 = type each data[`value1])
 };

/.log.out "Loaded .finnhub library";

\d .
