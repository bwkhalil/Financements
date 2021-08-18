USE volteqplus
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--ALTER PROCEDURE [dbo].[RappCommissionRBF]  
--AS 

declare @Lot  as cursor
declare @ActRnum as nvarchar(100)
declare @Actref as nvarchar(100)
declare @Actref1 as nvarchar(100)



set @Lot = cursor for 
					(
				
					
						select case when reg_ref like'f13%' or reg_ref like 'f14%'  then left(reg_ref,7) else right(reg_ref,7) end ,
						case when reg_ref1 like'f13%' or reg_ref1 like 'f14%'  then left(reg_ref1,7) else right(reg_ref1,7) end 
					,reg_num
						from reglement
						--inner join GaccExercice 
						--	on year(reg_datereglement) =GaccExercice.GaccEx_Code 	

						 where RegParam_Code in ('rbf')and reg_num  in ('RF19Tra238') --and  Reg_RegCpt=0 and year(reg_dateecheance)>=2020 and reg_banque like '%biat%' and (reg_ref is not null or reg_ref1 is not null)
					 )


open @Lot
FETCH NEXT FROM @Lot INTO @Actref,@Actref1,@ActRnum

WHILE @@FETCH_STATUS = 0    
	begin



	if @actref is null
	begin
	select @actref=@actref1
	end

	

declare @CR  as cursor
---------Règlement-------------------------
declare @Reg_Num as nvarchar(100)
declare @Reg_Ref as nvarchar(100)
declare @start as date --Date de déblocage
declare @end as date   --Date d'échéance
declare @reg_montant as numeric(18,3)
declare @banqueCode as nvarchar(20)
---------Relevé----------------------------
declare @Date_opr as date
declare @Libelle as nvarchar(200)
declare @Num_piece as nvarchar(7)
declare @Debit as decimal(18,3)
declare @Credit as decimal(18,3)
declare @Reference as nvarchar(16)
declare @idllig as int
--------Diversys---------------------------
declare @diversys_index as int
--------BanqueD----------------------------
declare @banqued_compte as nvarchar(10)
declare @BanqueD_CompteLib as nvarchar(100)
declare @banqued_montantd as numeric(18,3)
--------Banque-----------------------------
declare @bq_compte as nvarchar(10)
declare @gaccjou_code as nvarchar(50)
--------Variables--------------------------
declare @pay as int
declare @total as numeric(18,3)
declare @nbb as int
--------GaccPE-----------------------------
declare @ne as nvarchar(30)
declare @gaccpd_tiers as nvarchar(20)
--------Table------------------------------
DECLARE @gaccNums TABLE (id int,type_op varchar (30),dateOp date,dateEch date,numGce nvarchar(30),debt numeric(18,3),cred numeric(18,3),bcpt nvarchar(10),dsInd int,cbptlib nvarchar(100),bqmntd numeric(18,3),idl int )
--------Initialisation---------------------
select @pay=0
declare @cntt as int
				select @cntt=0
select @total=0
select @reg_montant=reg_montant from reglement where reg_num =@ActRnum			--Montant total
select @reg_ref=reg_ref from reglement where reg_num =@ActRnum					--Référence du règlement
select @gaccpd_tiers=Tiers_Code from reglement where reg_num =@ActRnum	--Tiers code
select @start= reg_datereglement from reglement where reg_num =@ActRnum			--Date de règlement
select @end= Reg_DateEcheance from reglement where reg_num =@ActRnum			--Date d'échéance
select @banquecode=reg_banque from reglement where reg_num =@ActRnum			--Code de la banque
select @bq_compte=Banque_Compte from banque where banque_code=@banquecode			--Compte de
select @bq_compte=isnull(@bq_compte, '0000')										--la banque
select @gaccjou_code=gaccjou_code from banque where banque_code=@banquecode
select @start,@end,@reg_montant
select '--'+@ActRnum+'-----------------------------------------'
set @CR = CURSOR LOCAL FAST_FORWARD  for (
	select  date_opr,reference,libelle,debit,credit,num_piece,idllig from (
		select top 100 xr.*
		from xrelevehistorique xr
		where
		xr.Valider=0  and xr.libelle not like '%retard%'  and
		
		 (right(ltrim(rtrim(xr.num_piece)),7) like right(rtrim(ltrim(@ActRef)),7) )or (right(ltrim(rtrim(xr.reference)),7) like right(rtrim(ltrim(@ActRef)),7)) 			
		and xr.date_opr>=@start 
			
			

		order by xr.date_opr asc
	) as T
)
select @nbb=0
open @CR
FETCH NEXT FROM @CR INTO @date_opr,@reference,@libelle,@debit,@credit,@num_piece,@idllig
delete from @gaccNums
WHILE @@FETCH_STATUS = 0    
	begin
	
		if ( @date_opr>=@end  ) or @pay=0
		begin
			if  @libelle like '%paiement%princi%'
			begin			
				if @Date_opr>=@end
				begin	
					select @nbb=@nbb+1		
					select @total=@total+@debit+@Credit
					--select '---------------------'+cast(@idllig as varchar(10))+'--------------------------------------En-tete paiement '+@Actrnum+'-------'+@Actref+'----------------------------------------------------------------------------------------------------------------'
					update cpt
					set cpt_num=cpt_num+1
					where cpt_doc=(
					select  TOP 1 cpt_doc
					from xReleveHistorique xr 
							inner join Reglement 
								on  xr.Libelle  like '%paiement%princi%' 
								and ((rtrim(ltrim(reglement.reg_ref)) like '%'+rtrim(ltrim(xr.reference))+'%' or rtrim(ltrim(reglement.reg_ref1)) like '%'+rtrim(ltrim(xr.reference))+'%')
							 or							 
								(rtrim(ltrim(reglement.reg_ref)) like '%'+rtrim(ltrim(xr.Num_piece))+'%' or rtrim(ltrim(reglement.reg_ref1)) like '%'+rtrim(ltrim(xr.Num_piece))+'%'))
								and xr.idllig =@idllig
								--and cast(reglement.Reg_DateEcheance as date) <=cast(xr.date_opr as date) --and year(cast(reglement.Reg_DateEcheance as date)) =year(cast(xr.date_opr as date))
								and xr.valider=0
							inner join GaccExercice 
								on year(date_opr) =GaccExercice.GaccEx_Code 
									and GaccExercice.GaccEx_Etat=1
							inner join banque bq 
								on reglement.Reg_Banque=bq.banque_code
							inner join Cpt 
								on Cpt_Doc=bq.GaccJou_Code +cast(YEAR(date_opr) as nvarchar)+right('00'+cast(MONTH(date_opr) as nvarchar),2)
					where Reglement.Reg_Num  = @ActRnum and xr.Libelle  like '%paiement%princi%' and Reglement.Reg_Ref like '%'+@Actref+'%'    )
					
					--select @ne=cpt_doc+right('0000'+cast( row_number() over(partition by gaccjou_code, year(date_opr),month(date_opr) order by gaccjou_code,date_opr)	+	cpt_num as nvarchar),4),@credit=xr.credit,@debit=xr.debit					
					
					select @ne=dbo.fn_CptJournal(Date_Opr,bq.GaccJou_Code),@credit=xr.credit,@debit=xr.debit
					
					from  Reglement
						inner join  xReleveHistorique xr
							on xr.Libelle  like '%paiement%princi%' 
							 and ((rtrim(ltrim(reglement.reg_ref)) like '%'+rtrim(ltrim(xr.reference))+'%' or rtrim(ltrim(reglement.reg_ref1)) like '%'+rtrim(ltrim(xr.reference))+'%')
							 or
							 
							 (rtrim(ltrim(reglement.reg_ref)) like '%'+rtrim(ltrim(xr.Num_piece))+'%' or rtrim(ltrim(reglement.reg_ref1)) like '%'+rtrim(ltrim(xr.Num_piece))+'%'))
							and xr.idllig =@idllig
							and xr.valider=0
							--and cast(Reglement.Reg_DateEcheance as date) <=cast(xr.date_opr as date)-- and year(cast(reglement.Reg_DateEcheance as date)) =year(cast(xr.date_opr as date))
						inner join GaccExercice 
							on year(date_opr) =GaccExercice.GaccEx_Code 
								and GaccExercice.GaccEx_Etat=1
						inner join banque bq 
							on reglement.Reg_Banque=bq.banque_code
						inner join Cpt 
							on Cpt_Doc=bq.GaccJou_Code +cast(YEAR(date_opr) as nvarchar)+right('00'+cast(MONTH(date_opr) as nvarchar),2)
					where Reglement.Reg_Num  =@ActRnum and xr.Libelle  like '%paiement%princi%' and Reglement.Reg_Ref like '%'+@Actref+'%' 
					-----------------------------------------------------------En-tete paiement RF20Tr051-------0526691----------------------------------------------------------------------------------------------------------------
					
					-------------------------------------------------------------------------------------------------
					if @pay=0
					begin
					insert into @gaccNums values(@nbb,'paiement',@date_opr,@end,@ne,@debit,@credit,'',0,'',0,@idllig)
					end
					-------------------------------------------------------------------------------------------------
					--select '-----------------------------------insertion de l"entete--------------------------------------'
					insert into  [dbo].[GaccPE] (
					GaccPE_Num, GaccPE_Date, GaccJou_Code, GaccPE_User, Devise_Code,  GaccPE_Total, GaccPE_Libelle, GaccEx_Code, Doc_Num, GaccPE_Statut, GaccPE_DateCreate)
					--select 'paiement'
					SELECT @ne as gaccpe_num,
					date_opr,gaccjou_code,'RapAuto' as utilisateur,Banque_Devise,	debit+Credit as gaccpe_total,
					'Financement Stock'+ ' / -Montant reg- ' +convert(nvarchar(20),(Reglement.Reg_Montant)) +' / du: '+convert(nvarchar(20),(Reglement.Reg_DateReglement),103),
					year(date_opr),reglement.Reg_Num,0,getdate()
					from  Reglement
						inner join  xReleveHistorique xr
							on xr.Libelle  like '%paiement%princi%' 
							 and ((rtrim(ltrim(reglement.reg_ref)) like '%'+rtrim(ltrim(xr.reference))+'%' or rtrim(ltrim(reglement.reg_ref1)) like '%'+rtrim(ltrim(xr.reference))+'%')
							 or
							 
							 (rtrim(ltrim(reglement.reg_ref)) like '%'+rtrim(ltrim(xr.Num_piece))+'%' or rtrim(ltrim(reglement.reg_ref1)) like '%'+rtrim(ltrim(xr.Num_piece))+'%'))
							and xr.idllig =@idllig
							and xr.valider=0
							--and cast(Reglement.Reg_DateEcheance as date) <=cast(xr.date_opr as date)-- and year(cast(reglement.Reg_DateEcheance as date)) =year(cast(xr.date_opr as date))
						inner join GaccExercice 
							on year(date_opr) =GaccExercice.GaccEx_Code 
								and GaccExercice.GaccEx_Etat=1
						inner join banque bq 
							on reglement.Reg_Banque=bq.banque_code
						inner join Cpt 
							on Cpt_Doc=bq.GaccJou_Code +cast(YEAR(date_opr) as nvarchar)+right('00'+cast(MONTH(date_opr) as nvarchar),2)
					where Reglement.Reg_Num  =@ActRnum and xr.Libelle  like '%paiement%princi%' and Reglement.Reg_Ref like '%'+@Actref+'%' 
					
					if cast(@total as numeric(18,3))=cast(@reg_montant as numeric(18,3))
					begin
						select @pay=1					
					end
				end	

		    end
			else
			begin
			    --select @pay,@Date_opr,@end,@Libelle,'-*-*-*-*-*--***--*-*-*'
				
			
					select @cntt = count(*) from @gaccNums where charindex(type_op,@libelle)>0
					

				if  @libelle not like '%paiement%princi%' 	and @libelle not like '%inter%' and @libelle not like '%deblo%' and @libelle not like '%redresse%' 
				begin
					select @diversys_index=min(DiverSys_index) from diversys where ltrim(rtrim(diversys_libelle)) like ltrim(rtrim(@libelle)) and diversys_type like '%f016%'
					select @banqued_compte=banqued_compte from banqued where banqued_originenum like '%'+@Actrnum+'%' and banqued_type=@diversys_index 
					select @BanqueD_CompteLib=BanqueD_CompteLib from banqued where banqued_originenum like '%'+@Actrnum+'%' and banqued_type=@diversys_index
					select @banqued_montantd=banqued_montantd from banqued where banqued_originenum like '%'+@Actrnum+'%' and banqued_type=@diversys_index
					--(id int,type_op varchar (30),dateOp date,dateEch date,numGce nvarchar(30),debt numeric(18,3),cred numeric(18,3),bcpt nvarchar(10),dsInd int,cbptlib nvarchar(100),bqmntd numeric(18,3) )
					--select @libelle,@diversys_index,@banqued_compte,@BanqueD_CompteLib,@banqued_montantd
					--------------------------------------------------------------------------------------------------------------------------------------------------------
					if @cntt=0
					begin
					insert into @gaccNums values(-1,@Libelle,@date_opr,@end,'',@debit,@credit,@banqued_compte,@diversys_index,@banqued_comptelib,@banqued_montantd,@idllig)
					end
					--------------------------------------------------------------------------------------------------------------------------------------------------------
				end
				if  @libelle like '%ajuste%'		
				begin
					select @diversys_index=min(DiverSys_index) from diversys where ltrim(rtrim(diversys_libelle)) like ltrim(rtrim(@libelle)) and diversys_type like '%f016%'
					select @banqued_compte=banqued_compte from banqued where banqued_originenum like '%'+@Actrnum+'%' and banqued_type=@diversys_index 
					select @BanqueD_CompteLib=BanqueD_CompteLib from banqued where banqued_originenum like '%'+@Actrnum+'%' and banqued_type=@diversys_index
					select @banqued_montantd=banqued_montantd from banqued where banqued_originenum like '%'+@Actrnum+'%' and banqued_type=@diversys_index
					--(id int,type_op varchar (30),dateOp date,dateEch date,numGce nvarchar(30),debt numeric(18,3),cred numeric(18,3),bcpt nvarchar(10),dsInd int,cbptlib nvarchar(100),bqmntd numeric(18,3) )
					--select @libelle,@diversys_index,@banqued_compte,@BanqueD_CompteLib,@banqued_montantd
					--------------------------------------------------------------------------------------------------------------------------------------------------------
					insert into @gaccNums values(-1,@Libelle,@date_opr,@end,'',@debit,@credit,@banqued_compte,@diversys_index,@banqued_comptelib,@banqued_montantd,@idllig)
					--------------------------------------------------------------------------------------------------------------------------------------------------------
				end

			end
        end
		if (@date_opr<@end)
		begin
			if @libelle like '%deblo%'
			begin
			
				if  @pay=0 and (@date_opr<@end)
				begin
					-----------------------------------------------------------En tete Déblocage1------------------------------------------------------------------
					
					--declare @ne as nvarchar(30)
					--declare @idllig as int
					--declare @Debit as decimal(18,3)
					--declare @Credit as decimal(18,3)
					update cpt
					set cpt_num=cpt_num+1
					where cpt_doc=(
					select  TOP 1 cpt_doc
					from xReleveHistorique xr 
							inner join Reglement 
								on  xr.Libelle  like '%deblocage%'
								and ((rtrim(ltrim(reglement.reg_ref)) like '%'+rtrim(ltrim(xr.reference))+'%' or rtrim(ltrim(reglement.reg_ref1)) like '%'+rtrim(ltrim(xr.reference))+'%')
							 or
							 
							 (rtrim(ltrim(reglement.reg_ref)) like '%'+rtrim(ltrim(xr.Num_piece))+'%' or rtrim(ltrim(reglement.reg_ref1)) like '%'+rtrim(ltrim(xr.Num_piece))+'%'))
								and xr.idllig =@idllig
								--and cast(@start as date) =cast(xr.date_opr as date) --and year(cast(reglement.Reg_DateEcheance as date)) =year(cast(xr.date_opr as date))
								and xr.valider=0
							inner join GaccExercice 
								on year(date_opr) =GaccExercice.GaccEx_Code 
									and GaccExercice.GaccEx_Etat=1
							inner join banque bq 
								on reglement.Reg_Banque=bq.banque_code
							inner join Cpt 
								on Cpt_Doc=bq.GaccJou_Code +cast(YEAR(date_opr) as nvarchar)+right('00'+cast(MONTH(date_opr) as nvarchar),2)
					where Reglement.Reg_Num  =@ActRnum  )
					
					--select @ne=cpt_doc+right('0000'+cast( row_number() over(partition by gaccjou_code, year(date_opr),month(date_opr) order by gaccjou_code,date_opr)	+	cpt_num as nvarchar),4),@credit=xr.credit,@debit=xr.debit
					select @ne=dbo.fn_CptJournal(@start,bq.GaccJou_Code),@credit=xr.credit,@debit=xr.debit
					from Reglement 
						inner join  xReleveHistorique xr 
							on xr.Libelle  like '%deblocage%' and
							 ((rtrim(ltrim(reglement.reg_ref)) like '%'+rtrim(ltrim(xr.reference))+'%' or rtrim(ltrim(reglement.reg_ref1)) like '%'+rtrim(ltrim(xr.reference))+'%')
							 or
							 
							 (rtrim(ltrim(reglement.reg_ref)) like '%'+rtrim(ltrim(xr.Num_piece))+'%' or rtrim(ltrim(reglement.reg_ref1)) like '%'+rtrim(ltrim(xr.Num_piece))+'%'))
							 and xr.idllig =@idllig
							 and xr.valider=0
							-- and cast(@start as date) =cast(xr.date_opr as date)-- or cast(reglement.Reg_DateEcheance as date) >cast(xr.date_opr as date)   --and year(cast(reglement.Reg_DateEcheance as date)) =year(cast(xr.date_opr as date))
						inner join GaccExercice 
							on year(date_opr) =GaccExercice.GaccEx_Code 
								and GaccExercice.GaccEx_Etat=1
						inner join banque bq 
							on reglement.Reg_Banque=bq.banque_code
						inner join Cpt 
							on Cpt_Doc=bq.GaccJou_Code +cast(YEAR(date_opr) as nvarchar)+right('00'+cast(MONTH(date_opr) as nvarchar),2)
					where Reglement.Reg_Num  = @ActRnum and xr.Libelle  like '%deblocage%'  --and Reglement.Reg_Ref like '%'+@Actref+'%'
					
					
					-------------------------------------------------------------------------------------------
					declare @deb as int
					select @deb = count(*) from @gaccNums where type_op ='deblocage'
					if @deb  =0
					begin
					insert into @gaccNums values(@nbb,'deblocage',@date_opr,@end,@ne,@debit,@credit,'',0,'',0,@idllig)
					-------------------------------------------------------------------------------------------
					--select '****************************************************************************'
					--select 'entete deblocage ----------------------------------------'
					insert into  [dbo].[GaccPE] (GaccPE_Num, GaccPE_Date, GaccJou_Code, GaccPE_User, Devise_Code, GaccPE_Total, GaccPE_Libelle, GaccEx_Code, Doc_Num, GaccPE_Statut, GaccPE_DateCreate)		
					--select 'deblocage',@pay,@idllig
					SELECT distinct @ne as gaccpe_num,date_opr,	gaccjou_code,'RapAuto' as utilisateur,
					Banque_Devise,	debit+credit as gaccpe_total,
					'Financement Stock'+ ' / -Montant reg- ' +convert(nvarchar(20),(Reglement.Reg_Montant)) +' / du: '+convert(nvarchar(20),(Reglement.Reg_DateReglement),103),	year(date_opr) as libelle,
					reglement.Reg_Num,	0,getdate()
					from Reglement 
						inner join  xReleveHistorique xr 
							on xr.Libelle  like '%deblocage%' and
							 ((rtrim(ltrim(reglement.reg_ref)) like '%'+rtrim(ltrim(xr.reference))+'%' or rtrim(ltrim(reglement.reg_ref1)) like '%'+rtrim(ltrim(xr.reference))+'%')
							 or
							 
							 (rtrim(ltrim(reglement.reg_ref)) like '%'+rtrim(ltrim(xr.Num_piece))+'%' or rtrim(ltrim(reglement.reg_ref1)) like '%'+rtrim(ltrim(xr.Num_piece))+'%'))
							 and xr.idllig =@idllig
							 and xr.valider=0
							-- and cast(@start as date) =cast(xr.date_opr as date)-- or cast(reglement.Reg_DateEcheance as date) >cast(xr.date_opr as date)   --and year(cast(reglement.Reg_DateEcheance as date)) =year(cast(xr.date_opr as date))
						inner join GaccExercice 
							on year(date_opr) =GaccExercice.GaccEx_Code 
								and GaccExercice.GaccEx_Etat=1
						inner join banque bq 
							on reglement.Reg_Banque=bq.banque_code
						inner join Cpt 
							on Cpt_Doc=bq.GaccJou_Code +cast(YEAR(date_opr) as nvarchar)+right('00'+cast(MONTH(date_opr) as nvarchar),2)
					where Reglement.Reg_Num  =@ActRnum and xr.Libelle  like '%deblocage%' -- and Reglement.Reg_Ref like '%'+@Actref+'%' 
					
				end
				end
			end
			else
			begin
			    --select @pay,@Date_opr,@end,@Libelle,'-*-*-*-*-*--***--*-*-*'
				select @cntt = count(*) from @gaccNums where charindex(type_op,@libelle)>0
				if  @libelle not like '%paiement%princi%'	and @libelle not like '%com%' and @libelle not like '%tva%'
				begin
					select @diversys_index=min(DiverSys_index) from diversys where ltrim(rtrim(diversys_libelle)) like ltrim(rtrim(@libelle)) and diversys_type like '%f016%'
					select @banqued_compte=banqued_compte from banqued where banqued_originenum like '%'+@Actrnum+'%' and banqued_type=@diversys_index 
					select @BanqueD_CompteLib=BanqueD_CompteLib from banqued where banqued_originenum like '%'+@Actrnum+'%' and banqued_type=@diversys_index
					select @banqued_montantd=banqued_montantd from banqued where banqued_originenum like '%'+@Actrnum+'%' and banqued_type=@diversys_index
					--(id int,type_op varchar (30),dateOp date,dateEch date,numGce nvarchar(30),debt numeric(18,3),cred numeric(18,3),bcpt nvarchar(10),dsInd int,cbptlib nvarchar(100),bqmntd numeric(18,3) )
					--select @libelle,@diversys_index,@banqued_compte,@BanqueD_CompteLib,@banqued_montantd
					--------------------------------------------------------------------------------------------------------------------------------------------------------
					if @cntt=0
					begin
					insert into @gaccNums values(-1,@Libelle,@date_opr,@end,'',@debit,@credit,@banqued_compte,@diversys_index,@banqued_comptelib,@banqued_montantd,@idllig)
					end
					
					--------------------------------------------------------------------------------------------------------------------------------------------------------
				end
			end
		end 
			
	FETCH NEXT FROM @CR INTO @date_opr,@reference,@libelle,@debit,@credit,@num_piece,@idllig
	end
	CLOSE @CR; 
	DEALLOCATE @CR;
	select *
	from @gaccNums


	---------------------------------------Détails  ---------------------------------------------------------------------------------
declare @CR1  as cursor
declare @typeOp as varchar(30)
declare @Id as int
declare @dateOp as date
declare @dateEch as date
declare @numCe as nvarchar(30)
declare @debt as numeric(18,3)
declare @cred as numeric(18,3)
declare @bcpt as nvarchar(10)
declare @dsInd as int
declare @bcptlib as nvarchar(100)
declare @bqmntd as numeric(18,3)
declare @idlg as int
declare @BanqueD_MontantBanque as numeric(18,3)
-------Initialisation--------------------------------
set @CR1 = CURSOR LOCAL FAST_FORWARD  for (
select id ,type_op ,dateOp ,dateEch ,numGce ,debt ,cred ,bcpt ,dsInd ,cbptlib ,bqmntd  ,idl
from @gaccNums
)

open @CR1
FETCH NEXT FROM @CR1 INTO @Id,@typeop,@dateop,@dateech,@numce,@debt,@cred,@bcpt,@dsind,@bcptlib,@bqmntd,@idlg
WHILE @@FETCH_STATUS = 0   
begin
update xrelevehistorique 
set valider=1,
piece=@ActRnum
where idllig like @idlg
	if @typeop like 'paiement' and @typeop not like '%inter%'
	begin
		---------------------------------------------------------------------Paiement debit-------------------------------------------------------------------------------------------
		 insert into GaccPD( GaccPE_Num, GaccCpt_Num, GaccPD_Libelle,GaccPD_Coll,  GaccPD_Debit, GaccPD_Credit,GaccPD_DebitDevise, GaccPD_CreditDevise, 
		 gaccpd_tiers,GaccPD_Ref,  Devise_Code, Devise_Cours, GaccPD_Date, GaccPD_Jou, GaccPD_Echeance, GaccEx_Code,  GaccPD_Doc_Num,GaccPD_ref2,gaccb_rb)
		SELECT distinct @numce,
		'50100001' AS GaccCpt_Num ,
		'Financement Stock'+ ' / -Montant reg- ' +convert(nvarchar(20),(@reg_montant)) +' / du: '+convert(nvarchar(20),(@start),103)  as GaccPD_Libelle,
		'' as GaccPD_Coll,
		
		CAST((@cred+@debt) as numeric(18,3)) as GaccPD_Debit,
		0 as  GaccPD_Credit,
		
		CAST((@cred+@debt) as numeric(18,3))  as  GaccPD_DebitDevise,
		0 as GaccPD_CreditDevise,
		@GaccPD_Tiers AS GaccPD_Tiers,
		@ActRnum,
		'TND',
		1,
		@dateop,
		'',
		@dateech,
		YEAR(@dateech),
		null,
		null,
		null
		---------------------------------------------------------------------Paiement credit-------------------------------------------------------------------------------------------
		insert into GaccPD( GaccPE_Num, GaccCpt_Num, GaccPD_Libelle,GaccPD_Coll,  GaccPD_Debit, GaccPD_Credit,GaccPD_DebitDevise,GaccPD_CreditDevise,  
		gaccpd_tiers,GaccPD_Ref,  Devise_Code, Devise_Cours, GaccPD_Date, GaccPD_Jou, GaccPD_Echeance, GaccEx_Code,  GaccPD_Doc_Num,GaccPD_ref2,gaccb_rb)
		SELECT distinct @numce,
		@bq_compte AS GaccCpt_Num ,
		'Financement Stock'+ ' / -Montant reg- ' +convert(nvarchar(20),(@reg_montant)) +' / du: '+convert(nvarchar(20),(@start),103)  as GaccPD_Libelle,
		'' as GaccPD_Coll,
		0 as  GaccPD_Debit,
		CAST((@cred+@debt) as numeric(18,3)) as GaccPD_Credit,
		0 as  GaccPD_DebitDevise,
		CAST((@cred+@debt) as numeric(18,3)) as GaccPD_CreditDevise,
		@GaccPD_Tiers AS GaccPD_Tiers,
		@ActRnum,
		'TND',
		1,
		@dateop,
		'',
		@dateech,
		YEAR(@dateech),
		null,
		null,
		'RELEVE '+CAST(RIGHT('00' + CAST(MONTH(@dateop) AS nvarchar(2)), 2) AS varchar(10))+'/'+ CAST(YEAR(@dateop) as nvarchar(4))
	end
	if @typeop like 'deblocage'
	begin
		---------------------------------------------------------------------Déblocage credit-------------------------------------------------------------------------------------------
		insert into GaccPD( GaccPE_Num, GaccCpt_Num, GaccPD_Libelle,GaccPD_Coll,  GaccPD_Debit, GaccPD_Credit, GaccPD_DebitDevise,GaccPD_CreditDevise,
		gaccpd_tiers,GaccPD_Ref,  Devise_Code, Devise_Cours, GaccPD_Date, GaccPD_Jou, GaccPD_Echeance, GaccEx_Code,  GaccPD_Doc_Num,GaccPD_ref2,gaccb_rb)
		
		
		SELECT distinct @numce,
		@bq_compte AS GaccCpt_Num ,
		'Financement Stock'+ ' / -Montant reg- ' +convert(nvarchar(20),(@reg_montant)) +' / du: '+convert(nvarchar(20),(@start),103)  as GaccPD_Libelle,
		'' as GaccPD_Coll,
		@debt+@cred as GaccPD_Debit,
		0 as GaccPD_Credit,
		@debt+@cred as GaccPD_DebitDevise,
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
		insert into GaccPD( GaccPE_Num, GaccCpt_Num, GaccPD_Libelle,GaccPD_Coll,  GaccPD_Debit, GaccPD_Credit,GaccPD_DebitDevise, GaccPD_CreditDevise,
		gaccpd_tiers,GaccPD_Ref,  Devise_Code, Devise_Cours, GaccPD_Date, GaccPD_Jou, GaccPD_Echeance, GaccEx_Code,  GaccPD_Doc_Num,GaccPD_ref2,gaccb_rb)
		SELECT distinct @numce,
		'50100001' AS GaccCpt_Num ,
		'Financement Stock'+ ' / -Montant reg- ' +convert(nvarchar(20),(@reg_montant)) +' / du: '+convert(nvarchar(20),(@start),103)  as GaccPD_Libelle,
		null as GaccPD_Coll,
		0 as GaccPD_Debit,
		@debt+@cred as GaccPD_Credit,
		0 as GaccPD_DebitDevise,
		@debt+@cred as GaccPD_CreditDevise,	
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
	end
	if (@typeop like '%comm%' and @typeop not like '%tva%') or @typeop like '%tva%'
	begin
	    select @BanqueD_MontantBanque=BanqueD_MontantBanque from banqued where banqued_type=@dsind and banqued_originenum like '%'+@Actrnum+'%'

		insert into GaccPD (GaccPE_Num,GaccCpt_Num ,GaccPD_Libelle,GaccPD_Debit,GaccPD_Credit,GaccPD_DebitDevise,GaccPD_CreditDevise,GaccPD_Ref,GaccB_RB,gaccpd_jou,GaccPD_Echeance)
		
		select (select numGce from @gaccnums where type_op='paiement' and id =(select min(id) from @gaccnums where type_op='paiement'))
		,@bcpt  ,@bcptlib,@bqmntd as debit,0 as credit,@bqmntd as debitdevise,0 as creditdevise,@Reg_Ref,null,null ,@dateop
		
		union all

		select (select numGce from @gaccnums where type_op='paiement' and id =(select min(id) from @gaccnums where type_op='paiement'))
		,@bq_compte  ,@bcptlib,0 as debit,@BanqueD_MontantBanque as credit,0 as debitdevise,@BanqueD_MontantBanque as creditdevise,
	     @Reg_Ref,'RELEVE '+CAST(RIGHT('00' + CAST(MONTH(@dateop) AS nvarchar(2)), 2) AS varchar(10))+'/'+ CAST(YEAR(@dateop) as nvarchar(4)),
	     @gaccjou_code ,@dateop

		
		--select '------------',@typeop,@bqmntd,@BanqueD_MontantBanque
			
		 if abs(@bqmntd-@BanqueD_MontantBanque)>0
		 begin
		 insert into GaccPD (GaccPE_Num,GaccCpt_Num ,GaccPD_Libelle,GaccPD_Debit,GaccPD_Credit,GaccPD_DebitDevise,GaccPD_CreditDevise,GaccPD_Ref,GaccB_RB,gaccpd_jou,GaccPD_Echeance)
			select (select numGce from @gaccnums where type_op='paiement' and id =(select min(id) from @gaccnums where type_op='paiement')),
			case  
				when @typeop like '%inter%' then '65160109'
				when @typeop like '%comm%' then '62799015'
			end
			
			,case  
				when @typeop like '%inter%' then 'ECART INTERET SUR FIN DE STOCK'
				when @typeop like '%comm%' then 'ECART - COMMISSION FIN DE STOCK'
			end
			,
			case when (@bqmntd-@BanqueD_MontantBanque) < 0 then abs((@bqmntd-@BanqueD_MontantBanque)) else 0 end as debit,
			case when (@bqmntd-@BanqueD_MontantBanque) > 0 then abs((@bqmntd-@BanqueD_MontantBanque)) else 0 end as credit,
			case when (@bqmntd-@BanqueD_MontantBanque) < 0 then abs((@bqmntd-@BanqueD_MontantBanque)) else 0 end as debitdevise,
			case when (@bqmntd-@BanqueD_MontantBanque) > 0 then abs((@bqmntd-@BanqueD_MontantBanque)) else 0 end as creditdevise,
			@Reg_Ref,null,null ,@dateop
		
		end
		 


	end
	if (@typeop like '%interê%' or @typeop like '%inter%') and @typeop not like '%ajustement%' and @bqmntd>0
	begin
		select @BanqueD_MontantBanque=BanqueD_MontantBanque from banqued where banqued_type=@dsind and banqued_originenum like '%'+@Actrnum+'%'
		
		insert into GaccPD (GaccPE_Num,GaccCpt_Num ,GaccPD_Libelle,GaccPD_Debit,GaccPD_Credit,GaccPD_DebitDevise,GaccPD_CreditDevise,GaccPD_Ref,GaccB_RB,gaccpd_jou,GaccPD_Echeance)
		select (select numGce from @gaccnums where type_op='deblocage')
		,@bcpt  ,@bcptlib,@bqmntd as debit,0 as credit,@bqmntd as debitdevise,0 as creditdevise,@Reg_Ref,null,null ,@dateop	
		union all
		select (select numGce from @gaccnums where type_op='deblocage')
		,@bq_compte  ,@bcptlib,0 as debit,@BanqueD_MontantBanque as credit,0 as debitdevise,@BanqueD_MontantBanque as creditdevise,
	     @Reg_Ref,'RELEVE '+CAST(RIGHT('00' + CAST(MONTH(@dateop) AS nvarchar(2)), 2) AS varchar(10))+'/'+ CAST(YEAR(@dateop) as nvarchar(4)),
	     @gaccjou_code ,@dateop
		 
		 if abs(@bqmntd-@BanqueD_MontantBanque)>0
		 begin
		 insert into GaccPD (GaccPE_Num,GaccCpt_Num ,GaccPD_Libelle,GaccPD_Debit,GaccPD_Credit,GaccPD_DebitDevise,GaccPD_CreditDevise,GaccPD_Ref,GaccB_RB,gaccpd_jou,GaccPD_Echeance)
		select (select numGce from @gaccnums where type_op='deblocage'),
		case  
			when @typeop like '%inter%' then '65160109'
			when @typeop like '%comm%' then '62799015'
		end
			
		,case  
			when @typeop like '%inter%' then 'ECART INTERET SUR FIN DE STOCK'
			when @typeop like '%comm%' then 'ECART - COMMISSION FIN DE STOCK'
		end
		,
		case when (@bqmntd-@BanqueD_MontantBanque) < 0 then abs((@bqmntd-@BanqueD_MontantBanque)) else 0 end as debit,
		case when (@bqmntd-@BanqueD_MontantBanque) > 0 then abs((@bqmntd-@BanqueD_MontantBanque)) else 0 end as credit,
		case when (@bqmntd-@BanqueD_MontantBanque) < 0 then abs((@bqmntd-@BanqueD_MontantBanque)) else 0 end as debitdevise,
		case when (@bqmntd-@BanqueD_MontantBanque) > 0 then abs((@bqmntd-@BanqueD_MontantBanque)) else 0 end as creditdevise,
		@Reg_Ref,null,null ,@dateop
		end

	end

	if @typeop like '%Redressem%cr%'
	begin
		select @BanqueD_MontantBanque=BanqueD_MontantBanque from banqued where banqued_type=@dsind and banqued_originenum like '%'+@Actrnum+'%'
		
		
		insert into GaccPD (GaccPE_Num,GaccCpt_Num ,GaccPD_Libelle,GaccPD_Debit,GaccPD_Credit,GaccPD_DebitDevise,GaccPD_CreditDevise,GaccPD_Ref,GaccB_RB,gaccpd_jou,GaccPD_Echeance)
		select (select numGce from @gaccnums where type_op='deblocage')
		,@bcpt  ,@typeop,0 as debit,@cred as credit,0 as debitdevise,@cred as creditdevise,@Reg_Ref,null,null ,@dateop	
		union all
		select (select numGce from @gaccnums where type_op='deblocage')
		,@bq_compte  ,@typeop,@cred as debit,0 as credit,@cred as debitdevise,0 as creditdevise,
	     @Reg_Ref,'RELEVE '+CAST(RIGHT('00' + CAST(MONTH(@dateop) AS nvarchar(2)), 2) AS varchar(10))+'/'+ CAST(YEAR(@dateop) as nvarchar(4)),
	     @gaccjou_code ,@dateop
	end
	if @typeop like '%Redressem%de%'
	begin
		select @BanqueD_MontantBanque=BanqueD_MontantBanque from banqued where banqued_type=@dsind and banqued_originenum like '%'+@Actrnum+'%'
		
		
		insert into GaccPD (GaccPE_Num,GaccCpt_Num ,GaccPD_Libelle,GaccPD_Debit,GaccPD_Credit,GaccPD_DebitDevise,GaccPD_CreditDevise,GaccPD_Ref,GaccB_RB,gaccpd_jou,GaccPD_Echeance)
		select (select numGce from @gaccnums where type_op='deblocage')
		,@bcpt  ,@typeop,@debt as debit,0 as credit,@debt as debitdevise,0 as creditdevise,@Reg_Ref,null,null ,@dateop	
		union all
		select (select numGce from @gaccnums where type_op='deblocage')
		,@bq_compte  ,@typeop,0 as debit,@debt as credit,0 as debitdevise,@debt as creditdevise,
	     @Reg_Ref,'RELEVE '+CAST(RIGHT('00' + CAST(MONTH(@dateop) AS nvarchar(2)), 2) AS varchar(10))+'/'+ CAST(YEAR(@dateop) as nvarchar(4)),
	     @gaccjou_code ,@dateop
	end
	FETCH NEXT FROM @CR1 INTO @Id,@typeop,@dateop,@dateech,@numce,@debt,@cred,@bcpt,@dsind,@bcptlib,@bqmntd,@idlg
end
CLOSE @CR1; 
DEALLOCATE @CR1;

update Reglement set Reg_RegCpt = 2
where reg_num=@ActRnum

FETCH NEXT FROM @Lot INTO @Actref,@Actref1,@ActRnum
end

CLOSE @lot; 
DEALLOCATE @lot;