
/*
Generate 1M rows of equipment daily transactional data for 4 years start from January 1, 2015 to 
May 31, 2019 for testing S&M Software based on the business rules and set of the dataset defined 
above*/

declare @startdate date = '2015-01-01' 
declare @enddate date = '2019-05-31' 
declare @currentrecord int= 1
declare @totalrecord int =1000000
declare @customerid int
declare @equipmentid int
declare @quantity float
declare @grossamount decimal(12,2)
declare @Discountamount decimal (12,2)
declare @floatrateamount decimal (12,2)
declare @floatexceededamount decimal (12,2)
declare @postalvariationamount decimal (12,2)
declare @noofDays int =datediff(day,@startdate,@enddate)
declare @randomdays int 
declare @transdate date


		
	While @currentrecord<=@totalrecord
		Begin
	
		select @randomdays= CAST(rand()*@noofdays as int)+1
		select @customerid=cast(rand() *(select max(customerid) from dbo.customer) as int)+1
		select @equipmentid=cast(rand() *(select max(equipmentid) from dbo.equipment) as int)+1
		select @quantity = cast(rand()*300 as int)+1              -- Max Quantity used is 300
		select @transdate= DATEADD(day,@randomdays,@startdate)
		
		select @grossamount=  @quantity *
						(select unitprice
						from dbo.equipment
						where equipmentid= @equipmentid)

	   select @Discountamount =@grossamount *
						(select discountpercent
						from dbo.equipment
						where equipmentid= @equipmentid)
		
		select @floatrateamount = case 
					when @quantity >=100 and @quantity <=150 then 
						@quantity * 				
						(select f.floatrate
						from Equipment e
						join Float_Category f
						on e.FloatCategoryID=f.FloatCategoryID
						where e.EquipmentID = @equipmentid )
						else 0
						end 

		select @floatexceededamount = case 
						when @quantity >150 and @quantity <=300 then 
						@quantity * 
							(
							select f.floatrate
							from Equipment e
							join Float_Category f
							on e.FloatCategoryID=f.FloatCategoryID
							where e.EquipmentID = @equipmentid )
							else 0
							end

		select @postalvariationamount = 
						(select
						        case 
							when  postalcode >= 7000 and postalcode <= 50000 then  (0.002*(@quantity))
							when postalcode >= 50001 and postalcode <=70000 then (0.05 * (@quantity ) )
							when  postalcode >= 70001 and postalcode <=90000 then (0.062 * (@quantity))
							when  postalcode >=90001 then (0.0078 * (@quantity ))
							end  as postalcode
							from dbo.customer
							where customerid = @customerid)

		Insert into Equipment_Transaction(TransDate,Customerid,Equipmentid,quantity,GrossAmount,DiscountAmount,FloatRateAmount,FloatExceededAmount,PostalVariationAmount)
		select @transdate,@customerid,@equipmentid,@quantity,@grossamount,@Discountamount,@floatrateamount,@floatexceededamount,@postalvariationamount
		select @currentrecord=@currentrecord + 1
		 End
 
  
  select * from Equipment_Transaction
  where year(transdate) =2019

  /*
  Create a dynamic function that produce top N customer purchased Amount by year
E.g. Top 10 customers with highest purchased in 2019 
Select * from TopCustomer (2019, 10)
*/

Create function Topcustomer(@transdate int ,@rownumber int)
Returns Table
AS
Return
(
select top (@rownumber)et.transid, et.transdate,et.quantity, et.GrossAmount,c.CustomerName,e.EquipmentName from Equipment_Transaction et
join Customer c on c.CustomerID=et.CustomerID
join Equipment e on e.EquipmentID=et.EquipmentID
where year(transdate) =@transdate 
order by GrossAmount desc		
)

select * from Topcustomer(2019,10)




