Create Database club_members;

use club_members;

create table if not exists club_member (
	member_id serial,
	full_name varchar(100),
	age int,
	maritial_status varchar(50),
	email varchar(150),
	phone varchar(20),
	full_address varchar(150),
	job_title varchar(100),
	membership_date date,
	PRIMARY KEY (member_id)
);
    
select * from club_member;


select count(full_name) from club_member; -- 2007 records 

/* Tasks:
- find duplicates 
- find and deal with any null values 
- ensure correct format of names, address etc*/ 

/*create table cleaned_club_member(
member_id serial,
full_name varchar (100),
first_name Varchar(50),
last_name Varchar(100),
age int,
marital_status varchar(50),
email varchar(150),
phone_number varchar (20),
full_address varchar (150),
street_address varchar(100),
job_title

);
 
-- GENERATED ALWAYS AS (regexp_replace(split_part(trim(lower(full_name)), ' ', 1), '\W+', '', 'g')), -- replace full_name with first name, makign sure no white spaces or non alphabetical values*/


Create table if not exists cleaned_club_member 
as select * from club_member;

select * from cleaned_club_member;

alter table cleaned_club_member
add column first_name varchar (50),
add column last_name varchar (100);


update cleaned_club_member 
SET first_name = regexp_replace(substring_index(trim(lower(full_name)), ' ', 1), '[^a-zA-Z0-9]', ''),
last_name =(CASE
when length(trim(lower(full_name))) - length(replace(trim(lower(full_name)), ' ', '')) = 2
	then concat(substring_index(substring_index(trim(lower(full_name)), ' ', 2), " ", -1),' ',substring_index(trim(lower(full_name)), ' ', -1))
WHEN length(trim(lower(full_name))) - length(replace(trim(lower(full_name)), ' ', ''))  = 3
	then concat(substring_index(substring_index(trim(lower(full_name)), ' ', 2), " ", -1),' ',substring_index(substring_index(trim(lower(full_name)), ' ', 3), " ", -1),' ',substring_index(trim(lower(full_name)), ' ', -1))
ELSE substring_index(substring_index(trim(lower(full_name)), ' ', 2), " ", -1)
END);

/* this was a pain to figure out but I'm glad I got there in the end. Knowing how I work, I'm sure there is a more efficient way to write this but that is a journey for another day.
the star of the show is substring_index(trim(lower(full_name))- lets go inside out:
		- lower: puts the name in lower case
        - trim: removes leading and trailing speaces like "   April  " to "April"
        - substring_index: substring_index(string, delimiter, number)- delimiter is what the function looks for to seperate indexes. number is the number of times the delimiter occurs and the index(s)
           before it. would have made my life easier if I knew this from the outright instead of assuming it meant index number. T_T can be positive(starts searching left) or negative(starts searching right)

first_name- pretty straight foward. we use the regexp_replace function to replace any non-alphabetical values with nothing, removing them from the first word of full name.ALTER


last_name - T_T yep, this took ages to figure out and everything I could find was either using JSON(???) or postgreSQL.... anyway, its a straightfoward case statement if you break it down.
			the condition is length of full_name (this function counts the spaces) - lenght of full_name with no spaces. This will tell us number of spaces in full name, telling us how many parts to the last name.
            for example- Jason De La Cruz- length=16, jasondelacruz- lenght = 13 meaning 3 spaces so 3 parts to last name.
            we now need to concat the parts- this was the tricky part-only because I didnt know the parts of the syntax.
            substring_index(substring_index(trim(lower(full_name)), ' ', 2), " ", -1)- this gives us the first part of the last name- why? work inside out.
            first substring_index counts the spaces from the left- and the index before that- Jason de la- but really Jason de. to get the de do another substring_index, this time using -1, to count from the right.*/

select * from cleaned_club_member;

-- checking to make sure age is correct
select age, (case
when length(cast(age as char)) > 2
	then "over 2 digits"
when length(cast(age as char)) = 0 
	then "NULL"
else "2 digits"
END) as is_age_clean
from cleaned_club_member
where length(cast(age as char)) > 2
or length(cast(age as char)) = 0; 

-- 15 rows returned that have triple digits like 222 or 41
-- alter age column to remove extra number 
select * from cleaned_club_member;

update cleaned_club_member
set age = (case
when length(cast(age as char)) = 0 
	then NULL
when length(cast(age as char)) = 3
	then cast(substring(cast(age as char), 1, 2) as signed)
else age
END);

-- check again for any ages with 3 numbers

-- nothing is returned 

-- lets fix the formatting of values within marital status table

update cleaned_club_member 
set maritial_status = (case
when trim(maritial_status) = "" 
then NULL
else trim(maritial_status)
END);

select maritial_status,
	count(*) AS new_record_count 
from cleaned_club_member
group by maritial_status; -- we have 4 records with the wrong spelling 

update cleaned_club_member
set maritial_status = "divorced"
where maritial_status = "divored";

-- make sure email addresses follow the same format (they are not case sensitive so it can all be lower case)
-- first check if there are any nulls 
select count(isnull(email))
from cleaned_club_member;

-- no nulls in email

update cleaned_club_member
set email = trim(lower(email));

-- we should check if any phone numbers are incomplete or null
select sum(isnull(phone)) as phone_null, sum(length(phone) != 12) not_complete
from cleaned_club_member; -- used sum here as it returns as 1 or 0 so if the condition is true, each row will be 1 and that will give us an accurate count.

-- no nulls or incomplete numbers 

update cleaned_club_member
set phone = (case
when trim(phone) = "" then NULL
when length(trim(phone)) < 12 then NULL
else trim(phone)
END);

-- lets seperate address into street name, city and state and make sure format is on point

select sum(isnull(full_address)) 
from cleaned_club_member;

alter table cleaned_club_member
add column street_address varchar (100),
add column city varchar (100),
add column state varchar (100);

update cleaned_club_member 
set street_address = substring_index(trim(lower(full_address)), ",", 1),
city = substring_index( substring_index(trim(lower(full_address)), ",", 2), ",", -1),
state = substring_index( substring_index(trim(lower(full_address)), ",", -2), ",", -1);


select DISTINCT(state)
from cleaned_club_member
group by state;
-- correct wrong state names 

update cleaned_club_member
set state = 'kansas'
where state = 'kansus';

update cleaned_club_member
set state = 'district of columbia'
where
	state = 'districts of columbia';

update cleaned_club_member
set state = 'north carolina'
where
	state = 'northcarolina';

update cleaned_club_member
set state = 'california'
where state = 'kalifornia';

update cleaned_club_member
set state = 'texas'
where state = 'tejas';

update cleaned_club_member
set state = 'texas'
where state = 'tej+f823as';

update cleaned_club_member
set state = 'tennessee'
where state = 'tennesseeee';

update cleaned_club_member
set state = 'new york'
where state = 'newyork';

update cleaned_club_member
set state = 'puerto rico'
where state = ' puerto rico';

update cleaned_club_member
set state = 'south dakota'
where state = 'south dakotaaa';



select street_address, city, state
from cleaned_club_member;

-- for Job titles, check if we have any missing data, change the roman numerals to (levels) and format



update cleaned_club_member
SET job_title = (case
    when trim(lower(job_title)) = "" then null
    else (case
        when substring_index(trim(lower(job_title)), " ", -1) = "i" then concat(substring(trim(lower(job_title)), 1, length(trim(lower(job_title))) - 1), " ", '(Level 1)')
        when substring_index(trim(lower(job_title)), " ", -1) = "ii" then concat(substring(trim(lower(job_title)), 1, length(trim(lower(job_title))) - 2), " ", '(Level 2)')
        when substring_index(trim(lower(job_title)), " ", -1) = "iii" then concat(substring(trim(lower(job_title)), 1, length(trim(lower(job_title))) - 3), " ", '(Level 3)')
        when substring_index(trim(lower(job_title)), " ", -1) = "iv"  then concat(substring(trim(lower(job_title)), 1, length(trim(lower(job_title))) - 2), " ", '(Level 4)')
        else trim(lower(job_title))
        end)
  end);

select job_title from cleaned_club_member;


select * from cleaned_club_member;

-- check for mistake in date inputted
select membership_date
from cleaned_club_member
where year(membership_date_copy) < 2000;

-- 16 coming back as early 1900s 

update cleaned_club_member
set membership_date = (case
when year(membership_date) < 2000 then cast(concat(replace(cast(year(membership_date) as char), 19, 20), "-", month(membership_date), "-", day(membership_date)) as date)
else membership_date
End);


-- lets drop the columns we no longer need 

alter table cleaned_club_member
drop column full_name,
drop column full_address,
drop column membership_date_copy;

-- it took me time to get here but I am proud. 

-- lets take away duplicate enteries
select count(*) from cleaned_club_member;
-- we have 2007 enteries 
-- we will need to look for duplicates using email since that must be unique to one person 

select count(distinct(email)) from cleaned_club_member;
-- 1997 emails are distinct meaning 10 enteries are duplicates 

select email, count(email)
from cleaned_club_member
group by email
having count(email) > 1;

-- perform a self join, using conditions of email being the same. the other condition ensures that after merging only the row with the larger id number remains.
delete c1
from cleaned_club_member c1
join cleaned_club_member c2
ON c1.member_id < c2.member_id AND c1.email = c2.email;


-- count is now 1997
-- export cleaned table to tableau 
select * from cleaned_club_member;

