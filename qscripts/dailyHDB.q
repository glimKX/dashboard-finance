//////////////////////////////////////////////////////////////////////////////////////////////////
//	dailyHDB.q script which loads up with required templates
//	q script will start a simple q process as daily data HDB
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////
// Vanila HDB
//////////////////////////

system "l ",getenv[`QSCRIPTS_DIR],"/log.q";
system "l ",getenv[`QSCRIPTS_DIR],"/cron.q";

.log.out "Loading DAILY HDB DIR";
system "l ",getenv `HDB_DAILY_DIR;
.log.out "Loaded DAILY HDB DIR";

//Framework to re-load HDB after scrapper has performed its job

\d .hdb

//symIDDir schema
symIDDirectorySchema:`sym xkey flip `id`information`sym`lastUpdated!"J*SZ"$\:();

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

//linkage schema
symMetaLinkageSchema:`sym xkey flip `sym`sector`industry`longBusinessSummary`beta`currency`marketCap`logo_url!"SSS*FSF*"$\:();
$[not () ~ key symMetaLinkageLoc:hsym `$getenv `SYM_META_LINKAGE;
        [
                .log.out "Loading symMeta Linkage";
                symMetaLinkage:get symMetaLinkageLoc;
                .log.out "Loaded symMeta Linkage"
        ];
        [
                .log.out "Using symMeta Linkage Schema";
                symMetaLinkageLoc:hsym `$getenv `SYM_META_LINKAGE;
                symMetaLinkage:symMetaLinkageSchema
        ]
 ];

//For incoming direct queries, it will be parsed to check if its a select statement.
//If so, to add int if sym exists
queryParse:{
	parseBoolean:@[{not first enlist[?] = first parse x};x;{:1b}];
	if[parseBoolean;
		:x
	];
	if[`dailyFinancialData <> (parseTree:parse x) 1;
		:x
	];

	.log.out "Query Parse triggered, manipulating query to include int";
	
	wClause:eval parseTree 2;
	$[(`sym = raze[wClause]1) & 1=count wClause;
		[
			ids:value ?[symIDDirectory;wClause;();enlist[`int]!enlist[`id]];
			wClause:enlist[(in;`int;ids)],wClause
		];
		(`int <> wClause[0;1]) & (`sym in wClause[;1]) & 1 < count wClause;
			[
				symWClause:wClause where `sym = wClause[;1];
				ids:value ?[symIDDirectory;symWClause;();enlist[`int]!enlist[`id]];
				wClause:enlist[(in;`int;ids)],wClause
			];
			:parseTree
	];
	
        parseTree[2]:wClause;
	.log.out .Q.s1 parseTree;
        :parseTree
	
 };

//Wrapper to perform the same actions as queryParse when this is done through UI
queryBySym:{[syms]
	if[11h <> abs type syms;'"Syms is not symbol type"]
	syms,:();
	wClause:enlist (in;`sym;syms);
	ids: value ?[symIDDirectory;wClause;();enlist[`int]!enlist[`id]];
	wClause:enlist[(in;`int;ids)],wClause;
	aClause:`Open`High`Low`Close`Volume`Date!`open`high`low`adjustedClose`volume`date;
	//TO-DO include arbitary limits
	:?[`dailyFinancialData;wClause;0b;aClause]
 };

pullSymByIndusty:{[ind]
 	5#select from `marketCap xdesc select sym,marketCap, beta, logo_url from symMetaLinkage where sector = ind
 };

queryForPartition:{[syms]
	if[11h <> abs type syms;'"Syms is not symbol type"];
        syms: enlist syms;
        wClause:enlist (in;`sym;syms);
        ids: value ?[symIDDirectory;wClause;();enlist[`int]!enlist[`id]];
	wClause:enlist[(in;`int;ids)],wClause
 };

queryForMetrics:{[tab;syms;col]
	wClause: queryForPartition[syms];
	aClause:$[1 = count col;;raze] {enlist[x]!enlist (last;x)} each col;
	bClause:enlist[`sym]!enlist `sym;
	:?[tab;wClause;bClause;aClause]
 };

queryForBS:{[syms]
	col:`year`cashAndCashEquivalents`accountsReceivableCurrent`accountPayableCurrent`assetsCurrent`liabilitiesCurrent;
	tab:`finnhubBSReport;
	queryForMetrics[tab;syms;col]
 };

queryForTop5SymMetrics:{[ind]
	syms:exec 5#sym from `marketCap xdesc select sym,marketCap from symMetaLinkage where sector = ind;
	tab:queryForBS[syms];
	//pivot for easier comparison
	(flip enlist[`metrics]!enlist 1 _ cols tab)!flip value[key[tab]`sym]!flip value flip value[tab]
 };
	
	
	

reloadDB:{
	.log.out "Re-loading HDB";
	system "l .";
	if[not () ~ key symIDDirLoc;
		symIDDirectory:get symIDDirLoc;
	];
	if[not () ~ key symMetaLinkageLoc;
		symMetaLinkage:get symMetaLinkageLoc
	];
	.log.out "HDB Re-loaded";
 };

\d .

.log.out "Modifying .z.pg and .z.ps";
.hdb.pg:.z.pg;
.hdb.ps:.z.ps;
.z.pg:{x:.hdb.queryParse[x]; .hdb.pg[x]};
.z.ps:{x:.hdb.queryParse[x]; .hdb.ps[x]};

.log.out "End of Init";
