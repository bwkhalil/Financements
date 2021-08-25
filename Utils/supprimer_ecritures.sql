DELETE
from mas..gaccpe
where gaccpe_num in('UIB012020060211','UIB012020030087')
DELETE
from mas..gaccpd
where gaccpe_num in('UIB012020060211','UIB012020030087')
update mas..reglement
set reg_regcpt=0
where reg_num in('RF20Tr057')



SELECT gaccpe_num
from mas..GaccPE
where Doc_Num in('RF20Tr001')


delete from mas..GaccPe
--set GaccPd_Libelle=REPLACE(GaccPd_Libelle,'Stock','Dinar')
where GaccPE_Num in(
   'UIB012020010109',
'UIB012020020126'
)

select mas..gaccpe_libelle
from gaccpe
where doc_num in(
'ATB012021060046',
'ATB012021060045',
'ATB012020110253',
'ATB012021060037',
'ATB012020110280',
'ATB012021020099',
'ATB012021020100',
'ATB012020080086',
'ATB012020110250',
'ATB012020080088',
'ATB012020110252',
'ATB012021020101',
'ATB012021060042',
'ATB012021020104',
'ATB012021060044'

)











