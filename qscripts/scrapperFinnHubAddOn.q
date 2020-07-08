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

if[enlist[`dailyFinancialData] ~ key ` sv hsym[`$getenv `HDB_DAILY_DIR],`0;
	.log.out "New FinnHub HDB, initialising first partition";
	{ report:`$ssr[string x;"Schema";""];
		sv[`;(hsym `0;report;`)] set .Q.en[`:.;value x]
	} each schemaNames;
	system "d .";
	.Q.chk[`:.];
	system "l ",get env `HDB_DAILY_DIR;
	system "d .scrapper";
	.log.out "Re-loaded New FinnHub HDB";
 ];

getReportedFinancialSym:{
 };

runReportedFinancialScrape:{[dict]
	//enter this analytic with an each of symIDDirectory
	.log.out "Running runReportedFinancialScrape for --- ",.Q.s1 dict;
	args:`function`symbol!("financials-reported";dict`sym);
	res:.finnhub.buildAndRunQuery[args];
	:.finnhub.ingestReportedFinancial[res]
 };

//Main ReportedFinancial Function
scrapeReportedFinancialMain:{[]
 	.log.out "Begin Reported Financial Scrapper function";
	.log.out "End of Reported Financial Scrapper Function";
 };

\d .

//Add updateSymMeta to the timer
//`datetime$.z.d+1 to use the next closest EOD time
.log.out "Adding scrapperFinnHubAddOn Timer Functions";
/.cron.addJob[`.scrapper.scrapeReportedFinancialMain;1;::;-0wz;0wz;1b];

.log.out "End of FinnHub Add-on Init";
