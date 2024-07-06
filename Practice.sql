

with person_request as
(
    select
    person_id,
    max(request) as max_request
    from requests
    group by 1
),
first_request as
(
    select c.*,
    min(c.request_id) over (partition by c.seat_no) as first_request_id
    from
    (
        select a.*,b.max_request 
        from requests as a
        JOIN person_request as b on a.person_id = b.person_id
    ) as c
    where c.max_request = c.request
),
seat_reservation as
(
    select 
     a.seat_no,
     a.status,
     a.person_id as base_person_id,
     coalesce(b.max_request,0) as request,
     coalesce(b.person_id,0) as request_person_id,
     coalesce(b.request_id,0) as request_id
    from seats as a
    left join first_request as b 
    on a.seat_no = b.seat_no and b.first_request_id = b.request_id
),
base as
(
    select
    c.seat_no,
    case 
    when c.status = 0 and c.request > 0
    then c.request
    when c.status = 1 and c.base_person_id = c.request_person_id
    then c.request
    when c.status = 2
    then c.status
    else c.status 
    end as status,
    case 
    when c.status = 0 and c.request > 0
    then c.request_person_id
    when c.status = 1 and c.base_person_id = c.request_person_id
    then c.request_person_id
    when c.status = 2
    then c.base_person_id
    else c.base_person_id 
    end as person_id
    from seat_reservation as c
)
select * from base;
Share
Improve this answer
Follow
edited May 18 at 13:59
answered May 18 at 13:57
n0ieee21's user avatar
n0ieee21
2622 bronze badges
Add a comment
-1

Here is an answer that works:

CREATE PROCEDURE solution()
BEGIN
    /* Write your SQL here. Terminate each statement with a semicolon. */
    
SELECT
    s.seat_no,
    -- Determine the final status of each seat after applying all requests
    CASE
