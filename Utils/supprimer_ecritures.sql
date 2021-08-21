DELETE
from mas..gaccpe
where gaccpe_num in('STB012021010118','STB012021010119','STB012020110141')
DELETE
from mas..gaccpd
where gaccpe_num in('STB012021010118','STB012021010119','STB012020110141')
update mas..reglement
set reg_regcpt=0
where reg_num='RF20Tr777'















