use mas
declare @lot as cursor
declare @parcourir as cursor
declare @ActRnum as nvarchar(100)
declare @nep as nvarchar(30)
declare @ned as nvarchar(30)
declare @ne as nvarchar(30)
declare @start as date
declare @end as date
declare @Montant as numeric (18,3)
declare @TMM as numeric (18,3)
declare @CalcInt as numeric(18,3)
declare @table as Table(id int,date_opr date,libelle varchar(200), credit numeric(18,3),debit numeric(18,3),idllig int,valider int)
declare @id as int
declare @dateop as date
declare @libelle as varchar(200)
declare @credit as numeric(18,3)
declare @debit as numeric(18,3)
declare @idllig int
declare @valider as int
declare @BanqueD_MontantBanque as numeric(18,3)


declare @banqueCode as nvarchar(20)
-------Diversys---------------------------
declare @diversys_index as int
--------BanqueD----------------------------
declare @banqued_compte as nvarchar(10)
declare @BanqueD_CompteLib as nvarchar(100)
declare @banqued_montantd as numeric(18,3)
--------Banque-----------------------------
declare @bq_compte as nvarchar(10)
declare @gaccjou_code as nvarchar(50)
--------GaccPE-----------------------------
declare @gaccpd_tiers as nvarchar(20)
declare @RegLabel as varchar(150)
declare @regl as varchar(150)
declare @ligDeb as varchar(150)

set @Lot = cursor for
( 
select DateReglement,Echeance,Regnum,Montant,TMM,Tiers_Code,reg_banque,reg_label from
(		

	select  top 100 Reg_DateReglement as DateReglement,Reg_DateEcheance as Echeance,reg_num as Regnum,Reg_Montant as Montant,xf.TMM as TMM,Tiers_Code,reg_banque,reg_label
	from reglement
	inner join xfrais xf
		on month(dateadd(month,-1,reg_datereglement))=xf.mois
		and year(dateadd(month,-1,reg_datereglement))=xf.année
	inner join GaccExercice 
	on year(reg_datereglement) =GaccExercice.GaccEx_Code 	
	where RegParam_Code in ('rfdt') and Reg_RegCpt>=0 /*and reg_num in( 'RF20Tr777')*/ and year(reg_dateecheance)>=2020 and reg_banque like '%stb%'  --and (reg_ref is not null or reg_ref1 is not null)
	--and Reg_Num not in ('RFE210005','RFE210006')
	--and reg_num='RF20Tr776'
	order by Reg_DateReglement,Reg_Num  asc
) as t
)
open @Lot
FETCH NEXT FROM @Lot INTO @start,@end,@ActRnum,@Montant,@TMM,@gaccpd_tiers,@banquecode,@RegLabel

if @RegLabel like '%prefin%' or @RegLabel like '%PREF%EXP%' or @RegLabel like '%préfin%exp%'
begin

select @regl=' DE Pref'
end
else
begin
select @regl=' De Fin'
end
select @ligDeb='MOBILISATION. Credit'+@regl

WHILE @@FETCH_STATUS = 0
	begin
	
	select @bq_compte=Banque_Compte from banque where banque_code=@banquecode			--Compte de
	select @bq_compte=isnull(@bq_compte, '0000')										--la banque
	select @gaccjou_code=gaccjou_code from banque where banque_code=@banquecode
	select @calcint =ISnull((((datediff(day,@start,@end)+1)*@Montant*(@TMM+2)/36000)),0);
	select @calcint,'*+*+***+',@ActRnum
	select @nep='-'
	select @ned='-';
	
WITH cte AS (
            
			select top 1 0 as typeop,idllig,valider,date_opr,libelle,credit,debit,
			ROW_NUMBER() OVER (	PARTITION BY date_opr,libelle ORDER BY credit  ,debit ,date_opr,libelle) row_num
			FROM xrelevehistorique
			where cast(date_opr as date) between dateadd(day,0,cast(@start   as date)) and dateadd(day,30,cast(@start   as date))
				  and banque like '%stb%'
				  --and valider=0			
				  and credit+debit=@Montant
				  and (rtrim(ltrim(libelle)) like '%'+@ligDeb+'%' or rtrim(ltrim(libelle)) like '%MOBILISATION. AVANCES SUR FACTU%')
				  order by Date_opr 
			
			union all
			select * from mas..xReleveHistorique where Date_opr>=CAST('2020-11-20' as date) and banque like '%stb%' and Credit+Debit=143766.000 /*cast(debit/1000 as int)=1 and Libelle like '%inter%'*/
			select top 1 1 as typeop,idllig,valider, date_opr,libelle,credit,debit,
			ROW_NUMBER() OVER (PARTITION BY date_opr,libelle ORDER BY abs(credit+debit-@calcint) asc ,date_opr,libelle ) row_num
			FROM xrelevehistorique
			where cast(date_opr as date) between dateadd(day,0,cast(@start   as date)) and dateadd(day,30,cast(@start   as date))
				  --and valider=0
				  and banque like '%stb%'
				  and rtrim(ltrim(libelle)) like '%REMBOURSEMENT%INTERET%'
				  order by Date_opr,abs(credit+debit-@calcint )asc
			
			union all
			select 2 as typeop,idllig,valider,date_opr,libelle,credit,debit,
			ROW_NUMBER() OVER (PARTITION BY date_opr,libelle,credit,debit ORDER BY date_opr,libelle,credit,debit) row_num
			FROM xrelevehistorique
			where /*abs(datediff(day,cast(date_opr as date),cast(@end   as date)))<=10
				  and valider=0
				  and */cast(date_opr as date) between dateadd(day,-20,cast(@end   as date)) and dateadd(day,8,cast(@end   as date))
				  and credit+debit<=@Montant
				  and banque like '%stb%'
				  and rtrim(ltrim(libelle)) like '%Remboursement%principal%'
			
			union all
			select top 1 3 as typeop,idllig,valider,date_opr,libelle,credit,debit,
			ROW_NUMBER() OVER (PARTITION BY date_opr,libelle,credit,debit ORDER BY date_opr,libelle,credit,debit) row_num
			FROM xrelevehistorique
			where cast(date_opr as date) between dateadd(day,-15,cast(@end   as date)) and dateadd(day,20,cast(@end   as date))
				  --and valider=0
				  and banque like '%stb%'
				  and rtrim(ltrim(libelle)) like '%COMMISSION REGLEMENT EFFET FINA%'
				  order by (datediff(day,@end,cast(date_opr as date)))

		--and rtrim(ltrim(libelle)) in ('MOBILISATION. CREDIT DE FINANCE','MOBILISATION. CREDIT DE PREFINA','REMBOURSEMENT INTERET A L''ECHEA','COMMISSION REGLEMENT EFFET FINA')
)

insert into @Table
select  typeop,date_opr,libelle,credit,debit,idllig,valider from cte 
order by typeop, Debit desc,Credit desc

select * from @table --where id=2 order by (@montant-debit)




declare @ch as varchar(10);
with output1 as (
select top 1 ST2.id, 
    SUBSTRING(
        (
            SELECT ','+cast(ST1.id as varchar(2))  AS [text()]
            FROM @table ST1
            WHERE ST1.id <= 500
            ORDER BY ST1.id
            FOR XML PATH ('')
        ), 2, 1000) x
FROM @table ST2
)

select  @ch=x from output1
--select @ch
if @ch in ('0,1','2,3','0,1,2,3','0,1,2,2,3','2,2,2,3','1,2,2,2,3')
begin
--select * from @table
--select @start as DateReglement,@end as Echeance,@ActRnum as Regnum,@CalcInt,'-**-*-*-*-*-' ;
update @table
set valider=0
set @parcourir =cursor for select * from @table
open @parcourir
declare @m as numeric(18,3)
select @m=0
FETCH NEXT FROM @parcourir INTO @id,@dateop,@libelle,@credit,@debit,@idllig,@valider
WHILE @@FETCH_STATUS = 0

begin

if @id in(0,2)
begin
	
	if @id=2 begin select @m=@m+@credit+@debit end
	update xrelevehistorique
	set valider=0
	where idllig =@idllig
	
	


	----------------------------------------------------------------En têtes------------------------------------------------------
	--select '----entete----'

	if @id=0 or @m<=@Montant
	begin
	-----------------------------------------------------------------CPT---------------------------------------------------------
	
	update cpt
	set cpt_num=cpt_num+1
	where cpt_doc=(
	select  TOP 1 cpt_doc
	from xReleveHistorique xr 
			inner join Reglement 
				on  rtrim(ltrim(xr.libelle))=@libelle
				--and cast(reglement.Reg_DateEcheance as date) <=cast(xr.date_opr as date) --and year(cast(reglement.Reg_DateEcheance as date)) =year(cast(xr.date_opr as date))
				and xr.valider=0
				and xr.idllig=@idllig
			inner join GaccExercice 
				on year(xr.date_opr) =GaccExercice.GaccEx_Code 
					--and GaccExercice.GaccEx_Etat=1
			inner join banque bq 
				on reglement.Reg_Banque=bq.banque_code
			inner join Cpt 
				on Cpt_Doc=bq.GaccJou_Code +cast(YEAR(xr.date_opr) as nvarchar)+right('00'+cast(MONTH(xr.date_opr) as nvarchar),2)
	where Reglement.Reg_Num  = @ActRnum and rtrim(ltrim(xr.libelle))=@libelle 
	)
	select @ne=cpt_doc+right('0000'+cast( row_number() over(partition by gaccjou_code, year(date_opr),month(date_opr) order by gaccjou_code,date_opr)	+	cpt_num+1 as nvarchar),4)--,@credit=xr.credit,@debit=xr.debit
	--select @ne=dbo.fn_CptJournal(@start,bq.GaccJou_Code)
	from  Reglement
			inner join  xrelevehistorique xr
				on rtrim(ltrim(xr.libelle))=@libelle
				and xr.valider=0
				and xr.idllig=@idllig
				--and cast(Reglement.Reg_DateEcheance as date) <=cast(xr.date_opr as date)-- and year(cast(reglement.Reg_DateEcheance as date)) =year(cast(xr.date_opr as date))
			inner join GaccExercice 
				on year(xr.date_opr) =GaccExercice.GaccEx_Code 
					and GaccExercice.GaccEx_Etat=1
			inner join banque bq 
				on reglement.Reg_Banque=bq.banque_code
			inner join Cpt 
				on Cpt_Doc=bq.GaccJou_Code +cast(YEAR(xr.date_opr) as nvarchar)+right('00'+cast(MONTH(xr.date_opr) as nvarchar),2)
	where Reglement.Reg_Num  =@ActRnum and rtrim(ltrim(xr.libelle))=@libelle
	--insert into  [dbo].[GaccPE] (
	--GaccPE_Num, GaccPE_Date, GaccJou_Code, GaccPE_User, Devise_Code,  GaccPE_Total, GaccPE_Libelle, GaccEx_Code, Doc_Num, GaccPE_Statut, GaccPE_DateCreate)
	
	SELECT @ne as gaccpe_num,
	date_opr,gaccjou_code,'RapAuto' as utilisateur,Banque_Devise,	debit+Credit as gaccpe_total,
	'Financement Stock'+ ' / -Montant reg- ' +convert(nvarchar(20),(Reglement.Reg_Montant)) +' / du: '+convert(nvarchar(20),(Reglement.Reg_DateReglement),103),
	year(date_opr),reglement.Reg_Num,0,getdate()
	from  Reglement
		inner join  xrelevehistorique xr
			on rtrim(ltrim(xr.libelle))=@libelle
			and xr.valider=0
			and xr.idllig=@idllig
			--and cast(Reglement.Reg_DateEcheance as date) <=cast(xr.date_opr as date)-- and year(cast(reglement.Reg_DateEcheance as date)) =year(cast(xr.date_opr as date))
		inner join GaccExercice 
			on year(xr.date_opr) =GaccExercice.GaccEx_Code 
				and GaccExercice.GaccEx_Etat=1
		inner join banque bq 
			on reglement.Reg_Banque=bq.banque_code
		inner join Cpt 
			on Cpt_Doc=bq.GaccJou_Code +cast(YEAR(xr.date_opr) as nvarchar)+right('00'+cast(MONTH(xr.date_opr) as nvarchar),2)
	where Reglement.Reg_Num  =@ActRnum and rtrim(ltrim(xr.libelle))=@libelle
    end
end
if @id=0 begin select @ned=@ne end
if @id=2 begin select @nep=@ne end

if @id=0
begin
--select '----details deblocage----'
---------------------------------------------------------------------Déblocage credit-------------------------------------------------------------------------------------------
		--insert into GaccPD( GaccPE_Num, GaccCpt_Num, GaccPD_Libelle,GaccPD_Coll,  GaccPD_Debit, GaccPD_Credit, GaccPD_DebitDevise,GaccPD_CreditDevise,
		--gaccpd_tiers,GaccPD_Ref,  Devise_Code, Devise_Cours, GaccPD_Date, GaccPD_Jou, GaccPD_Echeance, GaccEx_Code,  GaccPD_Doc_Num,GaccPD_ref2,gaccb_rb)
		
	
		SELECT distinct @ned,
		@bq_compte AS GaccCpt_Num ,
		'Financement Stock'+ ' / -Montant reg- ' +convert(nvarchar(20),(@Montant)) +' / du: '+convert(nvarchar(20),(@start),103)  as GaccPD_Libelle,
		'' as GaccPD_Coll,
		@debit+@credit as GaccPD_Debit,
		0 as GaccPD_Credit,
		@debit+@credit as GaccPD_DebitDevise,
		0 as GaccPD_CreditDevise,
		@GaccPD_Tiers AS GaccPD_Tiers
		,@ActRnum,
		'TND',
		1,
		@dateop,
		'',
		@end,
		YEAR(@end),
		null,
		null,
		'RELEVE '+CAST(RIGHT('00' + CAST(MONTH(@dateop) AS nvarchar(2)), 2) AS varchar(10))+'/'+ CAST(YEAR(@dateop) as nvarchar(4))
		---------------------------------------------------------------------Déblocage debit-------------------------------------------------------------------------------------------
		--insert into GaccPD( GaccPE_Num, GaccCpt_Num, GaccPD_Libelle,GaccPD_Coll,  GaccPD_Debit, GaccPD_Credit,GaccPD_DebitDevise, GaccPD_CreditDevise,
		--gaccpd_tiers,GaccPD_Ref,  Devise_Code, Devise_Cours, GaccPD_Date, GaccPD_Jou, GaccPD_Echeance, GaccEx_Code,  GaccPD_Doc_Num,GaccPD_ref2,gaccb_rb)
		SELECT distinct @ned,
		'50100001' AS GaccCpt_Num ,
		'Financement Stock'+ ' / -Montant reg- ' +convert(nvarchar(20),(@Montant)) +' / du: '+convert(nvarchar(20),(@start),103)  as GaccPD_Libelle,
		null as GaccPD_Coll,
		0 as GaccPD_Debit,
		@debit+@credit as GaccPD_Credit,
		0 as GaccPD_DebitDevise,
		@debit+@credit as GaccPD_CreditDevise,	
		@GaccPD_Tiers AS GaccPD_Tiers
		,@ActRnum,
		'TND',
		1,
		@dateop,
		'',
		@end,
		YEAR(@end),
		null,
		null,
		null
update xrelevehistorique
	set valider=1
	where idllig =@idllig

end
if @id =2
begin
--select '----details paiement----'
---------------------------------------------------------------------Paiement debit-------------------------------------------------------------------------------------------
		 if @m<=@Montant
		 begin
		 --insert into GaccPD( GaccPE_Num, GaccCpt_Num, GaccPD_Libelle,GaccPD_Coll,  GaccPD_Debit, GaccPD_Credit,GaccPD_DebitDevise, GaccPD_CreditDevise, 
		 --gaccpd_tiers,GaccPD_Ref,  Devise_Code, Devise_Cours, GaccPD_Date, GaccPD_Jou, GaccPD_Echeance, GaccEx_Code,  GaccPD_Doc_Num,GaccPD_ref2,gaccb_rb)
		
		SELECT distinct @nep,
		'50100001' AS GaccCpt_Num ,
		'Financement Stock'+ ' / -Montant reg- ' +convert(nvarchar(20),(@Montant)) +' / du: '+convert(nvarchar(20),(@start),103)  as GaccPD_Libelle,
		'' as GaccPD_Coll,
		
		CAST((@debit+@credit) as numeric(18,3)) as GaccPD_Debit,
		0 as  GaccPD_Credit,
		
		CAST((@debit+@credit) as numeric(18,3))  as  GaccPD_DebitDevise,
		0 as GaccPD_CreditDevise,
		@GaccPD_Tiers AS GaccPD_Tiers,
		@ActRnum,
		'TND',
		1,
		@dateop,
		'',
		@end,
		YEAR(@end),
		null,
		null,
		null
		---------------------------------------------------------------------Paiement credit-------------------------------------------------------------------------------------------
		--insert into GaccPD( GaccPE_Num, GaccCpt_Num, GaccPD_Libelle,GaccPD_Coll,  GaccPD_Debit, GaccPD_Credit,GaccPD_DebitDevise,GaccPD_CreditDevise,  
		--gaccpd_tiers,GaccPD_Ref,  Devise_Code, Devise_Cours, GaccPD_Date, GaccPD_Jou, GaccPD_Echeance, GaccEx_Code,  GaccPD_Doc_Num,GaccPD_ref2,gaccb_rb)
		SELECT distinct @nep,
		@bq_compte AS GaccCpt_Num ,
		'Financement Stock'+ ' / -Montant reg- ' +convert(nvarchar(20),(@Montant)) +' / du: '+convert(nvarchar(20),(@start),103)  as GaccPD_Libelle,
		'' as GaccPD_Coll,
		0 as  GaccPD_Debit,
		CAST((@debit+@credit) as numeric(18,3)) as GaccPD_Credit,
		0 as  GaccPD_DebitDevise,
		CAST((@debit+@credit) as numeric(18,3)) as GaccPD_CreditDevise,
		@GaccPD_Tiers AS GaccPD_Tiers,
		@ActRnum,
		'TND',
		1,
		@dateop,
		'',
		@end,
		YEAR(@end),
		null,
		null,
		'RELEVE '+CAST(RIGHT('00' + CAST(MONTH(@dateop) AS nvarchar(2)), 2) AS varchar(10))+'/'+ CAST(YEAR(@dateop) as nvarchar(4))

		update xrelevehistorique
	set valider=1
	where idllig =@idllig
	end
end

FETCH NEXT FROM @parcourir INTO @id,@dateop,@libelle,@credit,@debit,@idllig,@valider
end
CLOSE @parcourir; 

open @parcourir
FETCH NEXT FROM @parcourir INTO @id,@dateop,@libelle,@credit,@debit,@idllig,@valider
WHILE @@FETCH_STATUS = 0

begin

if @id not in(0,2)
begin
update xrelevehistorique
	set valider=0
	where idllig =@idllig
--select @id,@dateop,@libelle,@credit,@debit,@idllig,@valider


    
	if @id=3 begin select @diversys_index=15 end
	if @id=1 begin select @diversys_index=19 end
	-- else begin select @diversys_index=0 end
	select @BanqueD_MontantBanque=@credit+@debit
	--select @diversys_index=min(DiverSys_index) from diversys where charindex(ltrim(rtrim( @libelle)) , ltrim(rtrim(diversys_libelle)))>0 and diversys_type like '%f016%'
	
	select @banqued_compte=banqued_compte from banqued where banqued_originenum like '%'+@Actrnum+'%' and banqued_type=@diversys_index and Banque_Nature not like '%ttc%' 
	select @BanqueD_CompteLib=BanqueD_CompteLib from banqued where banqued_originenum like '%'+@Actrnum+'%' and banqued_type=@diversys_index and Banque_Nature not like '%ttc%' 
	select @banqued_montantd=banqued_montantd from banqued where banqued_originenum like '%'+@Actrnum+'%' and banqued_type=@diversys_index and Banque_Nature not like '%ttc%' 

	if @id in(1) --and @banqued_montantd>0
	begin
		--insert into GaccPD (GaccPE_Num,GaccCpt_Num ,GaccPD_Libelle,GaccPD_Debit,GaccPD_Credit,GaccPD_DebitDevise,GaccPD_CreditDevise,GaccPD_Ref,GaccB_RB,gaccpd_jou,GaccPD_Echeance)
		select @ned
		, @banqued_compte  ,@BanqueD_CompteLib,@banqued_montantd as debit,0 as credit,@banqued_montantd as debitdevise,0 as creditdevise,@ActRnum,null,null ,@dateop	
		union all
		select @ned
		,@bq_compte  ,@BanqueD_CompteLib,0 as debit,@BanqueD_MontantBanque as credit,0 as debitdevise,@BanqueD_MontantBanque as creditdevise,
	     @ActRnum,'RELEVE '+CAST(RIGHT('00' + CAST(MONTH(@dateop) AS nvarchar(2)), 2) AS varchar(10))+'/'+ CAST(YEAR(@dateop) as nvarchar(4)),
	     @gaccjou_code ,@dateop
		 
		 if abs(@banqued_montantd-@BanqueD_MontantBanque)>0
		 begin
		 --insert into GaccPD (GaccPE_Num,GaccCpt_Num ,GaccPD_Libelle,GaccPD_Debit,GaccPD_Credit,GaccPD_DebitDevise,GaccPD_CreditDevise,GaccPD_Ref,GaccB_RB,gaccpd_jou,GaccPD_Echeance)
		select @ned ,
		case  
			when @libelle  like '%inter%' then '65160109'
			when @libelle  like '%comm%' then '62799015'
		end
		,case  
			when @libelle  like '%inter%' then 'ECART INTERET SUR FIN DE STOCK'
			when @libelle  like '%comm%' then 'ECART - COMMISSION FIN DE STOCK'
		end
		,
		case when (@banqued_montantd-@BanqueD_MontantBanque) < 0 then abs((@banqued_montantd-@BanqueD_MontantBanque)) else 0 end as debit,
		case when (@banqued_montantd-@BanqueD_MontantBanque) > 0 then abs((@banqued_montantd-@BanqueD_MontantBanque)) else 0 end as credit,
		case when (@banqued_montantd-@BanqueD_MontantBanque) < 0 then abs((@banqued_montantd-@BanqueD_MontantBanque)) else 0 end as debitdevise,
		case when (@banqued_montantd-@BanqueD_MontantBanque) > 0 then abs((@banqued_montantd-@BanqueD_MontantBanque)) else 0 end as creditdevise,
		@ActRnum,null,null ,@dateop
		end
update xrelevehistorique
	set valider=1
	where idllig =@idllig
	end

	if @id in(3) --and @banqued_montantd>0
	begin
        select @BanqueD_MontantBanque=@BanqueD_MontantBanque/1.19
		--insert into GaccPD (GaccPE_Num,GaccCpt_Num ,GaccPD_Libelle,GaccPD_Debit,GaccPD_Credit,GaccPD_DebitDevise,GaccPD_CreditDevise,GaccPD_Ref,GaccB_RB,gaccpd_jou,GaccPD_Echeance)
		select @nep ,@banqued_compte  ,@BanqueD_CompteLib,@banqued_montantd as debit,0 as credit,@banqued_montantd as debitdevise,
        0 as creditdevise,@ActRnum,null,null ,@dateop	
		union all
		select @nep ,@bq_compte ,@BanqueD_CompteLib,0 as debit,@BanqueD_MontantBanque as credit,
        0 as debitdevise,@BanqueD_MontantBanque as creditdevise,
	    @ActRnum,'RELEVE '+CAST(RIGHT('00' + CAST(MONTH(@dateop) AS nvarchar(2)), 2) AS varchar(10))+'/'+ CAST(YEAR(@dateop) as nvarchar(4)),
	    @gaccjou_code ,@dateop
		 
		 if abs(@banqued_montantd-@BanqueD_MontantBanque)>0
		 begin
		 --insert into GaccPD (GaccPE_Num,GaccCpt_Num ,GaccPD_Libelle,GaccPD_Debit,GaccPD_Credit,GaccPD_DebitDevise,GaccPD_CreditDevise,GaccPD_Ref,GaccB_RB,gaccpd_jou,GaccPD_Echeance)
		select @nep ,
		case  
			when @libelle  like '%inter%' then '65160109'
			when @libelle  like '%comm%' then '62799015'
		end
			
		,case  
			when @libelle  like '%inter%' then 'ECART INTERET SUR FIN DE STOCK'
			when @libelle  like '%comm%' then 'ECART - COMMISSION FIN DE STOCK'
		end
		,
		case when (@banqued_montantd-@BanqueD_MontantBanque) < 0 then abs((@banqued_montantd-@BanqueD_MontantBanque)) else 0 end as debit,
		case when (@banqued_montantd-@BanqueD_MontantBanque) > 0 then abs((@banqued_montantd-@BanqueD_MontantBanque)) else 0 end as credit,
		case when (@banqued_montantd-@BanqueD_MontantBanque) < 0 then abs((@banqued_montantd-@BanqueD_MontantBanque)) else 0 end as debitdevise,
		case when (@banqued_montantd-@BanqueD_MontantBanque) > 0 then abs((@banqued_montantd-@BanqueD_MontantBanque)) else 0 end as creditdevise,
		@ActRnum,null,null ,@dateop
		
		end
		
        --insert into GaccPD (GaccPE_Num,GaccCpt_Num ,GaccPD_Libelle,GaccPD_Debit,GaccPD_Credit,GaccPD_DebitDevise,GaccPD_CreditDevise,GaccPD_Ref,GaccB_RB,gaccpd_jou,GaccPD_Echeance)
		select @nep ,'43660018' ,'TVA Sur Com',@banqued_montantd*0.19 as debit,0 as credit,@banqued_montantd*0.19 as debitdevise,
        0 as creditdevise,@ActRnum,null,null ,@dateop	
		union all
		select @nep ,@bq_compte ,'TVA Sur Com',0 as debit,@BanqueD_MontantBanque*0.19 as credit,
        0 as debitdevise,@BanqueD_MontantBanque*0.19 as creditdevise,
	    @ActRnum,'RELEVE '+CAST(RIGHT('00' + CAST(MONTH(@dateop) AS nvarchar(2)), 2) AS varchar(10))+'/'+ CAST(YEAR(@dateop) as nvarchar(4)),
	    @gaccjou_code ,@dateop
update xrelevehistorique
	set valider=1
	where idllig =@idllig
	end








	


end
FETCH NEXT FROM @parcourir INTO @id,@dateop,@libelle,@credit,@debit,@idllig,@valider
end


select * from @table 
update xrelevehistorique
set valider=1
where idllig in (select idllig from @table)

CLOSE @parcourir; 
DEALLOCATE @parcourir;




















--select *
--from @table
end
delete from @table
--update Reglement
--set Reg_RegCpt=2 where Reg_Num =@ActRnum
FETCH NEXT FROM @Lot INTO @start,@end,@ActRnum,@Montant,@TMM,@gaccpd_tiers,@banquecode,@RegLabel
end

CLOSE @lot; 
DEALLOCATE @lot;




















	--WITH cte AS (
--			select date_opr,libelle,credit,debit,
--				ROW_NUMBER() OVER (
--					PARTITION BY 
--						date_opr,libelle,credit,debit
--					ORDER BY 
--						date_opr,libelle,credit,debit
--				) row_num
--				FROM 
--				xrelevehistorique
--				where cast(date_opr as date)=cast(@end as date)
--				and credit+debit=@Montant
--		and banque like '%stb%'
--		and rtrim(ltrim(libelle)) in ('Remboursement principal')
--		--and rtrim(ltrim(libelle)) in ('MOBILISATION. CREDIT DE FINANCE','MOBILISATION. CREDIT DE PREFINA','REMBOURSEMENT INTERET A L''ECHEA','COMMISSION REGLEMENT EFFET FINA')
--		)
--		select * from cte