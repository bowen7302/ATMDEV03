CREATE OR REPLACE PACKAGE BODY Swgcnv_Receipts_Conv_Pkg
IS

/*=========================================================================+
| Copyright (c) 2005 DS Waters, Atlanta, GA 30328 USA All rights reserved. |
+==========================================================================+
|                                                                          |
| File Name:     SWGCNV_RECEIPTS_CONV_PKB.pls                              |
| Description:   Receipts LockBox Processing Package                       |
|                                                                          |
| Revision History:                                                        |
| Date        Author          Change Description                           |
| ---------   ----------      -------------------------------------------  |
| Unknown     Unknown         Production Release                           |
| 08/27/2008  Pankaj Umate    Changes As Part Of R12 Upgrade               |
| 10/31/2008  Ajay            R12 Change(replaced fnd_client_info)         |
| 12/12/2008  Pankaj Umate    Changes For ARS03 Conversion Project         |
| 01/14/2008  Pankaj Umate    Changes For ARS04 Conversion Project         |
|                             Daptiv Project# 768                          |
|+========================================================================*/

   PROCEDURE swgcnv_generate_receipts
      (   ou_errmsg_s       OUT     VARCHAR2
         ,ou_errcode_n      OUT     NUMBER
         ,p_legacy_system   IN      VARCHAR2
         ,p_sales_center    IN      VARCHAR2
         ,p_lockbox_id      IN      NUMBER
      )
   IS

      CURSOR a 
      IS
      SELECT *
      FROM   ar_transmissions_all
      WHERE  transmission_name LIKE  p_legacy_system||'%'||p_sales_center||'%'
      ORDER BY transmission_id;

      l_request_id      NUMBER   :=    NULL;
      l_phase           VARCHAR2(20);
      l_status          VARCHAR2(20);
      l_dev_phase       VARCHAR2(20);
      l_dev_status      VARCHAR2(20);
      l_message         VARCHAR2(100);
      l_status_b        BOOLEAN;

      l_lockbox_id      NUMBER   :=    p_lockbox_id;

   BEGIN

      -- Commented out by Ashok on 03/09/07 begin
      /*
      SELECT  lockbox_id
      INTO    l_lockbox_id
      FROM    ar_lockboxes
      --WHERE  lockbox_number  = 'SACS CONVERSION BANK';
      WHERE  lockbox_number    = 'HOD CONVERSION BANK';
      */

      -- Commented out by Ashok on 03/09/07 end

      FOR i IN a
      LOOP

         l_request_id   :=    Fnd_Request.submit_request
                                 (   'AR'
                                    ,'SWGCNV_GEN_AUTOLOCK'    --'ARLPLB'
                                    ,NULL
                                    ,NULL
                                    ,FALSE
                                    ,'N'                                -- New Transmission?
                                    ,i.transmission_id                  -- Transmission Id
                                    ,i.transmission_id                  -- Original Request Id
                                    ,i.transmission_name                -- Batch Name
                                    ,'N'                                -- Submit Import?
                                    ,NULL                               -- Data File
                                    ,NULL                               -- Control File
                                    ,i.requested_trans_format_id        -- Transmission Format Id
                                    ,'Y'                                -- Submit Validation?
                                    ,'Y'                                -- Pay Unrelated Invoices?
                                    ,l_lockbox_id                       -- Lockbox Id
                                    ,SYSDATE                            -- GL Date
                                    ,'A'                                -- Report Format
                                    ,'Y'                                -- Complete Batches Only?
                                    ,'Y'                                -- Submit Postbatch?
                                    , NULL                              -- Alternate name search option
                                    ,'Y'                                -- Ignore_Invalid_Txn_Num
                                    ,NULL                               -- USSGL Transaction Code
                                    ,2                                  -- Organization Id
                                    ,'L'                                -- Submission Type. Added For R12 Upgrade
                                    ,NULL                               -- Scoring Model. Added For R12 Upgrade
                                 );

         Fnd_File.put_line(Fnd_File.LOG,l_request_id);

         COMMIT;

      END LOOP;

   EXCEPTION
      WHEN OTHERS THEN
         dbms_output.put_line('eRROR : '||SQLERRM);
         Fnd_File.put_line(Fnd_File.LOG,'error while calling ar conversion procedure : '||SQLERRM);

         ou_errmsg_s  := SQLERRM;
         ou_errcode_n := 2;
   END swgcnv_generate_receipts;
   ----------------------------------------------
   PROCEDURE  swgcnv_receipt_postbatch
      (   ou_errmsg_s          OUT     VARCHAR2
         ,ou_errcode_n         OUT     NUMBER
         ,p_legacy_system      IN      VARCHAR2
         ,p_sales_center       IN      VARCHAR2
         ,p_lockbox_id         IN      NUMBER
      )
   IS

      CURSOR a
      IS
      SELECT *
      FROM   ar_transmissions_all
      WHERE  transmission_name LIKE  p_legacy_system||'%'||p_sales_center||'%';

      l_request_id1        NUMBER        :=   NULL;
      l_phase1             VARCHAR2(20);
      l_status1            VARCHAR2(20);
      l_dev_phase1         VARCHAR2(20);
      l_dev_status1        VARCHAR2(20);
      l_message1           VARCHAR2(100);
      l_status_b1          BOOLEAN;

      l_lockbox_id         NUMBER        :=   p_lockbox_id;
 
      l_process_flag       VARCHAR2(1)   :=  'Y';

   BEGIN

      -- Commented out by Ashok on 03/09/07 begin
      /*

      SELECT lockbox_id
      INTO   l_lockbox_id
      FROM   ar_lockboxes
      WHERE  lockbox_number = 'HOD CONVERSION BANK';--'SACS CONVERSION BANK';
   
      */

      -- Commented out by Ashok on 03/09/07 end

      FOR i IN a
      LOOP

         IF l_process_flag = 'Y' THEN

            l_process_flag   :=   'N';

            l_request_id1  :=    Fnd_Request.submit_request
                                    (   'AR'
                                       ,'ARLPLB'
                                       , NULL
                                       , NULL
                                       , FALSE
                                       ,'N'                          -- New Transmission?
                                       , i.transmission_id           -- Transmission Id
                                       , i.transmission_id           -- Original Request Id
                                       , i.transmission_name         -- Batch Name
                                       ,'N'                          -- Submit Import?
                                       , NULL                        -- Data File
                                       , NULL                        -- Control File
                                       , i.requested_trans_format_id -- Transmission Format Id
                                       ,'N'                          -- Submit Validation?
                                       , NULL                        -- Pay Unrelated Invoices?
                                       , l_lockbox_id                -- Lockbox Id
                                       , NULL                        -- GL Date
                                       , NULL                        -- Report Format
                                       , NULL                        -- Complete Batches Only?
                                       ,'Y'                          -- Submit Postbatch?
                                       , NULL                        -- Alternate name search option
                                       ,'Y'                          -- Ignore_Invalid_Txn_Num
                                       , NULL                        -- USSGL Transaction Code
                                       , 2                           -- Organization Id 
                                       ,'L'                          -- Submission Type. Added For R12 Upgrade
                                       ,NULL                         -- Scoring Model. Added For R12 Upgrade
                                    );

            COMMIT;

            Fnd_File.put_line(Fnd_File.LOG,l_request_id1);

            LOOP

               l_status_b1  :=   Fnd_Concurrent.wait_for_request
                                    (   l_request_id1
                                       ,30
                                       ,30
                                       ,l_phase1
                                       ,l_status1
                                       ,l_dev_phase1
                                       ,l_dev_status1
                                       ,l_message1
                                    );

               EXIT WHEN l_dev_phase1 = 'COMPLETE';

            END LOOP;

            Fnd_File.put_line(Fnd_File.LOG,'Status of the SWGCNV Autolockbox Program1  : '||l_dev_phase1||' '||l_dev_status1);

            --2nd
            IF    l_dev_phase1   =       'COMPLETE'   AND 
                  l_dev_status1    =       'NORMAL'     AND
                  l_request_id1    <>      0
            THEN

               l_process_flag := 'Y';
               Fnd_File.put_line(Fnd_File.LOG,'inside if : '||l_request_id1);

            END IF; --

            Fnd_File.put_line(Fnd_File.LOG,l_request_id1);

         END IF; --l_process_flag

      END LOOP;

   EXCEPTION
      WHEN OTHERS	THEN
         dbms_output.put_line('eRROR : '||SQLERRM);
         Fnd_File.put_line(Fnd_File.LOG,'error while calling ar conversion procedure : '||SQLERRM);
         ou_errmsg_s     :=   SQLERRM;
         ou_errcode_n    :=   2;

   END swgcnv_receipt_postbatch;
   ---------------------------------------------------

   PROCEDURE   Swgcnv_Lockbox_Proc
                  (   ou_errmsg_s          OUT     VARCHAR2
                     ,ou_errcode_n         OUT     NUMBER
                     ,p_legacy_system      IN      VARCHAR2
                     ,p_division           IN      VARCHAR2
                     ,p_sales_center       IN      VARCHAR2
                     ,p_trans_name         IN      VARCHAR2
                     ,p_gl_date            IN      DATE
                     ,p_lockbox_id         IN      NUMBER
                  )
   IS

      CURSOR cur_rec_cust
      IS
      SELECT    /*+ INDEX(SWGCNV_DD_AR_INTERFACE,SWGCNV_DD_AR_INTERFACE_NR) */
                a.orig_system_bill_customer_ref     legacy_customer
               ,b.oracle_customer_id                oracle_cust_id
      FROM      swgcnv_dd_ar_interface        a
               ,swgcnv_dd_temp_customers      b
      WHERE     a.interface_line_context            =      'DD CONVERSION'
      AND       a.division                          =       p_division
      AND       a.sales_center                      =       p_sales_center
      AND       a.orig_system_bill_customer_ref     =       b.legacy_customer_number
      AND       a.cust_trx_type_name                =      'PAYMENT'
      AND       b.receipt_proc_flag                 =      'N'   -- Uncommented For ARS03. Facilitates Receipt Reprocessing
      AND       b.cust_import_flag                  =      'Y'
      AND       b.division                          =       p_division      
      AND       b.new_sales_center                  =       p_sales_center
      GROUP BY  a.orig_system_bill_customer_ref
               ,b.oracle_customer_id;
      /*                
      SELECT    a.orig_system_bill_customer_ref     legacy_customer
               ,b.oracle_customer_id                oracle_cust_id
      FROM      swgcnv_dd_ar_interface        a
               ,swgcnv_dd_temp_customers      b
      WHERE     b.division                          =       p_division
      AND       a.sales_center                      =       p_sales_center
      AND       a.orig_system_bill_customer_ref     =       b.legacy_customer_number
      AND       a.division                          =       b.division
      AND       b.receipt_proc_flag                 =      'N'   -- Uncommented For ARS03. Facilitates Receipt Reprocessing
      AND       b.cust_import_flag                  =      'Y'
      AND       a.cust_trx_type_name                =      'PAYMENT'
      AND       a.interface_line_context            =      'DD CONVERSION'
      GROUP BY  a.orig_system_bill_customer_ref
               ,b.oracle_customer_id;
      */
      
      CURSOR cur_receipts(  l_orig_system_bill_cust      VARCHAR2
                           ,l_oracle_customer_id         NUMBER
                          )
      IS
      SELECT    
                a.orig_system_bill_customer_ref
               ,a.orig_system_bill_address_ref
               ,a.trx_date
               ,a.description
               ,a.currency_code
               ,a.trx_number
               ,SUM((NVL(a.amount,0) + NVL(a.attribute10,0))) total_amt
               ,a.tax_status
      FROM      swgcnv_dd_ar_interface           a
      WHERE    a.interface_line_context            =   'DD CONVERSION'
      AND      a.ar_proc_flag                      =   'N'   -- Added For ARS03 Conversion. Facilitates AR Transaction Reprocessing
      AND      a.division                          =    p_division       
      AND      a.sales_center                      =    p_sales_center
      AND      a.orig_system_bill_customer_ref     =    l_orig_system_bill_cust
      AND      a.cust_trx_type_name                =   'PAYMENT'
      GROUP BY  a.orig_system_bill_customer_ref
               ,a.orig_system_bill_address_ref
               ,a.trx_date
               ,a.description
               ,a.currency_code
               ,a.trx_number
               ,a.tax_status;
      
      /*
      SELECT    a.orig_system_bill_customer_ref
               ,a.orig_system_bill_address_ref
               --,a.orig_system_ship_address_ref
               ,a.trx_date
               ,a.description
               ,a.currency_code
               ,a.trx_number
               ,SUM((NVL(a.amount,0) + NVL(a.attribute10,0))) total_amt
               ,b.oracle_customer_id
               ,b.legacy_customer_number
               ,a.tax_status
      FROM      swgcnv_dd_ar_interface           a
               ,swgcnv_dd_temp_customers         b
      WHERE    b.division                          =   p_division
      AND      a.sales_center                      =   p_sales_center
      AND      a.orig_system_bill_customer_ref     =   b.legacy_customer_number
      AND      a.division                          =   b.division
      AND      a.orig_system_bill_customer_ref     =   l_orig_system_bill_cust
      AND      b.oracle_customer_id                =   l_oracle_customer_id
      AND      a.ar_proc_flag                      =   'N'   -- Added For ARS03 Conversion. Facilitates AR Transaction Reprocessing
      --AND     b.receipt_proc_flag                =   'N'
      --AND     b.cust_import_flag                 =   'Y'
      AND      a.cust_trx_type_name                =   'PAYMENT'
      AND      a.interface_line_context            =   'DD CONVERSION'
      GROUP BY  a.orig_system_bill_customer_ref
               ,a.orig_system_bill_address_ref
               --,a.orig_system_ship_address_ref
               ,a.trx_date
               ,a.description
               ,a.currency_code
               ,a.trx_number
               ,b.oracle_customer_id
               ,b.legacy_customer_number
               ,a.tax_status;
      */
      
      l_transmission_id             NUMBER          :=    NULL;
      l_lockbox_id                  NUMBER          :=    p_lockbox_id;
      l_lockbox_number              VARCHAR2(30);
      l_bank_orig_number            VARCHAR2(30);
      l_transmission_format_id      NUMBER;
      l_format_name                 VARCHAR2(25);
      l_description                 VARCHAR2(240);
      l_billto_number               VARCHAR2(40);
      l_account_number              VARCHAR2(30);
      l_cust_acct_id                NUMBER;
      l_billto_location             VARCHAR2(40);
      l_billto_site_use_id          NUMBER;
      l_rec_cnt                     NUMBER:= 0;
      l_billto_address_ref          VARCHAR2(200);
      l_item_number                 NUMBER:= 0;
      l_err_message                 VARCHAR2(2000)   :=    NULL;
      l_msi_date                    VARCHAR2(10);
      l_process_flag                VARCHAR2(1)      :=   'N';

      l_process_cnt                 NUMBER           :=    0;
      l_process_cnt_int             NUMBER           :=    0;
      l_process_batch               NUMBER           :=    0;

   BEGIN

      --Fnd_Client_Info.set_org_context(2);     -- Commented As Part Of R12 Changes
      Mo_Global.Set_Policy_Context('S', 2);     -- modified by Ajay on 9/2/2008 for R12	

      -- Get the Lockbox number
      BEGIN

         SELECT   --lockbox_id
                   lockbox_number
                  ,bank_origination_number
         INTO     --l_lockbox_id
                   l_lockbox_number
                  ,l_bank_orig_number
         FROM     ar_lockboxes
         WHERE  --lockbox_number = 'HOD CONVERSION BANK';--'SACS CONVERSION BANK';
         lockbox_id  =  l_lockbox_id;  -- Query parameterized by Ashok on 03/09/07
         
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            Fnd_File.put_line(Fnd_File.LOG,'error while getting the lockbox info : '||SQLERRM);
         WHEN OTHERS THEN
            Fnd_File.put_line(Fnd_File.LOG,'error while getting the lockbox info : '||SQLERRM);
      END;

      -- Get the Transmission format
      BEGIN

         SELECT transmission_format_id
               ,format_name
               ,description
         INTO   l_transmission_format_id
               ,l_format_name
               ,l_description
         FROM   ar_transmission_formats
         WHERE  format_name     =    'CONVERT';
         
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            Fnd_File.put_line(Fnd_File.LOG,'error while getting the format info : '||SQLERRM);
         WHEN OTHERS THEN
            Fnd_File.put_line(Fnd_File.LOG,'error while getting the format info : '||SQLERRM);
      END;

      FOR cur_group_cust IN cur_rec_cust
      LOOP

         -- Get the sequence Id for AR_TRANSMISSIONS
         l_transmission_id    :=    NULL;

         IF l_process_cnt = 0 THEN

            SELECT ar_transmissions_s.NEXTVAL
            INTO   l_transmission_id
            FROM   dual;

            l_process_cnt   :=  1;

         BEGIN
          
            INSERT INTO ar_transmissions_all
               (   transmission_request_id
                  ,created_by
                  ,creation_date
                  ,last_updated_by
                  ,last_update_date
                  ,trans_date
                  ,requested_trans_format_id
                  ,status
                  ,transmission_id
                  ,transmission_name
                  ,latest_request_id
                  ,org_id                 -- Added As Part Of Release 12 Update
               )
            VALUES  
               (   l_transmission_id
                  ,Fnd_Global.user_id
                  ,SYSDATE
                  ,Fnd_Global.user_id
                  ,SYSDATE
                  ,SYSDATE
                  ,l_transmission_format_id
                  ,'NB'
                  ,l_transmission_id
                  ,p_legacy_system||p_sales_center||' LOCKBOX'||l_process_batch
                  ,l_transmission_id
                  ,2                    -- Added As Part Of Release 12 Update
               );

            COMMIT;

            Fnd_File.put_line(Fnd_File.LOG,'transmission_name  : '||p_legacy_system||p_sales_center||' LOCKBOX'||l_process_batch);

         
         -- SGB  BAD ERROR CATCH...Commenting out.. Should bomb entire process
         -- EXCEPTION
         --   WHEN NO_DATA_FOUND THEN
         --      Fnd_File.put_line(Fnd_File.LOG,'error while inserting into ar_transmissions_all : '||SQLERRM);
         --   WHEN OTHERS THEN
         --      Fnd_File.put_line(Fnd_File.LOG,'error while inserting into ar_transmissions_all : '||SQLERRM);
         END;

      END IF;

      FOR cur_receipt_rec IN cur_receipts( cur_group_cust.legacy_customer
                                          ,cur_group_cust.oracle_cust_id
                                         )
      LOOP

         l_process_flag         :=   'Y';
         l_billto_address_ref   :=    NULL;

         IF SUBSTR(cur_receipt_rec.orig_system_bill_address_ref,1,1) = '0' THEN

            IF SUBSTR(cur_receipt_rec.orig_system_bill_address_ref,1,2) = '00' THEN

               l_billto_number := SUBSTR(cur_receipt_rec.orig_system_bill_address_ref,3);

            ELSE

               l_billto_number := SUBSTR(cur_receipt_rec.orig_system_bill_address_ref,2);

            END IF;

         ELSE

            l_billto_number := cur_receipt_rec.orig_system_bill_address_ref;

         END IF;

         l_billto_address_ref := 'DD'  ||'-'|| p_legacy_system 
                                       ||'-'|| p_sales_center 
                                       ||'-'|| cur_receipt_rec.orig_system_bill_customer_ref 
                                       ||'-'|| l_billto_number 
                                       ||'-'|| 'HEADER';

         BEGIN --1

            SELECT hzca.account_number
                  ,hzca.cust_account_id
                  ,hzcsu.location
                  ,hzcsu.site_use_id
            INTO   l_account_number
                  ,l_cust_acct_id
                  ,l_billto_location
                  ,l_billto_site_use_id
            FROM   hz_cust_accounts                      hzca
                  ,hz_cust_site_uses                     hzcsu
                  ,hz_cust_acct_sites                    hzcas
            WHERE  hzcas.cust_account_id         =     hzca.cust_account_id
            AND    hzcsu.cust_acct_site_id       =     hzcas.cust_acct_site_id
            AND    hzcsu.site_use_code           =    'BILL_TO'
            AND    hzca.cust_account_id          =     cur_group_cust.oracle_cust_id  --cur_receipt_rec.oracle_customer_id
            AND    hzcas.orig_system_reference   =     l_billto_address_ref;

            l_process_flag  := 'Y';

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               l_billto_address_ref    :=    'DD'  ||'-'|| p_legacy_system 
                                                   ||'-'|| p_sales_center
                                                   ||'-'|| cur_receipt_rec.orig_system_bill_customer_ref
                                                   ||'-'|| l_billto_number||'1' 
                                                   ||'-'|| 'HEADER';

               BEGIN --2

                  SELECT hzca.account_number
                        ,hzca.cust_account_id
                        ,hzcsu.location
                        ,hzcsu.site_use_id
                  INTO   l_account_number
                        ,l_cust_acct_id
                        ,l_billto_location
                        ,l_billto_site_use_id
                  FROM   hz_cust_accounts                  hzca
                        ,hz_cust_site_uses                 hzcsu
                        ,hz_cust_acct_sites                hzcas
                  WHERE  hzcas.cust_account_id             =    hzca.cust_account_id
                  AND    hzcsu.cust_acct_site_id           =    hzcas.cust_acct_site_id
                  AND    hzcsu.site_use_code               =   'BILL_TO'
                  AND    hzca.cust_account_id              =    cur_group_cust.oracle_cust_id --cur_receipt_rec.oracle_customer_id
                  AND    hzcas.orig_system_reference       =    l_billto_address_ref;

                  l_process_flag  := 'Y';

               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     l_billto_address_ref :=    'DD'  ||'-'|| p_legacy_system 
                                                      ||'-'|| p_sales_center 
                                                      ||'-'|| cur_receipt_rec.orig_system_bill_customer_ref
                                                      ||'%'|| 'HEADER';

                     BEGIN --3

                        SELECT hzca.account_number
                              ,hzca.cust_account_id
                              ,hzcsu.location
                              ,hzcsu.site_use_id
                        INTO   l_account_number
                              ,l_cust_acct_id 
                              ,l_billto_location
                              ,l_billto_site_use_id
                        FROM   hz_cust_accounts             hzca
                              ,hz_cust_site_uses            hzcsu
                              ,hz_cust_acct_sites           hzcas
                        WHERE  hzcas.cust_account_id         =   hzca.cust_account_id
                        AND    hzcsu.cust_acct_site_id       =   hzcas.cust_acct_site_id
                        AND    hzcsu.site_use_code           =  'BILL_TO'
                        AND    hzca.cust_account_id          =   cur_group_cust.oracle_cust_id --cur_receipt_rec.oracle_customer_id
                        AND    hzcas.orig_system_reference   LIKE l_billto_address_ref
                        AND    ROWNUM                        =   1;

                        l_process_flag  := 'Y';

                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN

                        dbms_output.put_line('No data found for this customer : '||l_billto_address_ref);

                        INSERT INTO swgcnv_conversion_exceptions
                           (   conversion_type
                              ,conversion_key_value
                              ,conversion_sub_key2
                              ,error_message
                           )
                        VALUES
                           (   'AUTOLOCKBOX'
                              ,SUBSTR(l_billto_address_ref,1,49)
                              ,p_sales_center
                              --,'Customer Information not found'
                              ,'Customer Information not found for customer/trx/date/bill addr ref/tot amt/description: '
                                 ||cur_receipt_rec.orig_system_bill_customer_ref||'/'
                                 ||cur_receipt_rec.trx_number||'/'
                                 ||to_char(cur_receipt_rec.trx_date,'DD-MON-YYYY')||'/'
                                 ||cur_receipt_rec.orig_system_bill_address_ref||'/'
                                 ||to_char(cur_receipt_rec.total_amt)||'/'
                                 ||cur_receipt_rec.description
                           );

                        l_process_flag := 'N';

                     WHEN OTHERS THEN

                        dbms_output.put_line('Error customer billto info : '||l_billto_address_ref||'  '||SQLERRM);
                        l_err_message  := SQLERRM;

                        INSERT INTO swgcnv_conversion_exceptions
                           (   conversion_type
                              ,conversion_key_value
                              ,conversion_sub_key2
                              ,error_message
                           )
                        VALUES
                           (   'AUTOLOCKBOX'
                              ,SUBSTR(l_billto_address_ref,1,49)
                              ,p_sales_center
                              ,l_err_message
                           );

                        l_process_flag := 'N';

                  END;--3

               WHEN OTHERS THEN
                  dbms_output.put_line('Error customer billto info : '||l_billto_address_ref||'  '||SQLERRM);
                  l_err_message  := SQLERRM;

                  INSERT INTO swgcnv_conversion_exceptions
                     (   conversion_type
                        ,conversion_key_value
                        ,conversion_sub_key2
                        ,error_message
                     )
                  VALUES 
                     (   'AUTOLOCKBOX'
                        ,SUBSTR(l_billto_address_ref,1,49)
                        ,p_sales_center
                        ,l_err_message
                     );

                  l_process_flag := 'N';

            END; --2

            WHEN OTHERS THEN
               dbms_output.put_line('Error customer billto info : '||l_billto_address_ref||'  '||SQLERRM);
               l_err_message  := SQLERRM;

               INSERT INTO swgcnv_conversion_exceptions
                  (   conversion_type
                     ,conversion_key_value
                     ,conversion_sub_key2
                     ,error_message
                  )
               VALUES 
                  (   'AUTOLOCKBOX'
                     ,SUBSTR(l_billto_address_ref,1,49)
                     ,p_sales_center
                     ,l_err_message
                  );

               l_process_flag := 'N';

         END; --1

         IF l_process_flag    =     'Y'   THEN

            BEGIN

               --IF cur_receipt_rec.tax_status IN ('UI','UP','UR','UN') THEN  -- Commented For ARS04 Conversion
               IF cur_receipt_rec.tax_status    IS    NULL  THEN
  
                  l_msi_date     :=    NULL;

               ELSE
  
                  l_msi_date     :=   'NA';

               END IF;

               l_item_number := l_item_number + 1;

               INSERT  INTO   ar_payments_interface_all
                  (   transmission_record_id
                     ,created_by
                     ,creation_date
                     ,last_updated_by
                     ,last_update_date
                     ,record_type
                     ,status
                     ,transmission_request_id
                     ,transmission_id
                     ,deposit_date
                     ,gl_date
                     ,batch_name
                     ,item_number
                     ,currency_code
                     ,remittance_amount
                     ,check_number
                     ,receipt_date
                     ,lockbox_number
                     ,customer_number
                     ,customer_id
                     ,customer_site_use_id
                     ,bill_to_location
                     ,attribute_category
                     ,attribute14
                     ,attribute5
                     ,org_id              -- Added As Part Of Release 12 Update
                  )
               VALUES
                  (   ar_payments_interface_s.NEXTVAL
                     ,Fnd_Global.user_id
                     ,SYSDATE
                     ,Fnd_Global.user_id
                     ,SYSDATE
                     ,'6'
                     ,'AR_PLB_NEW_RECORD'
                     ,ar_transmissions_s.CURRVAL
                     ,ar_transmissions_s.CURRVAL
                     ,cur_receipt_rec.trx_date
                     ,TO_DATE(p_gl_date,'DD-MON-RRRR')
                     ,p_legacy_system||p_sales_center||' LOCKBOX'||l_process_batch
                     ,l_item_number
                     ,'USD'
                     ,(cur_receipt_rec.total_amt * -1 * 100)
                     ,p_sales_center||'_'||l_item_number
                     ,cur_receipt_rec.trx_date
                     ,l_lockbox_number
                     ,l_account_number
                     ,l_cust_acct_id
                     ,l_billto_site_use_id
                     ,l_billto_location
                     ,'LOCKBOX'
                     ,l_msi_date
                     ,l_lockbox_number
                     ,2                      -- Added As Part Of Release 12 Update
                  );

               BEGIN

                  UPDATE swgcnv_dd_temp_customers
                  SET    receipt_proc_flag    =     'I'
                  WHERE  oracle_customer_id   =     l_cust_acct_id
                  AND    new_sales_center     =     p_sales_center;

               EXCEPTION
                  WHEN OTHERS THEN
                     Fnd_File.put_line(Fnd_File.LOG,'error while update temp cutomers table : '||'-'||l_cust_acct_id||'-'||SQLERRM);
               END;

               l_account_number        :=    NULL;
               l_cust_acct_id          :=    NULL;
               l_billto_site_use_id    :=    NULL;
               l_billto_location       :=    NULL;
               l_rec_cnt               :=    l_rec_cnt + 1;
               l_process_cnt_int       :=    l_process_cnt_int + 1;

            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  Fnd_File.put_line(Fnd_File.LOG,'error while inserting into ar_payments_interface_all : '||SQLERRM);
                  l_err_message  := SQLERRM;

                  INSERT INTO swgcnv_conversion_exceptions
                     (   conversion_type
                        ,conversion_key_value
                        ,conversion_sub_key2
                        ,error_message
                     )
                  VALUES 
                     (   'AUTOLOCKBOX'
                        ,l_cust_acct_id||'-'||l_billto_site_use_id
                        ,p_sales_center
                        ,l_err_message
                     );

               WHEN OTHERS THEN
                  Fnd_File.put_line(Fnd_File.LOG,'error while inserting into ar_payments_interface_all : '||SQLERRM);
                  l_err_message   :=   SQLERRM;

                  INSERT INTO swgcnv_conversion_exceptions
                     (   conversion_type
                        ,conversion_key_value
                        ,conversion_sub_key2
                        ,error_message
                     )
                  VALUES
                     (   'AUTOLOCKBOX'
                        ,l_cust_acct_id||'-'||l_billto_site_use_id
                        ,p_sales_center
                        ,l_err_message
                     );
               
            END;

         END IF; --  l_process_flag

      END LOOP; --cur_receipt_rec

         l_process_cnt  := l_process_cnt + 1;

         IF l_process_cnt  = 1501 THEN

            Fnd_File.put_line(Fnd_File.LOG,'No. of Records for Batch : '||l_process_batch||' '||l_process_cnt_int);

            l_process_cnt_int :=  0;
            l_process_cnt     :=  0;
            l_process_batch   :=  l_process_batch + 1;
         END IF;

      END LOOP;

      COMMIT;

   EXCEPTION
      WHEN OTHERS THEN
         dbms_output.put_line('eRROR : '||SQLERRM);
         Fnd_File.put_line(Fnd_File.LOG,'error while calling ar conversion procedure : '||SQLERRM);
         ou_errmsg_s       :=   SQLERRM;
         ou_errcode_n      :=   2;
   END Swgcnv_Lockbox_Proc;
END Swgcnv_Receipts_Conv_Pkg;
/
sho err
EXIT;
