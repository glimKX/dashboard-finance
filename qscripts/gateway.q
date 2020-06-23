//////////////////////////////////////////////////////////////////////////////////////////////////
//	gateway.q script which loads up with required templates
//	q script will start a simple q process as daily data HDB
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////
// Vanila GW
//////////////////////////

system "l ",getenv[`QSCRIPTS_DIR],"/log.q";
system "l ",getenv[`QSCRIPTS_DIR],"/cron.q";

\d .gw

//open connection to all processes using .log name space

connections:flip `process`handle`port`connection`status!"SJISS"$\:();
openConnection:{[w] procName:@[w;".log.processName";{:`unknown}];
	`.gw.connections insert (procName;`long$w;w(system;"p");`open;`free)
 };
closeConnection:{[w] update connection:`closed, status:`closed from `.gw.connections where handle = w; .log.out "Adding reconnection logic to timer"};
pushCallBack:{[w] neg[w](set;`.gw.callback;callback)};

//GW to open connection to all known processes
.log.out "Opening Connection to all known processes";
{.log.out "Opening Connection to ",.Q.s y;
	h:@[hopen;x;{.log.err "Failed to open connection due to ",.Q.s x;:0N}];
	if[not null h;openConnection[h]]
	} .' {flip (key[x]; value x)} .log.AllProcessName;

pending:()!();
reduceFunction:raze;

callback:{[client;res]
	isError:res[0];
	result:res[1];
	-30!(client;isError;result);
 };

remoteFunc:{[client;query]
	neg[.z.w](`.gw.callback;client;@[(0b;)value@;query;{[err](1b;err)}])
 };

sendToClient:{[proc;query]
	h:exec handle,status from connections where process = proc, connection = `open;
	//if handle is not opened, return failure immediately
	if[null first h`handle;'"Client is not present"];
	//TO-DO if handle is not present for free status, put query on a retry logic
	if[`free <> first h`status;.log.out "Process is busy, putting query on retry logic"];
	neg[first h`handle](remoteFunc;.z.w;query);
	-30!(::);
 };


\d .

.gw.po:.z.po;
.z.po:{.gw.openConnection[x]; .gw.pushCallBack[x]; .gw.po[x]};
.gw.pc:.z.pc;
.z.pc:{.gw.closeConnection[x];.gw.pc[x]};

.log.out "End of Init";
