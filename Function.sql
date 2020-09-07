------------------------------------------------
-------------------FUNCTIONS--------------------
------------------------------------------------
--Notes: that use can use the MIN function in a query to find the earliest value.
	--You can use the MAX function in a query to find the latest value.
	--You must put DBO in front of a function name to call it.
	--You must ensure that your function only returns one value or it will give an error.
	--It is easier to debug a function if you test the SQL inside it by itself, before using it.

create function getGrade(@grade numeric(5,2))
returns varchar(1)
as
	begin
		declare @letter varchar(1)
		if @grade=90 or @grade>90
			set @letter='A'
		else if @grade=80 or @grade>80
			set @letter='B'
		else if @grade=70 or @grade>70
			set @letter='C'
		else if @grade=60 or @grade>60
			set @letter='D'
		else 
			set @letter='F'
		return @letter
	end

select dbo.getGrade(72)

------------------------------------------------------------
alter function TotalTax(@amount numeric(10,2))
returns numeric(10,2)
as
	begin 
		declare @total numeric(10,2)
		declare @provtax numeric(10,2)
		declare @fedtax numeric(10,2)
		if @amount<100
			set @total=@amount*0.07
		else
			begin
			--still have a problem with the calculation
				set @provtax=@amount*0.08
				set @fedtax=(@provtax+@amount)*0.07
				set @total=@fedtax+@provtax
			end
		return @total 
	end

select dbo.TotalTax(200)

---------------------------------------------------------
create function Total(@amount numeric(10,2))
returns numeric(10,2)
as
	begin
		declare @total numeric(10,2)
		if @amount<=1500
			set @total=1500
		else if @amount<=6500
			set @total=@amount-((@amount-1500)*0.2)
		else 
			set @total=@amount-((@amount-6500)*0.25)
		return @total
	end
select dbo.Total(6501)

--------------------------------------------------------
--Create a scalar-valued function named fnUnpaidInvoiceID that returns the InvoiceID 
--of the earliest invoice with an unpaid balance. 

alter function fnUnpaidInvoiceID()
returns int
as
begin
	
	return (select invoiceID from invoices where invoicedate=(
				select min(invoicedate) from invoices 
				where invoicetotal-credittotal-paymenttotal>0))
	 
end

SELECT VendorName, InvoiceNumber, InvoiceDueDate, InvoiceTotal - CreditTotal - PaymentTotal AS Balance 
FROM Vendors JOIN Invoices ON Vendors.VendorID = Invoices.VendorID 
WHERE InvoiceID = dbo.fnUnpaidInvoiceID();

--------------------------------------------------------------------------------------------------------
-- create function. input: state & size. output: total for (inv_price * ol-quantity)

select inv_price,ol_quantity as total, i.inv_size,customer_province
from inventory i join order_line ol on ol.inv_id=i.inv_id
				 join orders o on ol.o_id=o.o_id
				 join ar_customers c on c.customer#=o.c_id
where i.inv_size='xl' and c.customer_province='bc'

--turn to function
create function state_size(@size varchar(2), @state varchar(2))
returns money
as
begin
	declare @total money
	select @total = sum(inv_price*ol_quantity)
					from inventory i join order_line ol on ol.inv_id=i.inv_id
									 join orders o on ol.o_id=o.o_id
									 join ar_customers c on c.customer#=o.c_id
					where i.inv_size=@size and c.customer_province=@state
	return @total
end

select dbo.state_size('xl','bc')

------------------------------------------------------------------------------
