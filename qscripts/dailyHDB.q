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

//For incoming queries, it will be parsed to check if its a select statement.
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
	

reloadDB:{
	.log.out "Re-loading HDB";
	system "l .";
	if[not () ~ key symIDDirLoc;
		symIDDirectory:get symIDDirLoc;
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
