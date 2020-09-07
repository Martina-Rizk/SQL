USE master
GO

/****** Object:  Database AP     ******/
IF DB_ID('TechnicianDB') IS NOT NULL
	DROP DATABASE TechnicianDB
GO

CREATE DATABASE TechnicianDB
GO 

USE [TechnicianDB]
GO

create table CustomerT
(cust_num      int primary key not null,
 cust_last     varchar(10),
 cust_first    varchar(10),
 cust_address  varchar(50),
 cust_city     varchar(50),
 cust_state    varchar(2),
 check (cust_state in ('AB','BC','CO','NC'))
)
GO

create table TechnicianT
(tech_num      int primary key not null,
 tech_last     varchar(10),
 tech_first    varchar(10),
 hire_date     datetime
)
GO

create table Service_CallT
(call_num      int primary key not null,
 cust_num      int foreign key references CustomerT(cust_num),
 Call_Date     datetime,
 tech_num      int foreign key references TechnicianT(tech_num)
)
GO

create table PartsT
(part_num       int primary key not null,
 part_desc      varchar(50),
 cost           numeric(10,2),
 price          numeric(10,2),
 qty_on_hand    int
)
GO

create table Service_Parts_DetailT
(call_num        int foreign key references Service_CallT(call_num),
 part_num        int foreign key references PartsT(part_num),
 qty             int
 primary key     (call_num, part_num)
)
GO


insert CustomerT (cust_num, cust_first, cust_last, cust_address,cust_city, cust_state)
values
(1, 'Jones', 'Albert', '43 Oak Drive', 'Charlotte', 'NC'),
(2, 'Mary', 'John', '678 8th street', 'Seattle', 'AB'),
(3, 'Sally', 'smith', '101 Main Street', 'Boston', 'BC')
GO 

insert TechnicianT (tech_num, tech_first, tech_last, hire_date)
values
(1, 'Robin', 'Gray', CAST(N'2014-04-08' AS Date)),
(2, 'Jack', 'Wilson', CAST(N'2019-10-08' AS Date)),
(3, 'Johnson', 'Cord', CAST(N'2016-09-06' AS Date))
GO 

insert Service_CallT(call_num, tech_num, cust_num, Call_Date)
values
(10, 3, 1, CAST(N'2020-08-08' AS Date)),
(20, 2, 1, CAST(N'2020-07-07' AS Date)),
(30, 3, 2, CAST(N'2020-08-08' AS Date))
GO

insert PartsT(part_num, part_desc,cost, price, qty_on_hand)
values
(501, 'Meter', 38.00, 125.00, 33),
(502, 'Cover', 1.30, 1.98, 220),
(503, 'Cable', 6.99, 7.99, 77)
GO

insert Service_Parts_DetailT (part_num, call_num, qty)
values
(502, 20, 1),
(503, 30, 2),
(503, 10, 1)
GO
