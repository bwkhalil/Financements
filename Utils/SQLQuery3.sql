select *
from polybat..xrelevehistorique
where credit+debit=37510.306

select *
from polybat..xrelevehistorique
where Num_piece like'%519828%'

select *
from polybat..xrelevehistorique
where date_opr=CAST('2020-02-10' as date) and Banque like '%biat%' and credit+debit in(146386.732,3.5,0.665)


select reg_ref,reg_ref1 from polybat..reglement
where reg_num='20DTC0002'

update polybat..reglement
set reg_ref1='R0512856'
where reg_num='19DTC0005'



select cast (right('44R0585235',7) as nvarchar(7))