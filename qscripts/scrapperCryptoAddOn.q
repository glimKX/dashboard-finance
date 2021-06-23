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
latestPartition:`$string max "J"$string except[key hsym[`$getenv `HDB_DAILY_DIR];`sym];

if[not `cryptoData in key ` sv hsym[`$getenv `HDB_DAILY_DIR],latestPartition;
	.log.out "New cryptoData HDB, initialising into latest partition";
	sv[`;(hsym latestPartition;`cryptoData;`)] set .Q.en[`:.;cryptoSchema];
	system "d .";
	system "l ",getenv `HDB_DAILY_DIR;
	.Q.chk[`:.];
	system "l ",getenv `HDB_DAILY_DIR;
	system "d .scrapper";
	.log.out "Re-loaded New cryptoData HDB";
 ];

//Pull Sym from Config File
cryptoConfig:("SSS";enlist ",") 0: ` sv (hsym `$getenv[`CONFIG_DIR];`crypto.config)

getCryptoSym:{[x]
	.log.out "Choosing ",.Q.s[x], " random crypto sym";
	symsToScrape:distinct x?cryptoConfig;
	//Remove syms which were updated recently
	baseDict:select from .scrapper.symIDDirectory where sym in symsToScrape[`sym], -[.z.P;0] < lastUpdated;
	symsToScrape: select from symsToScrape where not sym in baseDict`sym;
	//hardcoded number for ID
	baseDict:baseDict upsert flip `id`sym`information!(count[symsToScrape]?20;symsToScrape[`sym];count[symsToScrape]#enlist "Crypto data downloaded from alphanvantage");
	:(symsToScrape;baseDict)
 };


//Function to build query for Crypto Data
runCryptoScrape:{[dict]
	.log.out "Running runCryptoScrape for --- ",.Q.s1 dict;
	args:`function`symbol`market`interval`datatype!(`CRYPTO_INTRADAY;dict`sym;dict`market;dict`interval;`csv);
	//if sym is new, download full release
	if[0N ~ first .scrapper.symIDDirectory dict`sym;
		args[`outputsize]:`full
	];
	res:.alphavantage.buildAndRunQuery[args];
	:stampCryptoData[res;args]
 };

stampCryptoData:{[data;args]
	.log.out "Running stampCryptoData";
	data:("PFFFFJ";enlist",") 0: data;
	//create mdata schema to be compliant with .scrapper.symIDDirectory
        data:update sym:count[i]#args[`symbol] from data;
        :data
 };

//Function to integrate data into current HDB structure
writeCrypto:{[idDict;dataDict]
	//save dataDict to id hdb
	.debug.var:`idDict`dataDict!(idDict;dataDict);
	dataWithID: dataDict lj `sym xkey select sym,id from idDict;
	writeCryptoByID[;dataWithID] each distinct ![0;idDict]`id;
	//update symIDDirectory table
	.log.out "Write Crypto Completed, updaing symIDDirectory";
	`.scrapper.symIDDirectory upsert idDict;
	symIDDirLoc set .scrapper.symIDDirectory;	
 };

//Main Crypto Scrapper Function
cryptoMain:{[]
 	.log.out "Begin Crypto Scrapper function";
	allSyms:getCryptoSym[3];
	data:raze runCryptoScrape each allSyms[0];
	intDict:allSyms[1] lj select lastUpdated:"z"$max[timestamp] by sym from data;
	writeCrypto[intDict;data];
	system "l .";
	//Backfill data partitions
	.Q.chk[`:.];
	system "l .";
	hdbSendReload[];
	.log.out "End of Reported Financial Scrapper Function";
 };

\d .

//This needs to be in global namespace due to cryptoData
.scrapper.writeCryptoByID:{[idt;dataWithID]
        //we will each on the id
        existingData:enlist [`int] _ select from cryptoData where int = idt;
        toWriteDown:distinct existingData uj enlist[`id] _ select from dataWithID where id = idt;
        toWriteDown:update `p#sym from `sym`timestamp xasc toWriteDown;
        sv[`;(hsym `$getenv `HDB_DAILY_DIR;`$string idt;`cryptoData;`)] set .Q.en[`:.;toWriteDown];
 };

//Add cryptoMain to the timer
//`datetime$.z.d+1 to use the next closest EOD time
.log.out "Adding scrapperCryptoAddOn Timer Functions";
.cron.addJob[`.scrapper.cryptoMain;1%24*5;::;-0wz;0wz;1b];

.log.out "End of Crypto Add-on Init";
