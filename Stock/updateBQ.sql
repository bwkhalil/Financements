use mas
declare @CR  as cursor
declare @reg_mont as numeric(18,3)



declare @CR1  as cursor
declare @code as nvarchar(2)
declare @Reg_Num as nvarchar(100)
declare @reg_ref as nvarchar(100)
declare @reg_ref1 as nvarchar(100)
declare @reg_mnt as numeric(18,3)
declare @BanqueD_DateOpr as date
declare @diversys_index as int
declare @Nbr_decimal as nvarchar(1)
declare @Date_opr as date
declare @Date_valeur as date
declare @Libelle as nvarchar(200)
declare @Num_piece as nvarchar(7)
declare @Debit as decimal(18,3)
declare @Credit as decimal(18,3)
declare @MNT as decimal(18,3)
declare @Reference as nvarchar(16)
declare @Rapprocher as nvarchar(50)
declare @Observation as nvarchar(200)
declare @idlig as nvarchar(20)
declare @Banque as nvarchar(100)
declare @idllig as numeric(18,0)
declare @Date_ech as date
declare @Date_reg as date

set @CR = CURSOR LOCAL FAST_FORWARD  for (


-- select reg_num,case when reg_ref like'f13%' or reg_ref like 'f14%'  then left(reg_ref,7) else right(reg_ref,7) end ,case when reg_ref1 like'f13%' or reg_ref1 like 'f14%'  then left(reg_ref1,7) else right(reg_ref1,7) end ,reg_montant
-- ,reg_datereglement,Reg_DateEcheance
select reg_num,reg_ref ,reg_ref1 ,reg_montant
,reg_datereglement,Reg_DateEcheance
from reglement
where RegParam_Code in ('rbf')  and year(reg_dateecheance)>=2020 and (reg_ref is not null or reg_ref1 is not null)
 and reg_banque like '%atb%' /*and  reg_num ='RF20Tr692' and Reg_RegCpt=0*/
)


open @CR
FETCH NEXT FROM @CR INTO  @Reg_Num,@reg_ref,@Reg_ref1,@reg_mont,@Date_reg,@Date_ech;	
WHILE @@FETCH_STATUS = 0 
begin
select @Reg_Num,@reg_ref,@Reg_ref1,@reg_mont,@Date_reg,@Date_ech
set @CR1 = CURSOR LOCAL FAST_FORWARD  for (

        select  @reg_num as regnum ,xr.Code, 
        isnull(@reg_ref,@reg_ref1) as reg_ref,
        abs(xr.debit+xr.Credit) as Montant ,isnull(ds.diversys_index,-1),xr.[Nbr_decimal],xr.[Date_opr],xr.[Date_valeur]
        ,xr.[Libelle],xr.[Num_piece],xr.[Reference],xr.[Rapprocher],xr.[Observation],xr.[idlig],xr.[Banque],xr.[idllig],@reg_mont as montantTot
            from  xrelevehistorique xr 
            inner join [DiverSys] ds
                on rtrim(ltrim(ds.diversys_libelle)) like rtrim(ltrim(xr.libelle)) and ds.diversys_type like 'F016'
            where  xr.libelle like '%inter%'
             and xr.Date_opr<@Date_ech
            and xr.Date_opr>=@Date_reg            
            and  (left(ltrim(rtrim(xr.num_piece)),7) like left(rtrim(ltrim(@reg_ref)),7) )or (left(ltrim(rtrim(xr.reference)),7) like left(rtrim(ltrim(@reg_ref)),7)) 
            and	 xr.libelle not like '%retar%' --and ds.diversys_index is not null 
            and xr.valider=0

        union all

        select  @reg_num as regnum ,xr.Code, 
        isnull(@reg_ref,@reg_ref1) as reg_ref,
        abs(xr.debit+xr.Credit) as Montant ,isnull(ds.diversys_index,-1),xr.[Nbr_decimal],xr.[Date_opr],xr.[Date_valeur]
        ,xr.[Libelle],xr.[Num_piece],xr.[Reference],xr.[Rapprocher],xr.[Observation],xr.[idlig],xr.[Banque],xr.[idllig],@reg_mont as montantTot
            from  xrelevehistorique xr 
            inner join [DiverSys] ds
                on rtrim(ltrim(ds.diversys_libelle)) like rtrim(ltrim(xr.libelle)) and ds.diversys_type like 'F016'
            where    (xr.libelle not like '%inter%')
            and (xr.Date_opr> @Date_reg)
            and (left(ltrim(rtrim(xr.num_piece)),7) like left(rtrim(ltrim(@reg_ref)),7) )or (left(ltrim(rtrim(xr.reference)),7) like left(rtrim(ltrim(@reg_ref)),7)) 
            and	 (xr.libelle not like '%retar%') --and ds.diversys_index is not null 
            and (xr.valider=0)
            and (xr.banque like '%atb%')
           
            
        
       
        
		 
	

)
open @CR1
FETCH NEXT FROM @CR1 INTO  @Reg_Num,@code,@reg_ref,@reg_mnt,@diversys_index,@Nbr_decimal,@Date_opr,@Date_valeur,@Libelle,@Num_piece,@Reference,@Rapprocher,@Observation,@idlig,@Banque,@idllig,@MNT;	
WHILE @@FETCH_STATUS = 0    
	begin
    
    if @Date_opr>=@Date_reg
    begin
    -- select  top 1 @Reg_Num,@Date_opr,@code,@reg_ref,@reg_mnt,@diversys_index,@Nbr_decimal,@Date_opr,@Date_valeur,@Libelle,@Num_piece,@Reference,@Rapprocher,@Observation,@idlig,@Banque,@idllig,@MNT
	select @reg_num as regnum,right(rtrim(ltrim(@Reference)),7),right(rtrim(ltrim(@Num_piece)),7),@Libelle,@diversys_index,@Date_opr,@reg_mnt,@MNT--,banqued_ref
	from [BanqueD]
	
		-- UPDATE BanqueD
		-- SET	 banqued_ref=isnull(left(rtrim(ltrim(@Num_piece)),7),left(rtrim(ltrim(@Reference)),7))
		-- 	,BanqueD_MontantBanque=isnull(@reg_mnt,@reg_mont)
		-- 	,[BanqueD_DateOpr]=@Date_opr
        --     ,BanqueD_Date=@Date_opr
			
		WHERE
		rtrim(ltrim(banqued_originenum))=rtrim(ltrim(@reg_num))
		and BanqueD_Type=@diversys_index
		and banqued_type<>0
        and @Date_opr<=@Date_ech and @Date_opr>=@Date_reg
end

       

		FETCH NEXT FROM @CR1 INTO   @Reg_Num,@code,@reg_ref,@reg_mnt,@diversys_index,@Nbr_decimal,@Date_opr,@Date_valeur,@Libelle,@Num_piece,@Reference,@Rapprocher,@Observation,@idlig,@Banque,@idllig,@MNT;	
	
	
	END
	CLOSE @CR1;    
	DEALLOCATE @CR1;


     select'------','--------','---------------'
FETCH NEXT FROM @CR INTO  @Reg_Num,@reg_ref,@Reg_ref1,@reg_mont,@Date_reg,@Date_ech;


end
	CLOSE @CR;    
	DEALLOCATE @CR;



  
  