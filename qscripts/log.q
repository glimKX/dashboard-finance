//////////////////////////////////////////////////////////////////////////////////////////////////
//	log.q script which loads up with all tick templates
//	q script will define functions in .z.po .z.pc and some .log functions
//////////////////////////////////////////////////////////////////////////////////////////////////

//init connection schema
.log.connections:flip `dateTime`user`host`ipAddress`connection`handle`duration!"ZSS*SIV"$\:();

//when connection is opened, collect from handle the following information
//datetime username hostname ipaddress connection duration
//collect data from .z.po
.z.po:{[w] `.log.connections insert .z.Z,.z.u,(.Q.host .z.a;"." sv string "h"$0x0 vs .z.a),`opened,w,0Nv;.log.out .log.co w};
.z.wo:{[w] `.log.connections insert .z.Z,.z.u,(.Q.host .z.a;"." sv string "h"$0x0 vs .z.a),`opened,w,0Nv;.log.out .log.co w};

//when connection is closed, update connection to closed
.z.pc:{[w] update connection:`closed,duration:"v"$80000*.z.Z-dateTime from `.log.connections where handle = w;.log.out .log.cc w};
.z.wc:{[w] update connection:`closed,duration:"v"$80000*.z.Z-dateTime from `.log.connections where handle = w;.log.out .log.cc w};

//need unique name for each log file
.log.AllProcessName:{x:"=" vs' x;(!) . reverse flip @'[@'[@'[x;1;"J"$];0;-5_];0;"S"$]} system "grep -v \"#\" ", getenv[`CONFIG_DIR],"/port.config | awk '{print $2}'";
.log.processName:.log.AllProcessName system"p";
.log.getNewHandle:{hopen `$":",getenv[`LOG_DIR],"/",string[.log.processName],string[.z.D],".log"};
.log.file:hopen `$":",getenv[`LOG_DIR],"/",string[.log.processName],string[.z.D],".log";

.log.string:{string[.log.processName]," ## ",string[.z.P]," ## ",x," \n"};
/capture initalised time
.log.time:.z.T;
/declare log output function
.log.out:{.log.file "INFO: ",.log.string x};
.log.err:{.log.file "ERROR: ",.log.string x};
 
\c 200 200

.log.cc:{[w] "Connection closed: ",.Q.s1 exec from .log.connections where handle = w};
.log.co:{[w] "Connection opened: ",.Q.s1 exec from .log.connections where handle = w}; 

.log.value:{@[{.log.out "User: ",string[.z.u]," ## Running: ",.Q.s1 x;value x};x;{.log.err -1_.Q.s x;x}]};

/roll-over function
/note that you have to add activate this as an EOD function using cron
/.cron.addJob[`.log.rollOver;1;::;`datetime$.z.d+1;0wz;1b];

.log.rollOver:{
	.log.out "Rolling over to new file, closing handle: ",.Q.s .log.file;
	hclose .log.file;
	.log.file:.log.getNewHandle[];
	.log.out "Rolled over to new log file"
	};

/adding logging message in evaluating ipc
.z.pg:{.log.value x};
.z.ps:{.log.value x};

/shutdown function
.log.shutdown:{.log.out "Shutdown Trigger from mainScript";exit 0};


//After delcaring, throw initialising message
.log.out "Initialising ",string[.log.processName]," Process";
