select banqued_date,banqued_montantd,banqued_montantbanque
,banqued_ref
from mas..banqued
where banqued_originenum='RF210051'

select *
from mas..Reglement
where ((reg_ref like '%ft13%' or reg_ref1 like '%ft13%')or(reg_ref like '%ft14%' or reg_ref1 like '%ft14%'))
order by Reg_DateReglement

select valider,libelle,date_opr,debit,credit,idllig
from mas..xrelevehistorique
where ((reference like '%f13%' or num_piece like '%f13%')or(reference like '%f14%' or num_piece like '%f14%'))
and banque like '%atb%'
order by date_opr

update mas..xrelevehistorique
set valider=0
where ((reference like '%f13%' or num_piece like '%f13%')or(reference like '%f14%' or num_piece like '%f14%'))
and banque like '%atb%'


select DISTINCT regParam_Code
from mas..Reglement
where ((reg_ref like '%f13%' or reg_ref1 like '%f13%')or(reg_ref like '%f14%' or reg_ref1 like '%f14%'))


declare @rank table (
    ordering int identity(1,1)
    , number int    
    )

insert into @rank values (24)
insert into @rank values (12)
insert into @rank values (7)
insert into @rank values (14)
insert into @rank values (65)


select *
from
(select top 1200 row_number()over(partition by libelle order by date_opr ) as id
,libelle,Date_opr,debit,credit,banque,idllig
from mas..xrelevehistorique
where ((reference like '%f13%' or num_piece like '%f13%')or(reference like '%f14%' or num_piece like '%f14%'))
and banque like '%atb%'
and libelle not like '%retar%'
order by id,date_opr
, (CASE WHEN libelle LIKE 'debl%' THEN 0
        when libelle like '%inter%' then 1
        when libelle like '%com%eff%' then 2
        when libelle like '%tva%' then 3
        when libelle like '%paiement%princi%' then 4
    END) ASC


) as T
where T.id=3