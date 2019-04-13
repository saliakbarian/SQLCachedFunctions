# SQLCachedFunctions [![Tweet](https://img.shields.io/twitter/url/http/shields.io.svg?style=social)](https://twitter.com/intent/tweet?text=Performance%20Enhanced%T-SQL%20Functions%20Usinge%20Cache&url=https://github.com/saliakbarian/SQLCachedFunctions&via=saliakbarian&hashtags=T-SQL,sql,function,performance,NationalCode,PostalCode,Cache,Memory-Optimized,MOD,developers)

Performance Enhanced T-SQL Functions using Cache in SQL Server
<p dir='rtl' align='right'>
توابع با سرعت اجرای بالا با کمک cache در SQL Server به زبان T-SQL
</p>

SQL-Cached-Functions is a repository of some useful T-SQL functions, along with the enhanced version of them using caches. The caches are implemented by memory optimized tables in SQL Server, and that's why you have to use SQL Server 2014 or later.

The functions currently implemented are:

Scalar Functions:
```
fn_Validate_IranianNationalCode
fn_Validate_IranianPostalCode
```
Cached Functions:
```
cfn_CachedValidate
cfn_CachedValidate_IranianNationalCode
cfn_CachedValidate_IranianPostalCode
```

## Installation
The installation script, creates a new file-group for your database with a memory optimized table as the cache. Then it creates some scalar functions and uses them in the corresponding table valued functions together with the cache table to improve their performance.

Installation Steps:
1. Open CachedFunctions.sql in an editor
2. Replace all occurrences of YourDatabaseName to your database name
3. Change BUCKET_COUNT to a proper value
4. Execute the result code using SSMS or sqlcmd 
###### The recommended value for BUCKET_COUNT is 2*(the total number of records that you are going to insert into CachedValues table)

## Usage
```
SELECT OutputValue FROM dbo.cfn_CachedValidate_IranianNationalCode('0123456789')
SELECT * FROM dbo.cfn_CachedValidate_IranianNationalCode('0123456789')
SELECT * FROM dbo.cfn_CachedValidate_IranianNationalCode('1234567890')
SELECT * FROM dbo.cfn_CachedValidate_IranianNationalCode('12-345678-9')
SELECT * FROM dbo.cfn_CachedValidate_IranianPostalCode('81587-56491')
```
