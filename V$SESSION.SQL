select * from v$session
where useRname = 'ESTADIS'
and upper(osuser) = 'GOVIEDO'

ALTER SYSTEM KILL SESSION '68,7288'
