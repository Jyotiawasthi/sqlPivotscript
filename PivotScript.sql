** Script For Getting Pivot Data

SET NOCOUNT ON

-- Create temp tabels to hold the data
IF OBJECT_ID('tempdb..#Source') IS NOT NULL
BEGIN
	DROP TABLE #Source
END 

CREATE TABLE #Source (
	[UID] INT,
	IdPermission INT,
	Feature nvarchar(64),
	[Enable] BIT
)

IF OBJECT_ID('tempdb..#User') IS NOT NULL
BEGIN
	DROP TABLE #User
END 

CREATE TABLE #User (
	[UID] INT,
	UserName nvarchar(256)
)
Go


----------Insert some Tempory Data in Table
INSERT INTO #Source (UID, IdPermission, Feature, Enable) VALUES (122, 1, 'Tab 01', 0)
INSERT INTO #Source (UID, IdPermission, Feature, Enable) VALUES (122, 18, 'Tab 03', 0)
INSERT INTO #Source (UID, IdPermission, Feature, Enable) VALUES (122, 33, 'Tab 04', 1)
INSERT INTO #Source (UID, IdPermission, Feature, Enable) VALUES (133, 18, 'Tab 03', 1)
INSERT INTO #Source (UID, IdPermission, Feature, Enable) VALUES (133, 33, 'Tab 04', 0)

INSERT INTO #User (UID, UserName) VALUES (122, 'bob@gmail.com')
INSERT INTO #User (UID, UserName) VALUES (133, 'abe@gmail.com')
Go



---for procedure for pivot result
Create procedure #getpivot
As
begin
DECLARE @cols AS NVARCHAR(MAX),-------------@cols for column names
    @colsName AS NVARCHAR(MAX),-----------@colsName for feature column those having null values
    @query  AS NVARCHAR(MAX)----------------@query for complete query
select @colsName = STUFF((SELECT  ',ISNULL(' + QUOTENAME(Feature+'-'+c.col) + ', ''0'') As '+QUOTENAME(Feature+'-'+c.col) + '' as col1
                      from #Source 
                      cross apply 
                      (
                        select 'P',1 col
                        union all
                        select 'E',2 
                      ) c (col, so)
					     group by col, so, Feature
                    order by Feature , so
            FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'')
-----------@colsname give column name and if a column have  null value then it will give 0 value for that column in @query 
------------'P' dealing with idpermission column and 'E for enable column '
select @cols = STUFF((SELECT distinct ',' + QUOTENAME(Feature +'-'+c.col) 
                      from #Source
                      cross apply 
                      (
                        select 'P' col
                        union all
                        select 'E'
                      ) c
            FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'')


set @query   = 'SELECT Uid, UserName,' + @colsName + ' 
     from 
     (
      select 
        Uid, 
        Feature +''-''+ col as col,
        UserName,
        value
      from
      (
         select #Source.Uid,Feature,(CASE WHEN isnull(IdPermission,0)<>0 THEN ''1'' ELSE ''0'' END) as P,(CASE WHEN isnull(Enable,0)=1 THEN ''1'' ELSE ''0'' END) as E,UserName
                from #Source left join #User on #Source.Uid=#User.Uid	
      ) src
      unpivot
      (
        value
        for col in (P,E)
      ) unpiv
     ) s
     pivot 
     (
       max(value)
       for col in (' + @cols + ')
     ) p  '
     
----------in @query first select data from #source table and #user table and then unpivot these data and get value for idpermission and enable  in  col column thent piot this data for col
execute(@query)
end
Go

---for execution of procedure 
exec #getpivot
Go

---for Drop Temp procedure 
DROP PROC #getpivot
GO
