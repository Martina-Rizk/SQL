----------------------------------------------
-------------------PROCEDURE------------------
----------------------------------------------
create procedure countup(@max numeric(3))
as
	begin
		declare @x numeric(3)=1
		while @x<=@max
			begin
				print @x
				set @x=@x+1
			end
	end

exec countup 3 

-----------------------------------------------------------------------------------------------------------------------------
-- calculate the GIC bank account
create procedure GIC(@amount numeric(10,2), @rate numeric(3,1), @year numeric(2))
as
begin
	declare @start numeric(2) = 1
	while @start <= @year
	begin
		set @amount = @amount * (1 + ( @rate/100))
		print 'year'+convert(varchar,@start)+':'+char(9)+'$'+convert(varchar,@amount)
		set @start = @start +1
	end
end

exec GIC 2000,10,3

---------------------------------------------------------------------------------------------------------------
--Laon payment
create procedure loan(@amount numeric(10,2), @rate numeric(3,1), @year numeric(2), @payment numeric(10,2))
as
begin
	declare @month numeric(2) = 1
	declare @begin numeric(10,2) = @amount
	declare @interest numeric(10,2)
	declare @end numeric(10,2)
	declare @i numeric(2) = 1
	print 'Month'+char(9)+'Begin Value'+char(9)+'Interest'+char(9)+'Payment'+char(9)+char(9)+'End Value'
	while @i <= @year
	begin
		while @month <=12
		begin
			set @interest = @begin * ((@rate/100)/12)
			set @end = (@begin + @interest) - @payment
			print convert(varchar, @month)+char(9)+char(9)+convert(varchar,@begin)+char(9)+char(9)+
				  convert(varchar,@interest)+char(9)+char(9)+convert(varchar,@payment)+char(9)+char(9)+convert(varchar,@end)
			set @month = @month +1
			set @begin = @end
		end
		set @i = @i + 1
	end
end
exec loan 10000,12,1,888.49

--------------------------------------------------------------------------------------------------------------------------------------
-- calling a procedure inside a procdure
alter procedure gettaxes(@salary numeric(10,2), @eitax numeric(10,2) out, @cpptax numeric(10,2) out, @atax numeric(10,2) out)
as
begin
	set @eitax = @salary*0.02
	set @cpptax = @salary*0.03
	set @atax = @salary*0.10
end 

alter procedure showtaxes(@amount numeric(10,2))
as
begin
	declare @ei numeric(10,2)=0
	declare @cpp numeric(10,2)=0
	declare @ab numeric(10,2)=0
	exec gettaxes @amount, @ei out, @cpp out, @ab out
	print 'ei tax = '+convert(varchar,@ei)
	print 'cpp tax = '+convert(varchar,@cpp)
	print 'AB tax = '+convert(varchar,@ab)
end

exec showtaxes 1000

------------------------------------------------------------
-----------------------SQL PROCEDURE-----------------------
-----------------------------------------------------------
create procedure fancy
as
begin
	declare x cursor for select c_first,c_last,c_address,c_city,c_state,c_zip from customer
	declare @first varchar(30)
	declare @last varchar(30)
	declare @address varchar(30)
	declare @city varchar(30)
	declare @state varchar(2)
	declare @zip varchar(10)
	open x
	fetch next from x into @first,@last,@address,@city,@state,@zip --starts reading
	while @@FETCH_STATUS=0 --means cursor found some data
		begin
			print @first+' '+@last
			print @address
			print @city+', '+@state+' '+@zip
			print ' '
			fetch next from x into @first,@last,@address,@city,@state,@zip --keeps reads going
		end
	close x
	deallocate x --removes cursor from server memory
end

exec fancy

----------------------------------------------------------------------------------------------------
select ol.o_id, sum(i.inv_price*ol.ol_quantity) as amount
from order_line ol join inventory i on i.inv_id=ol.inv_id
				   join orders o on o.o_id=ol.o_id
where c_id=4
group by ol.o_id

--turn to procedure
alter procedure fancy2
as
begin
declare @custotal numeric(10,2)=0
declare @fintotal numeric(10,2)=0

--*****************************tip when there is customer with no orders****************
declare x cursor for select c_id,c_first,c_last,c_address,c_city,c_state,c_zip from customer
					 where c_id in (select c_id from orders)

declare @id numeric(3)
declare @first varchar(30)
declare @last varchar(30)
declare @address varchar(30)
declare @city varchar(30)
declare @state varchar(2)
declare @zip varchar(10)
open x
fetch next from x into @id,@first,@last,@address,@city,@state,@zip --starts reading
while @@FETCH_STATUS=0 --means cursor found some data
	begin
		print @first+' '+@last
		print @address
		print @city+', '+@state+' '+@zip
		print char(9)+'Order    Amount'
		declare y cursor for select o.o_id,sum(inv_price*ol_quantity) as amount
							 from orders o inner join order_line o2 on o.o_id=o2.o_id
							               inner join inventory i on i.inv_id=o2.inv_id
							 where c_id=@id
							 group by o.o_id

		declare @orderid numeric(3)
		declare @amt numeric(10,2)
		open y
		fetch next from y into @orderid,@amt
		while @@FETCH_STATUS=0
			begin
				print char(9)+convert(varchar,@orderid)+char(9)+char(9)+
				                  convert(varchar,@amt)
				set @custotal=@custotal+@amt
				set @fintotal=@fintotal+@amt
				fetch next from y into @orderid,@amt
			end
		close y
		deallocate y
		print char(9)+char(9)+char(9)+'Total '+convert(varchar,@custotal)
		set @custotal=0
		print ' '
		fetch next from x into @id,@first,@last,@address,@city,@state,@zip --keeps reads going
	end
close x
deallocate x --removes cursor from server memory
print 'Final '+convert(varchar,@fintotal)
end

exec fancy2

------------------------------------------------------------------------------------------------------
select cat_desc,inv_size
from item i join category c on c.cat_id=i.cat_id
		    join inventory inv on inv.item_id=i.item_id
order by 1,2



alter procedure categories
as
begin
declare x cursor for select cat_id, cat_desc from category order by cat_desc
declare @id numeric(3)
declare @desc varchar(30)
open x
fetch next from x into @id,@desc
while @@FETCH_STATUS=0
	begin
		print @desc
		declare y cursor for select distinct inv_size 
							 from item i inner join inventory i2 on i.item_id=i2.item_id 
							 where cat_id=@id
		declare @size varchar(10)
		declare @line varchar(80)='   '
		open y
		fetch next from y into @size
		while @@FETCH_STATUS=0
			begin
				set @line=@line+@size+' '
				fetch next from y into @size
			end
			print @line
		close y
		deallocate y
		fetch next from x into @id,@desc
	end
close x
deallocate x
end


exec categories

--------------------------------------------------------
--ex.1 book page.507 
--AP database
select vendorname, invoicenumber, invoicetotal-credittotal-paymenttotal as balance
from vendors v join invoices i on i.vendorid=v.vendorid 
where vendorname like 'm%' and invoicetotal-credittotal-paymenttotal=0

alter procedure spBalanceRange(@vendorvar varchar(50)=null, @minbalance money=null, @maxbalance money=null)
as
begin
	if @minbalance is null
		select @minbalance = min(invoicetotal) from invoices
	if @maxbalance is null
		select @maxbalance = max(invoicetotal) from invoices
	if @vendorvar is null
		set @vendorvar = '%'

	declare x cursor for select vendorname, invoicenumber, invoicetotal-credittotal-paymenttotal as balance
						 from vendors v join invoices i on i.vendorid=v.vendorid 
						 where vendorname like @vendorvar 
							   and invoicetotal-credittotal-paymenttotal > @minbalance
							   and invoicetotal-credittotal-paymenttotal < @maxbalance
	declare @vendorname varchar(50)
	declare @invoicenumber varchar(50)
	declare @balance money
	open x
	fetch next from x into @vendorname, @invoicenumber, @balance
	while @@fetch_status=0
	begin
		print @vendorname+char(9)+char(9)+
			  convert(varchar, @invoicenumber)+char(9)+char(9)+
			  convert(varchar, @balance)
		fetch next from x into @vendorname, @invoicenumber, @balance
	end
	close x
	deallocate x
end

exec spBalanceRange 'm%',0

---------------------------------------------------------------------------
-- show item description 
--		size	color	total(inv_price*inv_qoh)
--		----	-----	-----
--				total   -----
alter procedure items_desc
as 
begin
	declare x cursor for select  item_id, item_desc from item
	declare @id numeric(8)
	declare @desc varchar(30)
	open x
	fetch next from x into @id, @desc
	while @@FETCH_STATUS=0
	begin
		print @desc
		declare y cursor for select inv_price, inv_qoh, color, inv_size 
							 from inventory inv join item i on inv.item_id=i.item_id
							 where inv.item_id=@id
		declare @price numeric(6,2)
		declare @quantity numeric(4,0)
		declare @color varchar(20)
		declare @size varchar(10)
		declare @totalperitem numeric(10,2) = 0
		declare @total numeric(10,2) = 0
		print char(9)+'color'+char(9)+char(9)+'size'+char(9)+char(9)+'total'
		open y
		fetch next from y into @price, @quantity, @color, @size
		while @@fetch_status=0
		begin
			
			set @totalperitem = @price * @quantity
			set @total = @total + @totalperitem
			print char(9)+@color+char(9)+char(9)+@size+char(9)+char(9)+convert(varchar,@totalperitem)
			fetch next from y into @price, @quantity, @color, @size
		end
		close y
		deallocate y
		print char(9)+char(9)+'total'+char(9)+char(9)+convert(varchar,@total)
		fetch next from x into @id, @desc
	end
	close x 
	deallocate x
end

exec items_desc