//////////////////////////////////////////////////////////////////////////////////////////////////
//	scrapper.q script which loads up with required templates
//	q script will define the backend ability to scrap for historical data from API (Free)
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////
// Purpose
// To standalone from alphavantage api
// To Query data within free api restrictions
// To Save data so that we can build up a sufficient HDB
// This is to allow analysis that will breach free tier
//////////////////////////

\l log.q
\l cron.q
\l alphavantage.q


//Framework for scrapping daily data
//Run through list of sym to scrap every allowed interval
//Check if sym was already scrapped base on meta
//If not, send query to alphavantage
//This is a daily data scrapper
//Generate a an ID which the sym belongs to
//Send sym table to that ID and save splayed table down, note that if there are existing data, to merge it 

//symIDDir schema
symIDDirectorySchema:`sym xkey flip `id`information`sym`lastUpdated!"J*ST"$\:();

.log.out "Loading DAILY HDB DIR";
system "l ,"getenv `HDB_DAILY_DIR;
.log.out "Loaded DAILY HDB DIR";

$[not () ~ key hsym `$getenv `SYM_ID_DIRECTORY;
	[
		.log.out "Loading symID Directory";
		symIDDirectory:get hsym `$getenv `SYM_ID_DIRECTORY;
		.log.out "Loaded symID Directory"
	];
	[
		.log.out "Using symID Directory Schema";
		symIDDirectory:symIDDirectorySchema
	]
 ];

.log.out "Loading scrapper config";
scrapperConfig:`$read0 hsym `$getenv[`CONFIG_DIR],"/scrapper.config";

//Note the lack of recovery mechanism

//Start of Scrapper
//Get n random sym
getSym:{[x]
	.log.out "Choosing ",.Q.s[x], " random sym";
	symsToScrape:x?scrapperConfig;
	//Remove syms which are updated recently
	//Should a table where we can perform each
	baseDict:select from symIDDirectory where (sym in symsToScrape, not .z.D=`date$lastUpdated);
	symsToScrape:symsToScrape except key symIDDirectory;
	//hardcoded number for ID
	symsToScrape uj `id`sym!(count[symsToScrape]?9;symsToScrape)
 };

runScrape:{[dict]
	//enter this analytic with an each of symIDDirectory
	.log.out "Running runScrape for --- ".Q.s1 dict;
	res:.alphavantage.buildAndRunQuery[`function`symbol!(`TIME_SERIES_DAILY;dict`sym)];
	:.alphavantage.convertToTable[res]
 };

writeScrape:{[idDict;dataDict]
	//save dataDict to id hdb
	//TO-DO need to be able to merge data from existing id hdb
	sv[`;(hsym `$string idDict[`id];`dailyFinData;`)] set Q.en[`:.;dataDict[1]];
	//update symIDDirectory table
	`symIDDirectory upsert idDict;
 };

//Main Scrapper function
scrapeMain:{[]
	.log.out "Begin Main Srapper function";
	symDictsToScrape:getSym[3];
	scrapedData:runScrape each symDictsToScrape;
	writeScrape '[symDictsToScrape;scrapedData];
	.log.out "End of Scrapper function";
 };
