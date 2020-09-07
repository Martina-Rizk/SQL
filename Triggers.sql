------------------------------------------------
--------------------TRIGGERS--------------------
------------------------------------------------
select DATENAME(weekday,getdate())

select * from category

insert into category values(6,'stuff2')

select SUSER_SNAME() -- get the system user name

select @@SERVERNAME --in industry it gives the server not your pc

select serverproperty('machinename') -- this give the pc name, this is the best

------------------------------------------------------------
alter trigger stop_friday_changes
on category  --each trigger can watch one table
after update, insert, delete
as
begin
	if DATENAME(weekday,getdate())='friday'
	begin
		rollback   --undo user changes
		raiserror('>>>>>>no changes allowed today<<<<<<<',16,1)
	end
end

-------------------------------------------------------------
--Don't change the inventory-price more than 10%
alter trigger watch_inv_prices
on inventory
after update
as
begin
	declare @oldprice numeric(8,2)
	declare @newprice numeric(8,2)
	select @oldprice=inv_price from deleted --memory looks like a table
	select @newprice=inv_price from inserted
	if @newprice > 1.1 * @oldprice
	begin
		rollback
		raiserror('>>>Cannot change price more than 10 percent<<<',16,1)
	end
end

select * from inventory where inv_id=1
update inventory set inv_price=300 where inv_id=1

--------------------------------------------------------------------
--detecting the type of command that wake up the trigger
create trigger show_commands
on color
after insert,update,delete
as
begin
	declare @countdelete numeric(3)
	declare @countinsert numeric(3)
	select @countdelete=count(*) from deleted
	select @countinsert=count(*) from inserted
	if @countdelete>0 and @countinsert>0--oracle if updating
		print 'you are doing an update'
	else if @countdelete=0 and @countinsert>0--if inserting
			print 'you are doing an insert'
		 else if @countdelete>0 and @countinsert=0--if deleting
				print 'you are doing a delete'
end

update color set color='navy' where color='Navy'
select * from color

------------------------------------------------------------------

create table logfile
(loguser varchar(30),logdate datetime,loglocation varchar(30),
    logdescription varchar(500))

--description could be
--payroll changed  key=123456789  old salary=5000 new salary=7000
--inventory changed key=123 old price=120 new price=150
select * from logfile where loguser='bob'
select * from logfile where logdate=getdate()-1
select * from logfile where logdescription like '%payroll%'

create trigger monitor_inv
on inventory
after update
as
begin
	declare @oldprice numeric(8,2)
	declare @newprice numeric(8,2)
	declare @oldkey numeric(6)
	select @oldprice = inv_price, @oldkey = inv_id from deleted
	select @newprice = inv_price from inserted
	insert into logfile values(suser_sname(),getdate(),@@servername,
		 'inventory changed'+convert(varchar,@oldkey)+
			  ' old price='+convert(varchar,@oldprice)+
			  ' new price='+convert(varchar,@newprice))
end

update inventory set inv_price=265 where inv_id=1

select * from logfile

-----------------------------------------------------------------------

---------Examples DB------
select * from departments
select * from employees

create view department_employees as
select deptname, firstname, lastname, managerid
from departments d join employees e on d.deptno=e.deptno

select * from department_employees

insert into department_employees values('payroll', ' bob', 'smith', 2)
--------------xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx---------------
-- cannot insert into a view
create trigger watch_view
on department_employees
instead of insert
as
begin
	declare @nextkey numeric(6)
	select @nextkey = max(employeeid)+1 from employees
	declare @dept numeric(6)
	declare @name varchar(50)
	declare @mgrid numeric(6)
	declare @fname varchar(50)
	declare @lname varchar(50)
	select @name = deptname, @mgrid = managerid, 
		   @fname = firstname, @lname = lastname from inserted
	select @dept = deptno from departments where deptname = @name
	insert into employees values (@nextkey, @lname, @fname, @dept, @mgrid)
end

------------------------------------------------------------------------
create table invoices
(inv# numeric(6) primary key,
amount numeric(10,2),
prov char(2))

create table provtotals
(prov char(2) primary key,
total numeric(10,2))

create trigger warehouse_trigger
on invoices
after insert,update,delete
as
begin
	declare @counter numeric(6)
	declare @ins numeric(6)
	declare @del numeric(6)
	select @ins=count(*) from inserted--after changes(new)
	select @del=count(*) from deleted--before changes(old)
	declare @oldprov char(2)
	declare @newprov char(2)
	declare @oldamount numeric(10,2)
	declare @newamount numeric(10,2)
	if @ins>0 and @del>0 --update
	  begin
		select @oldprov=prov, @oldamount=amount from deleted
		select @newprov=prov, @newamount=amount from inserted
		if @newprov = @oldprov
			update provtotals set total = total + (@newamount - @oldamount)
					  where prov = @newprov
		else --remove amount from old province and put it in the new province
		  begin
			update provtotals set total = total - @oldamount where prov = @oldprov
			--need to know if new province exists in warehouse
			--if not there (count=0) then do an insert, else do an update total
			select @counter = count(*) from provtotals where prov = @newprov
			if @counter = 0
				insert into provtotals values(@newprov,@newamount)
			else
				update provtotals set total = total + @newamount
							  where prov = @newprov
		  end
	  end
	else if @ins = 0 and @del > 0     --delete
		  begin
			select @oldprov=prov,@oldamount=amount from deleted
			update provtotals set total=total - @oldamount where prov=@oldprov
		  end
	else if @ins > 0 and @del = 0 --insert
		   begin
			 select @newprov=prov,@newamount=amount from inserted
			 select @counter=count(*) from provtotals where prov=@newprov
			 if @counter=0 --use insert
				 insert into provtotals values(@newprov,@newamount)
			 else --use update to increase totals
				 update provtotals set total=total + @newamount
							  where prov=@newprov
		   end
end

insert into invoices values(1,100,'ab')
insert into invoices values(2,50,'ab')
insert into invoices values(3,200,'bc')
delete from invoices where inv#=2
insert into invoices values(4,75,'bc')
update invoices set amount = 175 where inv#=3
update invoices set prov = 'ab' where inv#=4

select * from provtotals

-----------------------------------------------------------------------
--------AP Database----------------
create table shippingtables
(vendorname varchar(50),
vendoraddress1 varchar(50),
vendoraddress2 varchar(50),
vendorcity varchar(50),
vendorstate char(2),
vendorzipcode varchar(20))

alter trigger watchinv
on invoices
after update
as
begin
	if update(paymenttotal)
	begin
		declare @name varchar(50)
		declare @add1 varchar(50)
		declare @add2 varchar(50)
		declare @city varchar(50)
		declare @state varchar(50)
		declare @zip varchar(50)
		declare @id int
		select @id=vendorid from inserted
		select @name=vendorname, @add1=vendoraddress1, @add2=vendoraddress2, @city=vendorcity,
			   @state=vendorstate, @zip=vendorzipcode from vendors where vendorid=@id
		insert into shippingtables values (@name, @add1, @add2, @city, @state, @zip)
	end
end

update invoices
set paymenttotal=67.92, paymentdate='2020-02-23'
where invoiceid=100

select * from shippingtables

-------------------------------------------------------------------------
