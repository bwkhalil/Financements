use mas 
select * from GaccPE
update GaccPE
set GaccPE_Libelle=REPLACE(GaccPE_Libelle,'Stock','DTC')
where doc_num in ('RF19Tr1002',
'RF19Tr1026',
'RF19Tr1025',
'RF19Tr1044',
'RF200010',
'RF20Tr139',
'RF20Tr145',
'RF20Tr253',
'RF20Tr708',
'RF200011',
'RF20Tr254',
'RF20Tr255',
'RF200016',
'RF200014',
'RF210085',
'RF210122',
'RF210120') and gaccpe_libelle like '%Financement Stock / -Montant%'

select * from GaccPD
--update GaccPD
--set GaccPD_Libelle=REPLACE(GaccPD_Libelle,'Stock','DTC')
where gaccpe_num in (
select gaccpe_num from GaccPE
where doc_num in ('RF19Tr1002',
'RF19Tr1026',
'RF19Tr1025',
'RF19Tr1044',
'RF200010',
'RF20Tr139',
'RF20Tr145',
'RF20Tr253',
'RF20Tr708',
'RF200011',
'RF20Tr254',
'RF20Tr255',
'RF200016',
'RF200014',
'RF210085',
'RF210122',
'RF210120')) and GaccPD_Libelle like '%Financement Stock / -Montant%'


select * from polybat..GaccPE
where doc_num in(
'19DTC0004',
'19DTC0005',
'20DTC0002',
'20DTC0005',
'20DTC0006',
'21DTC0004',
'21DTC0006') and gaccpe_user='rapauto'