# SAFARI-C0NNECT
End-to-end data project: cleaned messy booking data in PostgreSQL, answered 6 business questions with SQL, and built a 2-page Power BI dashboard with insights and recommendations.


Project Objective
Safari Connect is a Nairobi-based bus and matatu booking platform. This project cleans the company's raw booking export loads it into PostgreSQL, answers six business questions with SQL, and presents the findings in a Power BI dashboard.

1. Importing the Data into PostgreSQL
The raw CSV was imported into PostgreSQL.

2. Cleaning the Data
23 data-quality problems were identified and fixed with SQL:

Names and cities: INITCAP(TRIM(...))

Phone numbers: REGEXP_REPLACE to strip dashes and +254

Dates: TO_DATE for DD/MM/YYYY, MM-DD-YYYY, DD-MM-YY formats

Fares: REGEXP_REPLACE to strip "KES" then CAST to INTEGER

Gender, payment method, booking status, seat class: standardised with CASE

Invalid trip ratings (0, 6): set to NULL

Negative seats_booked: deleted

Duplicate booking_id: deleted with ctid

Final row count: 275 records across all statuses.

3. Connecting Power BI to PostgreSQL
Power BI Desktop → Get Data → PostgreSQL database

Server: localhost:5432

Database: postgres

Credentials: PostgreSQL username / password

Selected the cleaned_trips view 

Clicked Load

4. Measures and Calculations
Created in DAX:

DAX
Total Revenue      = SUM(cleaned_trips[total_fare])
Total Bookings     = COUNTROWS(cleaned_trips)
Cancelled Bookings = CALCULATE(COUNTROWS(cleaned_trips),
                      cleaned_trips[booking_status] IN {"Cancelled","No Show"})
Cancellation Rate %= DIVIDE([Cancelled Bookings], [Total Bookings], 0)
Average Rating     = AVERAGE(cleaned_trips[trip_rating])
Revenue per Seat   = DIVIDE(SUM(cleaned_trips[total_fare]),
                            SUM(cleaned_trips[seats_booked]), 0)
Lost Revenue       = CALCULATE(SUM(cleaned_trips[total_fare]),
                      cleaned_trips[booking_status] IN {"Cancelled","No Show"})
5. Dashboard Visuals
Page 1 — Overview

4 KPI cards: Total Revenue, Total Bookings, Cancellation Rate, Average Rating

Monthly Revenue Trend (line chart)

Revenue by Route (bar chart)

Top 10 Drivers by Revenue (table)

Cancellation Rate by Route (bar chart) + Lost Revenue card

Slicers: Date Range, Route, City, Status

Page 2 — Details

Revenue by Passenger City (map)

Revenue per Seat by Route (bar chart)

Revenue by Seat Class (donut)

Bookings by Gender (donut)

Passenger Satisfaction 1–5 (column chart)

Bookings by Hour (column chart)

Bookings by Day of Week (column chart)

6. Key Insights
1. Route concentration
RT001 which is from Nairobi to Mombasa is the top revenue route at KSh 51,600.
RT003 Nairobi to Nakuru is the weakest at KSh 20,700.

3. Driver performance
Isaac Korir leads on revenue with KSh 33,045 across 33 trips but holds the lowest driver rating of the top 5 (3.80). Samuel Gitonga has the highest driver rating (4.60) but ranks 5th on revenue. 

4. Revenue trend
Revenue fluctuated between KSh 13,400 on August 2024, which is the weakest and KSh 23,680 on October 2024, which is the strongest. 

5. Passenger base
Nairobi dominates with 113 completed bookings generating KSh 112,000.

6. Cancellations
Cancellations and no-shows cost KSh 32,150 in lost revenue across the year. RT001 which is from Nairobi to Mombasa is the biggest loss at KSh 10,800 which is nearly double the next route. RT006 has the highest cancellation rate at 18.52%, followed by RT009 at 16.67%.

7. Recommendations
1. Promote Brian Kamau, not Isaac Korir.
Brian combines strong revenue (KSh 29,340) with high passenger satisfaction (3.73) and a solid driver rating (4.20). 

2. Attack the RT001 cancellation problem.
RT001 loses KSh 10,800 which is the single largest revenue loss making route. 

3. Reduce Nairobi dependency.
With ~49% of revenue from one city, the business is exposed to any local disruption. Recommend a marketing push in Kisumu  and Mombasa both show to dominate compared to Nairobi's volume.

CEO Summary
Safari Connect earned KSh 229,310 from 253 completed bookings in 2024. RT001  is the top route at KSh 51,600 but also the biggest source of lost revenue (KSh 10,800 from cancellations). Nairobi drives ~49% of revenue which is a concentration risk. Recommend promoting Brian Kamau, fixing cancellations on RT001, and expanding marketing in Kisumu and Mombasa.


Tools
PostgreSQL, DBeaver, Power BI Desktop, DAX
