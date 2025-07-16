create database if not exists patients_data;
use patients_data;

# ______________ BASIC SQL & DATA RETRIEVAL_____________

-- Q1.Retrieve all columns from the Appointments table.
select * from virginia_patient_appointments;  # To see Complete record 


--  Q2. List the first 10 appointments where the patient is older than 60.
select * from 
virginia_patient_appointments
where age >60
order by age limit 10;

-- Q3. Show the unique neighborhoods from which patients came
select 
distinct Neighbourhood 
as Unique_Neighbourhood 
from virginia_patient_appointments; 


-- Q4. Find all female patients who received an SMS reminder. Give count of them
							-- ____part(1) of Q4____
# female patients_ids who received sms reminder
select PatientId,Gender,SMS_received
from virginia_patient_appointments
where SMS_received=1 and Gender="Female"
group by PatientId,Gender,SMS_received; # only female patients with sms reminder will get displayed

							-- ____part(2)of Q4_____
#                  Total female patients' COUNT  who received sms reminder

select distinct count(*) as total_count 
from virginia_patient_appointments 
where Gender="Female" and SMS_received=1; # total count of female patients who get sms reminder will be displayed

-- #Q5.Display all appointments scheduled on or after '2023-05-01' and before '2023-06-01'.

#   STEP-1 OF Q(5):  First we need to modify text-date to its proper  'date format'  for furthur operation

set sql_safe_updates=0;   
update virginia_patient_appointments
set ScheduledDay= str_to_date(ScheduledDay,"%m/%d/%Y");   #DATE MODIFICATION
alter table virginia_patient_appointments
modify ScheduledDay date;

#  STEP-2 OF Q(5):   All appointments scheduled on or after '2023-05-01' and before '2023-06-01'.
select *,
case
when  
ScheduledDay  between'2023-05-01' and  '2023-05-31' then 1  
end as scheduled_appointments
from virginia_patient_appointments
having scheduled_appointments is not null;


--                    _______ DATA MODIFICATION & FILTERING_________

-- Q6. Update the 'Showed_up' status to 'Yes' where it is null or empty
                            -- STEP(1) OF Q(6)
    select Showed_up from virginia_patient_appointments
    where Showed_up is NULL; # check if there is a missing value is present or not
							-- STEP(2) OF Q(6)
    set sql_safe_updates=0;
    update virginia_patient_appointments
    set Showed_up ='Yes'
	where
	Showed_up is NULL;
	select * from virginia_patient_appointments; # check if  missing value is still present or not 
    
--  Q7. Add a new column AppointmentStatus using a CASE statement:
--       ○ 'No Show' if Showed_up = 'No'
--       ○ 'Attended' otherwise
  
  #  PART (1) OF Q(7)
 alter table  virginia_patient_appointments
 add column AppointmentStatus varchar(20); #adding a column named AppointmentStatus
 
 #  PART (2) OF Q(7)
 set sql_safe_updates=0;
 update virginia_patient_appointments
 set AppointmentStatus = (select
 case when  Showed_up = 'No' then 'No Show' 
 else 'Attended'
 end ); #update according to given condition 
 
 select * from virginia_patient_appointments; #check modification in  complete table 

-- Q8. Filter appointments for diabetic patients with hypertension.

Select AppointmentID,PatientId,Diabetes,Hypertension
from virginia_patient_appointments
where Diabetes=1 and
Hypertension=1;  # patients who have diabetes and hypertension will be showed


-- Q9. Order the records by Age in descending order and show only the top 5 oldest patients.

Select *  from
virginia_patient_appointments
order by age desc limit 5; #show only the top 5 oldest patients in descending order


-- Q10. Limit results to the first 5 appointments for patients under age 18.

Select *  from virginia_patient_appointments
where  age<18
order by age asc  limit 5;

--                    _______ AGGREGATION & GROUPING__________

-- Q11. Find the average age of patients for each gender.

Select Gender, round(avg(age),2) from virginia_patient_appointments
group by Gender;

-- Q12. Count how many patients received SMS reminders, grouped by Showed_up status.


select SMS_received,
Showed_up,count(*) as patient_count
from  virginia_patient_appointments
group by Showed_up,SMS_received
having SMS_received=1; # patients  who received SMS-reminder will get display
 

-- Q 13. Count no-show appointments in each neighborhood using GROUP BY.

select  count(AppointmentStatus="No Show") as No_show_count, Neighbourhood
from virginia_patient_appointments
group by Neighbourhood;

-- Q14. Show neighborhoods with more than 100 total appointments (HAVING clause).
select Neighbourhood,count(AppointmentID) as total_appointments_count
from virginia_patient_appointments
group by Neighbourhood
having total_appointments_count>100;

-- Q15. Use CASE to calculate the total number of:
--      ○ children (Age < 12)
--      ○ adults (Age BETWEEN 12 AND 60)
--      ○ seniors (Age > 60)
    select
	count(case when Age<12 then 1 end )as children,
    count(case when Age between 12 and 60 then 1 end) as adults,
	count(case when Age >60  then  1 end) as seniors
	from virginia_patient_appointments;
    
-- _____________________________________-WINDOW FUNCTIONS __________________________

-- Q16
-- Tracks how appointments accumulate over time in each neighbourhood. (Running Total of
-- Appointments per Day) 
-- In simple words: How many appointments were there each day and how
-- do the total appointments keep adding up over time in each neighborhood?

select Neighbourhood,AppointmentDay,
count(AppointmentID) as Total_Appointments_per_day,
sum(count(AppointmentID) ) over (partition by Neighbourhood  order by AppointmentDay)  as Running_total_Appointments
from virginia_patient_appointments
group by Neighbourhood,AppointmentDay
order by Neighbourhood ;


-- Q17       Use Dense_Rank() to rank patients by age within each gender group.

select * from virginia_patient_appointments;
#Use Dense_Rank() to rank patients by age within each gender group.
 select  PatientId,Age,Gender,
 dense_rank() over ( partition by gender order by age desc) as age_dense_rank
 from  virginia_patient_appointments
 order by age desc;
 
 -- Q18 : How many days have passed since the last appointment in the same neighborhood? 
 -- (Hint:DATEDIFF and Lag) (This helps to see how frequently appointments are happening in each
-- neighborhood.)

select  AppointmentDay,Neighbourhood,
lag(AppointmentDay) over (partition by  Neighbourhood  order by appointmentDay) as previous_Appointment_date,
datediff(AppointmentDay, lag(AppointmentDay) over (partition by  Neighbourhood order by appointmentDay )) as Days_Difference
from  virginia_patient_appointments;

-- Q 19 Which neighborhoods have the highest number of missed appointments? Use DENSE_RANK()
-- to rank neighborhoods based on the number of no-show appointments.

select Neighbourhood, sum(AppointmentStatus='No Show')  as Missed,
dense_rank() over (order  by sum(AppointmentStatus = 'No Show') desc ) AS Missed_Appointment_rank
from virginia_patient_appointments
group by neighbourhood;


--          __________________________________________________________________________________
    

-- ________________COMPLEX QUERIES _______________

  -- Q20. Are patients more likely to miss appointments on certain days of the week?
  
#    First we need to modify text date to its proper  'date format'  for furthur operation
set sql_safe_updates=0;   
update virginia_patient_appointments
set AppointmentDay= str_to_date(AppointmentDay,"%m/%d/%Y");   #DATE FORMAT  MODIFICATION
alter table virginia_patient_appointments
modify AppointmentDay date;

#  STEP-I OF Q(20) :( DAYS  EXTRACTION )
alter table virginia_patient_appointments
add column days varchar(20);  # column named  "days" will be created 

set sql_safe_updates=0;
update virginia_patient_appointments
set days=(SELECT DAYNAME(AppointmentDay) as Days); # column named "days" will be updated by extracting name of days from date
																										

select * from virginia_patient_appointments;  # check whole column to see modifications clearly
		

#STEP -II OF Q(20) 'COUNT OF  SCHEDULED APPOINTMNETS','COUNT OF SHOWED-UP AND MISSED ' ON EACH DAY
                                  --  TOTAL APPOINTMENTS :
select  count(*) as total_Appointments  from virginia_patient_appointments; 

#count of showed-up,missed,%age of shows and missed according to each day in descending order will be displayed 
select  Days,sum(case when Showed_up="yes" then 1 end ) as Showed_up,
sum(case when Showed_up="No" then 1 end ) as Missed,
round(count(case when Showed_up ='yes' then 1 end )*100/count(*),2) as percentage_of_shows,
round(count(case when Showed_up ='no' then 1 end )*100/count(*),2) as percentage_of_no_shows
from virginia_patient_appointments
group by Days
order by percentage_of_no_shows desc;










































