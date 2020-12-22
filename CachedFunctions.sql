-- Cached Functions Installation
-- Author: Saeed Aliakbarian
-- Created: 2019-03-10 (1397-12-19)
-- Last Update: 2020-12-22 (1399-10-02)

-- Before Execute:
--	1. Replace all occurences of YourDatabaseName to your database name in the following code 
--	2. Change BUCKET_COUNT to a proper value
--		The recommended value for BUCKET_COUNT is 2*(the total number of records that you are going to insert into CachedValues table)
--	3. If your database already contains a Memory Optimized Data FileGroup, skip the Database Init Section
-- After Execute:
--	Insert as many valid and invalid values as you can into CachedValues table. 
--	The Cached Functions performance is highly dependent on the cache hit rate, i.e. the percentage of the input values that exist in the cache.
--	Remember that the OutputValue must be NULL for invalid InputValues. 


USE YourDatabaseName
GO

-- *** Database Init Section Begin ***
-- Adding Memory Optimized Data FileGroup
-- If your database already contains a Memory Optimized Data FileGroup, skip this section
ALTER DATABASE YourDatabaseName SET AUTO_CLOSE OFF;
GO
ALTER DATABASE YourDatabaseName ADD FILEGROUP YourDatabaseName_MOD CONTAINS MEMORY_OPTIMIZED_DATA
GO
DECLARE @MOD_FileName NVARCHAR(MAX)
DECLARE @SQL NVARCHAR(MAX)
SELECT @MOD_FileName=LEFT(physical_name,LEN(physical_name)-CHARINDEX('\',REVERSE(physical_name)))+'\YourDatabaseName_MOD'
FROM sys.master_files
WHERE name='YourDatabaseName'
SET @SQL='ALTER DATABASE YourDatabaseName ADD FILE (name=''YourDatabaseName_MOD'', filename='''+@MOD_FileName+''') TO FILEGROUP YourDatabaseName_MOD'
EXEC (@SQL)
GO
ALTER DATABASE YourDatabaseName SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT=ON  
GO  
-- *** Database Init Section End ***


-- Creating cache tables
CREATE TABLE [dbo].[CacheTypes](
	[Id] [int] NOT NULL,
	[Name] [nvarchar](50) NULL,
 CONSTRAINT [PK_CacheTypes] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)
)
GO

CREATE TABLE [dbo].[CachedValues]
(
	[CacheTypeId] [int] NOT NULL,
	[InputValue] [nvarchar](4000) NOT NULL,
	[OutputValue] [nvarchar](4000) NULL,

CONSTRAINT [PK_CachedValues] PRIMARY KEY NONCLUSTERED HASH 
(
	[CacheTypeId],
	[InputValue]
)WITH ( BUCKET_COUNT = 16384)
)WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_AND_DATA )
GO


							       
-- This function is a sample for validating an input string
-- Output:
--		If Input is Not Valid => Returns NULL
--		If Input is Valid => Returns the (possibly) corrected & transformed value of the input
-- Replace the code inside the function with your validation & transformation code
CREATE FUNCTION [dbo].[fn_Validate_Foo](@Input NVARCHAR(50)) 
RETURNS NVARCHAR(50)
AS
BEGIN
	DECLARE @Output NVARCHAR(50)

	IF LEN(@Input)<>10
		RETURN NULL
	SET @Output=UPPER(@Input)

    RETURN @Output
END
GO

-- Author: Saeed Aliakbarian
-- Created: 2019-03-10 (1397-12-19)
-- Last Update: 2020-12-22 (1399-10-02)
-- This function validates an input string to be a valid Iranian National Code
-- Output:
--		If Valid => the 10 digit Iranian National Code with English numeric digits
--		If Not Valid => NULL
-- Notes:
-- If the input string contains '-' or '.' or ' ' they are removed before validation
-- If the input string is 9 or 8 characters long, the functions adds 1 or 2 leading zeros
-- If the input string contains Persian or Arabic numeric digits, they are converted to English numeric digits as output
-- A valid Iranian National Code cannot start with 000 as no region is coded as 000 (as of 1397-12-12) 
-- An input string determined as an invalid one, is definitely invalid and will not be assigned to anybody even in the future
-- An input string determined as a valid one will have one of the following conditions:
--   1. Already assigned to a real person
--	 2. Valid and free that can be assigned to a real person in the future
--   3. Invalid because of other conditions not contained in this function, such as region prefixes that are invalid or other limitations not currently publicly announced by authorities 
-- To determin if an Iranian National Code is assigned to a real person or not, you have to check it with authorities at ssaa.ir
CREATE FUNCTION [dbo].[fn_Validate_IranianNationalCode](@NationalCode NVARCHAR(20)) 
RETURNS NVARCHAR(10)
AS
BEGIN
	DECLARE @NewNC NVARCHAR(10)=''
	SET @NationalCode=REPLACE(REPLACE(REPLACE(@NationalCode,'-',''),'.',''),' ','')
	SET @NationalCode=LTRIM(RTRIM(@NationalCode))
	IF @NationalCode IS NULL OR LEN(@NationalCode)>10 OR LEN(@NationalCode)<8
		RETURN NULL
	
	WHILE LEN(@NationalCode)<10
		SET @NationalCode='0'+@NationalCode

	-- National Code can not start with 000
    IF LEFT(@NationalCode,3)='000'
		RETURN NULL

	IF @NationalCode LIKE '%[^0123456789۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩]%'
		RETURN NULL

	DECLARE @c int
	DECLARE @ch nvarchar(1)
	DECLARE @UC INT

	DECLARE @i INT=1
    DECLARE @r int=0
	WHILE @i<=10
	BEGIN
		SET @ch=SUBSTRING(@NationalCode,@i,1)
		SET @UC=UNICODE(@ch)
		IF @UC BETWEEN 0x06F0 AND 0x6F9 -- Arabic Digits
			SET @CH=NCHAR(@UC-1728) -- English Digits
		ELSE IF @UC BETWEEN 0x0660 AND 0x669 -- Persian Digits
			SET @CH=NCHAR(@UC-1584) -- English Digits
		ELSE IF @UC NOT BETWEEN 0x30 AND 0x39	-- English Digits
			RETURN NULL
		SET @NewNC+=@ch
		IF @i<10
			SET @r+=CAST(@ch AS INT)*(11-@i)
		ELSE
			SET @c=CAST(@ch AS INT)
		SET @i+=1
	END

	SET @r%=11
	IF (@r<2 AND @r<>@c) OR (@r>=2 AND @r<>11-@c)
			RETURN NULL
    Return @NewNC
END
GO

-- Author: Saeed Aliakbarian
-- Created: 2019-03-10 (1397-12-19)
-- Last Update: 2019-04-07 (1398-01-18)
-- This function validates an input string to be a valid Iranian Postal Code
-- Output:
--		If Valid => the 10 digit Iranian Postal Code with English numeric digits
--		If Not Valid => NULL
-- Notes:
-- If the input string contains '-', '.' or ' ' characters, they are removed before validation
-- If the input string contains Persian or Arabic numeric digits, they are converted to English numeric digits it the output
-- A valid Iranian Postal Code must contain at least one '1' digit among its first 5 digits 
-- A valid Iranian Postal Code must not contain any '0' or '2' digits among its first 5 digits
-- An input string determined as an invalid one, is definitely invalid and will not be assigned to any place even in the future
-- An input string determined as a valid one, will have one of the following conditions:
--   1. Already assigned to a place
--	 2. Valid and free that can be assigned to a real place in the future
--   3. Invalid because of other conditions not contained in this function (possibly not currently publicly announced by authorities)
-- To determin if an Iranian Postal Code is assigned to a real place or not, you have to check it with authorities at post.ir
CREATE FUNCTION [dbo].[fn_Validate_IranianPostalCode](@PostalCode NVARCHAR(20)) 
RETURNS NVARCHAR(10)
AS
BEGIN
	DECLARE @IsOneFound BIT=0
	DECLARE @ResultPC NVARCHAR(10)=''

    DECLARE @C NCHAR(1)
	DECLARE @UC INT
	DECLARE @i INT=1

	SET @PostalCode=REPLACE(REPLACE(REPLACE(@PostalCode,'-',''),'.',''),' ','')
	SET @PostalCode=LTRIM(RTRIM(@PostalCode))
	IF @PostalCode IS NULL OR LEN(@PostalCode)<>10
		RETURN NULL

	WHILE @i<=10
	BEGIN
		SET @C=SUBSTRING(@PostalCode,@i,1)
		SET @UC=UNICODE(@C)

		IF @UC BETWEEN 0x06F0 AND 0x6F9 -- Arabic Digits
		BEGIN
			SET @UC-=1728 -- English Digits
			SET @C=NCHAR(@UC) 
		END
		ELSE IF @UC BETWEEN 0x0660 AND 0x669 -- Persian Digits
		BEGIN
			SET @UC-=1584 -- English Digits
			SET @C=NCHAR(@UC) 
		END

		-- No other Character are acceptable
		IF @UC NOT BETWEEN 0x30 AND 0x39 -- English Digits
			RETURN NULL
		
		IF @i<=5
		BEGIN
			IF @UC=0x31	-- 1
				SET @IsOneFound=1	-- a '1' Digit must exists in first five digits
			ELSE IF @UC=0x30 OR @UC=0x32	-- 0 and 2 are not acceptable in first 5 digits of postal code
				RETURN NULL
		END

		SET @ResultPC=@ResultPC+@C
		SET @i=@i+1
	END

	-- a '1' Digit must exist in first five digits
	IF @IsOneFound=0
		RETURN NULL

	RETURN @ResultPC
END
GO


-- This cached table function validates the @InputValue string based on @CacheTypeId
-- Output: (as OutputValue field)
--		if @InputValue is valid => corresponding output value
--		if @InputValue is not valid => NULL
CREATE FUNCTION [dbo].[cfn_CachedValidate]
(	
	@CacheTypeId INT,
	@InputValue NVARCHAR(4000)
)
RETURNS TABLE
AS
RETURN
(
	SELECT ISNULL((SELECT CV.OutputValue
				FROM  dbo.CachedValues CV
				WHERE CV.CacheTypeId=@CacheTypeId AND CV.InputValue=@InputValue),
					CASE @CacheTypeId
						WHEN 0 THEN dbo.fn_Validate_Foo(@InputValue)
						WHEN 1 THEN dbo.fn_Validate_IranianNationalCode(@InputValue)
						WHEN 2 THEN dbo.fn_Validate_IranianPostalCode(@InputValue)
					END) OutputValue
)
GO

-- This cached table function validates an input string to be a valid Iranian National Code
-- Output:
--		If Valid => the 10 digit Iranian National Code with English numeric digits
--		If not Valid => NULL
CREATE FUNCTION [dbo].[cfn_CachedValidate_IranianNationalCode]
(	
	@InputValue NVARCHAR(20)
)
RETURNS TABLE 
AS
RETURN
(
	SELECT OutputValue FROM cfn_CachedValidate( 1, @InputValue)
)
GO

-- This cached table function validates an input string to be a valid Iranian Postal Code
-- Output:
--		If Valid => the 10 digit Iranian Postal Code with English numeric digits
--		If not Valid => NULL
CREATE FUNCTION [dbo].[cfn_CachedValidate_IranianPostalCode]
(	
	@InputValue NVARCHAR(20)
)
RETURNS TABLE 
AS
RETURN
(
	SELECT OutputValue FROM cfn_CachedValidate( 2, @InputValue)
)
GO


-- Cache Types Data
INSERT [dbo].[CacheTypes] ([Id], [Name]) VALUES (0, N'Foo')
GO
INSERT [dbo].[CacheTypes] ([Id], [Name]) VALUES (1, N'IranianNationalCode')
GO
INSERT [dbo].[CacheTypes] ([Id], [Name]) VALUES (2, N'IranianPostalCode')
GO

-- Sample Data
INSERT [dbo].[CachedValues] ([CacheTypeId], [InputValue], [OutputValue]) VALUES (0, N'12345', NULL)
GO
INSERT [dbo].[CachedValues] ([CacheTypeId], [InputValue], [OutputValue]) VALUES (0, N'1234567890', N'1234567890')
GO
INSERT [dbo].[CachedValues] ([CacheTypeId], [InputValue], [OutputValue]) VALUES (0, N'123456789', N'0123456789')
GO
INSERT [dbo].[CachedValues] ([CacheTypeId], [InputValue], [OutputValue]) VALUES (1, N'1234567890', NULL)
GO
INSERT [dbo].[CachedValues] ([CacheTypeId], [InputValue], [OutputValue]) VALUES (1, N'1111111111', N'1111111111')
GO
INSERT [dbo].[CachedValues] ([CacheTypeId], [InputValue], [OutputValue]) VALUES (1, N'0123456789', N'0123456789')
GO
INSERT [dbo].[CachedValues] ([CacheTypeId], [InputValue], [OutputValue]) VALUES (1, N'123456789', N'0123456789')
GO
INSERT [dbo].[CachedValues] ([CacheTypeId], [InputValue], [OutputValue]) VALUES (1, N'012-345678-9', N'0123456789')
GO
INSERT [dbo].[CachedValues] ([CacheTypeId], [InputValue], [OutputValue]) VALUES (1, N'12-345678-9', N'0123456789')
GO
