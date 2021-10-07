
--FIND THE MAXIMUM AMT PAID PER LEASE
----Only look at ACTIVE contracts. 
----PIS_DATE > 2016
WITH CTE as (
SELECT CCAN, CAST(MAX(Paid) as decimal) Max_Paid
FROM (
	SELECT CCAN, CAST([Paid_(Rent_+_OM)] as decimal) Paid, Disposal_Flag Disp FROM 
	PRD_Consolidated_Monthly.dbo.Portfolio_DataMart_Consolidated
	WHERE Disposal_Flag = 'ACTIVE' AND PIS_Date > '2016-01-01'
	--AND CCAN in (SELECT TOP 50 CCAN FROM PRD_Calendar_Monthly.dbo.Portfolio_DataMart_Calendar)
	) a
GROUP BY CCAN
),

--BUILD BUCKETS AND JOIN WITH PORTFOLIO DATAMART TO RETRIEVE HISTORICAL DATA
CTE2 as (
SELECT Disposal_Flag, Report_Date, a.CCAN, Days_Past_Due, 
       CASE WHEN Days_Past_Due <= 30 THEN 0
            WHEN Days_Past_Due > 30 AND Days_Past_Due <= 60 THEN 30
			WHEN Days_Past_Due > 60 AND Days_Past_Due <= 90 THEN 60
			WHEN Days_Past_Due > 90 AND Days_Past_Due <= 120 THEN 90
			WHEN Days_Past_Due > 120 AND Days_Past_Due <= 150 THEN 120
			WHEN Days_Past_Due > 150 AND Days_Past_Due <= 180 THEN 150
			WHEN Days_Past_Due > 180 AND Days_Past_Due <= 210 THEN 180
			WHEN Days_Past_Due > 210 AND Days_Past_Due <= 240 THEN 210
			WHEN Days_Past_Due > 240 AND Days_Past_Due <= 270 THEN 240
			WHEN Days_Past_Due > 270 AND Days_Past_Due <= 300 THEN 270
			WHEN Days_Past_Due > 300 AND Days_Past_Due <= 330 THEN 300
			WHEN Days_Past_Due > 330 AND Days_Past_Due <= 360 THEN 330
			WHEN Days_Past_Due > 360 AND Days_Past_Due <= 390 THEN 360
			WHEN Days_Past_Due > 390 AND Days_Past_Due <= 420 THEN 390
			WHEN Days_Past_Due > 420 AND Days_Past_Due <= 450 THEN 420
			WHEN Days_Past_Due > 450 AND Days_Past_Due <= 480 THEN 450
			WHEN Days_Past_Due > 480 AND Days_Past_Due <= 510 THEN 480
			WHEN Days_Past_Due > 510 AND Days_Past_Due <= 540 THEN 510
			WHEN Days_Past_Due > 540 AND Days_Past_Due <= 570 THEN 540
			WHEN Days_Past_Due > 570 AND Days_Past_Due <= 600 THEN 570
			WHEN Days_Past_Due > 600 AND Days_Past_Due <= 630 THEN 600
			WHEN Days_Past_Due > 630 AND Days_Past_Due <= 660 THEN 630
			WHEN Days_Past_Due > 660 AND Days_Past_Due <= 690 THEN 660
			WHEN Days_Past_Due > 690 AND Days_Past_Due <= 720 THEN 690
			WHEN Days_Past_Due > 720 AND Days_Past_Due <= 750 THEN 720
			WHEN Days_Past_Due > 750 AND Days_Past_Due <= 780 THEN 750
			WHEN Days_Past_Due > 780 AND Days_Past_Due <= 810 THEN 780
			WHEN Days_Past_Due > 810 AND Days_Past_Due <= 840 THEN 810
			WHEN Days_Past_Due > 840 AND Days_Past_Due <= 870 THEN 840
			WHEN Days_Past_Due > 870  THEN 870
       END AS Past_Due_Bins, 
Cast([Paid_(Rent_+_OM)] as decimal) 'Paid_(Rent_+_OM)' , Max_Paid,  ROUNd(1 - CAST([Paid_(Rent_+_OM)] as decimal)/Max_Paid, 2) as Left_To_Pay, Branch, PIS_Date, CAST(Total_Past_Due as decimal) Total_Past_Due, [CBR_(Rent_+_OM)]
FROM (SELECT * FROM PRD_Consolidated_Monthly.dbo.Portfolio_DataMart_Consolidated WHERE Disposal_Flag = 'ACTIVE') a
RIGHT JOIN CTE b ON a.CCAN = b.CCAN
WHERE CAST([Paid_(Rent_+_OM)] as decimal) > 0 
--AND Report_Date < '2021-03-01'
--ORDER BY CCAN, Report_Date
) 

, CTE3 as (
SELECT Report_Date, Disposal_Flag, CCAN, Past_Due_Bins, Days_Past_Due, Left_To_Pay, [Paid_(Rent_+_OM)], Max_Paid, Branch, Total_Past_Due, PIS_Date, [CBR_(Rent_+_OM)],
Row_Number() OVER (PARTITION BY CCAN, Past_Due_Bins ORDER BY Report_Date) Bin_Count
FROM CTE2 
WHERE Past_Due_Bins is not null --AND Max_Paid > 1000 AND [Paid_(Rent_+_OM)] > 1000
--WHERE Past_Due_Bins = 210
--ORDER BY Left_To_Pay DESC
--ORDER BY CCAN, Report_Date
)


SELECT Past_Due_Bins, COUNT(Past_Due_Bins) Num_of_Leases, --Avg(Left_To_Pay) Left_To_Pay, --avg --max(left_to_pay), 
	1-(Count(CASE WHEN Left_to_Pay < 0.05 THEN 1 END) / CAST(Count(Past_Due_Bins)as decimal)) as Perc_0
	--(Count(CASE WHEN Left_to_Pay > 0.5 THEN 1 END) / CAST(Count(Past_Due_Bins)as decimal)) as Perc_50, 
	--(Count(CASE WHEN Left_to_Pay > 0.9 THEN 1 END) / CAST(Count(Past_Due_Bins)as decimal)) as Perc_90, 
	--(1 - SUM([Paid_(Rent_+_OM)])/SUM(Max_Paid)) Agg_Diff
FROM ( SELECT * FROM CTE3 WHERE Bin_Count = 1) a
GROUP BY Past_Due_Bins 
ORDER BY Past_Due_Bins 






