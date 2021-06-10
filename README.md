# dashboard-finance
Financial Dashboard Powered by Kx Dashboard

## Dependencies
- python 3.5 (Anaconda was used)
- kdb 4.0 64 bit
- embedPy
- Kx Dashboard 
- Ubuntu 16/AWS Linux 2
- API Keys
	- Alphavantage
	- Finnhub
- Python libraries
	- ranaroussi yfinance (https://github.com/ranaroussi/yfinance)

## Installation Guide
Check config/env.config to ensure that it is configured to your environment
Current settings are based off AWS home directory structure

When ready, run install.sh in home directory
You will be prompted to provide API Keys for supported data providers
1. ALPHAVANTAGE (https://www.alphavantage.co/)
2. FINNHUB (finnhub.io)

After installation of api, you can start the available QProcesses in sequence
1. ./startQProcess scrapper
2. ./startQProcess dailyhdb
3. ./startQProcess gateway

### Secret Keys
API Keys are stored in secretkey folder and this is manage by env.config on the location of it
Start QProcess.sh will then source for the secretkey file if availableo

## Credits
ranaroussi for yfinance which provided a quick solution to stock to industry linkage in python

