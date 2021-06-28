//////////////////////////////////////////////////////////////////////////////////////////////////
//	scrapperFinnHubAddon.q script is to be loaded into scrapper.q
//	q script will define the backend ability to scrap from finnhub available API
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////
// Purpose
// To have an add on script to scrapper when dealing with finnHub
// To query for reportedFinancialData 
//////////////////////////

system "l ",getenv[`QSCRIPTS_DIR],"/finnhub.q";

\d .scrapper

//Creation of a new table to store reportedFinancialData
//schema
schemaNames:`$ssr[;"Mapping";"ReportSchema"] each string key .finnhub.schemaDict;
schemaNames set' value .finnhub.schemaDict

.log.out "Perform check if this is initial init of finnhub tables";
latestPartition:`$string max "J"$string except[key hsym[`$getenv `HDB_DAILY_DIR];`sym];

if[any not `finnhubBSReport`finnhubCFReport`finnhubICReport in\: key ` sv hsym[`$getenv `HDB_DAILY_DIR],latestPartition;
	.log.out "New FinnHub HDB, initialising first partition";
	{ report:`$ssr[string x;"Schema";""];
		sv[`;(hsym `20;report;`)] set .Q.en[`:.;value x]
	} each schemaNames;
	system "d .";
	system "l ",getenv `HDB_DAILY_DIR;
	.Q.chk[`:.];
	system "d .scrapper";
	.log.out "Re-loaded New FinnHub HDB";
 ];

getReportedFinancialSym:{[]
	//instead of pulling this information daily
	//it should run as a monthly report
	allSyms:select id,sym from .scrapper.symIDDirectory;
	:allSyms
 };

runReportedFinancialScrape:{[dict]
	//enter this analytic with an each of symIDDirectory
	.log.out "Running runReportedFinancialScrape for --- ",.Q.s1 dict;
	args:`function`symbol!("financials-reported";dict`sym);
	res:.finnhub.buildAndRunQuery[args];
	if[() ~ res`data;
		.log.out "In .scrapper.runReportedFinancial Scrape --- Data pulled from finnhub is empty for sym: ",res`symbol;
		:()
	];
	dict:dict,enlist[`data]!enlist .finnhub.ingestReportedFinancial[res];
	writeReportedFinancialScrape[dict]
 };

writeReportedFinancialScrape:{[dict]
	//enter this analytic with ID on where to save and the report
	.debug.write:dict;
	existingData:{[id;tab] enlist[`int] _ ?[tab;enlist(=;`int;id);0b;()]}[dict`id] each key dict[`data];
	existingData:key[dict `data]!{[s;tab] delete from tab where sym = s}[dict[`sym]] each existingData;
	//to delete data then write to existing ID location (might go with this to bypass api limits)
	writeEach[dict[`data];existingData;dict`id] each key dict[`data];
	//2 models - 1) read and write, 2) read all then write. TBC on choice
 };

writeEach:{[newData;existingData;id;reportKey]
	toWriteDown:existingData[reportKey] uj newData[reportKey];
	toWriteDown:update `p#sym from `sym`year xasc toWriteDown;
	sv[`;(hsym `$string id;reportKey;`)] set .Q.en[`:.;toWriteDown];
 };

//Main ReportedFinancial Function
scrapeReportedFinancialMain:{[]
 	.log.out "Begin Reported Financial Scrapper function";
	allSyms:getReportedFinancialSym[];
	runReportedFinancialScrape each allSyms;
	system "l .";
	.Q.chk[`:.];
	system "l .";
	hdbSendReload[];
	.log.out "End of Reported Financial Scrapper Function";
 };

\d .

//Add updateSymMeta to the timer
//`datetime$.z.d+1 to use the next closest EOD time
.log.out "Adding scrapperFinnHubAddOn Timer Functions";
.cron.addJob[`.scrapper.scrapeReportedFinancialMain;1;::;-0wz;0wz;1b];

.log.out "End of FinnHub Add-on Init";
