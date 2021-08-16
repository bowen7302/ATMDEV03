CREATE OR REPLACE PACKAGE BODY  Swgcnv_Dd_Stmnt_Pkg AS
/*******************************************************************************
* Copyright (c) 2005 DS Waters, Atlanta, GA 30152 USA All rights reserved.     *
********************************************************************************
* WO#               : 17795                                                    *
* Project           :                                                          *
* Application       : SWG Conversions                                          *
* Title             :                                                          *
* Program Name      : SWGCNV_DD_STMNT_PKB.pls                                  *
* Description       : Script for RIM conversion Programs in APPS.              *
* Revision          : 1.0                                                      *
* Utility           : SQL*Plus                                                 *
* Created by        : Bharat Gollapudi                                         *
* Creation Date     : 11-JAN-2005                                              *
*                                                                              *
* Change History:                                                              *
*                                                                              *
* Update Date      Name                 Description                            *
* --------------------------------------------------------------------         *
* 30-OCT-2008      Vijay Padmanabhan    WO#18762 R12: Org_Id Setup             *
* 23-FEB-2009      Pankaj Umate         Changes For TYR01 Conversion Project   *
*                                       Daptiv # 813                           *
********************************************************************************/

   PROCEDURE    swg_output(in_outmsg_s  VARCHAR2)
   IS
   BEGIN
      Fnd_File.put_line(Fnd_File.output,in_outmsg_s);
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END swg_output;

   PROCEDURE Swgcnv_Dd_Stmnt_Cnv
         ( 
             Ou_errmsg_s       OUT   VARCHAR2
            ,Ou_errcode_n      OUT   NUMBER
            ,in_system_code     IN   VARCHAR2
            ,in_sales_center    IN   VARCHAR2
            ,in_stmt_date_s     IN   VARCHAR2 
            )
   IS

      CURSOR  Main_Cur
      IS
         SELECT  a.new_sales_center
                ,b.customer_number
                ,a.oracle_customer_id
                ,cb.bill_to_address_id
                ,b.billto_location_number
                ,b.customer_balance
                ,b.last_statement_date
                ,a.system_code
         FROM    swgcnv_dd_temp_customers     a
                ,swgcnv_dd_stmt_interface    b
                ,swgcnv_dd_customer_billto  cb
         WHERE   a.system_code               =  in_system_code
         AND     a.new_sales_center          =  in_sales_center
         AND     a.cust_import_flag          =  'Y'
         AND     a.stmnt_proc_flag           =  'N'
         AND     cb.customer_number          =  a.legacy_customer_number
         AND     b.customer_number           =  cb.customer_number
         AND     b.billto_location_number    =  cb.billing_location_number
         AND     b.sales_center              =  cb.sales_center;       --ADDED KIM 08/21/05 group by not necessary
         --GROUP BY a.new_sales_center
                  --,b.customer_number
                  --,b.billto_location_number
                  --,b.customer_balance
                  --,b.last_statement_date
                  --,a.system_code;

      CURSOR  cur_cust ( in_orig_system_customer_ref_s   IN    VARCHAR2
                        ,in_cust_account_id_n              IN    NUMBER
                        ,in_org_id_n                          IN    NUMBER
                       )
      IS
      SELECT  addr.cust_account_id
             ,site.site_use_id
      FROM    hz_cust_site_uses     site
             ,hz_cust_acct_sites    addr
      WHERE   addr.cust_account_id         =  in_cust_account_id_n
      AND     addr.orig_system_reference   =  in_orig_system_customer_ref_s
      AND     addr.cust_acct_site_id       =  site.cust_acct_site_id
      AND     site.site_use_code           =  'BILL_TO';

      l_customer_id_n                 NUMBER;
      l_billto_site_use_id_n          NUMBER;
      l_org_id_n                      NUMBER;
      l_user_id_n                     NUMBER;
   
      l_orig_system_customer_ref_s    VARCHAR2(240);
      l_error_mesg_s                  VARCHAR2(2000);
      l_total_rec_cnt                 NUMBER   := 0;
      l_ins_rec_cnt                   NUMBER   := 0;
      l_err_rec_cnt                   NUMBER   := 0;


      CURSOR Cur_Billto(in_cust_acct_id_n    NUMBER)
      IS
      SELECT hca.cust_account_id
             ,hcsu.site_use_id
      FROM   apps.hz_cust_site_uses_all        hcsu 
             ,apps.hz_cust_acct_sites_all      hcas
             ,apps.hz_cust_accounts            hca
      WHERE  hcsu.site_use_code        =    'BILL_TO'
      AND    hcsu.cust_acct_site_id    =    hcas.cust_acct_site_id
      AND    hcas.cust_account_id      =    hca.cust_account_id 
      AND    hca.cust_account_id       =    in_cust_acct_id_n;

      l_stmt_amt_n    NUMBER;
      l_inv_amt_n     NUMBER;
      l_pay_amt_n     NUMBER;
      l_stmt_d        DATE;

   BEGIN

      --Fnd_Client_Info.set_org_context(2);
      MO_GLOBAL.SET_POLICY_CONTEXT('S',2);   -- R12 VSP_Org_Id_setup
      --
      --Load Statement SQL
      l_stmt_d    :=   TO_DATE(in_stmt_date_s,'DD-MON-RR');
       
   BEGIN

     DELETE swgcnv.Swgcnv_dd_Stmt_Interface WHERE sales_center = in_sales_center;
     
     FOR Cust_Rec  IN  ( 
                      SELECT  oracle_customer_id
                              ,oracle_customer_number
                              ,legacy_customer_number
                              ,billing_location_number
                              ,new_sales_center
                              ,cust.division
                       FROM    swgcnv.swgcnv_dd_temp_customers tc
                              ,SWGCNV.SWGCNV_DD_CUSTOMER_BILLTO CB
                              ,swgcnv_dd_cb_prestaging_cust cust
                       WHERE   1 = 1  --new_sales_center = 'BDG'
                       AND     cb.customer_number   =  tc.legacy_customer_number
                       AND     cust.customer_number = cb.customer_number
                       AND     cust.sales_center    = in_sales_center
                     )
     LOOP
  
       FOR Bill_Rec IN Cur_Billto(Cust_Rec.oracle_customer_id)
       LOOP
  
            SELECT NVL(SUM(amount_due_original),0)
            INTO   l_inv_amt_n
            FROM   apps.ar_payment_schedules_all  aps
                  ,apps.ra_customer_trx_all       ract
            WHERE  1 = 1 
            AND    aps.customer_site_use_id    =   ract.bill_to_site_use_id
            AND    aps.customer_id             =   ract.bill_to_customer_id
            AND    aps.customer_trx_id         =   ract.customer_trx_id
            AND    ract.attribute14            =  'NA'
            AND    ract.bill_to_site_use_id    =   Bill_Rec.site_use_id
            AND    ract.bill_to_customer_id    =   Bill_Rec.cust_account_id;

            SELECT NVL(SUM(amount_due_original),0)
            INTO   l_pay_amt_n
            FROM   apps.ar_cash_receipts_all       acra   
                  ,apps.ar_payment_schedules_all   aps
            WHERE  1 = 1
            AND    aps.customer_site_use_id     =    acra.customer_site_use_id
            AND    aps.cash_receipt_id          =    acra.cash_receipt_id
            AND    acra.attribute14             =   'NA'
            AND    acra.customer_site_use_id    =    Bill_Rec.site_use_id
            AND    acra.pay_from_customer       =    Bill_Rec.cust_account_id;
    
            L_STMT_AMT_N    :=    L_INV_AMT_N  +   L_PAY_AMT_N;

            insert into swgcnv.swgcnv_dd_stmt_interface 
            VALUES(Cust_Rec.legacy_customer_number,cust_rec.billing_location_number,l_stmt_amt_n,cust_rec.new_sales_center,cust_rec.division,l_stmt_d);

            COMMIT;
              
       END LOOP;   
    
     END LOOP;
  
   EXCEPTION
   WHEN OTHERS THEN
      --Dbms_Output.Put_Line('ERROR EXECUTING LOAD STMT BAL UPDATE SCRIPT');
      --Dbms_Output.Put_Line('ERROR: '||SQLERRM(SQLCODE));
      Fnd_File.put_line(Fnd_File.LOG,'ERROR EXECUTING LOAD STMT BAL UPDATE SCRIPT '||SQLERRM);
      Ou_errcode_n := 2;
      Ou_errmsg_s  := SQLERRM;
      ROLLBACK;
      RETURN;
   END;  
      
      --
      SELECT p.organization_id
      INTO   l_org_id_n
      FROM   mtl_parameters p
      WHERE  p.organization_code =  in_sales_center;

      SELECT user_id
      INTO   l_user_id_n
      FROM   fnd_user
      WHERE  user_name  =  'SWGCNV';

      FOR  main_rec  IN main_cur
      LOOP
         l_orig_system_customer_ref_s   :=  'DD-'
                                             || main_rec.system_code 
                                             || '-' || in_sales_center
                                             || '-' || main_rec.customer_number
                                             || '-' || main_rec.bill_to_address_id  
                                             ||'-HEADER';

        OPEN   cur_cust ( l_orig_system_customer_ref_s, main_rec.oracle_customer_id,l_org_id_n );
         
        FETCH  cur_cust
        INTO    l_customer_id_n
               ,l_billto_site_use_id_n;

        IF cur_cust%NOTFOUND THEN
         
            l_customer_id_n         := NULL;
            l_billto_site_use_id_n  := NULL;
            
        END IF;
         
        CLOSE  cur_cust;

        IF l_billto_site_use_id_n IS NOT NULL THEN
            
            INSERT   INTO   swg_ar_stmt_cust_prev_bal
                    (   statement_run_id
                       ,STATEMENT_ID
                       ,cust_acct_id
                       ,billto_site_id
                       ,statement_date
                       ,statement_balance
                       ,source
                       ,creation_date
                       ,creation_by
                       ,last_updated_date
                       ,last_updated_by
                    )
            VALUES
               (        NULL
                       ,NULL
                       ,l_customer_id_n
                       ,l_billto_site_use_id_n
                       ,main_rec.last_statement_date
                       ,main_rec.customer_balance
                       ,'CONVERSION'
                       ,SYSDATE
                       ,l_user_id_n
                       ,SYSDATE
                       ,l_user_id_n
                );

                UPDATE  swgcnv_dd_temp_customers
                SET     stmnt_proc_flag  =  'Y'
                        ,customer_balance        =  main_rec.customer_balance
                WHERE   legacy_customer_number   =   main_rec.customer_number;

                l_ins_rec_cnt  := l_ins_rec_cnt + 1;
            
                COMMIT;
            
        ELSE
               
            l_error_mesg_s  :=  'Bill To Site Id not found. '||l_orig_system_customer_ref_s;
            
              INSERT   INTO swgcnv_conversion_exceptions
               (   conversion_type
                  ,conversion_key_value
                  ,conversion_sub_key1
                  ,error_message
                  ,conversion_sub_key2
               )
                VALUES
               (   'STATEMENT'
                    ,main_rec.customer_number
                    ,main_rec.billto_location_number
                    ,l_error_mesg_s
                    ,main_rec.new_sales_center
                );

                l_err_rec_cnt  := l_err_rec_cnt + 1;
                
            COMMIT;
        END IF;
         
         l_total_rec_cnt   := l_total_rec_cnt   +   1;
         
      END LOOP;
      
      swg_output('                                 ');
      swg_output('      Statement Statistics       ');
      swg_output('*-------------------------------*');
      swg_output('Records read       : ' || l_total_rec_cnt);
      swg_output('Records inserted   : ' || l_ins_rec_cnt);
      swg_output('Records in error   : ' || l_err_rec_cnt);
      swg_output('*-------------------------------*');
      
   EXCEPTION
      WHEN OTHERS THEN
      Fnd_File.put_line(Fnd_File.LOG,'ERROR EXECUTING DSW Statement Conversion '||SQLERRM);
      Ou_errcode_n := 2;
      Ou_errmsg_s := SQLERRM;
      ROLLBACK;
   END Swgcnv_Dd_Stmnt_Cnv;
   
END Swgcnv_Dd_Stmnt_Pkg;
/
SHOW ERRORS;
Exit;
