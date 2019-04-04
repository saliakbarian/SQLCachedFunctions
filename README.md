# SQLCachedFunctions
Performance Enhanced T-SQL Functions using Cache

<p dir='rtl' align='right'>
توابع با سرعت اجرای بالا با کمک cache در SQL Server
</p>
The installation script, creates a new database with a mempory optimized table as the cache. Then it creates some scalar functions and uses them in the corresponding table valued functions together with the cache table to improve their performance.

## Database Installation
1. Open CachedFunctions.sql in an editor
2. Replace all occurences of YourDatabaseName to your database name
3. Change BUCKET_COUNT to a proper value
4. Execute the result code using SSMS or sqlcmd 
###### The recommended value for BUCKET_COUNT is 2*(the total number of records that you are going to insert into CachedValues table)

## Usage
```
SELECT OutputValue FROM dbo.cfn_CachedValidate_IranianNationalCode('0123456789')
SELECT * FROM dbo.cfn_CachedValidate_IranianNationalCode('0123456789')
SELECT * FROM dbo.cfn_CachedValidate_IranianNationalCode('1234567890')
SELECT * FROM dbo.cfn_CachedValidate_IranianNationalCode('12-345678-9')
```

