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

.log.out "Loading DAILY HDB DIR";
system "l ",getenv `HDB_DAILY_DIR;
.log.out "Loaded DAILY HDB DIR";
.log.out .Q.s tables[];

\d .scrapper

//symIDDir schema
symIDDirectorySchema:`sym xkey flip `id`information`sym`lastUpdated!"J*SZ"$\:();
dailyFinData:update date:`date$(),sym:`$() from .alphavantage.dailyFinData;

$[not () ~ key hsym `$getenv `SYM_ID_DIRECTORY;
	[
		.log.out "Loading symID Directory";
		symIDDirectory:get symIDDirLoc:hsym `$getenv `SYM_ID_DIRECTORY;
		.log.out "Loaded symID Directory"
	];
	[
		.log.out "Using symID Directory Schema";
		symIDDirectory:symIDDirectorySchema
	]
 ];

if[$[`;()] ~ key hsym `$getenv `HDB_DAILY_DIR;
	.log.out "New HDB, initialising first partition";
	sv[`;(hsym `0;`dailyFinancialData;`)] set .Q.en[`:.;dailyFinData];
	system "d .";
	system "l ",getenv `HDB_DAILY_DIR;
	system "d .scrapper";
	.log.out "Re-loaded New HDB";
 ];
	

.log.out "Loading scrapper config";
scrapperConfig:`$read0 hsym `$getenv[`CONFIG_DIR],"/scrapper.config";

//Note the lack of recovery mechanism

//Start of Scrapper
//Get n random sym
getSym:{[x]
	.log.out "Choosing ",.Q.s[x], " random sym";
	symsToScrape:distinct x?scrapperConfig;
	//Remove syms which are updated recently
	//Should a table where we can perform each
	baseDict:select from symIDDirectory where sym in symsToScrape, not .z.D=`date$lastUpdated;
	symsToScrape:symsToScrape except raze key baseDict;
	//hardcoded number for ID
	baseDict upsert flip `id`sym!(count[symsToScrape]?9;symsToScrape)
 };

runScrape:{[dict]
	//enter this analytic with an each of symIDDirectory
	.log.out "Running runScrape for --- ".Q.s1 dict;
	res:.alphavantage.buildAndRunQuery[`function`symbol!(`TIME_SERIES_DAILY;dict`sym)];
	:.alphavantage.convertToTable[res]
 };

//Main Scrapper function
scrapeMain:{[]
	.log.out "Begin Main Srapper function";
	symDictsToScrape:getSym[3];
	scrapedData:runScrape each 0!symDictsToScrape;
	writeScrape '[0!symDictsToScrape;scrapedData];
	symIDDirLoc set .scrapper.symIDDirectory;
	.log.out "End of Scrapper function";
 };

\d .

//Declaring write function in global space due to global workspace restrictions
.scrapper.writeScrape:{[idDict;dataDict]
        //save dataDict to id hdb
        //TO-DO need to be able to merge data from existing id hdb
        .debug.var:`idDict`dataDict!(idDict;dataDict);
        existingData:select from dailyFinancialData where int = idDict[`id];
        existingData:delete from existingData where sym=distinct dataDict[1]`sym, date in dataDict[1]`date;
        toWriteDown:existingData uj dataDict[1];
        sv[`;(hsym `$string idDict[`id];`dailyFinancialData;`)] set Q.en[`:.;toWriteDown];
        //update symIDDirectory table
        `.scrapper.symIDDirectory upsert idDict;

 };

.log.out "End of Init";
