
### 0.2.0

#### New Features
	- Implemented multisync for all functions which means you can use the api in a normal sync context
	- Added `newAsyncClient`
	- Added basic caching of market data. If you try and access market data from a location you do not have a ship at
	  but you have been to it before then it returns the last cached market data
	  
#### Changes
	- A username is now claimed with `claimUsername`
