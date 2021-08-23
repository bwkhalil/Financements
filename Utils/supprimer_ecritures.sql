DELETE
from mas..gaccpe
where gaccpe_num in('ATB012021060043','ATB012021060043')
DELETE
from mas..gaccpd
where gaccpe_num in('ATB012021060043','ATB012021060043')
update mas..reglement
set reg_regcpt=1
where reg_num in('RF210119')



SELECT gaccpe_num
from mas..GaccPE
where Doc_Num in('RF20Vi204')


update mas..GaccPd
set GaccPd_Libelle=REPLACE(GaccPd_Libelle,'Stock','Dinar')
where GaccPE_Num in(
   'STB022020110015',
'STB022021020017' 
)
and 
GaccPd_Libelle like 'Fin%stoc%'











