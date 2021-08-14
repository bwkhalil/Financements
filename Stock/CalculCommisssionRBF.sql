USE mas
GO
/****** Object:  StoredProcedure [dbo].[Calcul_Commissionrbf]    Script Date: 28/06/2021 14:26:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--ALTER PROCEDURE [dbo].[Calcul_Commissionrbf]  
--AS 
 
--begin
	declare  @CR  as cursor
	declare @Reg_Num as nvarchar(100)
	declare @reg_ref as nvarchar(100)
	declare @Mnt as numeric (18,6)
	declare @regcpt as nvarchar(1)
	declare @Banque_Code as nvarchar(20)
	declare @BanqueD_Date as date
	declare @BanqueD_Libelle as nvarchar(100)
	declare @Banque_Formule as nvarchar(100)
	declare @BanqueD_CompteLib as nvarchar(100)
	declare @BanqueD_MontantE as numeric(18,3)
	declare @BanqueD_MontantD as numeric(18,3)
	declare @BanqueD_Statut as int
	declare @BanqueD_Type as int
	declare @BanqueD_Origine as int
	declare @BanqueD_Origine2 as nvarchar(20)
	declare @BanqueD_OrigineNum as nvarchar(20)
	declare @RegParam_Code as nvarchar(20)
	declare @Devise_Code as nvarchar(10)
	declare @Banque_Nature as nvarchar(50)
	declare @Devise_Cours as numeric(18,5)
	declare @Reg_Devise_CoursPay as numeric(18,5)
	declare @Reg_Devise_CoursMP as numeric(18,5)
	declare @Reg_Euribor as numeric(18,3)
	declare @Reg_Montant as numeric(18,3)
	declare @xReg_Taux as numeric(18,3)
	declare @Date_Create as date
	declare @Integ as int
	declare @xReg_Type as int
	declare @xReg_NbrSwift as int
	declare @xReg_NbrSwiftM as int
	declare @xReg_NbrDraft as int
	declare @xReg_TypeModif as int
	declare @xReg_Status as int
	declare @BanqueD_Compte as nvarchar(10)
	declare @BanqueD_TypeCompt as int
	declare @Compteur as int
    declare @changement_commission_stb as date
    declare @commission_stb_ttc as numeric(18,3)
    
    select @changement_commission_stb=cast('2020-11-09' as date)
    
	set @CR = cursor for 

	select reg_banque,Reg_DateEcheance,Reg_Label ,Reg_Montant,reg_status,reg_num,Reg_DateReglement ,regParam_Code,Reg_Devise_CoursMP,Devise_Code,
		   xReg_Type,Reg_Euribor,xReg_Taux,xReg_TypeModif,xReg_NbrDraft,xReg_NbrSwiftM,xReg_NbrSwift,Reg_Devise_CoursPay
	from reglement
	inner join GaccExercice 
		on year(reg_datereglement) =GaccExercice.GaccEx_Code 	
		where RegParam_Code in ('rbf')and Reg_RegCpt=0 and  year(reg_dateecheance)>=2020 and reg_banque like '%stb%'  --and (reg_ref is not null or reg_ref1 is not null)  
		order by reg_datereglement                         
	open @CR
	FETCH NEXT FROM @CR
	INTO @Banque_Code, @BanqueD_Date,@BanqueD_Libelle,@BanqueD_MontantD,@BanqueD_Statut,@BanqueD_OrigineNum, @Date_Create,@RegParam_Code,@Reg_Devise_CoursMP,@Devise_Code,
		 @xReg_Type,@Reg_Euribor,@xReg_Taux,@xReg_TypeModif,@xReg_NbrDraft,@xReg_NbrSwiftM,@xReg_NbrSwift,@Reg_Devise_CoursPay
	WHILE @@FETCH_STATUS = 0    
	begin
    if @Date_Create<@changement_commission_stb
    begin 
    select @commission_stb_ttc=2.380
    end
    else
    begin
    select @commission_stb_ttc=2.975
    end
	-----------------BIAT---------------------------------
		if  @Banque_Code like '%BIA%' 
		begin
		delete from BanqueD where BanqueD_OrigineNum =@BanqueD_OrigineNum and BanqueD_Type <> 0
	-------Paiement Interet--------------------------------
			if  @RegParam_Code in ('rbf') 
			begin
			insert into BanqueD ( Banque_Code,BanqueD_Date,BanqueD_Libelle,BanqueD_MontantE,BanqueD_MontantD,
								  BanqueD_Statut,BanqueD_Type,BanqueD_Origine,BanqueD_Origine2,BanqueD_OrigineNum,Date_Create, Integ,Banque_Nature,Banque_Formule,
								  BanqueD_Compte,BanqueD_TypeCompt,BanqueD_CompteLib)
	
			select				  @Banque_Code,@BanqueD_Date,@BanqueD_Libelle,0,ISnull((((datediff(day,@Date_Create,@BanqueD_Date))*@BanqueD_MontantD*(@xReg_Taux+2)/36000)),0),
								  @BanqueD_Statut,4,5,'',@BanqueD_OrigineNum,@Date_Create,0,'','MT*TMM+2%*Nbre de jours/36000',
								  '65160100','2','Paiements Interets'
			from Reglement where reg_num =@BanqueD_OrigineNum
			end
	-------Commission echeance credit----------------------
			if  @RegParam_Code in ('rbf')  
			begin
			insert into BanqueD ( Banque_Code, BanqueD_Date, BanqueD_Libelle, BanqueD_MontantE, BanqueD_MontantD, BanqueD_Statut, BanqueD_Type, BanqueD_Origine, BanqueD_Origine2,
								  BanqueD_OrigineNum,Date_Create,Integ,Banque_Nature,Banque_Formule,BanqueD_Compte,BanqueD_TypeCompt,BanqueD_CompteLib)

			select                @Banque_Code,@BanqueD_Date,@BanqueD_Libelle,0,3.5,@BanqueD_Statut,15,5,'',
								  @BanqueD_OrigineNum,@Date_Create,0,'HT','3.5 DT HT','62700100','2','Commission echeance credi'
			from Reglement where reg_num =@BanqueD_OrigineNum
			end			
	------- TVA Comm Imp effet Prin------------------------
			 if  @RegParam_Code in ('rbf') 
			 begin
			 insert into BanqueD
			 (Banque_Code, BanqueD_Date, BanqueD_Libelle, BanqueD_MontantE, BanqueD_MontantD, BanqueD_Statut, BanqueD_Type, BanqueD_Origine, BanqueD_Origine2,
			  BanqueD_OrigineNum,Date_Create,Integ,Banque_Nature,Banque_Formule,BanqueD_Compte,BanqueD_TypeCompt,BanqueD_CompteLib)
			 select @Banque_Code,@BanqueD_Date,@BanqueD_Libelle,0,0.665,@BanqueD_Statut,2 ,5 ,'',@BanqueD_OrigineNum,@Date_Create,0,'TVA','TVA sur Com','43660018','2','TVA sur Com'
			 from Reglement
			 where reg_num =@BanqueD_OrigineNum
			 end
		end
	-------------------STB---------------------------------
		if  @Banque_Code like '%STB%' 
		begin
			select @date_create,@commission_stb_ttc
			delete from BanqueD where BanqueD_OrigineNum =@BanqueD_OrigineNum and BanqueD_Type <> 0
	-------REMBOURSEMENT INTERET A L'ECHEANC-----
	----------------------------
			if  @RegParam_Code in ('rbf') 
			begin
			insert into BanqueD ( Banque_Code, BanqueD_Date,BanqueD_Libelle, BanqueD_MontantE, BanqueD_MontantD,
			BanqueD_Statut, BanqueD_Type, BanqueD_Origine, BanqueD_Origine2, BanqueD_OrigineNum, Date_Create, Integ,Banque_Nature,Banque_Formule,BanqueD_Compte,BanqueD_TypeCompt,BanqueD_CompteLib)
			select @Banque_Code,@BanqueD_Date,@BanqueD_Libelle,0,ISnull((((datediff(day,@Date_Create,@BanqueD_Date))*@BanqueD_MontantD*(@xReg_Taux+2) /36000)),0)
					,@BanqueD_Statut,19,5,'',@BanqueD_OrigineNum,@Date_Create,0,'','MT*TMM+2%*Nbre de jours/36000','65160100','2','REMBOURSEMENT INTERET A L''ECHEA'
			from Reglement 
			where reg_num =@BanqueD_OrigineNum
			end
	-------COMMISSION REGLEMENT EFFET FINA-----
			if  @RegParam_Code in ('rbf')  
			begin
			insert into BanqueD ( Banque_Code, BanqueD_Date    , BanqueD_Libelle, BanqueD_MontantE, BanqueD_MontantD, BanqueD_Statut, BanqueD_Type, BanqueD_Origine, BanqueD_Origine2, BanqueD_OrigineNum, Date_Create, Integ,Banque_Nature,Banque_Formule,BanqueD_Compte,BanqueD_TypeCompt,BanqueD_CompteLib)
			select @Banque_Code,@BanqueD_Date,@BanqueD_Libelle,0, @commission_stb_ttc,@BanqueD_Statut,15,5,'',@BanqueD_OrigineNum,@Date_Create,0,'TTC', cast(@commission_stb_ttc as varchar(30))+' DT TTC','','0','COMMISSION REGLEMENT EFFET FINA TTC'
					--from Reglement where reg_num =@BanqueD_OrigineNum
			end

			if  @RegParam_Code in ('rbf')  
			begin
			insert into BanqueD ( Banque_Code, BanqueD_Date    , BanqueD_Libelle, BanqueD_MontantE, BanqueD_MontantD, BanqueD_Statut, BanqueD_Type, BanqueD_Origine, BanqueD_Origine2, BanqueD_OrigineNum, Date_Create, Integ,Banque_Nature,Banque_Formule,BanqueD_Compte,BanqueD_TypeCompt,BanqueD_CompteLib)
			select @Banque_Code,@BanqueD_Date,@BanqueD_Libelle,0, @commission_stb_ttc/1.19,@BanqueD_Statut,15,5,'',@BanqueD_OrigineNum,@Date_Create,0,'HT','COMMISSION REGLEMENT EFFET HT','62700100','1','COMMISSION REGLEMENT EFFET FINA'
			from Reglement 
			where reg_num =@BanqueD_OrigineNum
			end

			--if  @RegParam_Code in ('rbf')  
			--begin
			--insert into BanqueD ( Banque_Code, BanqueD_Date    , BanqueD_Libelle, BanqueD_MontantE, BanqueD_MontantD, BanqueD_Statut, BanqueD_Type, BanqueD_Origine, BanqueD_Origine2, BanqueD_OrigineNum, Date_Create, Integ,Banque_Nature,Banque_Formule,BanqueD_Compte,BanqueD_TypeCompt,BanqueD_CompteLib)
			--select @Banque_Code,@BanqueD_Date,@BanqueD_Libelle,0,2.975/1.19,@BanqueD_Statut,15,5,'',@BanqueD_OrigineNum,@Date_Create,0,'HT','COMMISSION REGLEMENT EFFET HT','62700100','1','COMMISSION REGLEMENT EFFET FINA'
			--from Reglement 
			--where reg_num =@BanqueD_OrigineNum
			--end
		end
	-------------------UIB----------------------------------------------------------------------------------------------------------------------------------
		if  @Banque_Code like '%UIB%' 
		begin
			delete from BanqueD where BanqueD_OrigineNum =@BanqueD_OrigineNum and BanqueD_Type <> 0
	-------Interet /Remboursement Echeance-----
			if  @RegParam_Code in ('rbf') 
			begin
			insert into BanqueD ( Banque_Code, BanqueD_Date, BanqueD_Libelle, BanqueD_MontantE, BanqueD_MontantD, BanqueD_Statut, BanqueD_Type, BanqueD_Origine, BanqueD_Origine2, BanqueD_OrigineNum, Date_Create, Integ,Banque_Nature,Banque_Formule,BanqueD_Compte,BanqueD_TypeCompt,BanqueD_CompteLib)
			select @Banque_Code,@BanqueD_Date,@BanqueD_Libelle,0,ISnull((((datediff(day,@Date_Create,@BanqueD_Date))*@BanqueD_MontantD*(@xReg_Taux+2.25) /36000)),0)
				   ,@BanqueD_Statut,19,5,'',@BanqueD_OrigineNum ,@Date_Create,0,'','MT*TMM+2.25%*Nbre de jours/36000','65160100','2','REMBOURS. ECHEANCE CREDIT'
			from Reglement 
			where reg_num =@BanqueD_OrigineNum
			end

	------- FR. MISE EN PLACE CREDIT  -------------------------------------------------------------------------------------------------------------------
			if  @RegParam_Code in ('rbf') 
			begin
			insert into BanqueD ( Banque_Code, BanqueD_Date    , BanqueD_Libelle, BanqueD_MontantE, BanqueD_MontantD, BanqueD_Statut, BanqueD_Type, BanqueD_Origine, BanqueD_Origine2, BanqueD_OrigineNum, Date_Create, Integ,Banque_Nature,Banque_Formule,BanqueD_Compte,BanqueD_TypeCompt,BanqueD_CompteLib)
			select @Banque_Code,@BanqueD_Date,@BanqueD_Libelle,0,2.618,@BanqueD_Statut,16,5,'',@BanqueD_OrigineNum,@Date_Create,0,'TTC','2.618 DT TTC','','0','FR. MISE EN PLACE CREDIT TTC'
			from Reglement 
			where reg_num =@BanqueD_OrigineNum
			end

			if  @RegParam_Code in ('rbf') 
			begin
			insert into BanqueD ( Banque_Code, BanqueD_Date    , BanqueD_Libelle, BanqueD_MontantE, BanqueD_MontantD, BanqueD_Statut, BanqueD_Type, BanqueD_Origine, BanqueD_Origine2, BanqueD_OrigineNum, Date_Create, Integ,Banque_Nature,Banque_Formule,BanqueD_Compte,BanqueD_TypeCompt,BanqueD_CompteLib)
			select @Banque_Code,@BanqueD_Date,@BanqueD_Libelle,0,2.618/1.19,@BanqueD_Statut,16,5,'',@BanqueD_OrigineNum,@Date_Create,0,'HT','FR. MISE EN PLACE CREDIT ','62700100','1','FR. MISE EN PLACE CREDIT HT'
			from Reglement 
			where reg_num =@BanqueD_OrigineNum
			end
	-------REMBOURS. ECHEANCE CREDIT-----------------------------------------------------------------------------------------------------------------------
			if  @RegParam_Code in ('rbf')  
			begin
			insert into BanqueD ( Banque_Code, BanqueD_Date,BanqueD_Libelle, BanqueD_MontantE, BanqueD_MontantD, BanqueD_Statut, BanqueD_Type, BanqueD_Origine, BanqueD_Origine2, BanqueD_OrigineNum, Date_Create, Integ,Banque_Nature,Banque_Formule,BanqueD_Compte,BanqueD_TypeCompt,BanqueD_CompteLib)
			select @Banque_Code,@BanqueD_Date,@BanqueD_Libelle,0,2.975,@BanqueD_Statut,15,5  ,'',@BanqueD_OrigineNum,@Date_Create,0,'TTC','ajouter 2,975 DTT au montant principale lors du remboursement ','','0','REMBOURS. ECHEANCE CREDIT  TTC'
			from Reglement 
			where reg_num =@BanqueD_OrigineNum
			end
			
			if  @RegParam_Code in ('rbf') 
			begin
			insert into BanqueD ( Banque_Code, BanqueD_Date,BanqueD_Libelle, BanqueD_MontantE, BanqueD_MontantD, BanqueD_Statut, BanqueD_Type, BanqueD_Origine, BanqueD_Origine2, BanqueD_OrigineNum, Date_Create, Integ,Banque_Nature,Banque_Formule,BanqueD_Compte,BanqueD_TypeCompt,BanqueD_CompteLib)
			select @Banque_Code,@BanqueD_Date,@BanqueD_Libelle,0,(2.975/1.19),@BanqueD_Statut,17,5,'',@BanqueD_OrigineNum  ,@Date_Create,0,'HT','ajouter 2,975 DTT au montant principale lors du remboursement ','62700100','1','REMBOURS. ECHEANCE CREDIT'
			from Reglement 
			where reg_num =@BanqueD_OrigineNum
			end	
	--------Frais Effet et obligation------------------------------------------------------------------------------------------------------------------------
			if  @RegParam_Code in ('rbf')  
			begin
			insert into BanqueD ( Banque_Code, BanqueD_Date,BanqueD_Libelle, BanqueD_MontantE, BanqueD_MontantD, BanqueD_Statut, BanqueD_Type, BanqueD_Origine, BanqueD_Origine2, BanqueD_OrigineNum, Date_Create, Integ,Banque_Nature,Banque_Formule,BanqueD_Compte,BanqueD_TypeCompt,BanqueD_CompteLib)
			select @Banque_Code,@BanqueD_Date,@BanqueD_Libelle,0,14.875,@BanqueD_Statut,15,5  ,'',@BanqueD_OrigineNum,@Date_Create,0,'TTC','14,875 DT TTC','','0','REGLEM. EFFETS ET OBLIGATIONS'
			from Reglement 
			where reg_num =@BanqueD_OrigineNum
			end	
			if  @RegParam_Code in ('rbf') 
			begin
			insert into BanqueD ( Banque_Code, BanqueD_Date,BanqueD_Libelle, BanqueD_MontantE, BanqueD_MontantD, BanqueD_Statut, BanqueD_Type, BanqueD_Origine, BanqueD_Origine2, BanqueD_OrigineNum, Date_Create, Integ,Banque_Nature,Banque_Formule,BanqueD_Compte,BanqueD_TypeCompt,BanqueD_CompteLib)
			select @Banque_Code,@BanqueD_Date,@BanqueD_Libelle,0,(14.875/1.19),@BanqueD_Statut,18,5,'',@BanqueD_OrigineNum  ,@Date_Create,0,'HT','Frais Effet et obligation','62700100','1','REGLEM. EFFETS ET OBLIGATIONS'
			from Reglement 
			where reg_num =@BanqueD_OrigineNum
			end	
		end
	-----------------ATB---------------------------------
		if  @Banque_Code like '%ATB%' 
		begin
			delete from BanqueD where BanqueD_OrigineNum =@BanqueD_OrigineNum and BanqueD_Type <> 0
	-----Paiement Interet--------------------------------
			if  @RegParam_Code in ('rbf') 
			begin
			insert into BanqueD ( Banque_Code,BanqueD_Date,BanqueD_Libelle,BanqueD_MontantE,BanqueD_MontantD,
								  BanqueD_Statut,BanqueD_Type,BanqueD_Origine,BanqueD_Origine2,BanqueD_OrigineNum,Date_Create, Integ,Banque_Nature,Banque_Formule,
								  BanqueD_Compte,BanqueD_TypeCompt,BanqueD_CompteLib)
	
			select				  @Banque_Code,@BanqueD_Date,@BanqueD_Libelle,0,ISnull((((datediff(day,@Date_Create,@BanqueD_Date))*@BanqueD_MontantD*(@xReg_Taux+2)/36000)),0),
								  @BanqueD_Statut,23,5,'',@BanqueD_OrigineNum,@Date_Create,0,'','MT*TMM+2%*Nbre de jours/36000',
								  '65160100','2','Interêts'
			from Reglement 
			where reg_num =@BanqueD_OrigineNum
			end
	-----Comm Imp effet Prin----------------------
			if  @RegParam_Code in ('rbf')  
			begin
			insert into BanqueD ( Banque_Code, BanqueD_Date, BanqueD_Libelle, BanqueD_MontantE, BanqueD_MontantD, BanqueD_Statut, BanqueD_Type, BanqueD_Origine, BanqueD_Origine2,
								  BanqueD_OrigineNum,Date_Create,Integ,Banque_Nature,Banque_Formule,BanqueD_Compte,BanqueD_TypeCompt,BanqueD_CompteLib)

			select                @Banque_Code,@BanqueD_Date,@BanqueD_Libelle,0,10,@BanqueD_Statut,21,5,'',
								  @BanqueD_OrigineNum,@Date_Create,0,'HT','10 DT HT','62700100','2','Comm Imp effet Prin'
			from Reglement 
			where reg_num =@BanqueD_OrigineNum
			end			
	----- TVA Comm Imp effet Prin------------------------
			 if  @RegParam_Code in ('rbf') 
			 begin
			 insert into BanqueD
			 (Banque_Code,BanqueD_Date,BanqueD_Libelle,BanqueD_MontantE,BanqueD_MontantD,BanqueD_Statut,BanqueD_Type,BanqueD_Origine, BanqueD_Origine2,BanqueD_OrigineNum,Date_Create,Integ,Banque_Nature,Banque_Formule,BanqueD_Compte,BanqueD_TypeCompt,BanqueD_CompteLib)
			 select @Banque_Code,@BanqueD_Date,@BanqueD_Libelle,0,1.9,@BanqueD_Statut,22 ,5 ,'',@BanqueD_OrigineNum,@Date_Create,0,'TVA','TVA sur Com','43660018','2','TVA /comm effet'
			 from Reglement 
			 where reg_num =@BanqueD_OrigineNum
			 end
		end
		FETCH NEXT FROM @CR
		INTO @Banque_Code, @BanqueD_Date,@BanqueD_Libelle,@BanqueD_MontantD,@BanqueD_Statut,@BanqueD_OrigineNum, @Date_Create,@RegParam_Code,@Reg_Devise_CoursMP,@Devise_Code,
			 @xReg_Type,@Reg_Euribor,@xReg_Taux,@xReg_TypeModif,@xReg_NbrDraft,@xReg_NbrSwiftM,@xReg_NbrSwift,@Reg_Devise_CoursPay
	end--end while
	
	CLOSE @CR;    
	DEALLOCATE @CR;
--end