-----------------------------------------------------
-----------------------SCRIPTS-----------------------
-----------------------------------------------------
--ex.1 book page.455
use AP
declare @total money
select @total = sum(invoicetotal-paymenttotal) from invoices
if @total >=10000
begin
	select substring(vendorname,1,30) as name, substring(invoicenumber,1,20) as invoiceNumber, invoiceduedate,(invoicetotal-paymenttotal)as balance
	from vendors v join invoices i on i.vendorid=v.vendorid
	where (invoicetotal-paymenttotal) > 0
	order by invoiceduedate asc
end
else print 'Balance due is less than $10,000.00.'

---------------------------------------------------------

