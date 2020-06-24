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

yf:.p.import[`yfinance];

pullDataFromYFinance:{[syms]
	if[1<>count syms;syms:first syms];
	data:yf[`:Ticker]syms;
	//data is a ticker class and info returns a dictionary
	//have to convert back to q in order to index
	dict:data[`:info][`];
	//hardcoded list of data to keep
	:`symbol`sector`industry`longBusinessSummary`beta`currency`marketCap`logo_url#dict
 };

\d .


.log.out "End of Add-on Init";
