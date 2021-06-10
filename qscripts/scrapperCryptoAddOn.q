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
cryptoConfig:("SSS";enlist ",") 0: ` sv (hsym `$getenv[`CONFIG_DIR];`crypto.config)

getCryptoSym:{[x]
	.log.out "Choosing ",.Q.s[x], " random crypto sym";
	symsToScrape:distinct x?cryptoConfig;
	//Remove syms which were updated recently
	baseDict:select from symIDDirectory where sym in symsToScrape[`sym], -[.z.P;0] > lastUpdated;
	symsToScrape: select from symsToScrape where not sym in key[symIDDirectory]`sym;
	//hardcoded number for ID
	baseDict upsert flip `id`sym!(count[symsToScrape]?20;symsToScrape[`sym]);
	:(symsToScrape;baseDict)
 };


//NOT DONE
//Function to build query for Crypto Data
runCryptoScrape:{[dict]
	.log.out "Running runCryptoScrape for --- ",.Q.s1 dict;
	args:`function`symbol`market`interval`datatype!(`CRYPTO_INTRADAY;dict`sym;dict`market;dict`interval;`csv);
	//if sym is new, download full release
	if[0N ~ first .scrapper.symIDDirectory dict`sym;
		args[`outputsize]:`full
	];
	res:.alphavantage.buildAndRunQuery[args];
	
 };

//NOT DONE
stampCryptoData[data;args]
	.log.out "Running stampCryptoData";
	data:("PFFFFJ";enlist",") 0: data;
	//create mdata schema to be compliant with .scrapper.symIDDirectory
        mdata:update `$sym, "P"$max data[`timestamp] from mdata;
        data:update sym:count[i]#args[`sym] from data;
        :(mdata;data)
 };

//NOT DONE
//Function to integrate data into current HDB structure
.scrapper.writeCrypto:{[idDict;dataDict]
	//save dataDict to id hdb
	.debug.var:`idDict`dataDict!(idDict;dataDict);
	existingData:enlist [`int] _ select from cryptoData where int = idDict[`id];
	existingData:delete from existingData where sym in distinct dataDict[1]`sym, timestamp in dataDict[1]`timestamp;
	toWriteDown:existingData uj dataDict[1];
	toWriteDown:update `p#sym from `sym`timestamp xasc toWriteDown;
	sv[`;(hsym `$string idDict[`id];`cryptoData;`)] set .Q.en[`:.;toWriteDown];
	//update symIDDirectory table
	idDict:update information: first data Dict[0][`information],lastUpdated:`dateTime$first dataDict[0][`lastUpdated] from idDict;
	`.scrapper.symIDDirectory upsert idDict;
 };

//NOT DONE
//Main Crypto Scrapper Function
cryptoMain:{[]
 	.log.out "Begin Crypto Scrapper function";
	allSyms:getCryptoSym[3];
	runReportedFinancialScrape each allSyms;
	.log.out "End of Reported Financial Scrapper Function";
 };

\d .

//Add cryptoMain to the timer
//`datetime$.z.d+1 to use the next closest EOD time
.log.out "Adding scrapperCryptoAddOn Timer Functions";
.cron.addJob[`.scrapper.cryptoMain;1%24*50;::;-0wz;0wz;1b];

.log.out "End of Crypto Add-on Init";
