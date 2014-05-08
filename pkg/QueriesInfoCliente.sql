
declare
P_USER_ID       number := 10585;
P_RESP_ID       number := 51445;
P_RESP_APP_ID   number := 222;
P_ORG_ID        number := 346;
begin
MO_GLOBAL.INIT('AR');
   fnd_global.apps_initialize(P_USER_ID,P_RESP_ID,P_RESP_APP_ID);
     
         OE_MSG_PUB.Initialize;
         --+
         APPS.FND_CLIENT_INFO.SET_ORG_CONTEXT(P_ORG_ID);
         commit;
end;

       Select Orig_System_Reference
                , Customer_Id
                --, a.*
       From Apps.Ar_Bill_To_Addresses_Active_V A
       Where 1=1
--       and A.Orig_System_Reference in('SV-NEW-640','SV-NAV-5516','SV-NAV-4657','SV-MIC-38191','SV-MIC-37012','SV-MIC-38147','SV-NEW-433664','SV-NAV-4745','SV-NEW-418','SV-NAV-2908','SV-NAV-1810','SV-NAV-35931','SV-NAV-11722','SV-NEW-0337','SV-NAV-31247','SV-NEW-773','SV-MIC-36947','SV-MIC-39377','SV-MIC-39469','SV-MIC-40342','SV-NEW-606','SV-NAV-14109','SV-NAV-14359','SV-NAV-2584','SV-MIC-37174','SV-AMN-000-0086','SV-NAV-13924','SV-NEW-0209','SV-NAV-7697','SV-NEW-770','SV-NAV-2581','SV-NEW-400555','SV-NEW-709','SV-NEW-768','SV-NEW-0343','SV-NEW-581','SV-MIC-36814','SV-NEW-401093','SV-NEW-0333','SV-NAV-12695','SV-NEW-403','SV-NEW-0120','SV-NEW-629','SV-NEW-0092','SV-NEW-0385','SV-NEW-500027','SV-NEW-400650','SV-NEW-406483','SV-MIC-37886','SV-NEW-406493','SV-MIC-36151','SV-NEW-656','SV-MIC-39774','SV-NEW-524','SV-MIC-37515','SV-MIC-36816','SV-MIC-39085','SV-NEW-0341','SV-NAV-3226');
--        and A.Orig_System_Reference = 'SV-NAV-35931'
--        and Customer_Id = 1263235
       and Customer_Id in (1263233,1263234,1263235,1263236,1263237,1263238,1263239,1263240,1263241,1263242,1263243,1263244,1263245,1263246,1266395,4675970,4675989,4739873,4739919,4739928,4791128,4791202,4793717,4832165,4832644,4880670,5011384,5011391,5011393,5137973,5205045,5205087,5296194,5296205,5296215,5296219,5296226,5296233,5332431
)
        
        --+ customer_id 1264714


    select * from gl.gl_ledgers
    where name like 'SV%'

        select * 
         from hr_operating_units ou
         where ou.name like 'SV%'   
        
            SELECT distinct CA.CUST_ACCOUNT_ID 
--                   , TR.BILL_TO_SITE_USE_ID
--                   , TR.TRX_NUMBER
--                   , TR.CUST_TRX_TYPE_ID 
         FROM RA_CUSTOMER_TRX_ALL TR,
                  HZ_CUST_ACCOUNTS_ALL CA
         WHERE TR.BILL_TO_CUSTOMER_ID = CA.CUST_ACCOUNT_ID
--             AND TR.TRX_NUMBER = '6960'
--             AND CA.CUST_ACCOUNT_ID = 1264714
--            and TR.BILL_TO_SITE_USE_ID =2440351
             and tr.org_id = 346
--             AND TR.CUST_TRX_TYPE_ID = P_CUST_TRX_TYPE_ID;


1, -99, 76160, SV-TIGOCASH, 2014/05/07 00:00:00, , , , , , , , , , , , , , , , , , , , , Y,
1, 346, 76160, SV-TIGOCASH, 07-MAY-14, , , , , , , , , , , , , , , , , , , , ,           Y, ,
             

select count(1) from  ar.hz_cust_accounts CA where  CA.org_id = 346

             
select count(1) from  HZ_CUST_ACCOUNTS_ALL CA where  CA.org_id = 346

      
select * from 
RA_CUSTOMER_TRX_ALL TR
where org_id = 346
             
               Select Customer_Id
--          Into l_customer_id
       From Apps.Ar_Bill_To_Addresses_Active_V A
       Where A.Orig_System_Reference = TCNFOL;




    SELECT SUM(MONTO_AFECTADO)
--      INTO l_apply_amount_sum
      FROM XX_SV_CARGA_RECEIPTS
     WHERE NVL(NUMERO_PAGO, 'NULL') = NVL(NUM_REC, 'NULL')
       AND NVL(TCNFOL, 'NULL') = NVL(FOL, 'NULL');

    SELECT VALOR_PAGO
      INTO l_receipt_amount
      FROM XX_SV_CARGA_RECEIPTS
     WHERE NVL(NUMERO_PAGO, 'NULL') = NVL(NUM_REC, 'NULL')
       AND NVL(TCNFOL, 'NULL') = NVL(FOL, 'NULL')
       AND ROWNUM = 1;

    IF  nvl(l_apply_amount_sum,0) < nvl(l_receipt_amount,0) THEN
        RETURN 1;
    ELSIF  nvl(l_apply_amount_sum,0) = nvl(l_receipt_amount,0) THEN
              RETURN 1;
    ELSE
        fnd_file.PUT_LINE(fnd_file.OUTPUT, 'El Monto del Recibo es inferios al de las Facturas');
        fnd_file.PUT_LINE(fnd_file.OUTPUT, 'Monto del Recibo: '||to_char(nvl(l_receipt_amount,0),'999,999,999.99'));
        fnd_file.PUT_LINE(fnd_file.OUTPUT, 'Monto del Factura: '||to_char(nvl(l_apply_amount_sum,0),'999,999,999.99'));
        RETURN 0;
    END IF;



  select cust_trx_type_id,name
--        into l_cust_trx_type_id
    from Ra_Cust_Trx_Types_All trxt
    where 1=1
--    where name like p_name
    and set_of_books_id = 2249;
    
    
    select * from apps.set_of_books where org_id = 346
   
    v_cust_trx_type_id      := xx_cust_trx_type_id (v_tipo_factura, v_set_of_books_id);
    v_customer_site_use_id  := xx_get_customer_site_use_id(v_customer_id, B.NUMERO_FACTURA, v_cust_trx_type_id);
    v_customer_trx_id :=  xx_search_factura (B.NUMERO_FACTURA, v_customer_site_use_id, v_cust_trx_type_id);
    
    --SV-MIC-37012



       SELECT CUSTOMER_TRX_ID
--           INTO l_customer_trx_id
       FROM APPS.RA_CUSTOMER_TRX_ALL
       WHERE TRX_NUMBER = :P_NUMERO_FACTURA
           AND BILL_TO_SITE_USE_ID = P_BILL_TO_SITE_USE_ID
           AND CUST_TRX_TYPE_ID = P_CUST_TRX_TYPE_ID;
           
