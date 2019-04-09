-- Cached Date Functions
-- Author: Saeed Aliakbarian
-- Create Date: 2019-04-07 (1398-01-18)
-- Last Update: 2019-04-07 (1398-01-18)

-- IMPORTANT
-- Before executing the following code:
--	install CachedFunctions.sql
--	install https://github.com/mirsaeedi/SQLCLR-Jalali-Date-Utility

-- Creating CachedDates Table and Indexes
CREATE TABLE [dbo].[CachedDates]
(
	[DateValue] [date] NOT NULL,
	[Jalali] [nvarchar](100) NOT NULL,
	[Gregorian] [nvarchar](100) NOT NULL,
	[DateFormat] [nvarchar](100) 
CONSTRAINT [PK_DateFormat_Jalali_DateValue]  PRIMARY KEY NONCLUSTERED
(
	[DateFormat],
	[Jalali],
	[DateValue]
),
CONSTRAINT [IX_DateFormat_Gregorian_DateValue] UNIQUE NONCLUSTERED
(
	[DateFormat],
	[Gregorian],
	[DateValue]
)
)WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_AND_DATA )
GO

-- Author: Saeed Aliakbarian
-- Create Date: 2018-10-22 (1397-07-30)
-- Last Update: 2019-04-07 (1398-01-18)
-- Description:	Returns 1 if input string only contains numberc digits, returns 0 otherwise
CREATE FUNCTION [dbo].[fn_IsDigits]
(
	@Str as NVARCHAR(MAX)
)
RETURNS BIT
AS
BEGIN
	IF @Str LIKE '%[^0-9]%'
		RETURN 0
	RETURN 1
END
GO

-- Author: Saeed Aliakbarian
-- Create Date: 2018-10-15 (1397-07-23)
-- Last Update: 2019-04-07 (1398-01-18)
-- Description:	Converts a Two Digit Year To a Four Digit Year
CREATE FUNCTION [dbo].[fn_2DigitYearTo4DigitYear]
(
	@Year as NVARCHAR(4)
	,@IsGregorian AS BIT=0
	,@FutureYears INT=NULL
)
RETURNS NVARCHAR(4)
AS
BEGIN
	DECLARE @MinYearRange INT
		,@MaxYearRange AS INT

	if LEN(@Year)=1
		SET @Year='0'+@Year

	IF @Year IS NULL OR @Year NOT LIKE '[0-9][0-9]'
		RETURN NULL

	IF @FutureYears IS NULL
		SET @FutureYears=0

	IF @IsGregorian=0 
		SET @MaxYearRange=dbo.GregorianToJalali(GETDATE(),'yyyy')+@FutureYears
	ELSE
		SET @MaxYearRange=DATEPART(YEAR,GETDATE())+@FutureYears
	SET @MinYearRange=@MaxYearRange-99

	IF LEN(@Year)=2
	BEGIN
 			IF @Year>=RIGHT(@MinYearRange,2)
				 SET @Year=LEFT(@MinYearRange,2)+@Year
			ELSE 
				 SET @Year=LEFT(@MaxYearRange,2)+@Year
	END
	ELSE 
		RETURN NULL 

	RETURN @Year
END
GO


-- Author: Saeed Aliakbarian
-- Create Date: 2018-10-22 (1397-07-30)
-- Last Update: 2019-04-07 (1398-01-18)
-- Description: DO NOT USE THIS FUNCTION. INTERNAL PURPOSE ONLY.
-- Looks up Gregorian Date String with 2 digits year format (YY) in the Cache and returns the corresponding TSQL Date
CREATE FUNCTION [dbo].[cfn_Lookup_DateStringToDate_Gregorian_YY]
(
	@StrDate AS NVARCHAR(20),
	@FutureYears AS INT
)
RETURNS TABLE
AS RETURN
(
	SELECT MAX(D.DateValue) AS DateValue
	FROM CachedDates D
	WHERE D.Gregorian=@StrDate
		AND D.DateValue<=DATEADD(YEAR,@FutureYears,GETDATE())
		AND D.DateFormat IN ('yyMMdd','yy-MM-dd','yy/MM/dd')
)
GO

-- Author: Saeed Aliakbarian
-- Create Date: 2018-10-22 (1397-07-30)
-- Last Update: 2019-04-07 (1398-01-18)
-- Description: DO NOT USE THIS FUNCTION. INTERNAL PURPOSE ONLY.
-- Looks up Gregorian Date String with 4 digits year format (YYYY) in the Cache and returns the corresponding TSQL Date
CREATE FUNCTION [dbo].[cfn_Lookup_DateStringToDate_Gregorian_YYYY]
(
	@StrDate AS NVARCHAR(20)
)
RETURNS TABLE
AS RETURN
(
	SELECT D.DateValue
	FROM CachedDates D
	WHERE D.Gregorian=@StrDate
		AND D.DateFormat IN ('yyyyMMdd','yyyy-MM-dd','yyyy/MM/dd')
)
GO


-- =============================================
-- Author:		<Saeed Aliakbarian>
-- Create Date: <97.07.30>
-- Description:	<Convert Gregorian Date String(YY or YYYY) To TSQL Date>
-- =============================================

-- Author: Saeed Aliakbarian
-- Create Date: 2018-10-22 (1397-07-30)
-- Last Update: 2019-04-07 (1398-01-18)
-- Description: DO NOT USE THIS FUNCTION. INTERNAL PURPOSE ONLY.
-- Looks up Gregorian Date String with 2 or 4 digits year format (YY or YYYY) in the Cache and returns the corresponding TSQL Date
CREATE FUNCTION [dbo].[cfn_Lookup_DateStringToDate_Gregorian]
(
	@StrDate AS NVARCHAR(20),
	@FutureYears INT
)
RETURNS TABLE
AS RETURN
(
	SELECT ISNULL((SELECT DateValue	FROM  dbo.cfn_Lookup_DateStringToDate_Gregorian_YYYY(@StrDate)),
					(SELECT DateValue	FROM  dbo.cfn_Lookup_DateStringToDate_Gregorian_YY(@StrDate,@FutureYears))
				) DateValue
)
GO

-- Author: Saeed Aliakbarian
-- Create Date: 2018-10-22 (1397-07-30)
-- Last Update: 2019-04-07 (1398-01-18)
-- Description: DO NOT USE THIS FUNCTION. INTERNAL PURPOSE ONLY.
-- Looks up Jalali Date String with 2 digits year format (YY) in the Cache and returns the corresponding TSQL Date
CREATE FUNCTION [dbo].[cfn_Lookup_DateStringToDate_Jalali_YY]
(
	@StrDate AS NVARCHAR(20),
	@FutureYears AS INT
)
RETURNS TABLE
AS RETURN
(
	SELECT MAX(D.DateValue) AS DateValue
	FROM CachedDates D
	WHERE D.Jalali=@StrDate
		AND D.DateValue<=DATEADD(YEAR,@FutureYears,GETDATE())
		AND D.DateFormat IN ('yyMMdd','yy-MM-dd','yy/MM/dd')
)
GO


-- Author: Saeed Aliakbarian
-- Create Date: 2018-10-22 (1397-07-30)
-- Last Update: 2019-04-07 (1398-01-18)
-- Description: DO NOT USE THIS FUNCTION. INTERNAL PURPOSE ONLY.
-- Looks up Jalali Date String with 4 digits year format (YYYY) in the Cache and returns the corresponding TSQL Date
CREATE FUNCTION [dbo].[cfn_Lookup_DateStringToDate_Jalali_YYYY]
(
	@StrDate AS NVARCHAR(20)
)
RETURNS TABLE
AS RETURN
(
	SELECT D.DateValue
	FROM CachedDates D
	WHERE D.Jalali=@StrDate
		AND D.DateFormat IN ('yyyyMMdd','yyyy-MM-dd','yyyy/MM/dd')
)
GO

-- Author: Saeed Aliakbarian
-- Create Date: 2018-10-22 (1397-07-30)
-- Last Update: 2019-04-07 (1398-01-18)
-- Description: DO NOT USE THIS FUNCTION. INTERNAL PURPOSE ONLY.
-- Looks up Jalali Date String with 2 or 4 digits year format (YY or YYYY) in the Cache and returns the corresponding TSQL Date
CREATE FUNCTION [dbo].[cfn_Lookup_DateStringToDate_Jalali]
(
	@StrDate AS NVARCHAR(20),
	@FutureYears INT
)
RETURNS TABLE
AS RETURN
(
	SELECT ISNULL((SELECT DateValue	FROM  dbo.cfn_Lookup_DateStringToDate_Jalali_YYYY(@StrDate)),
					(SELECT DateValue	FROM  dbo.cfn_Lookup_DateStringToDate_Jalali_YY(@StrDate,@FutureYears))
				) DateValue
)
GO

-- Author: Saeed Aliakbarian
-- Create Date: 2018-10-22 (1397-07-30)
-- Last Update: 2019-04-07 (1398-01-18)
-- Description:	Converts Date String To TSQL Date with specified Separator
CREATE FUNCTION [dbo].[fn_Convert_DateStringToDate]
(
	@StrDate AS NVARCHAR(20),
	@Separator AS NVARCHAR(1),
	@IsGregorian AS BIT, -- 0:Jalali  1:Gregorian
	@FutureYears AS INT=15
)
RETURNS DATE
AS
BEGIN
	DECLARE @i INT,
			@C NVARCHAR(1),
			@Day NVARCHAR(2),
			@Month NVARCHAR(2),
			@Year NVARCHAR(4),
			@Result DATE

		SET @StrDate=LTRIM(RTRIM(@StrDate))

		SET @i=LEN(@StrDate)
		
		if @i<=0
			RETURN NULL

		-- Day Last Digit
		SET @c=SUBSTRING(@StrDate,@i,1)
		if dbo.fn_IsDigits(@c)=0
			RETURN NULL
			
		SET @i=@i-1
		
		if @i<=0 
			RETURN NULL

		SET @c=SUBSTRING(@StrDate,@i,1)
		if dbo.fn_IsDigits(@c)=1
		BEGIN
			SET @Day=RIGHT(@StrDate,2)
			SET @i=@i-1
			IF @i<=0
				RETURN NULL
		END
		ELSE
			SET @Day='0'+RIGHT(@StrDate,1)

		-- If Separator exists skip it
		SET @c=SUBSTRING(@StrDate,@i,1)
		IF LEN(@Separator)>0
		BEGIN
			IF @c=@Separator
				SET @i=@i-1
			ELSE	-- Invalid Separator
				RETURN NULL
			IF @i<=0 
				RETURN NULL
		END


		-- Month Last Digit
		SET @c=SUBSTRING(@StrDate,@i,1)
		IF dbo.fn_IsDigits(@c)=0
			RETURN NULL
		SET @i=@i-1
		
		IF @i<=0 
			RETURN NULL
				
		SET @c=SUBSTRING(@StrDate,@i,1)
		IF dbo.fn_IsDigits(@c)=1
		BEGIN
			SET @Month=SUBSTRING(@StrDate,@i,2)
			SET @i=@i-1
			if @i<=0 
				RETURN NULL
		END
		ELSE
			SET @Month='0'+SUBSTRING(@StrDate,@i+1,1)


		-- If Separator exists skip it
		SET @c=SUBSTRING(@StrDate,@i,1)
		IF LEN(@Separator)>0
		BEGIN
			IF @c=@Separator
				SET @i=@i-1
			ELSE	-- Invalid Separator
				RETURN NULL
			IF @i<=0 
				RETURN NULL
		END

		IF @i>4
			RETURN NULL
		SET @Year=LEFT(@StrDate,@i)
		IF dbo.fn_IsDigits(@Year)=0
			RETURN NULL

		IF LEN(@Year) NOT IN (2,4)
			RETURN NULL

		SET @StrDate=@Year+@Month+@Day

		SET @Result=NULL
		IF @IsGregorian=0
			SET @Result=(SELECT * FROM [dbo].[cfn_Lookup_DateStringToDate_Jalali](@StrDate,@FutureYears))
		ELSE
			SET @Result=(SELECT * FROM [dbo].[cfn_Lookup_DateStringToDate_Gregorian](@StrDate,@FutureYears))

		IF @Result IS NOT NULL
			RETURN @Result

		If LEN(@Year) < 4
			SET @Year=[dbo].[fn_2DigitYearTo4DigitYear] (@Year,@IsGregorian,@FutureYears)
		if LEN(@Year) <> 4 
			RETURN NULL
	
		SET @StrDate=@Year+'-'+@Month+'-'+@Day
		IF (@IsGregorian=0 AND @StrDate<'1131-10-12')
			OR (@IsGregorian=1 AND @StrDate<'1753-01-01') -- Minimum possible value for SQL Server Date
			RETURN NULL
			
		IF (@IsGregorian=0 AND @StrDate>'9378-10-12')
			OR (@IsGregorian=1 AND @StrDate>'9999-12-31') -- Maximum possible value for SQL Server Date
			RETURN NULL
			
		IF @IsGregorian=0
			RETURN dbo.JalaliToGregorian(@StrDate,'-')

		RETURN TRY_CAST(@StrDate AS DATE)
END
GO


-- Author: Saeed Aliakbarian
-- Create Date: 2018-10-22 (1397-07-30)
-- Last Update: 2019-04-07 (1398-01-18)
-- Description:	Converts Date String To TSQL Date with Optional Separator
CREATE FUNCTION [dbo].[fn_Convert_DateStringToDate_OptionalSeparator]
(
	@StrDate AS NVARCHAR(20)
	,@IsGregorian AS BIT -- 0:Jalali  1:Gregorian
	,@FutureYears AS INT=15
)
RETURNS DATE
AS
BEGIN
	DECLARE @i INT,
			@C NVARCHAR(1),
			@Day NVARCHAR(2),
			@Month NVARCHAR(2),
			@Year NVARCHAR(4),
			@Result DATE

		SET @StrDate=LTRIM(RTRIM(@StrDate))

		SET @i=LEN(@StrDate)
		
		if @i<=0
			RETURN NULL

		-- Day Last Digit
		SET @c=SUBSTRING(@StrDate,@i,1)
		if dbo.fn_IsDigits(@c)=0
			RETURN NULL
			
		SET @i=@i-1
		
		if @i<=0 
			RETURN NULL

		SET @c=SUBSTRING(@StrDate,@i,1)
		if dbo.fn_IsDigits(@c)=1
		BEGIN
			SET @Day=RIGHT(@StrDate,2)
			SET @i=@i-1
			IF @i<=0
				RETURN NULL
		END
		ELSE
			SET @Day='0'+RIGHT(@StrDate,1)

		-- If Separator exists skip it
		SET @c=SUBSTRING(@StrDate,@i,1)
		IF dbo.fn_IsDigits(@c)=0
			SET @i=@i-1
		IF @i<=0 
			RETURN NULL


		-- Month Last Digit
		SET @c=SUBSTRING(@StrDate,@i,1)
		IF dbo.fn_IsDigits(@c)=0
			RETURN NULL
		SET @i=@i-1
		
		IF @i<=0 
			RETURN NULL
				
		SET @c=SUBSTRING(@StrDate,@i,1)
		IF dbo.fn_IsDigits(@c)=1
		BEGIN
			SET @Month=SUBSTRING(@StrDate,@i,2)
			SET @i=@i-1
			if @i<=0 
				RETURN NULL
		END
		ELSE
			SET @Month='0'+SUBSTRING(@StrDate,@i+1,1)


		-- If Separator exists skip it
		SET @c=SUBSTRING(@StrDate,@i,1)
		IF dbo.fn_IsDigits(@c)=0
			SET @i=@i-1
		IF @i<=0 
			RETURN NULL

		IF @i>4
			RETURN NULL

		SET @Year=LEFT(@StrDate,@i)
		IF dbo.fn_IsDigits(@Year)=0
			RETURN NULL

		IF LEN(@Year) NOT IN (2,4)
			RETURN NULL

		SET @StrDate=@Year+@Month+@Day

		SET @Result=NULL
		IF @IsGregorian=0
			SET @Result=(SELECT * FROM [dbo].[cfn_Lookup_DateStringToDate_Jalali](@StrDate,@FutureYears))
		ELSE
			SET @Result=(SELECT * FROM [dbo].[cfn_Lookup_DateStringToDate_Gregorian](@StrDate,@FutureYears))

		IF @Result IS NOT NULL
			RETURN @Result

		If LEN(@Year) < 4
			SET @Year=[dbo].[Fn_2DigitYearTo4DigitYear] (@Year,@IsGregorian,@FutureYears)
		if LEN(@Year) <> 4 
			RETURN NULL
	
		SET @StrDate=@Year+'-'+@Month+'-'+@Day
		IF (@IsGregorian=0 AND @StrDate<'1131-10-12')
			OR (@IsGregorian=1 AND @StrDate<'1753-01-01') -- Minimum possible value for SQL Server Date
			RETURN NULL
			
		IF (@IsGregorian=0 AND @StrDate>'9378-10-12')
			OR (@IsGregorian=1 AND @StrDate>'9999-12-31') -- Maximum possible value for SQL Server Date
			RETURN NULL
			
		if @IsGregorian=0
			RETURN dbo.JalaliToGregorian(@StrDate,'-')

		RETURN TRY_CAST(@StrDate AS DATE)
END
GO

-- Author: Saeed Aliakbarian
-- Create Date: 2018-10-22 (1397-07-30)
-- Last Update: 2019-04-07 (1398-01-18)
-- Description:	Converts Date String To TSQL Date with specified Separator + Cache for speed up
CREATE FUNCTION [dbo].[cfn_Convert_DateStringToDate] 
(	
	@StrDate AS NVARCHAR(20)
	,@Separator AS NVARCHAR(1)
	,@IsGregorian AS BIT
	,@FutureYears AS INT=15
)
RETURNS TABLE
AS
RETURN 
(
	SELECT 
		CASE 
			WHEN @StrDate IS NULL THEN NULL
			WHEN @IsGregorian=1 THEN 
					ISNULL((SELECT DateValue	FROM  dbo.[cfn_Lookup_DateStringToDate_Gregorian](@StrDate,@FutureYears)),
							dbo.fn_Convert_DateStringToDate(@StrDate,@Separator,@IsGregorian,@FutureYears))
			ELSE
					ISNULL((SELECT DateValue	FROM  dbo.cfn_Lookup_DateStringToDate_Jalali(@StrDate,@FutureYears)),
							dbo.fn_Convert_DateStringToDate(@StrDate,@Separator,@IsGregorian,@FutureYears))
		END AS DateValue
)

GO

-- Author: Saeed Aliakbarian
-- Create Date: 2018-10-22 (1397-07-30)
-- Last Update: 2019-04-07 (1398-01-18)
-- Description:	Converts Date String To TSQL Date with Optional Separator + Cache for speed up
CREATE FUNCTION [dbo].[cfn_Convert_DateStringToDate_OptionalSeparator]
(	
	@StrDate AS NVARCHAR(20)
	,@IsGregorian AS BIT
	,@FutureYears AS INT=15
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT 
		CASE 
			WHEN @StrDate IS NULL THEN NULL
			WHEN @IsGregorian=1 THEN 
					ISNULL((SELECT DateValue	FROM  dbo.cfn_Lookup_DateStringToDate_Gregorian(@StrDate,@FutureYears)),
							dbo.fn_Convert_DateStringToDate_OptionalSeparator(@StrDate,@IsGregorian,@FutureYears))
			ELSE
					ISNULL((SELECT DateValue	FROM  dbo.cfn_Lookup_DateStringToDate_Jalali(@StrDate,@FutureYears)),
							dbo.fn_Convert_DateStringToDate_OptionalSeparator(@StrDate,@IsGregorian,@FutureYears))
		END AS DateValue
)

GO
