select count(distinct doc_num)
from MAS..GaccPE
where GaccPE_Libelle like '%Financement%DTC%'
union
select count(distinct doc_num)
from VOLTEQPLUS..GaccPE
where GaccPE_Libelle like '%Financement%DTC%'
union 
select count(distinct doc_num)
from polybat..GaccPE
where GaccPE_Libelle like '%Financement%DTC%'
