use mas
delete from gaccpd where gaccpe_num in(
delete from GaccPE 
where doc_num in(
select Reg_Num 
	from reglement
	inner join GaccExercice 
		on year(reg_datereglement) =GaccExercice.GaccEx_Code 	
		where RegParam_Code in ('rbf')and /*Reg_RegCpt=0 and */ year(reg_dateecheance)>=2020 and reg_banque like '%atb%'
  
	
		 ))


select dareg_ref,reg_ref1
from reglement 
where reg_num ='rf200008'
select *
from xrelevehistorique
where reference like '%0553121%' or Num_piece like '%0553121%'


select *
from BanqueD where banqued_originenum='RF20Tr781'
