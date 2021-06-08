//////////////////////////////////////////////////////////////////////////////////////////////////
//	scrapperCryptoAddon.q script is to be loaded into scrapper.q
//	q script will define the backend ability to scrap from alphaVantage available API
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////
// Purpose
// To have an add on script to scrapper when dealing with crypto
// To query for crypto data set
//////////////////////////

\d .scrapper

//Creation of a new table to store reportedFinancialData
//schema
cryptoSchema:flip `timestamp`sym`open`high`low`close`volume!"PSFFFFJ"$\:();

.log.out "Perform check if this is initial init of cryptoSchema";

if[enlist[`cryptoData] ~ key ` sv hsym[`$getenv `HDB_DAILY_DIR],`0;
	.log.out "New cryptoData HDB, initialising first partition";
	sv[`;(hsym `0;`cryptoData;`)] set .Q.en[`:.;cryptoSchema];
	system "d .";
	system "l ",getenv `HDB_DAILY_DIR;
	.Q.chk[`:.];
	system "d .scrapper";
	.log.out "Re-loaded New cryptoData HDB";
 ];

//Pull Sym from Config File

//Function to build query for Crypto Data

//Function to integrate data into current HDB structure

//Main Crypto Scrapper Function
cryptoMain:{[]
 	.log.out "Begin Crypto Scrapper function";
	allSyms:getReportedFinancialSym[];
	runReportedFinancialScrape each allSyms;
	.log.out "End of Reported Financial Scrapper Function";
 };

\d .

//Add updateSymMeta to the timer
//`datetime$.z.d+1 to use the next closest EOD time
.log.out "Adding scrapperCryptoAddOn Timer Functions";
.cron.addJob[`.scrapper.cryptoMain;1%24*50;::;-0wz;0wz;1b];

.log.out "End of Crypto Add-on Init";
