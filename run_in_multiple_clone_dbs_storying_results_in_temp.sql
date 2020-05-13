/* Below script can be used For cases where we have multiple clones of the same database
, working for different instances (not replication or mirroring) and we want to run the same script to each one of 
the different databases, storing the results to a temporary table. 
For example if we have 10 stores working with the same ERP application (10 different clones of the same ERP), 
and we want to search the total number of sales each store did during November of 2019 , we can run 
the below, and bring all the results at once.
*/

/*IMPORTANT
Windows Authentication is much more secure than SQL Server Authentication. 
You should use Windows Authentication whenever possible. 
OPENDATASOURCE should not be used with explicit passwords in the connection string.
In our example we assume that al the DBs are installed on the same LAN
*/

/*
OPENDATASOURCE can be used to access remote data from OLE DB data sources only 
when the DisallowAdhocAccess registry option is explicitly set to 0 for the specified provider,
 and the Ad Hoc Distributed Queries advanced configuration option is enabled. 
 When these options are not set, the default behavior does not allow for ad hoc access.
 */



DECLARE @database_instance NVARCHAR(5);
DECLARE @sql NVARCHAR(MAX);
DECLARE @serv NVARCHAR(5);
DECLARE @C2 INTEGER;

IF object_id('tempdb..#results') is not null
BEGIN
   DROP TABLE #results
END    


create table #results(id int identity (1,1),  number_of_sales int,revenue_of_sales money, database_instance nvarchar(20)   )



IF object_id('tempdb..#servercons') is not null
BEGIN
   DROP TABLE #servercons
END    


/*Below ipd represents the different IP address of each one of the 10 different database instances.
In this example we assume that all the database instances are of the below form:
10.10.14.37/X1 , 10.10.14.53/X2 ......   10.10.14.51/X10
The database instance represents the code of each store */

create table #servercons(id int identity (1,1), database_instance  nvarchar(5),ipd varchar(5))
insert into #servercons(database_instance ,ipd ) values
('X1','37'),
('X2','53'),
('X3','59'),
('X4','59'),
('X5','59'),
('X6','44'),
('X7','81'),
('X8','51'),
('X9','64'),
('X10','51')


--SELECT * FROM #servercons

SET @C2 = 1

WHILE @C2 <= (select max(id) from #servercons ) 
BEGIN

SET @database_instance = (select database_instance from #servercons where id = @C2)
SET @serv = (select ipd from #servercons where id = @C2)


print 'processing database_instance: ' +@database_instance



/** Replace server ip last two digits with @serv.
Ensure  you have the correct quotes in the connection strings and table definitions when using the the above parameters
**/

SET @sql = N'
  select  count(o1.orderID) , sum(o2.total_price)
  from OPENDATASOURCE(''SQLOLEDB'',''Data Source=10.10.14.'+@Serv+'\'+@database_instance+';user id=DB_USER_'+@database_instance+'_CH;password=Password4DB'').[My_'+@database_instance+'_sales].[dbo].[order_main] AS o1
  left join
  OPENDATASOURCE(''SQLOLEDB'',''Data Source=10.10.14.'+@Serv+'\'+@database_instance+';user id=DB_USER_'+@database_instance+'_CH;password=Password4DB'').[My_'+@database_instance+'_sales].[dbo].[order_price] AS o2
  on o1.orderID = o2.orderID 
  WHERE  o1.orderdate >= ''2019-11-01''  and o1.orderdate <= ''2019-11-30''

  '		 
	 	 
  	 
  
insert into #results( number_of_sales ,revenue_of_sales,  database_instance    )
  
EXECUTE sp_executesql @sql;
/*below we insert on the results temporary table the number of the store*/
update #results  set database_instance = @database_instance where database_instance is null
print 'Done!'
SET @C2 = @C2+1
END;
DROP TABLE #servercons;
select * from #results
