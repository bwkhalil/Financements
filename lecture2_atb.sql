use volteqplus

declare @table as table(id int,libelle varchar(200),date_opr date,debit numeric(18,3),credit numeric(18,3),banque varchar(20),idllig int,touche int default 0,ref varchar(50))
declare @correction as table(id int,libelle varchar(200),date_opr date,debit numeric(18,3),credit numeric(18,3),banque varchar(20),idllig int,touche int default 0,ref varchar(50))
insert into @table
select *
from
(select top 1200 row_number()over(partition by libelle order by date_opr ) as id
,libelle,Date_opr,debit,credit,banque,idllig,0 as touche,Num_piece as ref
from xrelevehistorique
where ((reference like '%13002%' or num_piece like '%13002%')or(reference like '%14002%' or num_piece like '%14002%'))
and banque like '%atb%'
and libelle not like '%retar%'
order by id,date_opr
, (CASE WHEN libelle LIKE 'debl%' THEN 0
        when libelle like '%inter%' then 1
        when libelle like '%com%eff%' then 2
        when libelle like '%tva%' then 3
        when libelle like '%paiement%princi%' then 4
    END) ASC,LEFT(num_piece,7)


) as T
--select * from @table

declare @cnt int
declare @ptr int
declare @ptr1 int
declare @mnt as numeric(18,3)
declare @mnt1 as numeric(18,3)
select @cnt=MAX(id) from @table
set @ptr=1

while (@ptr<=@cnt)
begin
	
	select @mnt=debit from @table where id=@ptr and libelle like '%paiement%princi%'
	if @mnt<20000
	begin
	set @ptr1=@ptr+1 	
	while (@ptr1<=@cnt)
	begin		
		--set @ptr1=@ptr+1
		select @mnt1=debit from @table where id=@ptr1 and libelle like '%paiement%princi%'
		select @ptr,@ptr1,@mnt1,@mnt+@mnt1
		if @mnt+@mnt1<=20000 
		begin
			select @mnt=@mnt+@mnt1
			update @table
			set id=@ptr,touche=1
			where id=@ptr1 and libelle like '%paiement%princi%' and touche =0
		end
		set @ptr1=@ptr1+1
		if @mnt=cast(20000 as numeric(18,3)) begin break end
		
	end
			
	end
	--end
	set @ptr=@ptr+1
	
	
end
declare @reference as varchar(50)
declare @fausse_ref as varchar(50)
declare @fausse_ref1 as varchar(50)
declare @f_idllig as int
declare @idllig as int
declare @proceder as int
declare @aux as varchar(50)
declare @partic as int
set @ptr=1
while (@ptr<=@cnt)
begin	
	select @reference=rtrim(ltrim(ref)) from @table where id=@ptr and libelle like '%deblo%'
	--commission
	select @fausse_ref=rtrim(ltrim(ref)) from @table where id=@ptr and libelle like '%comm%'
	select @f_idllig=idllig from @table where id=@ptr and libelle like '%comm%'
	if @fausse_ref is not null and @fausse_ref<>@reference
	begin
	set @proceder=1
	set @ptr1=@ptr+1 	
	while (@ptr1<=@cnt)
	begin
		select @fausse_ref1=rtrim(ltrim(ref)) from @table where id=@ptr1 and libelle like '%comm%' and touche =0
		select @idllig=idllig from @table where id=@ptr1 and libelle like '%comm%' and touche =0
		select @proceder=COUNT(distinct ref) from @table where id=@ptr1
		if @proceder>1 and @fausse_ref1=@reference
		begin
		--select 'comm',@ptr,@ptr1,@proceder,@reference,@fausse_ref,@fausse_ref1	
		    --set @aux=		
			update @table
			set /*id=@ptr,*/touche=2,ref=@fausse_ref1,idllig=@idllig
			where id=@ptr and libelle like '%comm%'
			update @table
			set /*id=@ptr1,*/touche=2,ref=@fausse_ref,idllig=@f_idllig
			where id=@ptr1 and libelle like '%comm%' and touche =0
			break
		end
		set @ptr1=@ptr1+1
	end
			
	end
	--interet
	select @fausse_ref=rtrim(ltrim(ref)) from @table where id=@ptr and libelle like '%inter%'
	select @f_idllig=idllig from @table where id=@ptr and libelle like '%inter%'
	if @fausse_ref is not null and @fausse_ref<>@reference
	begin
	set @proceder=1
	set @ptr1=@ptr+1
	while (@ptr1<=@cnt)
	begin
		select @fausse_ref1=rtrim(ltrim(ref)) from @table where id=@ptr1 and libelle like '%inter%' and touche =0
		select @idllig=idllig from @table where id=@ptr1 and libelle like '%inter%' and touche =0
		select @proceder=COUNT(distinct ref) from @table where id=@ptr1
		select @partic=COUNT(*) from @table where id=@ptr1
		if (@proceder>1 and @fausse_ref1=@reference) or (@partic in(1,3,5,6,7) and @fausse_ref1=@reference)
		begin
		--select 'int',@ptr,@ptr1,@proceder,@reference,@fausse_ref,@fausse_ref1	
		    --set @aux=		
			update @table
			set /*id=@ptr,*/touche=2,ref=@fausse_ref1,idllig=@idllig
			where id=@ptr and libelle like '%inter%'
			update @table
			set /*id=@ptr1,*/touche=2,ref=@fausse_ref,idllig=@f_idllig
			where id=@ptr1 and libelle like '%inter%' and touche =0
			break
		end
		set @ptr1=@ptr1+1
	end
			
	end

	--tva
	select @fausse_ref=rtrim(ltrim(ref)) from @table where id=@ptr and libelle like '%tva%'
	select @f_idllig=idllig from @table where id=@ptr and libelle like '%tva%'
	if @fausse_ref is not null and @fausse_ref<>@reference
	begin
	set @proceder=1
	set @ptr1=1
	while (@ptr1<=@cnt)
	begin
		select @fausse_ref1=rtrim(ltrim(ref)) from @table where id=@ptr1 and libelle like '%tva%' and touche =0
		select @idllig=idllig from @table where id=@ptr1 and libelle like '%tva%' and touche =0
		select @proceder=COUNT(distinct ref) from @table where id=@ptr1
		if @proceder>1 and @fausse_ref1=@reference
		begin
		--select 'tva',@ptr,@ptr1,@proceder,@reference,@fausse_ref,@fausse_ref1	
		    --set @aux=		
			update @table
			set /*id=@ptr,*/touche=2,ref=@fausse_ref1,idllig=@idllig
			where id=@ptr and libelle like '%tva%'
			update @table
			set /*id=@ptr1,*/touche=2,ref=@fausse_ref,idllig=@f_idllig
			where id=@ptr1 and libelle like '%tva%' and touche =0
			break
		end
		set @ptr1=@ptr1+1
	end
			
	end

	--paiement
	select @fausse_ref=rtrim(ltrim(ref)) from @table where id=@ptr and libelle like '%paiement%princ%'
	select @f_idllig=idllig from @table where id=@ptr and libelle like '%paiement%princ%'
	if @fausse_ref is not null and @fausse_ref<>@reference
	begin
	set @proceder=1
	set @ptr1=1	
	while (@ptr1<=@cnt)
	begin
		select @fausse_ref1=rtrim(ltrim(ref)) from @table where id=@ptr1 and libelle like '%paiement%princ%' and touche =0
		select @idllig=idllig from @table where id=@ptr1 and libelle like '%paiement%princ%' and touche =0
		select @proceder=COUNT(distinct ref) from @table where id=@ptr1
		if @proceder>1 and @fausse_ref1=@reference
		begin
		--select 'paiement',@ptr,@ptr1,@proceder,@reference,@fausse_ref,@fausse_ref1	
		    --set @aux=		
			update @table
			set /*id=@ptr,*/touche=2,idllig=@idllig
			where id=@ptr and libelle like '%paiement%princ%'
			update @table
			set /*id=@ptr1,*/touche=2,idllig=@f_idllig
			where id=@ptr1 and libelle like '%paiement%princ%' and touche =0
			break
		end
		set @ptr1=@ptr1+1
	end
			
	end
	set @ptr=@ptr+1
	
end





declare @cpt_pay as int
declare @cpt_pay1 as int
declare @dte_ev as date
declare @dte_deb as date
declare @dte_ev1 as date
declare @dte_ev2 as int
set @ptr=1
declare @somme as numeric(18,3)
while (@ptr<=@cnt)
begin	
	select @reference=rtrim(ltrim(ref)) from @table where id=@ptr and libelle like '%deblo%'
	select @dte_ev=DATEADD(day,90,date_opr) from @table where id=@ptr and libelle like '%deblo%'
	select @mnt=credit from @table where id=@ptr and libelle like '%deblo%'
	--paiement
	select @cpt_pay= COUNT(*) from @table where libelle like '%paiement%princ%' and id=@ptr 
	select @f_idllig=idllig from @table where id=@ptr and libelle like '%paiement%princ%'
	select @somme=SUM(debit) from @table where id=@ptr and libelle like '%paiement%princ%'
	
	if @cpt_pay =0 or @somme<@mnt
	begin
		--set @proceder=1
		set @mnt1=0
		set @ptr1=@ptr+1
		if @ptr1>@cnt begin set @ptr1=@ptr-1 end 
		
		while (@ptr1<=@cnt)
		begin
			select @fausse_ref1=rtrim(ltrim(ref)) from @table where id=@ptr1 and libelle like '%paiement%princ%' and touche <>3
			select @mnt1=@mnt1+debit from @table where id=@ptr1 and libelle like '%paiement%princ%' and touche <>3
			declare @myref as varchar(150)
			select @myref=rtrim(ltrim(ref)) from @table where id=@ptr1 and libelle like '%deblo%' and touche <>3
			select @idllig=idllig from @table where id=@ptr1 and libelle like '%paiement%princ%' and touche <>3
			select @cpt_pay1= COUNT(*) from @table where libelle like '%paiement%princ%' and id=@ptr1 and touche <>3			
			if @cpt_pay1 >0
			begin
			
				select @dte_deb=cast(date_opr as date) from @table where id=@ptr1 and libelle like '%deblo%' and touche <>3
				select @dte_ev2=datediff(day,@dte_deb,date_opr) from @table where id=@ptr1 and libelle like '%paiement%princ%' and touche <>3
				select @ptr,@ptr1,@dte_ev2,@fausse_ref1,@reference
				if @fausse_ref1<>@myref and @reference=@fausse_ref1
				begin

					update @table
					set id=@ptr,touche=3
					where  id=@ptr1 and libelle like '%paiement%princ%' --and @fausse_ref1=@reference
					break
				end
				if @reference=@fausse_ref1 and @mnt1>@mnt
				begin
					update @table
					set id=@ptr,touche=3
					where  id=@ptr1 and libelle like '%paiement%princ%' --and @fausse_ref1=@reference
					break
				end
				--select @dte_ev1=DATEADD(day,90,date_opr) from @table where id=@ptr1 and libelle like '%deblo%'
				
			
				--select '   ',@ptr1,@fausse_ref1,@ptr,@reference, @dte_ev2,DATEDIFF(day,GETDATE(),@dte_ev1),@mnt1,@mnt
				--select @mnt1=@mnt1+debit from @table where id=@ptr1 and libelle like '%paiement%princ%' and touche <>3
				--if @dte_ev2>=90 and DATEDIFF(day,GETDATE(),@dte_ev1)<0 and @mnt1<=@mnt and @fausse_ref1=@reference
				--begin
				--	update @table
				--	set id=@ptr,touche=3
				--	where  id=@ptr1 and libelle like '%paiement%princ%' --and @fausse_ref1=@reference
				--	--select '      ',@ptr1 ,'----',@dte_ev2,@cpt_pay1,GETDATE(),@dte_ev1,DATEDIFF(day,GETDATE(),@dte_ev1)
				--end

			end
			--	select @proceder=COUNT(distinct ref) from @table where id=@ptr1
			--	if @proceder>1 and @fausse_ref1=@reference
			--	begin
			--	select 'paiement',@ptr,@ptr1,@proceder,@reference,@fausse_ref,@fausse_ref1	
			--		--set @aux=		
			--		update @table
			--		set /*id=@ptr,*/touche=2,ref=@fausse_ref1,idllig=@idllig
			--		where id=@ptr and libelle like '%paiement%princ%'
			--		update @table
			--		set /*id=@ptr1,*/touche=2,ref=@fausse_ref,idllig=@f_idllig
			--		where id=@ptr1 and libelle like '%paiement%princ%' and touche =0
			--		break
			--	end
			set @ptr1=@ptr1+1
		end
		
			
	end
	set @ptr=@ptr+1
	
end















insert Into @correction
select * from @table where id in(
select id from @table
group by id
having count(*) > 1)
order by id


----------------------------------Ecritures-------------------------------------------------------------------------------------------------------------------------------------------
declare @Lot  as cursor
declare @ActRnum as nvarchar(100)
declare @Actref as nvarchar(100)
declare @Actref1 as nvarchar(100)
declare @tk3 as int
declare @actId as int
declare @parcourir as cursor
declare @id as int
declare @dateop as date
declare @libelle as varchar(200)
declare @credit as numeric(18,3)
declare @debit as numeric(18,3)
declare @idllig1 int
declare @nep as nvarchar(30)
declare @ned as nvarchar(30)
declare @ne as nvarchar(30)
declare @bq_compte as nvarchar(10)
declare @gaccjou_code as nvarchar(50)
declare @Montant as numeric (18,3)
declare @banqueCode as nvarchar(20)
declare @gaccpd_tiers as nvarchar(20)
declare @start as date
declare @end as date
declare @diversys_index as int
declare @BanqueD_MontantBanque as numeric(18,3)
declare @banqued_compte as nvarchar(10)
declare @BanqueD_CompteLib as nvarchar(100)
declare @banqued_montantd as numeric(18,3)
declare @ent_pay as table(id int,gce nvarchar(30) )
declare @cntpay as int
set @Lot = cursor for 
					(	
						select * from(
						select  top 1 case when reg_ref like'f13%' or reg_ref like 'f14%'  then left(reg_ref,7) else left(reg_ref,7) end as ref ,
						case when reg_ref1 like'f13%' or reg_ref1 like 'f14%'  then left(reg_ref1,7) else left(reg_ref1,7) end as ref1 
						,reg_num,Reg_Montant as Montant,Tiers_Code,reg_banque,Reg_DateReglement as DateReglement,Reg_DateEcheance as Echeance
						from reglement
						inner join GaccExercice 
							on year(reg_datereglement) =GaccExercice.GaccEx_Code 	
						
						 where RegParam_Code in ('rbf') and  Reg_RegCpt=0 and year(reg_dateecheance)>=2020 and reg_banque like '%atb%' and (reg_ref is not null or reg_ref1 is not null)
						 order by Reg_DateReglement
						 )as T
					 )


open @Lot
FETCH NEXT FROM @Lot INTO @Actref,@Actref1,@ActRnum,@montant,@gaccpd_tiers,@banquecode,@start,@end
WHILE @@FETCH_STATUS = 0    
	begin

	

		if @actref is null
		begin
			select @actref=@actref1
		end
		select @actref=replace(@actref,'t','')
		select @actref1=replace(@actref1,'t','')
		select @actref,@actref,'*-*-*-*-'
		select @tk3=count(*)  from @correction cr
		inner join Reglement reg
		on (replace(left(reg.reg_ref,7),'t','')=left(cr.ref,6) or replace(left(reg.reg_ref,7),'t','')=left(cr.ref,6))
		and reg.reg_montant=(select credit+debit from xrelevehistorique where idllig=cr.idllig and cr.libelle like '%deblo%')
		and cast(reg.Reg_DateReglement  as date) =cast((select date_opr from xrelevehistorique where idllig=cr.idllig and cr.libelle like '%deblo%') as date)
		where reg.Reg_Num=@ActRnum
		if @tk3=0
		begin
			select @actId=cr.id from @correction cr
			inner join Reglement reg
			on (replace(left(reg.reg_ref,7),'t','')=left(cr.ref,6) or replace(left(reg.reg_ref1,7),'t','')=left(cr.ref,6))
			and reg.reg_montant=(select credit+debit from xrelevehistorique where idllig=cr.idllig and cr.libelle like '%deblo%')
			and cast(reg.Date_create as date) between dateadd(day,-30,cast((select date_opr from xrelevehistorique where idllig=cr.idllig and cr.libelle like '%deblo%') as date))
											  and     dateadd(day,30,cast((select date_opr from xrelevehistorique where idllig=cr.idllig and cr.libelle like '%deblo%') as date))
			where reg.Reg_Num=@ActRnum 
		end
		else
		begin
			select @actId=cr.id from @correction cr
			inner join Reglement reg
			on (replace(left(reg.reg_ref,7),'t','')=left(cr.ref,6) or replace(left(reg.reg_ref1,7),'t','')=left(cr.ref,6))
			and reg.reg_montant=(select credit+debit from xrelevehistorique where idllig=cr.idllig and cr.libelle like '%deblo%')
			and cast(reg.Reg_DateReglement  as date) =cast((select date_opr from xrelevehistorique where idllig=cr.idllig and cr.libelle like '%deblo%') as date)
			where reg.Reg_Num=@ActRnum 
		end
		select @ActRnum,'---',@actId
		select @nep='-'
		select @ned='-';
		select @bq_compte=Banque_Compte from banque where banque_code=@banquecode			--Compte de
		select @bq_compte=isnull(@bq_compte, '0000')										--la banque
		select @gaccjou_code=gaccjou_code from banque where banque_code=@banquecode
		
		-- @correction as table(id int,libelle varchar(200),date_opr date,debit numeric(18,3),credit numeric(18,3),banque varchar(20),idllig int,touche int default 0,ref varchar(50))
		select id,libelle,date_opr,debit,credit,idllig from @correction where id=@actId
		set @parcourir =cursor for select id,libelle,date_opr,debit,credit,idllig from @correction where id=@actId
		open @parcourir
		FETCH NEXT FROM @parcourir INTO @id,@libelle,@dateop,@debit,@credit,@idllig1
		WHILE @@FETCH_STATUS = 0

		begin
		
			if @libelle like '%deblo%' or @libelle like '%paiem%princ%'
			begin
			
				update cpt
				set cpt_num=cpt_num+1
				where cpt_doc=(
				select  TOP 1 cpt_doc
				from xReleveHistorique xr 
						inner join Reglement 
							on  rtrim(ltrim(xr.libelle))=rtrim(ltrim(@libelle))
							--and cast(reglement.Reg_DateEcheance as date) <=cast(xr.date_opr as date) --and year(cast(reglement.Reg_DateEcheance as date)) =year(cast(xr.date_opr as date))
							--and xr.valider=0
							and xr.idllig=@idllig1
						inner join GaccExercice 
							on year(xr.date_opr) =GaccExercice.GaccEx_Code 
								and GaccExercice.GaccEx_Etat=1
						inner join banque bq 
							on reglement.Reg_Banque=bq.banque_code
						inner join Cpt 
							on Cpt_Doc=bq.GaccJou_Code +cast(YEAR(xr.date_opr) as nvarchar)+right('00'+cast(MONTH(xr.date_opr) as nvarchar),2)
				where Reglement.Reg_Num  = @ActRnum and rtrim(ltrim(xr.libelle))=rtrim(ltrim(@libelle)) 
				)
				select @ne=cpt_doc+right('0000'+cast( row_number() over(partition by gaccjou_code, year(date_opr),month(date_opr) order by gaccjou_code,date_opr)	+	cpt_num+1 as nvarchar),4)--,@credit=xr.credit,@debit=xr.debit
				--select @ne=dbo.fn_CptJournal(@start,bq.GaccJou_Code)
				from  Reglement
						inner join  xrelevehistorique xr
							on rtrim(ltrim(xr.libelle))=rtrim(ltrim(@libelle))
							--and xr.valider=0
							and xr.idllig=@idllig1
							--and cast(Reglement.Reg_DateEcheance as date) <=cast(xr.date_opr as date)-- and year(cast(reglement.Reg_DateEcheance as date)) =year(cast(xr.date_opr as date))
						inner join GaccExercice 
							on year(xr.date_opr) =GaccExercice.GaccEx_Code 
								and GaccExercice.GaccEx_Etat=1
						inner join banque bq 
							on reglement.Reg_Banque=bq.banque_code
						inner join Cpt 
							on Cpt_Doc=bq.GaccJou_Code +cast(YEAR(xr.date_opr) as nvarchar)+right('00'+cast(MONTH(xr.date_opr) as nvarchar),2)
				where Reglement.Reg_Num  =@ActRnum and rtrim(ltrim(xr.libelle))=rtrim(ltrim(@libelle))
				select @libelle,@ne
				----------------------------------------------------------------En t�tes------------------------------------------------------
				--select '----entete----'
				--insert into  [dbo].[GaccPE] (
				--GaccPE_Num, GaccPE_Date, GaccJou_Code, GaccPE_User, Devise_Code,  GaccPE_Total, GaccPE_Libelle, GaccEx_Code, Doc_Num, GaccPE_Statut, GaccPE_DateCreate)
	
				SELECT @ne as gaccpe_num,
				date_opr,gaccjou_code,'RapAuto' as utilisateur,Banque_Devise,	debit+Credit as gaccpe_total,
				'Financement Stock'+ ' / -Montant reg- ' +convert(nvarchar(20),(Reglement.Reg_Montant)) +' / du: '+convert(nvarchar(20),(Reglement.Reg_DateReglement),103),
				year(date_opr),reglement.Reg_Num,0,getdate()
				from  Reglement
					inner join  xrelevehistorique xr
						on rtrim(ltrim(xr.libelle))=rtrim(ltrim(@libelle))
						--and xr.valider=0
						and xr.idllig=@idllig1
						--and cast(Reglement.Reg_DateEcheance as date) <=cast(xr.date_opr as date)-- and year(cast(reglement.Reg_DateEcheance as date)) =year(cast(xr.date_opr as date))
					inner join GaccExercice 
						on year(xr.date_opr) =GaccExercice.GaccEx_Code 
							and GaccExercice.GaccEx_Etat=1
					inner join banque bq 
						on reglement.Reg_Banque=bq.banque_code
					inner join Cpt 
						on Cpt_Doc=bq.GaccJou_Code +cast(YEAR(xr.date_opr) as nvarchar)+right('00'+cast(MONTH(xr.date_opr) as nvarchar),2)
				where Reglement.Reg_Num  =@ActRnum and rtrim(ltrim(xr.libelle))=rtrim(ltrim(@libelle))
			end
			if @libelle like '%deblo%' begin select @ned=@ne end
			if @libelle like '%paiem%eff%princ%' begin
			
			 select @nep=@ne 
			 select @cntpay=count(*) from @ent_pay
			 insert into @ent_pay values (@cntpay,@nep)
			 select 'pay',* from @ent_pay
			end
			if @libelle like '%deblo%'
			begin
			select '----details deblocage----'
			---------------------------------------------------------------------D�blocage credit-------------------------------------------------------------------------------------------
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
					---------------------------------------------------------------------D�blocage debit-------------------------------------------------------------------------------------------
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

			if @libelle like '%paiement%princ%'
			begin
			select '----details paiement----'
			---------------------------------------------------------------------Paiement debit-------------------------------------------------------------------------------------------
					 --insert into GaccPD( GaccPE_Num, GaccCpt_Num, GaccPD_Libelle,GaccPD_Coll,  GaccPD_Debit, GaccPD_Credit,GaccPD_DebitDevise, GaccPD_CreditDevise, 
					 --gaccpd_tiers,GaccPD_Ref,  Devise_Code, Devise_Cours, GaccPD_Date, GaccPD_Jou, GaccPD_Echeance, GaccEx_Code,  GaccPD_Doc_Num,GaccPD_ref2,gaccb_rb)
		
					SELECT distinct (select gce from @ent_pay where id=(select max(id) from @ent_pay)),
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
					SELECT distinct (select gce from @ent_pay where id=(select max(id) from @ent_pay)),
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
				--delete from @ent_pay where id=(select min(id) from @ent_pay) 
			end

			FETCH NEXT FROM @parcourir INTO @id,@libelle,@dateop,@debit,@credit,@idllig1
		end
		CLOSE @parcourir; 
		open @parcourir
		FETCH NEXT FROM @parcourir INTO @id,@libelle,@dateop,@debit,@credit,@idllig1
		WHILE @@FETCH_STATUS = 0
		begin
			
			--if ((@libelle not like '%paiem%princ%') and (@libelle like '%deblo%'))
			--begin
			select @libelle
				--select @id,@dateop,@libelle,@credit,@debit,@idllig,@valider
				if @libelle like '%Inter%ts%' begin select @diversys_index=23 end
				if @libelle like '%TVA%' begin select @diversys_index=22 end
				if @libelle like '%Comm Imp effet Prin%' begin select @diversys_index=21 end
				-- else begin select @diversys_index=0 end
				select @BanqueD_MontantBanque=@credit+@debit
				--select @diversys_index=min(DiverSys_index) from diversys where charindex(ltrim(rtrim( @libelle)) , ltrim(rtrim(diversys_libelle)))>0 and diversys_type like '%f016%'
	
				select @banqued_compte=banqued_compte from banqued where banqued_originenum like '%'+@Actrnum+'%' and banqued_type=@diversys_index --and Banque_Nature not like '%ttc%' 
				select @BanqueD_CompteLib=BanqueD_CompteLib from banqued where banqued_originenum like '%'+@Actrnum+'%' and banqued_type=@diversys_index --and Banque_Nature not like '%ttc%' 
				select @banqued_montantd=banqued_montantd from banqued where banqued_originenum like '%'+@Actrnum+'%' and banqued_type=@diversys_index --and Banque_Nature not like '%ttc%' 

				if @libelle like '%Inter%ts%' --and @banqued_montantd>0
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

				if @libelle like '%Comm Imp effet Prin%' --and @banqued_montantd>0
				begin
					--select @BanqueD_MontantBanque=@BanqueD_MontantBanque/1.19
					--insert into GaccPD (GaccPE_Num,GaccCpt_Num ,GaccPD_Libelle,GaccPD_Debit,GaccPD_Credit,GaccPD_DebitDevise,GaccPD_CreditDevise,GaccPD_Ref,GaccB_RB,gaccpd_jou,GaccPD_Echeance)
					select (select gce from @ent_pay where id=(select min(id) from @ent_pay)) ,@banqued_compte  ,@BanqueD_CompteLib,@banqued_montantd as debit,0 as credit,@banqued_montantd as debitdevise,
					0 as creditdevise,@ActRnum,null,null ,@dateop	
					union all
					select (select gce from @ent_pay where id=(select min(id) from @ent_pay)) ,@bq_compte ,@BanqueD_CompteLib,0 as debit,@BanqueD_MontantBanque as credit,
					0 as debitdevise,@BanqueD_MontantBanque as creditdevise,
					@ActRnum,'RELEVE '+CAST(RIGHT('00' + CAST(MONTH(@dateop) AS nvarchar(2)), 2) AS varchar(10))+'/'+ CAST(YEAR(@dateop) as nvarchar(4)),
					@gaccjou_code ,@dateop
		 
					 if abs(@banqued_montantd-@BanqueD_MontantBanque)>0
					 begin
						 --insert into GaccPD (GaccPE_Num,GaccCpt_Num ,GaccPD_Libelle,GaccPD_Debit,GaccPD_Credit,GaccPD_DebitDevise,GaccPD_CreditDevise,GaccPD_Ref,GaccB_RB,gaccpd_jou,GaccPD_Echeance)
						select (select gce from @ent_pay where id=(select min(id) from @ent_pay)) ,
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
				end
				if @libelle like '%tva%' --and @banqued_montantd>0
				begin		
					--insert into GaccPD (GaccPE_Num,GaccCpt_Num ,GaccPD_Libelle,GaccPD_Debit,GaccPD_Credit,GaccPD_DebitDevise,GaccPD_CreditDevise,GaccPD_Ref,GaccB_RB,gaccpd_jou,GaccPD_Echeance)
					select (select gce from @ent_pay where id=(select min(id) from @ent_pay)) ,'43660018' ,'TVA Sur Com',@banqued_montantd*0.19 as debit,0 as credit,@banqued_montantd*0.19 as debitdevise,
					0 as creditdevise,@ActRnum,null,null ,@dateop	
					union all
					select (select gce from @ent_pay where id=(select min(id) from @ent_pay)) ,@bq_compte ,'TVA Sur Com',0 as debit,@BanqueD_MontantBanque*0.19 as credit,
					0 as debitdevise,@BanqueD_MontantBanque*0.19 as creditdevise,
					@ActRnum,'RELEVE '+CAST(RIGHT('00' + CAST(MONTH(@dateop) AS nvarchar(2)), 2) AS varchar(10))+'/'+ CAST(YEAR(@dateop) as nvarchar(4)),
					@gaccjou_code ,@dateop
					update xrelevehistorique
						set valider=1
						where idllig =@idllig
				end
			--end
FETCH NEXT FROM @parcourir INTO @id,@libelle,@dateop,@debit,@credit,@idllig1
end



























--update reglement

--set reg_regcpt=2
--where reg_num=@ActRnum







		FETCH NEXT FROM @Lot INTO @Actref,@Actref1,@ActRnum,@montant,@gaccpd_tiers,@banquecode,@start,@end


	end








--------------------------------------------------------------------------------
--select cr.id,cr.libelle,cr.ref,cr.date_opr,cr.credit+cr.debit as mt,cr.banque from @correction cr
--inner join Reglement reg
--on (left(reg.reg_ref,7)=cr.ref or left(reg.reg_ref1,7)=cr.ref)
--and reg.reg_montant=(select credit+debit from xrelevehistorique where idllig=cr.idllig and cr.libelle like '%deblo%')
--and cast(reg.Date_create as date) <=cast((select date_opr from xrelevehistorique where idllig=cr.idllig and cr.libelle like '%deblo%') as date)
--where reg.Reg_Num in (select Reg_Num
--from Reglement

--where RegParam_Code in ('rbf')  and year(reg_dateecheance)>=2020 and (reg_ref is not null or reg_ref1 is not null)
-- and reg_banque like '%atb%')





