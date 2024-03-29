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

system "l ",getenv[`QSCRIPTS_DIR],"/log.q";
system "l ",getenv[`QSCRIPTS_DIR],"/cron.q";
system "l ",getenv[`QSCRIPTS_DIR],"/alphavantage.q";
@[system;"l p.q";{.log.err "p.q not loaded, embedPy functionality will have issues"}];

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
		symIDDirLoc:hsym `$getenv `SYM_ID_DIRECTORY;
		symIDDirectory:symIDDirectorySchema
	]
 ];

if[{lvDown:key x;not `dailyFinancialData in distinct raze key each ` sv' x,'lvDown} hsym `$getenv `HDB_DAILY_DIR;
	.log.out "New HDB, initialising first partition";
	sv[`;(hsym `20;`dailyFinancialData;`)] set .Q.en[`:.;dailyFinData];
	.Q.chk[`:.];
	system "d .";
	system "l ",getenv `HDB_DAILY_DIR;
	system "d .scrapper";
	.log.out "Re-loaded New HDB";
 ];
	

.log.out "Loading scrapper config";
scrapperConfig:`$read0 hsym `$getenv[`CONFIG_DIR],"/scrapper.config";
resetScrapperConfig:{scrapperConfig:`$read0 hsym `$getenv[`CONFIG_DIR],"/scrapper.config"};

//HDB Async Refresh Logic 
hdbConnections:flip `dateTime`processName`connection`handle!"ZSSJ"$/:();
//Function called from HDB process after connection with scrapper unit
hdbConnection:{[name]
	`.scrapper.hdbConnections upsert (.z.Z;name;`open;.z.w);
	.log.out "Connection opened: ",.Q.s1 exec from .scrapper.hdbConnections where handle = .z.w;
 };
//Function triggers when a handle is dropped to update hdbConnections Table, needs to be included in .z.pc
hdbConnectionDropped:{[w]
	if[null (exec from hdbConnections where handle = w)[`connection];:()];
	update connection:`closed from `.scrapper.hdbConnections where handle = w;
	.log.out "Connection closed: ",.Q.s1 exec from .scrapper.hdbConnections where handle = w;
 };
//If handle is present, to send neg h to connected HDB to reload
hdbSendReload:{[]
	//Using hdbConnections, we will send neg h command across hdbs to reload
	.log.out "Sending reload to all connected HDBs";
	h:exec handle from hdbConnections where connection = `open;
	-25!(h;(`.hdb.reloadDB;`));
 };

//Note the lack of recovery mechanism

//Start of Scrapper
//Get n random sym
getSym:{[x]
	.log.out "Choosing ",.Q.s[x], " random sym";
	symsToScrape:distinct x?scrapperConfig;
	//Remove syms which are updated recently
	//Should a table where we can perform each
	baseDict:select from symIDDirectory where sym in symsToScrape, -[.z.D;0]>`date$lastUpdated;
	symsToScrape:symsToScrape except key[symIDDirectory]`sym;
	//hardcoded number for ID
	baseDict upsert flip `id`sym!(count[symsToScrape]?20;symsToScrape)
 };

runScrape:{[dict]
	//enter this analytic with an each of symIDDirectory
	.log.out "Running runScrape for --- ",.Q.s1 dict;
	args:`function`symbol!(`TIME_SERIES_DAILY_ADJUSTED;dict`sym);
	//add in functionality to check if sym is new, if so download full release
	if[0N ~ first .scrapper.symIDDirectory dict`sym;
        	args[`outputsize]:`full
	];
	res:.alphavantage.buildAndRunQuery[args];
	:.alphavantage.convertToTable[res]
 };

//Main Scrapper function
scrapeMain:{[]
	.log.out "Begin Main Srapper function";
	symDictsToScrape:getSym[3];
	scrapedData:runScrape each 0!symDictsToScrape;
	writeScrape '[0!symDictsToScrape;scrapedData];
	symIDDirLoc set .scrapper.symIDDirectory;
	system "l .";
	//back fill new partitions created
	.Q.chk[`:.];
	system "l .";
	hdbSendReload[];
	.log.out "End of Scrapper function";
 };

\d .

//Declaring write function in global space due to global workspace restrictions
.scrapper.writeScrape:{[idDict;dataDict]
        //save dataDict to id hdb
        //TO-DO need to be able to merge data from existing id hdb
        .debug.var:`idDict`dataDict!(idDict;dataDict);
        existingData:enlist[`int] _ select from dailyFinancialData where int = idDict[`id];
        existingData:delete from existingData where sym in distinct dataDict[1]`sym, date in dataDict[1]`date;
        toWriteDown:existingData uj dataDict[1];
	toWriteDown:update `p#sym from `sym`date xasc toWriteDown;
        sv[`;(hsym `$string idDict[`id];`dailyFinancialData;`)] set .Q.en[`:.;toWriteDown];
        //update symIDDirectory table
	idDict:update information:first dataDict[0][`information], lastUpdated:`datetime$first dataDict[0][`lastUpdated] from idDict;
        `.scrapper.symIDDirectory upsert idDict;

 };

//Redefining .z.pc, note that there are other logic running in .z.pc already
.scrapper.pc:.z.pc;
.z.pc:{[w] .scrapper.pc[w]; .scrapper.hdbConnectionDropped[w]};

.log.out "Declaring timer functions";
.cron.addJob[`.scrapper.scrapeMain;1%60*24%10;::;-0wz;0wz;1b];
.cron.addJob[`.log.rollOver;1;::;`datetime$.z.d+1;0wz;1b];

//Add on script 
system "l ",getenv[`QSCRIPTS_DIR],"/scrapperEmbedPyAddOn.q";
system "l ",getenv[`QSCRIPTS_DIR],"/scrapperFinnHubAddOn.q";
system "l ",getenv[`QSCRIPTS_DIR],"/scrapperCryptoAddOn.q";

.log.out "End of Init";


