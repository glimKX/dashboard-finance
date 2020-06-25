//////////////////////////////////////////////////////////////////////////////////////////////////
//	scrapperEmbedPyAddon.q script is to be loaded into scrapper.q
//	q script will define the backend ability to scrap from pythonic available API
// 	Note this however increase the level of libraries dependencies
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////
// Purpose
// To have a add on script to scrapper when dealing with embedPy
// To query for data from yahoo finance 
//////////////////////////

if[() ~ key `.p;.log.err "Not loading EmbedPy Addons";:()];


\d .scrapper

//Creation of a new table separate from symIDDirectory as that is to be kept lite for speed
//This linkage table is to be updated once every EOD
//linkage schema
symMetaLinkageSchema:`sym xkey flip `sym`sector`industry`longBusinessSummary`beta`currency`marketCap`logo_url!"SSS*FSF*"$\:();

$[not () ~ key symMetaLinkageLoc:hsym `$getenv `SYM_META_LINKAGE;
        [
                .log.out "Loading symMeta Linkage";
                symMetaLinkage:get symMetaLinkageLoc;
                .log.out "Loaded symMeta Linkage"
        ];
        [
                .log.out "Using symMeta Linkage";
                symMetaLinkageLoc:hsym `$getenv `SYM_META_LINKAGE;
                symMetaLinkage:symMetaLinkageSchema
        ]
 ];

yf:.p.import[`yfinance];

pullDataFromYFinance:{[syms]
	//To prevent unsupported multiple sym in ticker class
	if[1<>count syms;syms:first syms];
	data:yf[`:Ticker]syms;
	//data is a ticker class and info returns a dictionary
	//have to convert back to q in order to index
	//Exception Handling for certain syms with bad data
	dict:@[data;`:info;{.log.err ".scrapper.pullDataFromYFinance failed with ",string[x]," due to ",.Q.s y;:()}[syms]];
	if[() ~ dict;:`symbol`sector`industry`longBusinessSummary`beta`currency`marketCap`logo_url!(syms;`;`;" ";0nf;`;0nf;" ")];
	dict:data[`:info][`];
	//hardcoded list of data to keep
	data:`symbol`sector`industry`longBusinessSummary`beta`currency`marketCap`logo_url#dict;
	:update `$symbol, `$sector,`$industry, `$currency, `float$marketCap from data
 };

updateSymMeta:{
	.log.out "Sym Meta Linkage Update Initialised, note that this is a heavy query";
	//pull list of sym in system that needs linkage
	//TO-DO need method to prevent excessive calls
	syms:raze flip key symIDDirectory;
	.debug.data:data:pullDataFromYFinance each syms;
	//due to some ticker having weird beta, exception clause here to fix it
	data:update beta:0nf from data where -9 <> type each data[`beta]
	`.scrapper.symMetaLinkage upsert `sym xkey `sym xcol data;
	symMetaLinkageLoc set symMetaLinkage;
	.log.out "Sym Meta Linkage Updated"
 };

\d .

//Add updateSymMeta to the timer
//`datetime$.z.d+1 to use the next closest EOD time
.log.out "Adding scrapperAddOn Timer Functions";
.cron.addJob[`.scrapper.updateSymMeta;1;::;`datetime$.z.d+1;0wz;1b];

.log.out "End of Add-on Init";
