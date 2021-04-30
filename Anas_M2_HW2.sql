select * from ecohort_sql.masterdata_branch;
select * from ecohort_sql.masterdata_customer;
select * from ecohort_sql.masterdata_product;
select * from `ecohort_sql`.`transactional_sales_filtered`;
alter table `ecohort_sql`.`transactional_sales_filtered` add column new_date DATE;
set sql_safe_updates = 0;
select * from `ecohort_sql`.`transactional_sales_filtered`;

select substring(`Date`,2,1) from `ecohort_sql`.`transactional_sales_filtered`;

update `ecohort_sql`.`transactional_sales_filtered` set new_date = str_to_date(date, '%d-%m-%Y')
where substring(date,3,1) = '-';
update `ecohort_sql`.`transactional_sales_filtered` set new_date = str_to_date(date, '%d/%m/%Y')
where substring(date,2,1) = '/';
update `ecohort_sql`.`transactional_sales_filtered` set new_date = str_to_date(date, '%d/%m/%Y')
where substring(date,3,1) = '/';
update `ecohort_sql`.`transactional_sales_filtered` set new_date = str_to_date(date, '%Y/%m/%d')
where substring(date,4,1) = '-';

select * from `ecohort_sql`.`transactional_sales_filtered`;

-- 3. Select ` transactional_sales_filtered` table where date is greater than 10 and month is May.
select * from `ecohort_sql`.`transactional_sales_filtered` where day(new_date) > 10 and month(new_date) = 5;

-- 4. Select ` masterdata_salesman` with descending values of RVS.
-- Select ` transactional_sales_filtered` table with ascending order of
-- new_date and return only 10 records.

SELECT 
    *
FROM
    `ecohort_sql`.`masterdata_salesman`
ORDER BY RVS DESC;

select * from `ecohort_sql`.`transactional_sales_filtered` order by new_date asc limit 10;

-- 5. Get maximum, minimum, avg of sales and make sure sale value is not null.

select max(Sales), min(Sales), avg(Sales) from `ecohort_sql`.`transactional_sales_filtered` where Sales is not null;

-- 6. Select all the data from `transactional_sales_filtered ` for branches of Jeddah, Medinah &amp; Makkah.

select * from `ecohort_sql`.`transactional_sales_filtered`;
select Sales_Office from `ecohort_sql`.`masterdata_branch` where branch_name IN ('Jeddah','Medinah', 'Makkah');

SELECT 
    *
FROM
    `ecohort_sql`.`transactional_sales_filtered`
WHERE
    sales_office IN (SELECT 
            Sales_Office
        FROM
            `ecohort_sql`.`masterdata_branch`
        WHERE
            branch_name IN ('Jeddah' , 'Medinah', 'Makkah'));

-- 7. Select all the product names from `masterdata_product ` where name has no ‘FD’.

select * from  `ecohort_sql`.`masterdata_product` where Product not like '%FD%';

-- 8. Select all the product names from `masterdata_product ` where name has ‘FD’ or its BU number is less than 2.

select * from  `ecohort_sql`.`masterdata_product` where Product like '%FD%' or substr(BU,4,1) <2;

-- 9. Group by day and count transactions.

select day(new_date) , count(*) as Transactions from  `ecohort_sql`.`transactional_sales_filtered`group by 1;

-- 10. Group by day and count transactions where transactions are greater than 1000.

select day(new_date) , count(*) as Transactions from  `ecohort_sql`.`transactional_sales_filtered` group by 1 having Transactions > 1000;

-- 11. Calculate Avg_Sale or Rev_per_Trans of every day and also weighted average of the month of May only. (round your results to 2 decimal places)

select date(new_date) , round(avg(Sales),2) as `RPT/avg_sales` from  `ecohort_sql`.`transactional_sales_filtered` where month(new_date) = 5 group by 1 ;
select date(new_date) , round(avg(Sales),2) as `RPT/avg_sales`  from  `ecohort_sql`.`transactional_sales_filtered` where month(new_date) = 5 group by 1 with rollup;

-- 13. Creating a new Column name on_off_flag.

alter table `ecohort_sql`.`transactional_sales_filtered` add column on_off_flag bool;

select * from `ecohort_sql`.`transactional_sales_filtered`;

-- 14. Updating Column. Update on_off_flag by putting 1 for even days and 0 for odd days
Update `ecohort_sql`.`transactional_sales_filtered` set on_off_flag = 0 where day(new_date) % 2 = 0;
Update `ecohort_sql`.`transactional_sales_filtered` set on_off_flag = 1 where day(new_date) % 2 <> 0;

select * from  `ecohort_sql`.`transactional_sales_filtered`;

-- 15. Dropping Columns.

alter table `ecohort_sql`.`transactional_sales_filtered` drop column Date_sales;
alter table `ecohort_sql`.`transactional_sales_filtered` drop column Date;

-- 16. Create temporary tables for April and May separately.
Create database tempdb;

drop temporary table if exists tempdb.april;
create temporary TABLE tempdb.april (
	select * from `ecohort_sql`.`transactional_sales_filtered` where month(new_date) = 4
);

select * from tempdb.april;

drop temporary table if exists tempdb.may;
create temporary TABLE tempdb.may (
	select * from `ecohort_sql`.`transactional_sales_filtered` where month(new_date) = 5
);

SELECT 
    *
FROM
    tempdb.may;


-- 17. Compute the day-wise total unique transactions for April and May separately. Is there a particular trend?

select distinct day(new_date)as days, count( day(new_date)) as transactions from tempdb.april group by 1 order by days;
select distinct day(new_date)as days, count( day(new_date)) as transactions from tempdb.may group by 1 order by days;

-- 18. Join all the columns with ` transactional_sales_filtered ` so that all the names are present in that temporary table.

drop temporary table if exists tempdb.all_columns;
 
Create temporary table tempdb.all_columns (
	select tsf.*,mb.branch_Name, mc.Customer_Name, mp.Product, mp.BU, ms.RVS_Name, ms.RVS_Channel, ms.Channel_Name  from `ecohort_sql`.`transactional_sales_filtered` as tsf join `ecohort_sql`.`masterdata_branch` as mb on tsf.sales_office = mb.sales_office
    join `ecohort_sql`.`masterdata_customer` as mc on tsf.Customer = mc.Customer
    join `ecohort_sql`.`masterdata_product`as mp on tsf.Product_ID = mp.Product_Code
    join `ecohort_sql`.`masterdata_salesman` as ms on tsf.RVS = ms.RVS  
);

select * from tempdb.all_columns;

-- 19. Complute April and May Transactions per Product

select product,month(new_date) as mon,  count(product_ID) as product_count from tempdb.all_columns where month(new_date) in (4,5) group by 1,2 order by Product;

-- 20. Filter out salesman who make sales in either April or May, but not both. Check if they have a significant number of Sales (say ~10 or 15 Sales)

select * from tempdb.all_columns;

drop temporary table if exists tempdb.aprilonly;
Create temporary table tempdb.aprilonly
select * from tempdb.april where rvs not in (select distinct rvs from tempdb.may);

drop temporary table if exists tempdb.mayonly;
Create temporary table tempdb.mayonly
select * from tempdb.may where rvs not in (select distinct rvs from tempdb.april);

drop temporary table if exists tempdb.aprilormay;
Create temporary table tempdb.aprilormay
select * from tempdb.aprilonly union select * from tempdb.mayonly;

Select Distinct RVS, count(Distinct Invoice_ID) as Total_Transactions from tempdb.aprilormay 
group by RVS  Having Total_Transactions>15 order by Total_Transactions asc;

-- 21. Assignment: Using Case Statements and other functions make all these analysis.

select on_off_flag, count(1) from tempdb.all_columns where Branch_Name = 'Al Baha' group by 1;

select * from tempdb.all_columns;
select 
branch_name,
avg(Sales)
from tempdb.all_columns group by branch_name order by Branch_Name;

-- create temporary table tempdb.off_flag
-- (
-- select * from tempdb.all_columns where on_off_flag =0 
-- );

-- select * from tempdb.off_flag;
-- select avg(case when on_off_flag = 0 then (Sales) else 0 end) as off_rpt from tempdb.off_flag group by branch_name order by Branch_Name;
-- select avg(case when on_off_flag = 0 then (Sales) else null end) as off_rpt from tempdb.off_flag group by branch_name order by Branch_Name;
-- select branch_name,avg(Sales),count(*) as off_rpt from tempdb.off_flag group by branch_name order by Branch_Name;

-- select product,branch_name,count(product) from tempdb.all_columns group by 1,2 order by Branch_Name;
-- select product, branch_name,sum(case when product like '%FD%' then 1 else 0 end) ,count(product) from tempdb.all_columns group by 1 order by Branch_Name;
-- select product, branch_name,sum(case when product like '%FD%' then 1 else 0 end) ,count(product) from tempdb.all_columns group by 1,2 order by Branch_Name;
-- select product, branch_name,sum(case when product like '%FD%' then 1 else 0 end) ,count(product) from tempdb.all_columns group by 2 order by Branch_Name;
-- select product, branch_name,count(sales),sum(sales),sum(case when product like '%FD%' then sales else 0 end) ,count(product) from tempdb.all_columns group by 1,2 order by Branch_Name;

-- select product, branch_name,count(sales),sum(sales),sum(case when product like '%FD%' then sales else 0 end) ,count(product) from tempdb.all_columns group by 2 order by Branch_Name;
-- select product, branch_name,count(sales),sum(sales),sum(case when product like '%FD%' then sales else 0 end)/sum(sales) ,count(product) from tempdb.all_columns group by 2 order by Branch_Name;

Select Branch_name ,
sum(case when sales<>0 then 1 else 0 end) T_Count,
sum(case when on_off_flag = 1 then 1 else 0 end) T_on_Count,
sum(case when on_off_flag = 0 then 1 else 0 end) T_off_Count,
sum(case when on_off_flag = 1 then sales else 0 end ) as on_sales,
count(DISTINCT RVS) T_Salesman,
count(DISTINCT Customer) T_Customer,
count(DISTINCT Product_ID) T_Product,
round(sum(case when sales>4000 then 1 else 0 end)*100/count(distinct Invoice_ID),2) as High_Potential_Cust,
round(sum(case when Sales >1000 and Sales<=4000 then 1 else 0 end)*100/count(distinct Invoice_ID),2) as Medium_Potential_Cust,
round(sum(case when Sales <=1000  then 1 else 0 end)*100/count(distinct Invoice_ID),2) as Low_Potential_Cust,
round(avg(Sales),2) as RPT,
round(avg(case when on_off_flag = 1 then (Sales) else null end),2) on_RPT,
round(avg(case when on_off_flag = 0 then (Sales) else null end),2) as off_rpt,
round(sum(case when product like '%FD%' then sales else 0 end)*100/sum(sales),2) as food_sale_percentage,
round(sum(case when  Product not like '%FD%' then Sales else 0 end)*100/sum(Sales),2) as non_food_sale_percentage,
round(avg(case when product like '%FD%' then sales else null end),2) as food_RPT,
round(avg(case when  Product not like '%FD%' then Sales else null end),2) as non_food_RPT
from tempdb.all_columns group by branch_name order by Branch_Name;

-- Bonus Assignment Question: Calculate Incrementals Value which your AI Model provided and Gain.
-- Incrementals = (On_RPT-Off_RPT)*T_On_Count

-- Gain=( Incrementals*100)/(On_Sales-  Incrementals)

-- select *, (on_RPT-off_RPT)*T_on_Count as Incrementals
-- from (Select Branch_name ,
-- sum(case when sales<>0 then 1 else 0 end) T_Count,
-- sum(case when on_off_flag = 1 then 1 else 0 end) T_on_Count,
-- sum(case when on_off_flag = 0 then 1 else 0 end) T_off_Count,
-- sum(case when on_off_flag = 1 then sales else 0 end ) as on_sales,
-- count(DISTINCT RVS) T_Salesman,
-- count(DISTINCT Customer) T_Customer,
-- count(DISTINCT Product_ID) T_Product,
-- round(sum(case when sales>4000 then 1 else 0 end)*100/count(distinct Invoice_ID),2) as High_Potential_Cust,
-- round(sum(case when Sales >1000 and Sales<=4000 then 1 else 0 end)*100/count(distinct Invoice_ID),2) as Medium_Potential_Cust,
-- round(sum(case when Sales <=1000  then 1 else 0 end)*100/count(distinct Invoice_ID),2) as Low_Potential_Cust,
-- round(avg(Sales),2) as RPT,
-- round(avg(case when on_off_flag = 1 then (Sales) else null end),2) on_RPT,
-- round(avg(case when on_off_flag = 0 then (Sales) else null end),2) as off_rpt,
-- round(sum(case when product like '%FD%' then sales else 0 end)*100/sum(sales),2) as food_sale_percentage,
-- round(sum(case when  Product not like '%FD%' then Sales else 0 end)*100/sum(Sales),2) as non_food_sale_percentage,
-- round(avg(case when product like '%FD%' then sales else null end),2) as food_RPT,
-- round(avg(case when  Product not like '%FD%' then Sales else null end),2) as non_food_RPT
-- from tempdb.all_columns group by branch_name order by Branch_Name) as analysis;

-- select * ,round(( Incrementals*100)/(on_sales-Incrementals),2) as Gain
-- from (select *, (on_RPT-off_RPT)*T_on_Count as Incrementals
-- from (Select Branch_name ,
-- sum(case when sales<>0 then 1 else 0 end) T_Count,
-- sum(case when on_off_flag = 1 then 1 else 0 end) T_on_Count,
-- sum(case when on_off_flag = 0 then 1 else 0 end) T_off_Count,
-- sum(case when on_off_flag = 1 then sales else 0 end ) as on_sales,
-- count(DISTINCT RVS) T_Salesman,
-- count(DISTINCT Customer) T_Customer,
-- count(DISTINCT Product_ID) T_Product,
-- round(sum(case when sales>4000 then 1 else 0 end)*100/count(distinct Invoice_ID),2) as High_Potential_Cust,
-- round(sum(case when Sales >1000 and Sales<=4000 then 1 else 0 end)*100/count(distinct Invoice_ID),2) as Medium_Potential_Cust,
-- round(sum(case when Sales <=1000  then 1 else 0 end)*100/count(distinct Invoice_ID),2) as Low_Potential_Cust,
-- round(avg(Sales),2) as RPT,
-- round(avg(case when on_off_flag = 1 then (Sales) else null end),2) on_RPT,
-- round(avg(case when on_off_flag = 0 then (Sales) else null end),2) as off_rpt,
-- round(sum(case when product like '%FD%' then sales else 0 end)*100/sum(sales),2) as food_sale_percentage,
-- round(sum(case when  Product not like '%FD%' then Sales else 0 end)*100/sum(Sales),2) as non_food_sale_percentage,
-- round(avg(case when product like '%FD%' then sales else null end),2) as food_RPT,
-- round(avg(case when  Product not like '%FD%' then Sales else null end),2) as non_food_RPT
-- from tempdb.all_columns group by branch_name order by Branch_Name) as analysis) as incrementals;


-- OR it can be solved by storing tables in tempdp 

create temporary table tempdb.analysis(
Select Branch_name ,
sum(case when sales<>0 then 1 else 0 end) T_Count,
sum(case when on_off_flag = 1 then 1 else 0 end) T_on_Count,
sum(case when on_off_flag = 0 then 1 else 0 end) T_off_Count,
sum(case when on_off_flag = 1 then sales else 0 end ) as on_sales,
count(DISTINCT RVS) T_Salesman,
count(DISTINCT Customer) T_Customer,
count(DISTINCT Product_ID) T_Product,
round(sum(case when sales>4000 then 1 else 0 end)*100/count(distinct Invoice_ID),2) as High_Potential_Cust,
round(sum(case when Sales >1000 and Sales<=4000 then 1 else 0 end)*100/count(distinct Invoice_ID),2) as Medium_Potential_Cust,
round(sum(case when Sales <=1000  then 1 else 0 end)*100/count(distinct Invoice_ID),2) as Low_Potential_Cust,
round(avg(Sales),2) as RPT,
round(avg(case when on_off_flag = 1 then (Sales) else null end),2) on_RPT,
round(avg(case when on_off_flag = 0 then (Sales) else null end),2) as off_rpt,
round(sum(case when product like '%FD%' then sales else 0 end)*100/sum(sales),2) as food_sale_percentage,
round(sum(case when  Product not like '%FD%' then Sales else 0 end)*100/sum(Sales),2) as non_food_sale_percentage,
round(avg(case when product like '%FD%' then sales else null end),2) as food_RPT,
round(avg(case when  Product not like '%FD%' then Sales else null end),2) as non_food_RPT
from tempdb.all_columns group by branch_name order by Branch_Name
);

select * from tempdb.analysis;

create temporary table tempdb.incrementals(
select * ,(on_RPT-off_RPT)*T_on_Count as Incrementals from tempdb.analysis
);

select * ,round(( Incrementals*100)/(on_sales-Incrementals),2) as Gain from tempdb.incrementals;

