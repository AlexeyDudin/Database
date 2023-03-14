DROP TABLE [Lab2_1].[dbo].[temporary]
DROP TABLE [Lab2_1].[dbo].[stop_on_the_road]
DROP TABLE [Lab2_1].[dbo].[road]
DROP TABLE [Lab2_1].[dbo].[placement_along_the_road]
DROP TABLE [Lab2_1].[dbo].[locality_name]
GO
CREATE TABLE [Lab2_1].[dbo].[temporary]
(
	[id] INT NOT NULL PRIMARY KEY IDENTITY, 
    [road_name] nvarchar(50) NOT NULL, 
    [length] FLOAT NOT NULL, 
    [bus_stop_name] nvarchar(50) NOT NULL, 
    [bus_position] nvarchar(10) NOT NULL, 
    [is_have_pavilion] nvarchar(10) NOT NULL
)
GO

-- truncate the table first
TRUNCATE TABLE [Lab2_1].[dbo].[temporary];
GO

-- import the file
BULK INSERT [Lab2_1].[dbo].[temporary]
FROM 'D:\station.csv'
WITH
(
		CODEPAGE = '1251',
        FORMAT='CSV',
		FIELDTERMINATOR = ';',
		ROWTERMINATOR='\n',
        FIRSTROW=2,
		TABLOCK
)
GO

CREATE TABLE [Lab2_1].[dbo].[placement_along_the_road]
(
	[id] INT NOT NULL PRIMARY KEY IDENTITY, 
	[placement_along_the_road] nvarchar(50) NOT NULL
)

CREATE TABLE [Lab2_1].[dbo].[locality_name]
(
	[id] INT NOT NULL PRIMARY KEY IDENTITY, 
	[locality_name] NVARCHAR(50) NOT NULL UNIQUE
)
GO

CREATE TABLE [Lab2_1].[dbo].[road]
(
	[id] INT NOT NULL PRIMARY KEY IDENTITY, 
	[start_point_id] INT NOT NULL,
	[end_point_id] INT NOT NULL,
	CONSTRAINT [FK_road_sp_to_locality_name] FOREIGN KEY ([start_point_id]) REFERENCES [Lab2_1].[dbo].[locality_name]([id]),
	CONSTRAINT [FK_road_ep_to_locality_name] FOREIGN KEY ([end_point_id]) REFERENCES [Lab2_1].[dbo].[locality_name]([id])
)
GO

CREATE TABLE [Lab2_1].[dbo].[stop_on_the_road]
(
	[id] INT NOT NULL PRIMARY KEY IDENTITY,
	[road_id] INT NOT NULL,
	[is_have_pavilion] nvarchar(50) NOT NULL,
	[placement_along_the_road_id] INT NOT NULL,
	[range_from_start] FLOAT NOT NULL,
	[bus_stop_name] NVARCHAR(50) NOT NULL,
	CONSTRAINT [FK_stop_ont_the_road_to_road] FOREIGN KEY ([road_id]) REFERENCES [Lab2_1].[dbo].[road]([id]),
	CONSTRAINT [FK_stop_ont_the_road_to_placement_along_the_road] FOREIGN KEY ([placement_along_the_road_id]) REFERENCES [Lab2_1].[dbo].[placement_along_the_road]([id]),
)
GO

INSERT INTO [Lab2_1].[dbo].[placement_along_the_road](placement_along_the_road)
SELECT bus_position 
FROM [dbo].[temporary]
GROUP BY bus_position
GO

INSERT INTO [Lab2_1].[dbo].[locality_name]([locality_name])
SELECT TRIM(value) AS trimmed_locality_name
FROM [Lab2_1].[dbo].[temporary]
CROSS APPLY STRING_SPLIT(road_name, '-')
GROUP BY TRIM(value)
GO

INSERT INTO [LAB2_1].[dbo].[road]([start_point_id], [end_point_id])
SELECT DISTINCT lnm_sp.id, lnm_fp.id
FROM [Lab2_1].[dbo].[temporary] AS sd
    INNER JOIN [Lab2_1].[dbo].[locality_name] AS lnm_sp ON lnm_sp.locality_name = TRIM(SUBSTRING(sd.road_name, 0, CHARINDEX('-', sd.road_name)))
    INNER JOIN [Lab2_1].[dbo].[locality_name] AS lnm_fp ON lnm_fp.locality_name = TRIM(SUBSTRING(sd.road_name, CHARINDEX('-', sd.road_name) + 1, LEN(sd.road_name)));
GO

INSERT INTO [Lab2_1].[dbo].[stop_on_the_road](is_have_pavilion, bus_stop_name, range_from_start, placement_along_the_road_id, road_id)
SELECT DISTINCT 
		CASE WHEN sd.is_have_pavilion IS NULL THEN 'Не указано' ELSE sd.is_have_pavilion END, 
		CASE WHEN sd.bus_stop_name IS NULL THEN 'Не указано' ELSE sd.bus_stop_name END, 
		sd.length, 
		pl_r.id, 
		r.id
FROM [Lab2_1].[dbo].[temporary] AS sd
	INNER JOIN [Lab2_1].[dbo].[placement_along_the_road] AS pl_r ON sd.bus_position = pl_r.placement_along_the_road
	INNER JOIN [Lab2_1].[dbo].[locality_name] AS lnm_sp ON lnm_sp.locality_name = TRIM(SUBSTRING(sd.road_name, 0, CHARINDEX('-', sd.road_name))) 
    INNER JOIN [Lab2_1].[dbo].[locality_name] AS lnm_fp ON lnm_fp.locality_name = TRIM(SUBSTRING(sd.road_name, CHARINDEX('-', sd.road_name) + 1, LEN(sd.road_name)))
	INNER JOIN [Lab2_1].[dbo].[road] AS r ON r.start_point_id = lnm_sp.id AND r.end_point_id = lnm_fp.id;
GO

SELECT road_name AS current_road_name,
	   length AS current_lenght,
	   bus_stop_name AS current_bus_stop_name,
	   bus_position AS current_bus_position,
	   is_have_pavilion AS current_is_have_pavilion
FROM [Lab2_1].[dbo].[temporary]
GO