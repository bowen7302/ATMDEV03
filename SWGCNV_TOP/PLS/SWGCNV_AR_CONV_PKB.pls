CREATE OR REPLACE PACKAGE BODY APPS.Swgcnv_Ar_Conv_Pkg
IS

/* $Header: SWGCNV_AR_CONV_PKB.pls 1.1 2010/04/09 09:33:33 PU $ */
/*=============================================================================+
| Copyright (c) 2005 DS Waters, Atlanta, GA 30328 USA All rights reserved.     |
+==============================================================================+
| Name:          SWGCNV_AR_CONV_PKG                                            |
| File Name:     SWGCNV_AR_CONV_PKB.pls                                        |
| Description:   Converion AR Package                                          |
|                                                                              |
| Revision History:                                                            |
| Date        Author          Change Description                               |
| ---------   ----------      -------------------------------------------      |
| Unknown     Unknown         Production Release                               |
| 01/14/2008  Pankaj Umate    Changes as Per WO 18998. Conversion Enhancements |    
| 08/25/2008  Pankaj Umate    Changes As Part Of R12 Upgrade                   |
| 10/30/08    Ajay            Changes for R12(fnd_client_info replaced)        |
| 10/27/2008  Pankaj Umate    Changes For RHDIST Conversion. Hard Coded RA     |
|                             Distribution Accounts                            | 
| 12/08/2008  Pankaj Umate    Changes For ARS03 Conversion. Hard Coded RA      |
|                             Distribution Accounts                            |
| 01/13/2008  Pankaj Umate    Change For ARS04 Conversion. Hard Coded RA       |
|                             Distribution Accounts and Fine Tuning Queries    |
|                             Moved SWGCNV_UPD_AR_STAGING_P Into Package       |
|                             Daptiv Project # 768                             |
| 02/20/2009  Pankaj Umate    Hard Coded SUW Distribution Account. Daptiv # 822|
| 05/18/2009  Mike Schenk     #303                                             |
| 12/08/2009  Pankaj Umate    Changes For SAGE Acquisition. Daptiv # 1299      |
|                             Added Procedure To Apply And Unapply Receipts    |
| 02/18/2010  Mike Schenk     #1359                                            |
| 04/09/2010  Pankaj Umate    Daptiv # 1471. Conversion Mapping Table Migration|
| 06/10/2010  Mike Schenk     #1552                                            |
| 08/20/2010  Mike Schenk     #1641                                            |
| 10/21/2010  Mike Schenk     #1646                                            |
| 03/31/2011  Mike Schenk     #19447 Derive gl segment2 from mapping instead of|
|                                    hard coding.                              |
| 03/09/2012  Mike Schenk     #20129                                           |
| 06/06/2012  Mike Schenk     #20429  Procedure to load and submit Autoinvoice |
| 08/06/2012  Stephen Bowen   #20457  If Master missing, derive new one        |
| 09/09/2015  Stephen Bowen   EB-1596 Changes to AR Diagnostic Report          |
| 09/10/2015  Vijay Padmanabhan EB-1596 Changes to AR Diagnostic Report        |
|                               DSW AR Conversion Pre-update (ARS01)           |    
| 11/01/2015  Stephen Bowen   EB-1669 Remove oracle item id on trx line        |
| 03/23/2016  Stephen Bowen   EB 1821 Added new columns for insert             |
+=============================================================================*/

   FUNCTION swgcnv_shipto_address_id ( p_legacy_system      IN VARCHAR2
                                       ,p_sales_center      IN VARCHAR2
                                       ,p_customer_ref      IN VARCHAR2
                                       ,p_ship_address_ref  IN VARCHAR2
                                       ,p_cust_account_id   IN NUMBER
                                     )
   RETURN  NUMBER
   IS

      CURSOR cur_ship_address(l_ship_address_ref VARCHAR2)
      IS
      SELECT hzcas.cust_acct_site_id  
      FROM   hz_cust_site_uses         hzcsu
            ,hz_cust_acct_sites        hzcas
            ,hz_cust_accounts          hzca
      WHERE  hzcsu.site_use_code       =   'SHIP_TO'
      AND    hzcsu.cust_acct_site_id   =    hzcas.cust_acct_site_id
      AND    DECODE ( INSTR ( hzcas.orig_system_reference,'HEADER',1,1)
                     ,0, SUBSTR ( hzcas.orig_system_reference, 
                                  INSTR (hzcas.orig_system_reference,'-',1,4)+ 1
                                 )
                     ,SUBSTR (REPLACE ( hzcas.orig_system_reference, '-HEADER'), 
                                        INSTR (hzcas.orig_system_reference,'-',1,4) + 1
                                       )
                     )           --mts 20129 =  p_ship_address_ref
                                 LIKE   p_ship_address_ref
      AND hzcas.cust_account_id  =  hzca.cust_account_id
      AND hzca.cust_account_id   =  p_cust_account_id;
      
      CURSOR  cur_alt_ship_address
      IS
      SELECT  hzcas.cust_acct_site_id
      FROM    hz_cust_site_uses         hzcsu
             ,hz_cust_acct_sites        hzcas
      WHERE   hzcas.cust_acct_site_id   =   hzcsu.cust_acct_site_id
      AND     hzcsu.site_use_code       =  'SHIP_TO'
      AND     hzcas.cust_account_id     =   p_cust_account_id
      AND     ROWNUM                    =   1;

      l_shipto_address_ref   VARCHAR2(200) := NULL;
      l_shipto_address_id    NUMBER        := NULL;
      l_shipto_number        VARCHAR2(20)  := NULL;

   BEGIN

      --Fnd_Client_Info.set_org_context(2);     -- R12 Changes
      mo_global.set_policy_context('S', 2);     -- modified by Ajay on 9/2/2008 for R12
    
      l_shipto_address_ref    :=    NULL;
      l_shipto_address_id     :=    NULL;
      l_shipto_number         :=    NULL;

      IF SUBSTR( p_ship_address_ref,1,1 ) = '0' THEN

         IF SUBSTR( p_ship_address_ref,1,2 ) = '00' THEN

            l_shipto_number := SUBSTR(p_ship_address_ref,3);

         ELSE

            l_shipto_number := SUBSTR(p_ship_address_ref,2);

         END IF;

      ELSE

         l_shipto_number := p_ship_address_ref;

      END IF;

      l_shipto_address_ref := 'DD'||'-'|| p_legacy_system   ||'%'||p_customer_ref ||'%'|| l_shipto_number ||'%';

      FOR i IN cur_ship_address(l_shipto_address_ref)
      LOOP

         l_shipto_address_id := i.cust_acct_site_id;

      END LOOP;

      IF  l_shipto_address_id IS NULL THEN

         FOR j IN cur_alt_ship_address
         LOOP

            l_shipto_address_id := j.cust_acct_site_id;

         END LOOP;

      END IF;

      RETURN l_shipto_address_id;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         dbms_output.put_line('No Data found : '||SQLERRM);
         Fnd_File.put_line(Fnd_File.LOG,'No Data found for shipto : '||SQLERRM);
         RETURN NULL;
      WHEN OTHERS THEN
         dbms_output.put_line('eRROR         : '||SQLERRM);
         Fnd_File.put_line(Fnd_File.LOG,'eRROR while retreving shipto : '||SQLERRM);
         RETURN NULL;
   END swgcnv_shipto_address_id;
   
   --
   PROCEDURE  swgcnv_unbilled_billed  (  
                                         ou_errbuff_s            OUT           VARCHAR2
                                        ,in_legacy_s             IN            VARCHAR2
                                      )
   IS
   CURSOR swg_billed_lookup
   IS
   SELECT  old_code                        sales_center,
           old_sub_code_1                  msi_type,
           to_date(new_code,'dd-mon-rrrr') trx_date
   FROM    swgcnv_map
   WHERE   system_code   =  in_legacy_s
   AND     type_code     = 'UNBILLED'
   ;
   
   l_sc_n  number:=0;
   
   TYPE   l_billed_look_type IS TABLE OF swg_billed_lookup%ROWTYPE INDEX BY BINARY_INTEGER;

   CURSOR billed_unbilled_csr IS
   SELECT
          DISTINCT
          orig_system_bill_customer_ref,
          DECODE(cust.stmt_type,'P','P','M') STMT_TYPE,
          ah.sales_center
   FROM   swgcnv_dd_ar_history ah,
          swgcnv_dd_cb_prestaging_cust cust
   WHERE  cust.customer_number = ah.orig_system_bill_customer_ref;

   TYPE   l_billed_data_type IS TABLE OF billed_unbilled_csr%ROWTYPE INDEX BY BINARY_INTEGER;

   l_billed_info_type            l_billed_data_type;
   l_billed_lookup_type          l_billed_look_type;
   
   BEGIN

    ou_errbuff_s   :=   'S';

    UPDATE swgcnv_dd_cb_prestaging_cust
    SET    stmt_type  =  'P'
    WHERE  stmt_type  IS NULL;

    l_billed_lookup_type.DELETE;
    OPEN     swg_billed_lookup;
    FETCH    swg_billed_lookup
    BULK     COLLECT
    INTO     l_billed_lookup_type;
    CLOSE    swg_billed_lookup;

    l_billed_info_type.DELETE;
    OPEN     billed_unbilled_csr;
    FETCH    billed_unbilled_csr
    BULK     COLLECT
    INTO     l_billed_info_type;
    CLOSE    billed_unbilled_csr;
      
    SELECT count( distinct sales_center)
    INTO   l_sc_n
    FROM   swgcnv_dd_ar_history;

    l_sc_n := l_sc_n * 2;
    --2 rows per SC

    IF ( l_billed_lookup_type.COUNT > 0
         AND l_sc_n <= l_billed_lookup_type.COUNT
             AND l_billed_info_type.COUNT > 0 ) THEN

      FOR i IN 1..l_billed_lookup_type.COUNT LOOP

        FOR t IN 1..l_billed_info_type.COUNT LOOP

          IF l_billed_info_type( t ).stmt_type = l_billed_lookup_type( i ).msi_type
            AND l_billed_info_type( t ).sales_center = l_billed_lookup_type( i ).sales_center THEN

          UPDATE    swgcnv_dd_ar_history
             SET    trxn_status  =   'NA'
           WHERE    sales_center =   l_billed_lookup_type( i ).sales_center
             AND    trx_date     <=  l_billed_lookup_type( i ).trx_date
             AND    orig_system_bill_customer_ref = l_billed_info_type( t ).orig_system_bill_customer_ref;

          END IF;

        END LOOP;

      END LOOP;

    ELSE
        
      Fnd_File.put_line(Fnd_File.LOG,'ERROR swgcnv_unbilled_billed .  Validate mapping and AR data load');
      ou_errbuff_s   :=   'E';

    END IF;
    
   EXCEPTION
   WHEN OTHERS THEN
    
      Fnd_File.put_line(Fnd_File.LOG,'ERROR swgcnv_unbilled_billed '||SQLERRM);
      ou_errbuff_s   :=   'E';
      
   END swgcnv_unbilled_billed;
   
   ----
   FUNCTION swgcnv_newitem_code  ( p_sales_center      VARCHAR2
                                  ,p_old_item_code     VARCHAR2
                                 )
   RETURN  VARCHAR2
   IS

      CURSOR  cur_new_code1
      IS
      SELECT new_code
      FROM   swgcnv_map   
      WHERE  type_code        =     'ITEM'
      AND    old_sub_code_1   =     p_sales_center
      AND    old_code         =     p_old_item_code
      AND    old_sub_code     =     '00069091'
      AND    system_code      =     'SACS';

      CURSOR  cur_new_code2
      IS
      SELECT new_code
      FROM   swgcnv_map
      WHERE  type_code        =     'ITEM'
      AND    old_code         =      p_old_item_code
      AND    old_sub_code     =     '00069091'
      AND    system_code      =     'SACS'
      AND    old_sub_code_1   IS  NULL;

      l_new_item_code VARCHAR2(20):= NULL;

   BEGIN

      FOR i IN cur_new_code1
      LOOP

         l_new_item_code := i.new_code;

      END LOOP;

      IF l_new_item_code IS NULL THEN

         FOR j IN cur_new_code2
         LOOP

            l_new_item_code := j.new_code;

         END LOOP;

      END IF;

      RETURN l_new_item_code;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         dbms_output.put_line('No Data found : '||SQLERRM);
         Fnd_File.put_line(Fnd_File.LOG,'No Data found : '||SQLERRM);
         RETURN NULL;

      WHEN OTHERS THEN
         dbms_output.put_line('eRROR         : '||SQLERRM);
         Fnd_File.put_line(Fnd_File.LOG,'eRROR         : '||SQLERRM);
         RETURN NULL;
   END swgcnv_newitem_code;
   
   ----
   FUNCTION swgcnv_salesrep (  p_legacy_system VARCHAR2
                              ,p_old_code      VARCHAR2
                            )
   RETURN NUMBER
   IS

      CURSOR cur_new_code
      IS   
      SELECT new_code
      FROM   swgcnv_map
      WHERE  system_code   =  p_legacy_system
      AND    type_code     = 'SALESREP'
      AND    old_code      =  p_old_code;

      CURSOR cur_salesrep( l_new_code VARCHAR2 )
      IS
      SELECT    salesrep_id
      FROM     jtf_rs_salesreps
      WHERE    salesrep_number   =     l_new_code;

      l_new_salesrep    VARCHAR2(20)  :=  NULL;
      l_salesrep_id     NUMBER        :=  NULL;

   BEGIN

      --Fnd_Client_Info.set_org_context(2);  -- R12 Changes
      MO_GLOBAL.SET_POLICY_CONTEXT('S',2);

      FOR i IN cur_new_code
      LOOP

         FOR j IN cur_salesrep(i.new_code)
         LOOP

            l_salesrep_id     := j.salesrep_id;

         END LOOP;

      END LOOP;

      RETURN NVL(l_salesrep_id,100000670);

   EXCEPTION

      WHEN NO_DATA_FOUND THEN

         RETURN 100000670;

      WHEN OTHERS THEN

         RETURN 100000670;

   END swgcnv_salesrep;
   ----
   FUNCTION swgcnv_gl_loc_code (  p_legacy_system VARCHAR2  --MTS 19447 04/01/11
                                 ,p_old_code       VARCHAR2
                                )
   RETURN VARCHAR2
   IS



      l_new_code_s      VARCHAR2(20);

   BEGIN
      SELECT new_code
      INTO   l_new_code_s
      FROM   swgcnv_map
      WHERE  system_code   =  p_legacy_system
      AND    type_code     = 'LOCGLCODE'
      AND    old_code      =  p_old_code;

      RETURN NVL(l_new_code_s,'NOT MAPPED');

   EXCEPTION

      WHEN OTHERS THEN

         RETURN 'NOT MAPPED';

   END swgcnv_gl_loc_code;
---
   
   FUNCTION Swgcnv_billto_address_id (  p_legacy_system     VARCHAR2
                                       ,p_sales_center      VARCHAR2
                                       ,p_customer_ref      VARCHAR2
                                       ,p_bill_address_ref  VARCHAR2
                                       ,p_cust_account_id   NUMBER
                                    )
   RETURN  NUMBER
   IS
   
      CURSOR cur_billto_address(l_bill_address_ref VARCHAR2)
      IS
      SELECT   hzcas.cust_acct_site_id
      FROM     hz_cust_site_uses            hzcsu
              ,hz_cust_acct_sites           hzcas
      WHERE    hzcas.cust_acct_site_id      =    hzcsu.cust_acct_site_id
      AND       hzcsu.site_use_code         =   'BILL_TO'
      AND      hzcas.cust_account_id        =   p_cust_account_id
      --mts 20129 AND       hzcas.orig_system_reference =   l_bill_address_ref;
      AND       hzcas.orig_system_reference LIKE   l_bill_address_ref;

      CURSOR    cur_alt_billto_address
      IS
      SELECT   hzcas.cust_acct_site_id
      FROM     hz_cust_site_uses            hzcsu
              ,hz_cust_acct_sites           hzcas
      WHERE   hzcas.cust_acct_site_id   =   hzcsu.cust_acct_site_id
      AND     hzcsu.site_use_code       =   'BILL_TO'
      AND     hzcas.cust_account_id     =   p_cust_account_id
      AND     ROWNUM                    =   1;

      l_billto_address_ref   VARCHAR2(200)   :=   NULL;
      l_billto_address_id    NUMBER          :=   NULL;
      l_billto_number        VARCHAR2(20)    :=   NULL;

   BEGIN
   
      --Fnd_Client_Info.set_org_context(2);
      MO_GLOBAL.SET_POLICY_CONTEXT('S',2);

        l_billto_address_ref    :=    NULL;
        l_billto_address_id     :=    NULL;
        l_billto_number         :=    NULL;

      IF SUBSTR(p_bill_address_ref,1,1) = '0' THEN
      
         IF SUBSTR(p_bill_address_ref,1,2) = '00' THEN
              l_billto_number := SUBSTR(p_bill_address_ref,3);
         ELSE
              l_billto_number := SUBSTR(p_bill_address_ref,2);
         END IF;
         
      ELSE
         l_billto_number := p_bill_address_ref;
      END IF;

      l_billto_address_ref    :=    'DD'              ||'-'||
                                    p_legacy_system   ||'-'||
                                    '%'||  --mts 20129 p_sales_center    ||'-'||
                                    p_customer_ref    ||'-'||
                                    l_billto_number   ||'-'||
                                    'HEADER';

      FOR i IN cur_billto_address(l_billto_address_ref)
      LOOP
         l_billto_address_id := i.cust_acct_site_id;
      END LOOP;

      IF  l_billto_address_id IS NULL THEN
      
         FOR j IN cur_alt_billto_address
         LOOP
            l_billto_address_id := j.cust_acct_site_id;
         END LOOP;
      END IF;
      
      RETURN l_billto_address_id;
      
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         dbms_output.put_line('No Data found : '||SQLERRM);
         Fnd_File.put_line(Fnd_File.LOG,'No Data found for billto : '||SQLERRM);
         RETURN NULL;
      WHEN OTHERS THEN
         dbms_output.put_line('eRROR         : '||SQLERRM);
         Fnd_File.put_line(Fnd_File.LOG,'ERROR while retreving billto : '||SQLERRM);
         RETURN NULL;
   END Swgcnv_billto_address_id;
   
   --------------------
   
   PROCEDURE swgcnv_ar_conversion(   ou_errmsg_s       OUT   VARCHAR2
                                    ,ou_errcode_n      OUT   NUMBER
                                    ,p_legacy_system   IN    VARCHAR2
                                    ,p_division        IN    VARCHAR2
                                    ,p_sales_center    IN    VARCHAR2
                                 )
   IS

      CURSOR  cur_customer_trx
      IS
      SELECT   /*+ INDEX(a,SWGCNV_DD_AR_INTERFACE_N2) INDEX(b,SWGCNV_DD_TEMP_CUSTOMERS_N1) */
                a.*
               ,b.oracle_customer_id
               ,b.legacy_customer_number
               --,a.rowid
      FROM    swgcnv_dd_ar_interface       a,
              swgcnv_dd_temp_customers     b
      WHERE   a.ar_proc_flag           =   'N'
      AND     a.cust_trx_type_name     <>  'PAYMENT'
      AND     a.orig_system_bill_customer_ref  =  b.legacy_customer_number
      AND     b.cust_import_flag       =  'Y'
      AND     a.division               =   p_division
      AND     a.sales_center       =   p_sales_center;
      
      CURSOR  cur_inv_item( in_segment1_s   VARCHAR2 )
      IS
      SELECT  segment1
             ,inventory_item_id
             ,primary_uom_code
             ,description
             ,invoice_enabled_flag
      FROM    mtl_system_items_b
      WHERE   segment1             =    in_segment1_s
      AND     organization_id       =   5;
      
      CURSOR cur_ship_address ( p_cust_account_id   NUMBER
                               ,p_ship_address_ref  VARCHAR2
                              )
      IS
      SELECT hzcas.cust_acct_site_id
      FROM   hz_cust_site_uses         hzcsu
            ,hz_cust_acct_sites        hzcas
            ,hz_cust_accounts          hzca
      WHERE  hzcsu.site_use_code          =    'SHIP_TO'
      AND    hzcsu.cust_acct_site_id      =     hzcas.cust_acct_site_id
      AND    hzcas.orig_system_reference  LIKE  p_ship_address_ref
      AND    hzcas.cust_account_id        =     hzca.cust_account_id
      AND    hzca.cust_account_id         =     p_cust_account_id;      
      
      CURSOR cur_billto_address ( p_cust_account_id   NUMBER
                                 ,p_bill_address_ref  VARCHAR2
                                )
      IS
      SELECT   hzcas.cust_acct_site_id
      FROM     hz_cust_site_uses            hzcsu,
               hz_cust_acct_sites           hzcas
      WHERE    hzcsu.cust_acct_site_id      =    hzcas.cust_acct_site_id
      AND      hzcsu.site_use_code          =   'BILL_TO'
      AND      hzcas.orig_system_reference LIKE   p_bill_address_ref
      AND      hzcas.cust_account_id        =   p_cust_account_id;

     CURSOR  cur_gl_seg2 IS
     SELECT  code_combination_id 
     FROM    gl_code_combinations gcc,
             swgcnv.swgcnv_map    map
     WHERE   segment1 = '10'
     AND     segment2 = map.new_code
     AND     segment3 = '000'
     AND     segment4 = '1110'
     AND     segment5 = '00'
     AND     segment6 = '000'
     AND     segment7 = '000'
     AND     map.system_code = p_legacy_system
     AND     map.old_code    = p_sales_center
     AND     map.type_code   = 'LOCGLCODE';

      l_ra_int_lines_rec    ra_interface_lines_all%ROWTYPE;
      l_ra_int_tax_rec      ra_interface_lines_all%ROWTYPE;    -- Added As Part Of R12 Changes
      l_ra_int_dist_rec     ra_interface_distributions_all%ROWTYPE;
      l_ra_int_sales_rec    ra_interface_salescredits_all%ROWTYPE;
      l_scredit_rec         oe_sales_credit_types%ROWTYPE;

      l_cust_trx_cnt        NUMBER         :=   0;
      l_user_id             NUMBER;
      l_new_item_code       VARCHAR2(20)   :=   NULL;
      l_err_cnt             NUMBER         :=   0;
      l_trx_line_cnt_n      NUMBER         :=   0;            


      l_item_rec            Swgcnv_Cntrct_Vldt.item_info_rec_type;
      l_org_rec             Swgcnv_Cntrct_Vldt.org_info_rec_type;
      l_status_c            VARCHAR2(1);

      l_error_msg           VARCHAR2(4000) := NULL;
      l_primary_salesrep_id NUMBER;
      l_cnt                 NUMBER        := 0;
      l_dummy_var           VARCHAR2(40)  := 'ZYX';
      l_err_mesg_s          VARCHAR2(4000);
      l_commit_flag_c       VARCHAR2(1);
      
      l_shipto_address_ref      VARCHAR2(240);
      l_billto_address_ref      VARCHAR2(240);
      l_ra_int_dist_segment2_s  VARCHAR2(10);
      l_ra_int_tax_segment2_s   VARCHAR2(10);

      mapping_error            exception;  --MTS 19447
      l_gl_code_s              VARCHAR2(10);  --sgb

   BEGIN

      --Fnd_Client_Info.set_org_context(2); -- R12 Changes
      MO_GLOBAL.SET_POLICY_CONTEXT('S',2);
      --sgb
               l_gl_code_s :=  swgcnv_gl_loc_code(p_legacy_system,p_sales_center);
              IF l_gl_code_s = 'NOT MAPPED' THEN
                  Fnd_File.Put_Line(FND_FILE.OUTPUT,'GL ENTRY NOT ESTABLISHED IN MAPPING TABLE FOR=> '||p_legacy_system||' - '||p_sales_center);
                  ou_errmsg_s    :=   'ERROR : GL ENTRY NOT ESTABLISHED IN MAPPING TABLE';
                  ou_errcode_n    :=   2;
                  RETURN;
              END IF;

      Fnd_Stats.GATHER_TABLE_STATS('SWGCNV', 'SWGCNV_DD_AR_INTERFACE',90);
      --execute immediate 'alter session set events ''10046 trace name context forever, level 12''';    
    
      SELECT    user_id
      INTO     l_user_id
      FROM     fnd_user
      WHERE    user_name     =      'SWGCNV';

      SELECT    *
      INTO     l_scredit_rec
      FROM     oe_sales_credit_types
      WHERE    name              =  'Quota Sales Credit'
      AND       enabled_flag     =  'Y';

      FOR cur_trx_rec  IN cur_customer_trx
      LOOP

         BEGIN

            l_cust_trx_cnt  :=   l_cust_trx_cnt +  1;

            -- Added As Part Of R12 Upgrade

            IF ( l_dummy_var  <>  cur_trx_rec.interface_line_attribute1 ) THEN

               BEGIN

                  SELECT /*+ INDEX(SWGCNV_DD_AR_INTERFACE,SWGCNV_DD_AR_INTERFACE_N2) */  -- Added Pankaj
                         COUNT(*)
                  INTO   l_trx_line_cnt_n
                  FROM   swgcnv_dd_ar_interface
                  WHERE  interface_line_attribute1      =   cur_trx_rec.interface_line_attribute1
                  AND    trx_number                     =   cur_trx_rec.trx_number
                  AND    trx_date                       =   cur_trx_rec.trx_date
                  AND    cust_trx_type_name             =   cur_trx_rec.cust_trx_type_name
                  AND    orig_system_bill_customer_ref  =   cur_trx_rec.orig_system_bill_customer_ref
                  AND    sales_center                   =   p_sales_center;

                  l_cnt            :=    0;
                  l_commit_flag_c  :=   'Y';
                  
                  Fnd_File.Put_Line(FND_FILE.LOG,'Line Count For Trx Number: '||cur_trx_rec.trx_number||'='||l_trx_line_cnt_n);

               EXCEPTION
                  WHEN OTHERS THEN

                     Fnd_File.Put_Line(FND_FILE.LOG,'Error Retrieving Trx Count For: '||cur_trx_rec.trx_number);
                     l_trx_line_cnt_n  :=   0;
                     l_cnt             :=   0;
                     l_commit_flag_c   :=  'N';

               END;

               l_dummy_var     :=   cur_trx_rec.interface_line_attribute1;

            END IF;

            -- Added As Part Of R12 Upgrade

            IF ( cur_trx_rec.line_type   =    'LINE' )  THEN

               IF   cur_trx_rec.cust_trx_type_name     =   'INVOICE'  THEN

                  l_ra_int_lines_rec.cust_trx_type_name         :=  'DDCONV INVOICE R12';

               ELSIF    cur_trx_rec.cust_trx_type_name  =   'CREDIT MEMO'   THEN

                  l_ra_int_lines_rec.cust_trx_type_name         :=  'DDCONV CM R12';

               ELSIF    cur_trx_rec.cust_trx_type_name  =   'PAYMENT'           THEN

                  l_ra_int_lines_rec.cust_trx_type_name         :=  'DDCONV PAYMENT';

               ELSIF    cur_trx_rec.cust_trx_type_name  =   'DEBIT MEMO'    THEN

                  l_ra_int_lines_rec.cust_trx_type_name         :=  'DDCONV DM R12';

               END IF;

               l_ra_int_dist_rec.interface_line_context           := 'DD CONVERSION';
               l_ra_int_dist_rec.interface_line_attribute1        :=     cur_trx_rec.interface_line_attribute1;--p_sales_center||'*'||interface_line_attribute1;
               l_ra_int_dist_rec.interface_line_attribute2        :=     cur_trx_rec.interface_line_attribute2;

               l_ra_int_lines_rec.interface_line_context          := 'DD CONVERSION';
               l_ra_int_lines_rec.interface_line_attribute1       :=     cur_trx_rec.interface_line_attribute1;--p_sales_center||'*'||interface_line_attribute1;
               l_ra_int_lines_rec.interface_line_attribute2       :=     cur_trx_rec.interface_line_attribute2;
               --l_ra_int_lines_rec.trx_number                    :=   cur_trx_rec.interface_line_attribute1;--p_sales_center||'*'||interface_line_attribute1;
               l_ra_int_lines_rec.trx_number                      :=    cur_trx_rec.trx_number; -- Added For ARS03 Conversion

               l_ra_int_lines_rec.trx_date                        :=    cur_trx_rec.trx_date;
               l_ra_int_lines_rec.gl_date                         :=     cur_trx_rec.gl_date;
               l_ra_int_lines_rec.sales_order                     :=   'Legacy Sales Order#: ' || LTRIM(RTRIM(cur_trx_rec.sales_order));
  
               l_ra_int_lines_rec.sales_order_date                :=   cur_trx_rec.sales_order_date;
               l_ra_int_lines_rec.ship_date_actual                :=   NULL;
               l_ra_int_lines_rec.orig_system_bill_customer_id    :=     cur_trx_rec.oracle_customer_id;
               l_ra_int_lines_rec.orig_system_ship_customer_id    :=     cur_trx_rec.oracle_customer_id;
               l_ra_int_lines_rec.tax_code                        :=    NULL;  --'DDCONV TAX';

               l_ra_int_lines_rec.reference_line_context          := 'DD CONVERSION';
               l_ra_int_lines_rec.reference_line_attribute1       :=     NULL;
               l_ra_int_lines_rec.reference_line_attribute2       :=     NULL;

               l_ra_int_lines_rec.amount                          :=     cur_trx_rec.amount;
               l_ra_int_lines_rec.quantity                        :=     cur_trx_rec.quantity;
               l_ra_int_lines_rec.quantity_ordered                :=  cur_trx_rec.quantity;
               l_ra_int_lines_rec.unit_selling_price              :=  cur_trx_rec.unit_selling_price;
               l_ra_int_lines_rec.unit_standard_price             :=  cur_trx_rec.unit_standard_price;
               l_ra_int_lines_rec.sales_order_line                :=     cur_trx_rec.sales_order_line;
               l_ra_int_lines_rec.purchase_order                  :=     cur_trx_rec.purchase_order;

               l_ra_int_lines_rec.attribute10                     :=     cur_trx_rec.attribute10;
               l_ra_int_lines_rec.attribute11                     :=     cur_trx_rec.attribute1;
               l_ra_int_lines_rec.attribute12                     :=     cur_trx_rec.attribute2;

               l_ra_int_lines_rec.header_attribute15              :=  cur_trx_rec.due_date;
               l_ra_int_lines_rec.header_attribute_category       := 'DIRECT DELIVERY';
               l_ra_int_lines_rec.batch_source_name               :=    'DD CONVERSION';

               l_ra_int_lines_rec.set_of_books_id                 :=     1;
               l_ra_int_lines_rec.line_type                       :=    'LINE';

               l_ra_int_lines_rec.currency_code                   :=    'USD';
               l_ra_int_lines_rec.conversion_type                 :=    'User';
               l_ra_int_lines_rec.conversion_rate                 :=     1;

               l_ra_int_lines_rec.created_by                      :=     l_user_id;
               l_ra_int_lines_rec.creation_date                   :=     SYSDATE;
               l_ra_int_lines_rec.last_updated_by                 :=     l_user_id;
               l_ra_int_lines_rec.last_update_date                :=     SYSDATE;
               l_ra_int_lines_rec.org_id                          :=     2;

               l_ra_int_lines_rec.taxable_amount                  :=     NULL;
               l_ra_int_lines_rec.tax_rate_code                   :=     NULL;
               l_ra_int_lines_rec.tax_rate                        :=     NULL;
               l_ra_int_lines_rec.link_to_line_context            :=     NULL;
               l_ra_int_lines_rec.link_to_line_attribute1         :=     NULL;
               l_ra_int_lines_rec.link_to_line_attribute2         :=     NULL;

               l_ra_int_lines_rec.comments                        :=  cur_trx_rec.comments;

               --IF cur_trx_rec.tax_status IN ('UI','UP','UR','UN','UC','U') THEN -- Commented For ARS04 Conversion
               IF cur_trx_rec.tax_status IS  NULL  THEN

                  l_ra_int_lines_rec.header_attribute14           :=      NULL;

               ELSE

                  l_ra_int_lines_rec.header_attribute14           :=     'NA';

               END IF;

               --Shipto Address ID
            
               l_ra_int_lines_rec.orig_system_ship_address_id    :=  NULL;
            
               l_shipto_address_ref := 'DD'||'-'|| p_legacy_system  ||'-'||
                                                   --mts 20129  p_sales_center     ||'-'||
                                                     '%'||  --mts 20129
                                                   cur_trx_rec.legacy_customer_number         ||'-'|| 
                                                   cur_trx_rec.orig_system_ship_address_ref   ||'%';
                                                
               Fnd_File.Put_Line(FND_FILE.LOG,'Ship Address Reference: '||l_shipto_address_ref);                                                                                          
            
               OPEN  cur_ship_address ( cur_trx_rec.oracle_customer_id
                                       ,l_shipto_address_ref
                                       );
            
               FETCH cur_ship_address
               INTO  l_ra_int_lines_rec.orig_system_ship_address_id;
            
               CLOSE cur_ship_address;
            
               /* -- Commented To Reduce Function Call Overhead. Pankaj
            
               SELECT Swgcnv_Shipto_Address_Id ( p_legacy_system
                                                ,p_sales_center
                                                ,cur_trx_rec.legacy_customer_number
                                                ,cur_trx_rec.orig_system_ship_address_ref
                                                ,cur_trx_rec.oracle_customer_id
                                                )
               INTO  l_ra_int_lines_rec.orig_system_ship_address_id
               FROM  DUAL;
            
               */ -- Commented To Reduce Function Call Overhead. Pankaj

               IF l_ra_int_lines_rec.orig_system_ship_address_id IS NULL THEN

                  l_err_mesg_s     :=   l_err_mesg_s || 'Line Shipto Address Id Not Found For Customer: '||cur_trx_rec.legacy_customer_number;
               
                  Fnd_File.Put_Line(FND_FILE.LOG,'Line Shipto Address Id Not Found For Customer: '||cur_trx_rec.legacy_customer_number);

                  l_commit_flag_c  :=   'N';

                  /* Commented Pankaj

                  INSERT INTO  swgcnv_conversion_exceptions
                     (   
                         conversion_type
                        ,conversion_key_value
                        ,error_message
                     )
                  VALUES 
                     ( 
                        'AR Validation'
                        ,NVL(cur_trx_rec.oracle_customer_id,cur_trx_rec.legacy_customer_number)
                        ,'Shipto Addressid Not found'
                     );
                  */

               END IF;

               --Billto Address Id
            
               l_ra_int_lines_rec.orig_system_bill_address_id   :=   NULL;
            
               l_billto_address_ref    :=       'DD'              ||'-'||
                                                p_legacy_system   ||'-'||
                                                '%'||  --mts 20129 p_sales_center    ||'-'||
                                                cur_trx_rec.legacy_customer_number         ||'-'||
                                                cur_trx_rec.orig_system_bill_address_ref   ||'-'||
                                                'HEADER';
                                          
               Fnd_File.Put_Line(FND_FILE.LOG,'Bill Address Reference: '||l_billto_address_ref);                                                                                    
            
               OPEN  cur_billto_address(   cur_trx_rec.oracle_customer_id
                                          ,l_billto_address_ref
                                       );
                                    
               FETCH cur_billto_address
               INTO  l_ra_int_lines_rec.orig_system_bill_address_id;

               CLOSE cur_billto_address;
            
               IF l_ra_int_lines_rec.orig_system_bill_address_id IS NULL THEN

                  l_err_mesg_s  :=   l_err_mesg_s || 'Line Billto Address Id Not Found For Customer: '||cur_trx_rec.legacy_customer_number;
               
                  Fnd_File.Put_Line(FND_FILE.LOG,'Line Billto Address Id Not Found For Customer: '||cur_trx_rec.legacy_customer_number);

                  l_commit_flag_c  :=   'N';

               END IF;

               --Payment Terms

               IF l_ra_int_lines_rec.cust_trx_type_name NOT IN ('DDCONV PAYMENT','DDCONV CM R12') THEN
            
                  BEGIN

                     SELECT standard_terms
                     INTO   l_ra_int_lines_rec.term_id
                     FROM   hz_customer_profiles
                     WHERE  cust_account_id    =   cur_trx_rec.oracle_customer_id
                     AND    site_use_id        IS  NULL;

                     SELECT name
                     INTO   l_ra_int_lines_rec.term_name
                     FROM   ra_terms_tl
                     WHERE  term_id     =  l_ra_int_lines_rec.term_id;

                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        l_ra_int_lines_rec.term_id    :=    5;
                        l_ra_int_lines_rec.term_name  :=   'IMMEDIATE';
                     WHEN OTHERS THEN
                        l_ra_int_lines_rec.term_id    :=    5;
                        l_ra_int_lines_rec.term_name  :=   'IMMEDIATE';
                  END;

               ELSE

                  l_ra_int_lines_rec.term_id    :=   NULL;
                  l_ra_int_lines_rec.term_name  :=   NULL;

               END IF;

               --Salesrep id

               SELECT swgcnv_salesrep(  p_legacy_system
                                       ,cur_trx_rec.primary_salesrep_number
                                     )
               INTO   l_primary_salesrep_id
               FROM   DUAL;

               l_ra_int_lines_rec.primary_salesrep_id   :=  l_primary_salesrep_id;

               /*  BEGIN of EB-1669               
               Swgcnv_Cntrct_Vldt.get_maps_and_details
                  (   in_sacs_org_s    =>  p_sales_center
                     ,in_sacs_brand_s  =>  cur_trx_rec.item_sub_code
                     ,in_sacs_item_s   =>  LTRIM(RTRIM(cur_trx_rec.item_code))
                     ,in_eff_date_d    =>  TRUNC(SYSDATE)
                     ,io_item_rec      =>  l_item_rec
                     ,io_org_rec       =>  l_org_rec
                     ,io_status_c      =>  l_status_c
                     ,io_message_s     =>  l_error_msg
                     ,in_debug_c       => 'N' --swgcnv_cntrct_vldt.g_debug
                     ,in_system_code_c =>  p_legacy_system
                  );

                  IF l_status_c != Swgcnv_Cntrct_Vldt.G_STS_SUCCESS THEN

                     l_new_item_code   :=   NULL;
                     l_error_msg          :=   p_legacy_system || ' -' || LTRIM(RTRIM(cur_trx_rec.item_code))  || 'Sub Code' || 
                                            cur_trx_rec.item_sub_code || 'Sales Center' || p_sales_center || 'Error returned from Get_Maps_And_Details: ' || l_error_msg;

                     Fnd_File.Put_Line(Fnd_File.LOG, l_error_msg);
      
                  ELSE

                     l_new_item_code   := l_item_rec.item_code;

                  END IF;

               IF l_new_item_code IS NOT NULL  THEN

                  FOR inv_item_rec IN cur_inv_item(l_new_item_code)
                  LOOP
  
                     IF inv_item_rec.invoice_enabled_flag   = 'N'   THEN

                        l_ra_int_lines_rec.mtl_system_items_seg1   :=      NULL;
                        l_ra_int_lines_rec.inventory_item_id       :=      NULL;
                        l_ra_int_lines_rec.uom_code              :=      NULL;

                        --l_ra_int_lines_rec.description  :=      cur_trx_rec.description;              -- Commented For WO 18998. Conversion Enhancements
                        l_ra_int_lines_rec.description    :=      cur_trx_rec.description||'-'||cur_trx_rec.item_code; -- Added For WO 18998. Conversion Enhancements

                     ELSE

                        l_ra_int_lines_rec.mtl_system_items_seg1        :=      inv_item_rec.segment1;
                        l_ra_int_lines_rec.inventory_item_id            :=      inv_item_rec.inventory_item_id;
                        l_ra_int_lines_rec.uom_code                     :=      inv_item_rec.primary_uom_code;

                        --l_ra_int_lines_rec.description   :=      inv_item_rec.description;             -- Commented For WO 18998. Conversion Enhancements
                        l_ra_int_lines_rec.description     :=      cur_trx_rec.description||'-'||cur_trx_rec.item_code; -- Added For WO 18998. Conversion Enhancements

                     END IF; --inv_item_rec.invoice_enabled_flag

                  END  LOOP;

               ELSE

                  l_ra_int_lines_rec.mtl_system_items_seg1     :=      NULL;
                  l_ra_int_lines_rec.inventory_item_id         :=      NULL;
                  l_ra_int_lines_rec.uom_code                  :=      NULL;

                  --l_ra_int_lines_rec.description      :=  cur_trx_rec.description;              -- Commented For WO 18998. Conversion Enhancements
                  l_ra_int_lines_rec.description        :=  cur_trx_rec.description||'-'||cur_trx_rec.item_code; -- Added For WO 18998. Conversion Enhancements

               END IF; --l_new_item_code
               */   --    END of EB-1669               
               
               --EB-1669 Remove oracle item id and display on legacy item description SGB
               l_ra_int_lines_rec.description               :=      NULL;
               l_ra_int_lines_rec.mtl_system_items_seg1     :=      NULL;
               l_ra_int_lines_rec.inventory_item_id         :=      NULL;
               l_ra_int_lines_rec.uom_code                  :=      NULL;               
               --EB-1669 END

               IF SUBSTR(cur_trx_rec.description,1,16) = 'UNBILLED PAYMENT' THEN

                  l_ra_int_lines_rec.description   := l_ra_int_lines_rec.description;--||'-UN-PAYMENT';

               ELSIF SUBSTR(cur_trx_rec.description,1,16) = 'UNBILLED INVOICE' THEN
  
                  l_ra_int_lines_rec.description   := l_ra_int_lines_rec.description;--||'-UN-INVOICE';

               ELSIF    l_ra_int_lines_rec.description IS NULL THEN

                  l_ra_int_lines_rec.description   := cur_trx_rec.description;

               END IF;
 
               --
               --Sales Credits
 
               l_ra_int_sales_rec.interface_line_context       :=    l_ra_int_lines_rec.interface_line_context;
               l_ra_int_sales_rec.interface_line_attribute1    :=    l_ra_int_lines_rec.interface_line_attribute1;
               l_ra_int_sales_rec.interface_line_attribute2    :=    l_ra_int_lines_rec.interface_line_attribute2;
               l_ra_int_sales_rec.salesrep_id                  :=    l_primary_salesrep_id;--l_ra_int_lines_rec.primary_salesrep_id;
               l_ra_int_sales_rec.sales_credit_type_name       :=    l_scredit_rec.name;
               l_ra_int_sales_rec.sales_credit_type_id         :=    l_scredit_rec.sales_credit_type_id;
               l_ra_int_sales_rec.sales_credit_percent_split   :=    100;
               l_ra_int_sales_rec.attribute_category           :=    l_ra_int_lines_rec.attribute_category;
               l_ra_int_sales_rec.attribute15                  :=    l_scredit_rec.name;
               l_ra_int_sales_rec.org_id                       :=    l_ra_int_lines_rec.org_id;
            
               Fnd_File.Put_Line(FND_FILE.LOG,'Inserting Into Interface Line: '||cur_trx_rec.interface_line_attribute2);

               insert_ra_lines ( l_ra_int_lines_rec);
  
               BEGIN
            
                  Fnd_File.Put_Line(FND_FILE.LOG,'Inserting Into SC Interface Line: '||cur_trx_rec.interface_line_attribute2);
               
                  INSERT INTO ra_interface_salescredits_all
                  VALUES l_ra_int_sales_rec;

               EXCEPTION
                  WHEN OTHERS THEN
                     dbms_output.put_line('Error while inserting into ra_intf_salescredits: '||SQLERRM);
                     Fnd_File.put_line(Fnd_File.LOG,'Error while inserting into ra_intf_salescredits for trx_number: '||cur_trx_rec.interface_line_attribute1||': '||SQLERRM);
                     l_err_mesg_s     :=   l_err_mesg_s || 'Error While Inserting Into Ra Interface Sales Credits';
                     l_commit_flag_c  :=  'N';
               END;

               Fnd_File.Put_Line(FND_FILE.LOG,'Inserting Into Interface Dist Line: '||cur_trx_rec.interface_line_attribute2);

              l_ra_int_dist_segment2_s := swgcnv_gl_loc_code(p_legacy_system,cur_trx_rec.sales_center); --MTS 19447 04/01/2011

              IF l_ra_int_dist_segment2_s = 'NOT MAPPED' THEN
                 l_err_mesg_s := 'Mapping Error LOCGLCODE ';
                 RAISE mapping_error;
              END IF;
    
               INSERT INTO ra_interface_distributions_all
                  (   interface_line_context
                     ,interface_line_attribute1
                     ,interface_line_attribute2
                     ,account_class
                     ,amount
                     ,segment1
                     ,segment2
                     ,segment3
                     ,segment4
                     ,segment5
                     ,segment6
                     ,segment7
                     ,percent
                     ,org_id
                  )
               VALUES
                  (   l_ra_int_dist_rec.interface_line_context
                     ,l_ra_int_dist_rec.interface_line_attribute1
                     ,l_ra_int_dist_rec.interface_line_attribute2
                     ,'REV'
                     ,NVL(cur_trx_rec.amount,0) + NVL (cur_trx_rec.attribute10,0)
                     ,'10'   -- SAGE ACQ  --MTS 303 ABN1/DSD CONVERSION
                     ,l_ra_int_dist_segment2_s --MTS ??? ARSO5 '2930' -- SAGE ACQ  --MTS 303 ABN1/DSD CONVERSION
                     ,'000'
                     ,'1110'
                     ,'00'
                     ,'000'
                     ,'000'
                     ,100
                     ,2
                  ) ;
          

            ELSIF ( cur_trx_rec.line_type   =   'TAX' )  THEN

               IF   cur_trx_rec.cust_trx_type_name     =   'INVOICE'  THEN

                  l_ra_int_tax_rec.cust_trx_type_name      :=   'DDCONV INVOICE R12';

               ELSIF    cur_trx_rec.cust_trx_type_name   =   'CREDIT MEMO'  THEN

                  l_ra_int_tax_rec.cust_trx_type_name      :=   'DDCONV CM R12';

               ELSIF    cur_trx_rec.cust_trx_type_name  =   'PAYMENT'           THEN

                  l_ra_int_tax_rec.cust_trx_type_name    := 'DDCONV PAYMENT';

               ELSIF    cur_trx_rec.cust_trx_type_name  =   'DEBIT MEMO'    THEN

                  l_ra_int_tax_rec.cust_trx_type_name    := 'DDCONV DM R12';
   
               END IF;

               l_ra_int_tax_rec.interface_line_context         :=    'DD CONVERSION';
               l_ra_int_tax_rec.interface_line_attribute1      :=    cur_trx_rec.interface_line_attribute1;
               l_ra_int_tax_rec.interface_line_attribute2      :=    cur_trx_rec.interface_line_attribute2;
               --l_ra_int_tax_rec.trx_number                        :=   cur_trx_rec.interface_line_attribute1;
               l_ra_int_tax_rec.trx_number                     :=   cur_trx_rec.trx_number;

               l_ra_int_tax_rec.trx_date                       :=    cur_trx_rec.trx_date;
               l_ra_int_tax_rec.gl_date                        :=    cur_trx_rec.gl_date;
               l_ra_int_tax_rec.sales_order                    :=    NULL;

               l_ra_int_tax_rec.sales_order_date               :=  NULL;
               l_ra_int_tax_rec.ship_date_actual               :=  NULL;
               l_ra_int_tax_rec.orig_system_bill_customer_id   :=    cur_trx_rec.oracle_customer_id;
               l_ra_int_tax_rec.orig_system_ship_customer_id   :=    cur_trx_rec.oracle_customer_id;

               l_ra_int_tax_rec.reference_line_context         :=     NULL;
               l_ra_int_tax_rec.reference_line_attribute1      :=    NULL;
               l_ra_int_tax_rec.reference_line_attribute2      :=    NULL;

               l_ra_int_tax_rec.amount                         :=    cur_trx_rec.amount;
               l_ra_int_tax_rec.quantity                       :=    cur_trx_rec.quantity;
               l_ra_int_tax_rec.quantity_ordered               :=  NULL;
               l_ra_int_tax_rec.unit_selling_price             :=  NULL;
               l_ra_int_tax_rec.unit_standard_price            :=  NULL;
               l_ra_int_tax_rec.sales_order_line               :=    NULL;
               l_ra_int_tax_rec.purchase_order                 :=    NULL;

               l_ra_int_tax_rec.attribute10                    :=    cur_trx_rec.attribute10;
               l_ra_int_tax_rec.attribute11                    :=    cur_trx_rec.attribute1;
               l_ra_int_tax_rec.attribute12                    :=    cur_trx_rec.attribute2;

               l_ra_int_tax_rec.header_attribute15             :=  cur_trx_rec.due_date;
               l_ra_int_tax_rec.header_attribute_category      := 'DIRECT DELIVERY';
               l_ra_int_tax_rec.batch_source_name              :=   'DD CONVERSION';

               l_ra_int_tax_rec.set_of_books_id                :=    1;
               l_ra_int_tax_rec.line_type                      :=   'TAX';
               l_ra_int_tax_rec.tax_code                       :=   'DDCONV TAX';
               l_ra_int_tax_rec.tax_rate_code                  :=  'DDCONV TAX';
               l_ra_int_tax_rec.tax_rate                       :=  cur_trx_rec.tax_rate;
               l_ra_int_tax_rec.taxable_amount                 :=  cur_trx_rec.attribute10;

               l_ra_int_tax_rec.currency_code                  :=   'USD';
               l_ra_int_tax_rec.conversion_type                :=   'User';
               l_ra_int_tax_rec.conversion_rate                :=    1;

               l_ra_int_tax_rec.created_by                     :=    l_user_id;
               l_ra_int_tax_rec.creation_date                  :=    SYSDATE;
               l_ra_int_tax_rec.last_updated_by                :=    l_user_id;
               l_ra_int_tax_rec.last_update_date               :=    SYSDATE;
               l_ra_int_tax_rec.org_id                         :=    2;
  
               l_ra_int_tax_rec.comments                       :=  cur_trx_rec.comments;
               l_ra_int_tax_rec.term_id                        :=  NULL;
               l_ra_int_tax_rec.term_name                      :=  NULL; --cur_trx_rec.term_name;
               l_ra_int_tax_rec.primary_salesrep_id            :=  NULL;

               l_ra_int_tax_rec.mtl_system_items_seg1          :=  NULL;
               l_ra_int_tax_rec.inventory_item_id              :=  NULL;
               l_ra_int_tax_rec.uom_code                       :=  NULL;

               l_ra_int_tax_rec.description                    := 'TAX';

               l_ra_int_tax_rec.link_to_line_context           :=  cur_trx_rec.reference_line_context;
               l_ra_int_tax_rec.link_to_line_attribute1        :=  cur_trx_rec.reference_line_attribute1;
               l_ra_int_tax_rec.link_to_line_attribute2        :=  cur_trx_rec.reference_line_attribute2;

               IF cur_trx_rec.tax_status IS  NULL  THEN

                  l_ra_int_tax_rec.header_attribute14          :=  NULL;

               ELSE

                  l_ra_int_tax_rec.header_attribute14          := 'NA';

               END IF;

               --Shipto Address ID
            
           
               l_ra_int_tax_rec.orig_system_ship_address_id    :=  NULL;
            
               l_shipto_address_ref :=       'DD'              ||'-'|| 
                                             p_legacy_system    ||'-'||
                                             --mts 20129  p_sales_center       ||'-'||
                                            '%'||  --mts 20129
                                             cur_trx_rec.legacy_customer_number         ||'-'|| 
                                             cur_trx_rec.orig_system_ship_address_ref   ||'%';
                                                
               Fnd_File.Put_Line(FND_FILE.LOG,'Ship Address Reference: '||l_shipto_address_ref);
               Fnd_File.Put_Line(FND_FILE.LOG,'Processing Line: '||cur_trx_rec.interface_line_attribute2);
            
               OPEN  cur_ship_address ( cur_trx_rec.oracle_customer_id
                                       ,l_shipto_address_ref
                                      );
            
               FETCH cur_ship_address
               INTO  l_ra_int_tax_rec.orig_system_ship_address_id;
            
               CLOSE cur_ship_address;
            
               Fnd_File.Put_Line(FND_FILE.LOG,'Ship Address Id: '||l_ra_int_tax_rec.orig_system_ship_address_id);
           
               IF l_ra_int_tax_rec.orig_system_ship_address_id IS NULL THEN

                  l_err_mesg_s  :=   l_err_mesg_s || 'Tax Shipto Address Id Not Found For Customer: '||cur_trx_rec.legacy_customer_number;
               
                  Fnd_File.Put_Line(FND_FILE.LOG,'Tax Shipto Address Id Not Found For Customer: '||cur_trx_rec.legacy_customer_number);
                  l_commit_flag_c  :=   'N';

               END IF;

               --Billto Address Id
            
               /* -- Commented To Reduce Function Call Overhead. Pankaj
            
               SELECT Swgcnv_Billto_Address_Id ( p_legacy_system
                                                ,p_sales_center
                                                ,cur_trx_rec.legacy_customer_number
                                                ,cur_trx_rec.orig_system_bill_address_ref
                                                ,cur_trx_rec.oracle_customer_id
                                                )
               INTO  l_ra_int_tax_rec.orig_system_bill_address_id
               FROM  dual;
            
               */  -- Commented To Reduce Function Call Overhead. Pankaj
            
               l_ra_int_tax_rec.orig_system_bill_address_id   :=   NULL;
            
               l_billto_address_ref    :=          'DD'              ||'-'||
                                                   p_legacy_system   ||'-'||
                                                   '%'||  --mts 20129 p_sales_center    ||'-'||
                                                   cur_trx_rec.legacy_customer_number         ||'-'||
                                                   cur_trx_rec.orig_system_bill_address_ref   ||'-'||
                                                   'HEADER';
                                          
               Fnd_File.Put_Line(FND_FILE.LOG,'Bill Address Reference: '||l_billto_address_ref);                                          
            
               OPEN  cur_billto_address( cur_trx_rec.oracle_customer_id
                                        ,l_billto_address_ref
                                       );
                                    
               FETCH cur_billto_address
               INTO  l_ra_int_tax_rec.orig_system_bill_address_id;

               CLOSE cur_billto_address;
           
               IF l_ra_int_tax_rec.orig_system_bill_address_id IS NULL THEN

                  l_err_mesg_s  :=   l_err_mesg_s || 'Tax Billto Address Id Not Found For Customer: '||cur_trx_rec.legacy_customer_number;
                  Fnd_File.Put_Line(FND_FILE.LOG,'Tax Billto Address Id Not Found For Customer: '||cur_trx_rec.legacy_customer_number);

                  l_commit_flag_c  :=   'N';

               END IF;
            
               Fnd_File.Put_Line(FND_FILE.LOG,'Inserting Into Interface Tax Lines: '||cur_trx_rec.interface_line_attribute2);

               insert_ra_lines ( l_ra_int_tax_rec );
            
               Fnd_File.Put_Line(FND_FILE.LOG,'Inserting Into Interface Dist Tax Lines: '||cur_trx_rec.interface_line_attribute2);

              l_ra_int_tax_segment2_s := swgcnv_gl_loc_code(p_legacy_system,cur_trx_rec.sales_center); --MTS 20129 04/30/12

              IF l_ra_int_tax_segment2_s = 'NOT MAPPED' THEN
                 l_err_mesg_s := 'Mapping Error LOCGLCODE ';
                 RAISE mapping_error;
              END IF;

               INSERT INTO ra_interface_distributions_all
                  (   interface_line_context
                     ,interface_line_attribute1
                     ,interface_line_attribute2
                     ,account_class
                     ,amount
                     ,segment1
                     ,segment2
                     ,segment3
                     ,segment4
                     ,segment5
                     ,segment6
                     ,segment7
                     ,percent
                     ,org_id
                  )
               VALUES
                  (   l_ra_int_tax_rec.interface_line_context
                     ,l_ra_int_tax_rec.interface_line_attribute1
                     ,l_ra_int_tax_rec.interface_line_attribute2
                     ,'TAX'
                     ,NVL (l_ra_int_tax_rec.amount,0)
                     ,'10'    -- SAGE ACQ  --mts 303 ABN1/DSD CONVERSION
                     ,l_ra_int_tax_segment2_s --MTS ARS05/RAM ??? '2930'  -- SAGE ACQ  --mts 303 ABN1/DSD CONVERSION
                     ,'000'
                     ,'2100'
                     ,'00'
                     ,'000'
                     ,'000'
                     ,100
                     ,2
                  ) ;
          
            END IF; /* Customer Trx Type */            

         
            UPDATE /*+ INDEX(SWGCNV_DD_AR_INTERFACE,SWGCNV_DD_AR_INTERFACE_NR) */
                   swgcnv_dd_ar_interface
            SET    ar_proc_flag               =  'Y'
            WHERE  interface_line_attribute1      =   cur_trx_rec.interface_line_attribute1
            AND    interface_line_attribute2      =   cur_trx_rec.interface_line_attribute2
            AND    line_type                      =   cur_trx_rec.line_type
            AND    trx_number                     =   cur_trx_rec.trx_number
            AND    trx_date                       =   cur_trx_rec.trx_date
            AND    orig_system_bill_customer_ref  =   cur_trx_rec.orig_system_bill_customer_ref
            AND    cust_trx_type_name             =   cur_trx_rec.cust_trx_type_name
            AND    sales_center                   =   p_sales_center;

            l_cnt := l_cnt + 1;


         EXCEPTION
            WHEN MAPPING_ERROR THEN 
               Fnd_File.put_line(Fnd_File.LOG,'Error While Calling AR Conversion Procedure For Interface Attribute: '||cur_trx_rec.interface_line_attribute1||'-'||cur_trx_rec.interface_line_attribute2);
               l_commit_flag_c   :=   'N';
               l_err_mesg_s      :=   SUBSTR(l_err_mesg_s || 'Error While Calling AR Conversion Procedure : '||SQLERRM,1,4000);
            WHEN OTHERS THEN
               dbms_output.put_line('Error While Calling AR Conversion Procedure : '||SQLERRM);
               Fnd_File.put_line(Fnd_File.LOG,'Error While Calling AR Conversion Procedure For Interface Attribute: '||cur_trx_rec.interface_line_attribute1||'-'||cur_trx_rec.interface_line_attribute2);

               l_commit_flag_c   :=   'N';
               l_err_mesg_s      :=   SUBSTR(l_err_mesg_s || 'Error While Calling AR Conversion Procedure : '||SQLERRM,1,4000);
         END;
         FOR gl_seg2_rec  IN cur_gl_seg2 LOOP   --MTS 20129
             UPDATE 
                 ra_cust_trx_types_all
             set 
                 gl_id_rec =  gl_seg2_rec.code_combination_id,
                 gl_id_rev =  gl_seg2_rec.code_combination_id,
                 gl_id_tax =  gl_seg2_rec.code_combination_id
             WHERE 
                 cust_trx_type_id in (1800,1801,1802);
         END LOOP;


         -- Added Pankaj
         IF ( l_cnt = l_trx_line_cnt_n  AND l_commit_flag_c  =  'Y' ) THEN

            COMMIT;

         ELSIF ( l_cnt = l_trx_line_cnt_n  AND l_commit_flag_c  =  'N' ) THEN

            ROLLBACK;

            UPDATE /*+ INDEX(SWGCNV_DD_AR_INTERFACE,SWGCNV_DD_AR_INTERFACE_NR) */
                   swgcnv_dd_ar_interface
            SET    ar_proc_flag                  =  'E'
            WHERE  interface_line_attribute1      =   cur_trx_rec.interface_line_attribute1
            AND    trx_number                     =   cur_trx_rec.trx_number
            AND    trx_date                       =   cur_trx_rec.trx_date
            AND    orig_system_bill_customer_ref  =   cur_trx_rec.orig_system_bill_customer_ref
            AND    cust_trx_type_name             =   cur_trx_rec.cust_trx_type_name
            AND    sales_center                   =   p_sales_center;

            INSERT INTO  swgcnv_conversion_exceptions 
               (   conversion_type
                  ,conversion_key_value
                  ,error_message
               )
            VALUES ( 'AR Validation'
                     ,NVL(cur_trx_rec.oracle_customer_id,cur_trx_rec.legacy_customer_number)
                     ,SUBSTR(l_err_mesg_s,1,2000)
                  );

            COMMIT;

         END IF;
 
         IF ( l_commit_flag_c  =  'N' ) THEN

            l_err_cnt   :=   l_err_cnt + 1;

         END IF;

         -- Added Pankaj

      END LOOP; --cur_customer_trx

      Fnd_File.put_line(Fnd_File.OUTPUT,'Total No Of Records    : '||l_cust_trx_cnt);
      Fnd_File.put_line(Fnd_File.OUTPUT,'No Of Records Inserted : '||To_Char(l_cust_trx_cnt - l_err_cnt));
      Fnd_File.put_line(Fnd_File.OUTPUT,'No Of Error Records    : '||l_err_cnt );

      Fnd_File.put_line(Fnd_File.LOG,'Total No Of Records       : '||l_cust_trx_cnt);
      Fnd_File.put_line(Fnd_File.LOG,'No Of Records Inserted    : '||To_Char(l_cust_trx_cnt - l_err_cnt));
      Fnd_File.put_line(Fnd_File.LOG,'No Of Error Records       : '||l_err_cnt );

      dbms_output.put_line('l_err_cnt : '||l_err_cnt );

      COMMIT;
      
   EXCEPTION
      WHEN OTHERS THEN
         dbms_output.put_line('Error While Calling AR Conversion Procedure : '||SQLERRM);
         Fnd_File.put_line(Fnd_File.LOG,'Error While Calling AR Conversion Procedure: '||SQLERRM);

   END swgcnv_ar_conversion;
   ------------------------------------------

   PROCEDURE    insert_ra_lines ( p_ra_lines_rec    IN  ra_interface_lines_all%ROWTYPE
                              )
   IS
      l_err_message VARCHAR2(2000):= NULL;
   BEGIN
      INSERT   INTO ra_interface_lines_all
         (   cust_trx_type_name
            ,interface_line_attribute1
            ,trx_number
            ,trx_date
            ,gl_date
            ,sales_order
            ,sales_order_date
            ,ship_date_actual
            ,term_id
            ,term_name
            ,orig_system_bill_customer_id
            ,orig_system_bill_address_id
            ,orig_system_ship_customer_id
            ,orig_system_ship_address_id
            ,interface_line_attribute2
            ,line_number
            ,mtl_system_items_seg1
            ,inventory_item_id
            ,description
            ,amount
            ,quantity
            ,quantity_ordered
            ,unit_selling_price
            ,unit_standard_price
            ,sales_order_line
            ,attribute10
            ,reference_line_context
            ,reference_line_attribute1
            ,reference_line_attribute2
            ,interface_line_context
            ,batch_source_name
            ,set_of_books_id
            ,line_type
            ,currency_code
            ,conversion_type
            ,conversion_date
            ,conversion_rate
            ,tax_code
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,org_id
            ,uom_code
            ,primary_salesrep_number
            ,primary_salesrep_id
            ,purchase_order
            ,header_attribute14
            ,header_attribute15
            ,header_attribute_category
            ,attribute11
            ,attribute12
            ,comments
            ,taxable_amount
            ,tax_rate_code
            ,tax_rate
            ,link_to_line_context
            ,link_to_line_attribute1
            ,link_to_line_attribute2
       
         )
      VALUES
         (   p_ra_lines_rec.cust_trx_type_name
            ,p_ra_lines_rec.interface_line_attribute1
            ,p_ra_lines_rec.trx_number
            ,p_ra_lines_rec.trx_date
            ,p_ra_lines_rec.gl_date
            ,p_ra_lines_rec.sales_order
            ,p_ra_lines_rec.sales_order_date
            ,p_ra_lines_rec.ship_date_actual
            ,p_ra_lines_rec.term_id
            ,p_ra_lines_rec.term_name
            ,p_ra_lines_rec.orig_system_bill_customer_id
            ,p_ra_lines_rec.orig_system_bill_address_id
            ,p_ra_lines_rec.orig_system_ship_customer_id
            ,p_ra_lines_rec.orig_system_ship_address_id
            ,p_ra_lines_rec.interface_line_attribute2
            ,p_ra_lines_rec.line_number
            ,p_ra_lines_rec.mtl_system_items_seg1
            ,p_ra_lines_rec.inventory_item_id
            ,p_ra_lines_rec.description
            ,p_ra_lines_rec.amount
            ,p_ra_lines_rec.quantity
            ,p_ra_lines_rec.quantity_ordered
            ,p_ra_lines_rec.unit_selling_price
            ,p_ra_lines_rec.unit_standard_price
            ,p_ra_lines_rec.sales_order_line
            ,p_ra_lines_rec.attribute10 -- sales tax goes here
            ,p_ra_lines_rec.reference_line_context
            ,p_ra_lines_rec.reference_line_attribute1
            ,p_ra_lines_rec.reference_line_attribute2
            ,p_ra_lines_rec.interface_line_context
            ,p_ra_lines_rec.batch_source_name
            ,p_ra_lines_rec.set_of_books_id
            ,p_ra_lines_rec.line_type
            ,p_ra_lines_rec.currency_code
            ,p_ra_lines_rec.conversion_type
            ,p_ra_lines_rec.conversion_date
            ,p_ra_lines_rec.conversion_rate
            ,p_ra_lines_rec.tax_code
            ,p_ra_lines_rec.created_by
            ,p_ra_lines_rec.creation_date
            ,p_ra_lines_rec.last_updated_by
            ,p_ra_lines_rec.last_update_date
            ,p_ra_lines_rec.org_id
            ,p_ra_lines_rec.uom_code
            ,p_ra_lines_rec.primary_salesrep_number
            ,p_ra_lines_rec.primary_salesrep_id
            ,p_ra_lines_rec.purchase_order
            ,p_ra_lines_rec.header_attribute14
            ,p_ra_lines_rec.header_attribute15
            ,p_ra_lines_rec.header_attribute_category
            ,p_ra_lines_rec.attribute11
            ,p_ra_lines_rec.attribute12
            ,p_ra_lines_rec.comments
            ,p_ra_lines_rec.taxable_amount
            ,p_ra_lines_rec.tax_rate_code
            ,p_ra_lines_rec.tax_rate
            ,p_ra_lines_rec.link_to_line_context
            ,p_ra_lines_rec.link_to_line_attribute1
            ,p_ra_lines_rec.link_to_line_attribute2
         );

   EXCEPTION
   
      WHEN OTHERS THEN
         l_err_message  :=  SQLERRM;
         INSERT INTO  swgcnv_conversion_exceptions
               (   conversion_type
               ,conversion_key_value
               ,error_message
               )
         VALUES 
            (  'AR Validation'
               ,p_ra_lines_rec.orig_system_bill_customer_id
               ,l_err_message
            );

         UPDATE   swgcnv_dd_temp_customers
         SET       ar_proc_flag         = 'E'
            WHERE    oracle_customer_id   =  p_ra_lines_rec.orig_system_bill_customer_id;
         
   END  insert_ra_lines;
   
   -----------------------------------------------
   
   PROCEDURE swgcnv_update_duedate
      (   ou_errmsg_s       OUT     VARCHAR2
            ,ou_errcode_n       OUT     NUMBER
            ,p_sales_center         IN      VARCHAR2
        )
   IS
   
      CURSOR cur_custtrx (in_batch_source_id NUMBER)
      IS
      SELECT a.trx_date
            ,a.customer_trx_id
            ,attribute15
            ,a.trx_number
      FROM   ra_customer_trx_all a
            ,swgcnv_dd_temp_customers b
      WHERE  1=1  --SUBSTR(a.trx_number,1,3)  =  p_sales_center
      AND    batch_source_id                  =  in_batch_source_id
      AND    a.bill_to_customer_id            =  b.oracle_customer_id
      AND    a.cust_trx_type_id        IN  (1800,1801,1802); -- Created New Conversion Transaction Types For R12
      
      l_cnt              NUMBER           :=    0;
      l_batch_source_id  NUMBER;
      l_err_message      VARCHAR2(2000)   :=    NULL;
      
   BEGIN
   
      --Fnd_Client_Info.set_org_context(2);
      MO_GLOBAL.SET_POLICY_CONTEXT('S',2);
      
      BEGIN
         SELECT batch_source_id
         INTO   l_batch_source_id
         FROM   ra_batch_sources
         WHERE  name = 'DD CONVERSION';
      
      EXCEPTION
         WHEN OTHERS THEN
            Fnd_File.put_line(Fnd_File.LOG,'Error while retriving batch source id : '||SQLERRM);
      END;
   
      FOR i IN cur_custtrx(l_batch_source_id)
      LOOP
      
         UPDATE ar_payment_schedules_all
         SET    due_date              =  i.attribute15
         WHERE  customer_trx_id     =  i.customer_trx_id
         AND    trx_date             =  i.trx_date
         AND    trx_number          =  i.trx_number;
         
         l_cnt := l_cnt + 1;
         
      END LOOP;
      
      COMMIT;
      
      Fnd_File.put_line(Fnd_File.LOG,'No of transactions are updated : '||l_cnt);
   EXCEPTION
      WHEN OTHERS THEN
         l_err_message  :=  SQLERRM;
         
         INSERT INTO  swgcnv_conversion_exceptions
            (   conversion_type
               ,conversion_key_value
               ,error_message
               )
         VALUES 
            (  'AR Update Duedate'
               ,p_sales_center
               ,l_err_message
            );
            
         Fnd_File.put_line(Fnd_File.LOG,'Error : '||SQLERRM);
         
   END Swgcnv_Update_Duedate;
   ----------------------------
   PROCEDURE Swgcnv_Post_Update1 
      (   ou_errmsg_s       OUT     VARCHAR2
            ,ou_errcode_n       OUT     NUMBER
            ,p_sales_center         IN      VARCHAR2
        )
   IS
   
      CURSOR cur_arpaysch
      IS
      SELECT customer_id
            ,customer_site_use_id
            ,due_date
            ,amount_due_remaining
            ,payment_schedule_id
            ,amount_due_original
            ,class
            ,customer_trx_id
            ,cash_receipt_id
            ,cust_trx_type_id
            ,trx_date
            ,trx_number
      FROM   ar_payment_schedules      arps
            ,swgcnv_dd_temp_customers  swgtemp
      WHERE  swgtemp.new_sales_center        =  p_sales_center
      AND    arps.customer_id                =  swgtemp.oracle_customer_id
      AND    arps.status                         =  'OP'
      AND    arps.customer_id                    IS NOT NULL
      AND    arps.customer_site_use_id       IS NOT NULL;
      
      l_cnt NUMBER := 0;
      
   BEGIN
   
      --Fnd_Client_Info.set_org_context(2);
      MO_GLOBAL.SET_POLICY_CONTEXT('S',2);
      
      FOR i IN cur_arpaysch
      LOOP
      
         INSERT INTO swg_ar_open_trx
         --EB 1821
         ( CUSTOMER_ID,
           BILL_TO_ID,
           DUE_DATE,
           OPEN_AMOUNT,
           PAYMENT_SCHEDULE_ID,
           AMOUNT_DUE_ORIGINAL,
           CLASS,
           CUSTOMER_TRX_ID,
           CASH_RECEIPT_ID,
           CUST_TRX_TYPE_ID,
           TRX_DATE,
           TRX_NUMBER
         )  
         VALUES
            (   i.customer_id
               ,i.customer_site_use_id
               ,i.due_date
               ,i.amount_due_remaining
               ,i.payment_schedule_id
               ,i.amount_due_original
               ,i.class
               ,i.customer_trx_id
               ,i.cash_receipt_id
               ,i.cust_trx_type_id
               ,i.trx_date
               ,i.trx_number
            );
            
         l_cnt := l_cnt + 1;
         
      END LOOP;
      
      COMMIT;
      
      dbms_output.put_line('No of transactions are inserted : '||l_cnt);
      Fnd_File.put_line(Fnd_File.LOG,'No of transactions are inserted : '||l_cnt);
      
   EXCEPTION
      WHEN OTHERS THEN
         Fnd_File.put_line(Fnd_File.LOG,'Error : '||SQLERRM);
   END Swgcnv_Post_Update1;
   ----------------------------------
   
   PROCEDURE Swgcnv_Post_Update2
      (   ou_errmsg_s       OUT     VARCHAR2
            ,ou_errcode_n       OUT     NUMBER
            ,p_sales_center         IN       VARCHAR2
        )
   IS
   
      CURSOR cur_swgopentrx
      IS
      SELECT    customer_id
               ,bill_to_id
               ,SUM(open_amount)     open_balance
               ,MIN(due_date)    oldest_due_date
               ,SUM(DECODE ( class, 'DM', open_amount, NULL)) dm_amount
               ,SUM(DECODE ( class, 'CM', open_amount, NULL)) cm_amount
               ,SUM(DECODE ( class, 'INV', open_amount, NULL)) inv_amount
               ,SUM(DECODE ( class, 'PMT', open_amount, NULL)) pmt_amount
               ,MAX(DECODE ( class, 'DM', 'Y', NULL)) dm_flag
               ,MAX(DECODE ( class, 'CM', 'Y', NULL)) cm_flag
               ,MAX(DECODE ( class, 'INV', 'Y', NULL)) inv_flag
               ,MAX(DECODE ( class, 'PMT', 'Y', NULL)) pmt_flag
               ,MAX(SYSDATE)    creation_date
      FROM      swg_ar_open_trx  swgarot
               ,swgcnv_dd_temp_customers swgtemp
      WHERE     swgarot.customer_id       =  swgtemp.oracle_customer_id
      AND       swgtemp.new_sales_center  =  p_sales_center
      GROUP BY  swgarot.customer_id
               ,swgarot.bill_to_id;
               
      l_cnt    NUMBER := 0;
      
   BEGIN
   
      --Fnd_Client_Info.set_org_context(2);
      MO_GLOBAL.SET_POLICY_CONTEXT('S',2);
      
      FOR i IN cur_swgopentrx
      LOOP
      
         INSERT INTO swg_cust_billto_open_balance
            (   customer_id
               ,bill_to_id
               ,open_balance
               ,oldest_due_date
               ,dm_amount
               ,cm_amount
               ,inv_amount
               ,pmt_amount
               ,dm_flag
               ,cm_flag
               ,inv_flag
               ,pmt_flag
               ,creation_date
            )
         VALUES
            (   i.customer_id
               ,i.bill_to_id
               ,i.open_balance
               ,i.oldest_due_date
               ,i.dm_amount
               ,i.cm_amount
               ,i.inv_amount
               ,i.pmt_amount
               ,i.dm_flag
               ,i.cm_flag
               ,i.inv_flag
               ,i.pmt_flag
               ,i.creation_date
            );
            
         l_cnt := l_cnt + 1;
         
      END LOOP;
      
      COMMIT;
      
      dbms_output.put_line('No of transactions are inserted : '||l_cnt);
      Fnd_File.put_line(Fnd_File.LOG,'No of transactions are inserted : '||l_cnt);
      
   EXCEPTION
      WHEN OTHERS THEN
      Fnd_File.put_line(Fnd_File.LOG,'Error : '||SQLERRM);
   END Swgcnv_Post_Update2;
   
   -----------------------------------------------------
   PROCEDURE Swgcnv_ar_Trx_Number
      (   ou_errmsg_s       OUT   VARCHAR2
         ,ou_errcode_n      OUT   NUMBER
         ,p_sales_center        IN      VARCHAR2
         ,p_legacy_system     IN    VARCHAR2
      )
   IS
      CURSOR A
      IS
      SELECT    /*+ INDEX(SWGCNV_DD_AR_INTERFACE,SWGCNV_DD_AR_INTERFACE_N4) */
                orig_system_bill_customer_ref
               ,orig_system_ship_customer_ref
               ,interface_line_attribute1
               ,cust_trx_type_name
               ,tax_status
               ,trx_date
               ,sales_center
               ,primary_salesrep_number
      FROM      swgcnv_dd_ar_interface
      WHERE     sales_center           =   p_sales_center
      AND        cust_trx_type_name     <> 'PAYMENT'
      GROUP BY  orig_system_bill_customer_ref
               ,orig_system_ship_customer_ref
               ,interface_line_attribute1
               ,cust_trx_type_name
               ,tax_status
               ,trx_date
               ,sales_center
               ,primary_salesrep_number;
               
      CURSOR B( l_orig_cust_ref        VARCHAR2
               ,l_orig_ship_cust_ref    VARCHAR2
               ,l_interface_line_att1   VARCHAR2
               ,l_trx_date                DATE
               ,l_sales_center         VARCHAR2
               ,l_cust_trx_type        VARCHAR2
               ,l_tax_status               VARCHAR2
               ,l_pri_salesrep_number  VARCHAR2
               )
      IS
      SELECT    /*+ INDEX(SWGCNV_DD_AR_INTERFACE,SWGCNV_DD_AR_INTERFACE_NR) */
                *
      FROM      swgcnv_dd_ar_interface
      WHERE     interface_line_attribute1         =  l_interface_line_att1
      AND       trx_date                             =  l_trx_date
      AND        tax_status                          =  l_tax_status
      AND        primary_salesrep_number           =  l_pri_salesrep_number
      AND        orig_system_ship_customer_ref  =  l_orig_ship_cust_ref
      AND       orig_system_bill_customer_ref   =  l_orig_cust_ref
      AND        cust_trx_type_name               =  l_cust_trx_type      
      AND       sales_center                        =  l_sales_center;

        l_header_cnt  NUMBER    := 0;
        l_line_cnt    NUMBER    := 0;
        l_total_cnt   NUMBER    := 0;
      
   BEGIN
   
      FOR i IN a
      LOOP
      
         l_header_cnt := l_header_cnt + 1;

         FOR j IN b(  i.orig_system_bill_customer_ref
                     ,i.orig_system_ship_customer_ref
                     ,i.interface_line_attribute1
                     ,i.trx_date
                     ,i.sales_center
                     ,i.cust_trx_type_name
                     ,i.tax_status
                     ,i.primary_salesrep_number
                  )
         LOOP

            l_line_cnt := l_line_cnt + 1;
            
            UPDATE /*+ INDEX(SWGCNV_DD_AR_INTERFACE,SWGCNV_DD_AR_INTERFACE_NR) */
                   swgcnv_dd_ar_interface
            SET    interface_line_attribute2       =  l_line_cnt
                  ,line_number                     =  l_line_cnt
                  ,attribute1                      =  j.interface_line_attribute1
                  ,attribute2                      =  j.interface_line_attribute2
            WHERE  interface_line_attribute1       =  j.interface_line_attribute1
            AND    interface_line_attribute2       =  j.interface_line_attribute2
            AND    primary_salesrep_number         =  j.primary_salesrep_number
            AND    NVL(item_code,1)                =  NVL(j.item_code,1)      -- Added for WO 18998. Conversion Enhancements
            AND    tax_status                      =  j.tax_status
            AND    orig_system_ship_customer_ref   =  j.orig_system_ship_customer_ref
            AND    trx_date                        =  j.trx_date
            AND    orig_system_bill_customer_ref   =  j.orig_system_bill_customer_ref
            AND    cust_trx_type_name              =  j.cust_trx_type_name
            AND    sales_center                    =  j.sales_center;
            
            l_total_cnt := l_total_cnt + 1;
            
            COMMIT;
            
         END LOOP;
         
         l_line_cnt    := 0;
      
      END LOOP;
      
      COMMIT;
      
      Fnd_File.put_line(Fnd_File.LOG,'Total No of Transactions are Updated : '||l_total_cnt);
   
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         Fnd_File.put_line(Fnd_File.LOG,'No data found  : '||SQLERRM);
        WHEN OTHERS THEN
         Fnd_File.put_line(Fnd_File.LOG,'Others         : '||SQLERRM);
   END Swgcnv_ar_Trx_Number;
   ---------------------------------------
   PROCEDURE Swgcnv_ar_Preupdates
      (   ou_errmsg_s      OUT   VARCHAR2
            ,ou_errcode_n     OUT   NUMBER
            ,p_division         IN    VARCHAR2
            ,p_sales_center IN      VARCHAR2
        )
   IS
   
      l_sales_center  VARCHAR2(3)   :=    p_sales_center;
      l_division         VARCHAR2(4)   :=    p_division;
      
   BEGIN
      --Fnd_Client_Info.set_org_context(2);
      MO_GLOBAL.SET_POLICY_CONTEXT('S',2);
   --1)
      BEGIN
         UPDATE swgcnv_dd_ar_interface
         SET    division    = l_division
         WHERE  sales_center  = l_sales_center;
         
         DBMS_OUTPUT.PUT_LINE(' 1 ');
         Fnd_File.put_line(Fnd_File.LOG,' 1 ');
      EXCEPTION
            WHEN NO_DATA_FOUND THEN
            Fnd_File.put_line(Fnd_File.LOG,'NDF FOR swgcnv_dd_ar_interface table        : '||SQLERRM);
            WHEN OTHERS THEN
                Fnd_File.put_line(Fnd_File.LOG,'ERR while updating replace trx_number -     : '||SQLERRM);
      END;
      
      COMMIT;
   --2)
      BEGIN
         UPDATE swgcnv_dd_ar_interface
         SET    cust_trx_type_name  = 'INVOICE'
         WHERE  tax_status            = 'UI'
         AND    sales_center          = l_sales_center;
         
            Fnd_File.put_line(Fnd_File.LOG,' 2 ');
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            Fnd_File.put_line(Fnd_File.LOG,'NDF for tax_status = UI : '||SQLERRM);
            WHEN OTHERS THEN
                Fnd_File.put_line(Fnd_File.LOG,'ERR for tax_status = UI : '||SQLERRM);
      END;
      
      COMMIT;
   --3)
      BEGIN
         UPDATE swgcnv_dd_ar_interface
         SET    cust_trx_type_name  = 'PAYMENT'
         WHERE  tax_status          = 'UP'
         AND    amount              <  0
         AND    sales_center          =  l_sales_center;
         
            Fnd_File.put_line(Fnd_File.LOG,' 3 ');
      EXCEPTION
            WHEN NO_DATA_FOUND THEN
            Fnd_File.put_line(Fnd_File.LOG,'NDF for tax_status = UP  AND AMT < 0        : '||SQLERRM);
            WHEN OTHERS THEN
                Fnd_File.put_line(Fnd_File.LOG,'ERR for tax_status = UP  AND AMT < 0        : '||SQLERRM);
      END;
      
      COMMIT;
   --4)
      BEGIN
         UPDATE swgcnv_dd_ar_interface
         SET    cust_trx_type_name  = 'INVOICE'
         WHERE  tax_status            = 'UP'
         AND    amount                >= 0
         AND    sales_center          =  l_sales_center;
         
            Fnd_File.put_line(Fnd_File.LOG,' 4 ');
      EXCEPTION
            WHEN NO_DATA_FOUND THEN
            Fnd_File.put_line(Fnd_File.LOG,'NDF for tax_status = UP  AND AMT >= 0      : '||SQLERRM);
            WHEN OTHERS THEN
                Fnd_File.put_line(Fnd_File.LOG,'ERR for tax_status = UP  AND AMT >= 0      : '||SQLERRM);
      END;
      
      COMMIT;
   --5)
      BEGIN
         UPDATE swgcnv_dd_ar_interface
         SET    cust_trx_type_name   =  'CREDIT MEMO'
         WHERE  tax_status          =  'B'
         AND    cust_trx_type_name  =  'INVOICE'
         AND    amount                <  0
         AND    sales_center          =  l_sales_center;
         
            Fnd_File.put_line(Fnd_File.LOG,' 5 ');
         
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            Fnd_File.put_line(Fnd_File.LOG,'NDF for tax_status = B  AND AMT < 0       : '||SQLERRM);
            WHEN OTHERS THEN
                Fnd_File.put_line(Fnd_File.LOG,'ERR for tax_status = B  AND AMT < 0       : '||SQLERRM);
      END;
      
      COMMIT;
   --6)
      BEGIN
         UPDATE swgcnv_dd_ar_interface
         SET    cust_trx_type_name  = 'INVOICE'
         WHERE  cust_trx_type_name  = 'PAYMENT'
         AND    amount                > 0
         AND    sales_center        = l_sales_center;
         
            Fnd_File.put_line(Fnd_File.LOG,' 6 ');
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            Fnd_File.put_line(Fnd_File.LOG,'NDF for trx type = PAYMENT  AND AMT > 0   : '||SQLERRM);
            WHEN OTHERS THEN
                Fnd_File.put_line(Fnd_File.LOG,'ERR for trx type = PAYMENT  AND AMT > 0   : '||SQLERRM);
      END;
      
      COMMIT;
   --7)
      BEGIN
         UPDATE swgcnv_dd_ar_interface
         SET    attribute10               =  SUBSTR(attribute10,1,1)||LTRIM(RTRIM(SUBSTR(attribute10,2)))
         WHERE  attribute10               IS NOT NULL
         AND    SUBSTR(attribute10,1,1)   =  '-'
         AND    sales_center              =  l_sales_center;
      
         Fnd_File.put_line(Fnd_File.LOG,' 7 ');
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            Fnd_File.put_line(Fnd_File.LOG,'NDF for -      7                        : '||SQLERRM);
            WHEN OTHERS THEN
            Fnd_File.put_line(Fnd_File.LOG,'ERR for -      7                        : '||SQLERRM);
      END;
      
      COMMIT;
   --8)
      BEGIN
         UPDATE  swgcnv_dd_ar_interface
         SET      cust_trx_type_name    = 'CREDIT MEMO'
         WHERE   sales_center         =  l_sales_center
         AND     tax_status              IN ('UP','B')
         AND     cust_trx_type_name    IN ('PAYMENT','UNBILLED')
         AND      attribute10            <> 0;
         
            Fnd_File.put_line(Fnd_File.LOG,' 8 ');
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            Fnd_File.put_line(Fnd_File.LOG,'NDF for -      8                         : '||SQLERRM);
            WHEN OTHERS THEN
                Fnd_File.put_line(Fnd_File.LOG,'ERR for -      8                         : '||SQLERRM);
      END;
      
      COMMIT;
   --9)
      BEGIN
         UPDATE swgcnv_dd_ar_interface
         SET    primary_salesrep_number   = 'DEFAULT'
         WHERE  primary_salesrep_number   IS NULL
         AND    sales_center                =  l_sales_center;
         
         DBMS_OUTPUT.PUT_LINE(' 9 ');
         Fnd_File.put_line(Fnd_File.LOG,' 9 ');
      EXCEPTION
            WHEN NO_DATA_FOUND THEN
            Fnd_File.put_line(Fnd_File.LOG,'NDF FOR swgcnv_dd_ar_interface table        : '||SQLERRM);
            WHEN OTHERS THEN
                Fnd_File.put_line(Fnd_File.LOG,'ERR while updating replace trx_number -     : '||SQLERRM);
      END;
      
      COMMIT;
   --10)
      BEGIN
         UPDATE swgcnv_dd_ar_interface
         SET    cust_trx_type_name   = 'CREDIT MEMO'
         WHERE  tax_status          = 'U'
         AND    cust_trx_type_name  = 'PAYMENT'
         AND    amount                < 0
         AND    sales_center           = l_sales_center;
         
         DBMS_OUTPUT.PUT_LINE(' 9 ');
         Fnd_File.put_line(Fnd_File.LOG,' 9 ');
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            Fnd_File.put_line(Fnd_File.LOG,'NDF FOR swgcnv_dd_ar_interface table        : '||SQLERRM);
            WHEN OTHERS THEN
                Fnd_File.put_line(Fnd_File.LOG,'ERR while updating amount lessthan zero value -     : '||SQLERRM);
      END;
      
      COMMIT;
   EXCEPTION
        WHEN OTHERS THEN
         Fnd_File.put_line(Fnd_File.LOG,'ERR for : '||SQLERRM);
   END Swgcnv_ar_Preupdates;

   --------------------------------------
   
  PROCEDURE swgcnv_ar_preconv_reports
      (      ou_errmsg_s        OUT     VARCHAR2
            ,ou_errcode_n       OUT     NUMBER
            ,p_sales_center     IN      VARCHAR2
      )
   IS

      CURSOR a
      IS
      SELECT    sales_center
               ,COUNT (*)                            transactions
               ,SUM (NVL (amount,0))                 amt
               ,SUM (NVL (attribute10,0))            tax
               ,SUM(NVL (amount,0) +  NVL (attribute10,0) )      total
      FROM      swgcnv_dd_ar_history
      GROUP BY  sales_center
      ORDER BY  2;

      CURSOR b
      IS
      SELECT    sales_center
               ,cust_trx_type_name
               ,COUNT (*)                                   transactions
               ,SUM (NVL (amount,0))                        amt
               ,SUM (NVL (attribute10,0))                   tax
               ,SUM (NVL (amount,0)+ NVL (attribute10,0))   total
               ,'NA' trxn_status
      FROM      swgcnv_dd_ar_history
      GROUP BY  cust_trx_type_name
               ,sales_center
      ORDER BY  1,2;

      CURSOR c 
      IS
      SELECT    COUNT(*)
      FROM      swgcnv_dd_ar_history
      WHERE     1=1  --sales_center  =  in_sales_center
      AND       attribute10   <> 0;

      CURSOR d
      IS
      SELECT    orig_system_bill_customer_ref
               ,orig_system_bill_address_ref
               ,cust_trx_type_name
               ,COUNT (*)                                   transactions
               ,SUM (NVL (amount,0))                        amt
               ,SUM (NVL (attribute10,0))                   tax
               ,SUM (NVL (AMOUNT,0)+ NVL (ATTRIBUTE10,0)) TOTAL
               ,'NA' trxn_status
      FROM     swgcnv_dd_ar_history h
      WHERE    orig_system_bill_customer_ref IN
                                                (     SELECT   orig_system_bill_customer_ref
                                                      FROM     swgcnv_dd_ar_history c
                                                      WHERE    c.sales_center   =  h.sales_center 
                                                      MINUS
                                                      SELECT   legacy_customer_number
                                                      FROM     swgcnv_dd_temp_customers
                                                )
      GROUP BY  cust_trx_type_name
               ,trxn_status
               ,orig_system_bill_customer_ref
               ,orig_system_bill_address_ref
      ORDER BY 1,2;

      CURSOR e
      IS
      SELECT    sales_center
               ,COUNT(*)                cnt
               ,SUM(customer_balance)   total_amt
      FROM     swgcnv_dd_stmt_interface
      GROUP BY sales_center;

      -- AR Balance On Statements
      CURSOR f
      IS
      SELECT    sales_center
               ,COUNT(*)                                cnt
               ,SUM(NVL(amount,0) + NVL(attribute10,0)) total_amt
      FROM      swgcnv_dd_ar_history
      WHERE     trxn_status       IS NULL
      GROUP BY  sales_center;

      -- AR Balance Not On Statements
      CURSOR g
      IS
      SELECT    sales_center
               ,COUNT(*)                                cnt
               ,SUM(NVL(amount,0) + NVL(attribute10,0)) total_amt
      FROM      swgcnv_dd_ar_history
      WHERE     trxn_status   =  'NA' 
      GROUP BY  sales_center;

        l_rpt1_cnt     NUMBER := 0;
        l_rpt2_cnt     NUMBER := 0;
        l_rpt3_cnt     NUMBER := 0;
        l_rpt4_cnt     NUMBER := 0;
        l_rpt5_cnt     NUMBER := 0;
        l_total_rep_n  NUMBER := 0;
        
        l_sales_center VARCHAR2(100);

   BEGIN
      --Fnd_Client_Info.set_org_context(2);
      MO_GLOBAL.SET_POLICY_CONTEXT('S',2);

      Fnd_File.put_line(Fnd_File.output,RPAD(' ',30,' ')||'Pre Conversion AR Reports Ver.2');  --EB-1596
      Fnd_File.put_line(Fnd_File.output,RPAD(' ',33,' ')||'Report Date :'||SYSDATE);
      Fnd_File.put_line(Fnd_File.output,RPAD(' ',30,' ')||'-------------------------------');
      Fnd_File.put_line(Fnd_File.output,' ');
      Fnd_File.put_line(Fnd_File.output,' ');
      Fnd_File.put_line(Fnd_File.output,'Report1 : Total Transactions for the Legacy System');
      Fnd_File.put_line(Fnd_File.output,' ');
      Fnd_File.PUT_LINE(Fnd_File.output,RPAD(' ',5,' ')||'Sales Center'||'  '||'No of Trans'||'  '||' Trans Amount '||'  '||'TAX Amount'||' '||'  Total Amount  ');
      Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||RPAD('=',12,'=')||'  '||RPAD('=',11,'=')||'  '||LPAD('=',14,'=')||'  '||LPAD('=',10,'=')||' '||LPAD('=',16,'='));
      Fnd_File.put_line(Fnd_File.output,' ');

      FOR i IN a
      LOOP

         Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||'  '||RPAD(i.sales_center,12,' ')||'  '||RPAD(i.transactions,11,' ')||'  '||LPAD(i.amt,14,' ')||'  '||LPAD(i.tax,10,' ')||' '||LPAD(i.total,16,' '));
         l_rpt1_cnt := l_rpt1_cnt + 1;
         l_total_rep_n  := l_total_rep_n + i.total;

      END LOOP;--i

      Fnd_File.put_line(Fnd_File.output, RPAD(' ',60,' ')||'-----------------');
      Fnd_File.put_line(Fnd_File.output, LPAD(l_total_rep_n,77,' '));

      IF l_rpt1_cnt = 0 THEN
         Fnd_File.put_line(Fnd_File.output,RPAD(' ',30,' ')||'*****No Data Found*****');
      END IF;

      Fnd_File.put_line(Fnd_File.output,' ');
      Fnd_File.put_line(Fnd_File.output,'Report2 : Total Transactons for the Legacy System Transaction Type wise');
      Fnd_File.put_line(FND_FILE.OUTPUT,' ');
      Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||'  '||'Sales Center'||' '||'Transaction Type'||' '||'Trxn Status'||'  '||'No of Trans'||'  '||' Trans Amount '||'  '||'TAX Amount'||' '||'  Total Amount  ');
      Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||'  '||RPAD('=',12,'=')||' '||RPAD('=',16,'=')||'  '||RPAD('=',10,'=')||'  '||RPAD('=',11,'=')||'  '||LPAD('=',14,'=')||'  '||LPAD('=',10,'=')||' '||LPAD('=',16,'='));
      Fnd_File.put_line(Fnd_File.output,' ');

      FOR j IN b
      LOOP

         Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||'  '||RPAD(j.sales_center,12,' ')||' '||RPAD(j.cust_trx_type_name,16,' ')||'  '||RPAD(j.trxn_status,10,' ')||'  '||RPAD(j.transactions,11,' ')||'  '||LPAD(j.amt,14,' ')||'  '||LPAD(j.tax,10,' ')||' '||LPAD(j.total,16,' '));
         l_rpt2_cnt := l_rpt2_cnt + 1;

      END LOOP;--i

      IF l_rpt2_cnt = 0 THEN
         Fnd_File.put_line(Fnd_File.output,RPAD(' ',30,' ')||'*****No Data Found*****');
      END IF;

      Fnd_File.put_line(Fnd_File.output,' ');
      Fnd_File.put_line(Fnd_File.output,'Report3 : Total Transactons for the Legacy System without Customers');
      Fnd_File.put_line(Fnd_File.output,' ');
      Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||'Legacy Customer'||' '||'Transaction Type'||' '||'Tax Status'||'  '||'No of Trans'||'  '||' Trans Amount '||'  '||'TAX Amount'||' '||'  Total Amount  ');
      Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||RPAD('=',15,'=')||' '||RPAD('=',16,'=')||'  '||RPAD('=',10,'=')||'  '||RPAD('=',11,'=')||'  '||LPAD('=',14,'=')||'  '||LPAD('=',10,'=')||' '||LPAD('=',16,'='));
      Fnd_File.put_line(Fnd_File.output,' ');

      FOR l IN d
      LOOP

         Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||RPAD(l.orig_system_bill_customer_ref,15,' ')||' '||RPAD(l.cust_trx_type_name,16,' ')||'  '||RPAD(l.trxn_status,10,' ')||'  '||RPAD(l.transactions,11,' ')||'  '||LPAD(l.amt,14,' ')||'  '||LPAD(l.tax,10,' ')||' '||LPAD(l.total,16,' '));
         l_rpt3_cnt := l_rpt3_cnt + 1;

      END LOOP;--i

      IF l_rpt3_cnt = 0 THEN
         Fnd_File.put_line(Fnd_File.output,RPAD(' ',30,' ')||'*****No Data Found*****');
      END IF;

      Fnd_File.put_line(Fnd_File.output,' ');    --4)

      Fnd_File.put_line(Fnd_File.output,'Report4 : Statement Balance for Legacy System ');
      Fnd_File.put_line(Fnd_File.output,' ');
      Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||'Sales Center'||' '||'No of Trans'||' '||' Total Amount ');
      Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||RPAD('=',12,'=')||' '||RPAD('=',11,'=')||'  '||RPAD('=',14,'='));
      Fnd_File.put_line(Fnd_File.output,' ');

      FOR m IN e
      LOOP
         Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||RPAD(m.sales_center,12,' ')||' '||RPAD(m.cnt,11,' ')||'  '||LPAD(m.total_amt,14,' '));
         l_rpt4_cnt := l_rpt4_cnt + 1;
      END LOOP;--i

      IF l_rpt4_cnt = 0 THEN
         Fnd_File.put_line(Fnd_File.output,RPAD(' ',30,' ')||'*****No Data Found*****');
      END IF;

      Fnd_File.put_line(Fnd_File.output,' ');     --5)
      Fnd_File.put_line(Fnd_File.output,CHR(12));
      Fnd_File.put_line(Fnd_File.output,'Report5 : AR Balances for Legacy System for Statements');
      Fnd_File.put_line(Fnd_File.output,' ');
      Fnd_File.put_line(Fnd_File.output,RPAD(' ',27,' ')||'Sales Center'||' '||'No of Trans'||' '||' Total Amount ');
      Fnd_File.put_line(Fnd_File.output,RPAD(' ',27,' ')||RPAD('=',12,'=')||' '||RPAD('=',11,'=')||'  '||RPAD('=',14,'='));
      Fnd_File.put_line(Fnd_File.output,' ');

      FOR n IN f
      LOOP
         Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||RPAD('Exclude Trx On Stmt  ',22,' ')||' '||RPAD(n.sales_center,12,' ')||' '||RPAD(n.cnt,11,' ')||'  '||LPAD(n.total_amt,14,' '));
         l_rpt5_cnt := l_rpt5_cnt + 1;
      END LOOP;--i

      FOR O IN g
      LOOP
         Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||RPAD('Exclude B,O  ',22,' ')||' '||RPAD(O.sales_center,12,' ')||' '||RPAD(O.cnt,11,' ')||'  '||LPAD(O.total_amt,14,' '));
      END LOOP;--i

      IF l_rpt4_cnt = 0 THEN
         Fnd_File.put_line(Fnd_File.output,RPAD(' ',30,' ')||'*****No Data Found*****');
      END IF;

      Fnd_File.put_line(Fnd_File.output,' ');

      Fnd_File.put_line(Fnd_File.output,RPAD(' ',30,' ')||'*****End of Report*****');

   EXCEPTION
      WHEN OTHERS THEN
         Fnd_File.put_line(Fnd_File.LOG,'ERR for : '||SQLERRM);
   END swgcnv_ar_preconv_reports;
   
   ----------------------------------------------
   PROCEDURE swgcnv_ar_preconv_reports1
      (   ou_errmsg_s       OUT     VARCHAR2
            ,ou_errcode_n       OUT     NUMBER
            ,p_sales_center     IN      VARCHAR2
        )
   IS
      CURSOR a
      IS
      SELECT    sales_center
               ,COUNT (*)                                            transactions
               ,SUM (NVL (amount,0))                               amt
               ,SUM (NVL (attribute10,0))                     tax
               ,SUM(NVL (amount,0) +  NVL (attribute10,0) ) total
      FROM      swgcnv_dd_ar_interface
      WHERE     sales_center = p_sales_center
      GROUP BY  sales_center
      ORDER BY  2;

      CURSOR b
      IS
      SELECT    sales_center
               ,cust_trx_type_name
               ,COUNT (*)                                        transactions
               ,SUM (NVL (amount,0))                               amt
               ,SUM (NVL (attribute10,0))                      tax
               ,SUM (NVL (amount,0)+ NVL (attribute10,0))   total
               ,tax_status
      FROM      swgcnv_dd_ar_interface
      WHERE     sales_center = p_sales_center
      GROUP BY  cust_trx_type_name
               ,tax_status
               ,sales_center
      ORDER BY  6;

      CURSOR C
      IS
      SELECT    sales_center
               ,cust_trx_type_name
               ,COUNT (*)                                        transactions
               ,SUM (NVL (amount,0))                               amt
               ,SUM (NVL (attribute10,0))                      tax
               ,SUM (NVL (amount,0)+ NVL (attribute10,0))   total
      FROM      swgcnv_dd_ar_interface
      WHERE     sales_center = p_sales_center
      GROUP BY  cust_trx_type_name
               ,sales_center
      ORDER BY  6;

      CURSOR d
      IS    
      SELECT    orig_system_bill_customer_ref
               ,orig_system_bill_address_ref
               ,cust_trx_type_name
               ,COUNT (*)                                       transactions
               ,SUM (NVL (amount,0))                               amt
               ,SUM (NVL (attribute10,0))                       tax
               ,SUM (NVL (amount,0)+ NVL (attribute10,0))   total
               ,tax_status
      FROM      swgcnv_dd_ar_interface
      WHERE     sales_center   =   p_sales_center
      AND       orig_system_bill_customer_ref IN   (  SELECT orig_system_bill_customer_ref
                                                      FROM swgcnv_dd_ar_history
                                                      WHERE sales_center   =  p_sales_center
                                                   MINUS
                                                      SELECT legacy_customer_number
                                                      FROM swgcnv_dd_temp_customers
                                                   )
      GROUP BY  cust_trx_type_name
               ,tax_status
               ,orig_system_bill_customer_ref
               ,orig_system_bill_address_ref
      ORDER BY 1,2;

        l_rpt1_cnt   NUMBER := 0;
        l_rpt2_cnt   NUMBER := 0;
        l_rpt3_cnt   NUMBER := 0;
        l_rpt4_cnt   NUMBER := 0;

   BEGIN
   
      --Fnd_Client_Info.set_org_context(2);
      MO_GLOBAL.SET_POLICY_CONTEXT('S',2);
      
      Fnd_File.PUT_LINE(Fnd_File.output,RPAD(' ',30,' ')||'Pre Conversion AR Reports Ver.2');
      Fnd_File.PUT_LINE(Fnd_File.output,RPAD(' ',33,' ')||'Report Date :'||SYSDATE);
      Fnd_File.PUT_LINE(Fnd_File.output,RPAD(' ',30,' ')||'-------------------------------');
      Fnd_File.put_line(Fnd_File.output,' ');
      Fnd_File.put_line(Fnd_File.output,' ');
      Fnd_File.put_line(Fnd_File.output,'Report1 : Total Transactons for the '||p_sales_center||' Sales center');
      Fnd_File.put_line(Fnd_File.output,' ');
      Fnd_File.PUT_LINE(Fnd_File.output,RPAD(' ',5,' ')||'Sales Center'||'  '||'No of Trans'||'  '||' Trans Amount '||'  '||'TAX Amount'||' '||'  Total Amount  ');
      Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||RPAD('=',12,'=')||'  '||RPAD('=',11,'=')||'  '||LPAD('=',14,'=')||'  '||LPAD('=',10,'=')||' '||LPAD('=',16,'='));
      Fnd_File.put_line(Fnd_File.output,' ');
      
      FOR i IN a
      LOOP
         Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||'  '||RPAD(i.sales_center,12,' ')||'  '||RPAD(i.transactions,11,' ')||'  '||LPAD(i.amt,14,' ')||'  '||LPAD(i.tax,10,' ')||' '||LPAD(i.total,16,' '));
         l_rpt1_cnt := l_rpt1_cnt + 1;
      END LOOP;--i
   
      IF l_rpt1_cnt = 0 THEN
         Fnd_File.put_line(Fnd_File.output,RPAD(' ',30,' ')||'*****No Data Found*****');
      END IF;
   
      Fnd_File.put_line(Fnd_File.output,' ');
      Fnd_File.put_line(Fnd_File.output,'Report2 : Total Transactons for the '||p_sales_center||' Sales center TAX Status wise');
      Fnd_File.put_line(Fnd_File.output,' ');
      Fnd_File.PUT_LINE(Fnd_File.output,RPAD(' ',5,' ')||'  '||'Sales Center'||' '||'Transaction Type'||' '||'Tax Status'||'  '||'No of Trans'||'  '||' Trans Amount '||'  '||'TAX Amount'||' '||'  Total Amount  ');
      Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||'  '||RPAD('=',12,'=')||' '||RPAD('=',16,'=')||'  '||RPAD('=',10,'=')||'  '||RPAD('=',11,'=')||'  '||LPAD('=',14,'=')||'  '||LPAD('=',10,'=')||' '||LPAD('=',16,'='));
      Fnd_File.put_line(Fnd_File.output,' ');
      
      FOR j IN b
      LOOP
         Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||'  '||RPAD(j.sales_center,12,' ')||' '||RPAD(j.cust_trx_type_name,16,' ')||'  '||RPAD(j.tax_status,10,' ')||'  '||RPAD(j.transactions,11,' ')||'  '||LPAD(j.amt,14,' ')||'  '||LPAD(j.tax,10,' ')||' '||LPAD(j.total,16,' '));
         l_rpt2_cnt := l_rpt2_cnt + 1;
      END LOOP;--i
      
      IF l_rpt2_cnt = 0 THEN
         Fnd_File.put_line(Fnd_File.output,RPAD(' ',30,' ')||'*****No Data Found*****');
      END IF;
      
      Fnd_File.put_line(Fnd_File.output,' ');
      
      --3)
      Fnd_File.put_line(Fnd_File.output,'Report3 : Total Transactons for the '||p_sales_center||' Sales center Transaction Type wise');
      Fnd_File.put_line(Fnd_File.output,' ');
      Fnd_File.PUT_LINE(Fnd_File.output,RPAD(' ',5,' ')||'  '||'Sales Center'||' '||'Transaction Type'||'  '||'No of Trans'||'  '||' Trans Amount '||'  '||'TAX Amount'||' '||'  Total Amount  ');
      Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||'  '||RPAD('=',12,'=')||' '||RPAD('=',16,'=')||'  '||RPAD('=',11,'=')||'  '||LPAD('=',14,'=')||'  '||LPAD('=',10,'=')||' '||LPAD('=',16,'='));
      Fnd_File.put_line(Fnd_File.output,' ');
      
      FOR k IN c
      LOOP
         Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||'  '||RPAD(k.sales_center,12,' ')||' '||RPAD(k.cust_trx_type_name,16,' ')||'  '||RPAD(k.transactions,11,' ')||'  '||LPAD(k.amt,14,' ')||'  '||LPAD(k.tax,10,' ')||' '||LPAD(k.total,16,' '));
         l_rpt3_cnt := l_rpt3_cnt + 1;
      END LOOP;--i
      
      IF l_rpt3_cnt = 0 THEN
         Fnd_File.put_line(Fnd_File.output,RPAD(' ',30,' ')||'*****No Data Found*****');
      END IF;
      
      Fnd_File.put_line(Fnd_File.output,' ');
      
      --4)
      Fnd_File.put_line(Fnd_File.output,CHR(12));
      Fnd_File.put_line(Fnd_File.output,'Report4 : Total Transactons for the '||p_sales_center||' Sales center without Customers');
      Fnd_File.put_line(Fnd_File.output,' ');
      Fnd_File.PUT_LINE(Fnd_File.output,RPAD(' ',5,' ')||'Legacy Customer'||' '||'Transaction Type'||' '||'Tax Status'||'  '||'No of Trans'||'  '||' Trans Amount '||'  '||'TAX Amount'||' '||'  Total Amount  ');
      Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||RPAD('=',15,'=')||' '||RPAD('=',16,'=')||'  '||RPAD('=',10,'=')||'  '||RPAD('=',11,'=')||'  '||LPAD('=',14,'=')||'  '||LPAD('=',10,'=')||' '||LPAD('=',16,'='));
      Fnd_File.put_line(Fnd_File.output,' ');
      
      FOR l IN d
      LOOP
         Fnd_File.put_line(Fnd_File.output,RPAD(' ',5,' ')||RPAD(l.orig_system_bill_customer_ref,15,' ')||' '||RPAD(l.cust_trx_type_name,16,' ')||'  '||RPAD(l.tax_status,10,' ')||'  '||RPAD(l.transactions,11,' ')||'  '||LPAD(l.amt,14,' ')||'  '||LPAD(l.tax,10,' ')||' '||LPAD(l.total,16,' '));
         l_rpt4_cnt := l_rpt4_cnt + 1;
      END LOOP;--i
      
      IF l_rpt4_cnt = 0 THEN
         Fnd_File.put_line(Fnd_File.output,RPAD(' ',30,' ')||'*****No Data Found*****');
      END IF;
      
      Fnd_File.put_line(Fnd_File.output,' ');
      Fnd_File.put_line(Fnd_File.output,RPAD(' ',30,' ')||'*****End of Report*****');
   EXCEPTION
      WHEN OTHERS THEN
         Fnd_File.put_line(Fnd_File.LOG,'ERR for : '||SQLERRM);
   END swgcnv_ar_preconv_reports1;
   ------------------------------------------
   PROCEDURE swgcnv_seq_prog
      (   out_errbuf_s        OUT   VARCHAR2
            ,out_errnum_n         OUT   NUMBER
         ,p_legacy_system     IN       VARCHAR2
         ,p_sales_center      IN       VARCHAR2
                                          
      )
   IS

      l_request_id1         NUMBER   :=    NULL;
      l_phase1                 VARCHAR2(20);
      l_status1             VARCHAR2(20);
      l_dev_phase1          VARCHAR2(20);
      l_dev_status1         VARCHAR2(20);
      l_message1                VARCHAR2(100);
      l_status_b1               BOOLEAN;

      l_request_id2         NUMBER   :=    NULL;
      l_phase2                 VARCHAR2(20);
      l_status2             VARCHAR2(20);
      l_dev_phase2          VARCHAR2(20);
      l_dev_status2         VARCHAR2(20);
      l_message2                VARCHAR2(100);
      l_status_b2               BOOLEAN;

      l_request_id3         NUMBER   :=   NULL;
      l_phase3                 VARCHAR2(20);
      l_status3             VARCHAR2(20);
      l_dev_phase3          VARCHAR2(20);
      l_dev_status3         VARCHAR2(20);
      l_message3                VARCHAR2(100);
      l_status_b3               BOOLEAN;

      l_request_id4         NUMBER   :=    NULL;
      l_phase4                 VARCHAR2(20);
      l_status4             VARCHAR2(20);
      l_dev_phase4          VARCHAR2(20);
      l_dev_status4         VARCHAR2(20);
      l_message4                VARCHAR2(100);
      l_status_b4               BOOLEAN;

      l_request_id5         NUMBER   :=    NULL;
      l_phase5                 VARCHAR2(20);
      l_status5             VARCHAR2(20);
      l_dev_phase5          VARCHAR2(20);
      l_dev_status5         VARCHAR2(20);
      l_message5                VARCHAR2(100);
      l_status_b5               BOOLEAN;

      l_request_id6         NUMBER   :=    NULL;
      l_phase6                 VARCHAR2(20);
      l_status6             VARCHAR2(20);
      l_dev_phase6          VARCHAR2(20);
      l_dev_status6         VARCHAR2(20);
      l_message6                VARCHAR2(100);
      l_status_b6               BOOLEAN;

      error_encountered        exception;
      l_error_reqid          varchar2(100);

   BEGIN
   
      --1st
        l_request_id1   :=  Fnd_Request.submit_request
                           (   'SWGCNV'
                                        ,'SWGCNV_AR_POSTUPDATE1'
                                        ,'SWGCNV_AR_POSTUPDATE1'
                                        ,NULL
                                        ,NULL
                                        ,p_sales_center
                                    );
                           
        COMMIT;
        Fnd_File.put_line(Fnd_File.LOG,l_request_id1);
       LOOP
      
            l_status_b1 :=     Fnd_Concurrent.wait_for_request
                              (   l_request_id1
                                            ,15
                                            ,15
                                            ,l_phase1
                                            ,l_status1
                                            ,l_dev_phase1
                                            ,l_dev_status1
                                            ,l_message1
                                    );
                              
            EXIT WHEN l_dev_phase1 = 'COMPLETE';
         
      END LOOP;
        Fnd_File.put_line(Fnd_File.LOG,'Status of the first conc prog  : '||l_dev_phase1||' '||l_dev_status1);
      
      --2nd
        IF l_dev_phase1        =    'COMPLETE' AND
            l_dev_status1          =    'NORMAL'   AND
            l_request_id1          <>   0
        THEN
      
            l_request_id2   :=     Fnd_Request.submit_request
                                 (   'SWGCNV'
                                                ,'SWGCNV_AR_POSTUPDATE2'
                                                ,'SWGCNV_AR_POSTUPDATE2'
                                                ,NULL
                                                ,NULL
                                                ,p_sales_center
                                            );
          COMMIT;
         
       ELSE
       
            l_error_reqid := ' GOT ERROR '||l_request_id1;
            RAISE  ERROR_ENCOUNTERED;
         
        END IF; --

        Fnd_File.put_line(Fnd_File.LOG,l_request_id2);
      LOOP
            l_status_b2 :=     Fnd_Concurrent.wait_for_request
                              (   l_request_id2
                                            ,15
                                            ,15
                                            ,l_phase2
                                            ,l_status2
                                            ,l_dev_phase2
                                            ,l_dev_status2
                                            ,l_message2
                                    );
            EXIT WHEN l_dev_phase2 = 'COMPLETE';
      END LOOP;
        Fnd_File.put_line(Fnd_File.LOG,'Status of the first conc prog  : '||l_dev_phase2||' '||l_dev_status2);
      
      --3rd
      IF l_dev_phase2           =    'COMPLETE' AND
         l_dev_status2          =    'NORMAL'   AND
         l_request_id2          <>   0
      THEN
      
         l_request_id3  :=    Fnd_Request.submit_request 
                                 (   'SWGCNV'
                                    ,'SWGCNV_POSTUPDATE_RECEIPT'
                                    ,'SWGCNV_POSTUPDATE_RECEIPT'
                                    ,NULL
                                    ,NULL
                                    ,p_sales_center
                                 );
         COMMIT;
      ELSE
         l_error_reqid := ' GOT ERROR '||l_request_id2;
         RAISE  ERROR_ENCOUNTERED;
      END IF; --

      Fnd_File.put_line(Fnd_File.LOG,l_request_id3);
      LOOP
      
         l_status_b3 :=    Fnd_Concurrent.wait_for_request
                              (   l_request_id3
                                 ,15
                                 ,15
                                 ,l_phase3
                                 ,l_status3
                                 ,l_dev_phase3
                                 ,l_dev_status3
                                 ,l_message3
                              );
                              
         EXIT WHEN l_dev_phase3 = 'COMPLETE';
      END LOOP;
      Fnd_File.put_line(Fnd_File.LOG,'Status of the first conc prog  : '||l_dev_phase3||' '||l_dev_status3);
      
      --4th
      IF l_dev_phase3           =    'COMPLETE' AND
         l_dev_status3          =    'NORMAL'   AND
         l_request_id3          <>   0
      THEN
      
         l_request_id4  :=    Fnd_Request.submit_request 
                                 (   'SWGCNV'
                                    ,'SWGCNV_STATEMENT_PROGRAM'
                                    ,'SWGCNV_STATEMENT_PROGRAM'
                                    ,NULL
                                    ,NULL
                                    ,p_legacy_system
                                    ,p_sales_center
                                 );
         COMMIT;
      ELSE
         l_error_reqid := ' GOT ERROR '||l_request_id3;
         RAISE  ERROR_ENCOUNTERED;
         
      END IF; --

      Fnd_File.put_line(Fnd_File.LOG,l_request_id4);
      LOOP
         l_status_b4 :=    Fnd_Concurrent.wait_for_request
                              (   l_request_id4
                                 ,15
                                 ,15
                                 ,l_phase4
                                 ,l_status4
                                 ,l_dev_phase4
                                 ,l_dev_status4
                                 ,l_message4
                              );
                              
         EXIT WHEN l_dev_phase4  = 'COMPLETE';
      END LOOP;
      
      Fnd_File.put_line(Fnd_File.LOG,'Status of the first conc prog  : '||l_dev_phase4||' '||l_dev_status4);
      --5th
      IF l_dev_phase4            =   'COMPLETE' AND
         l_dev_status4           =   'NORMAL'   AND
         l_request_id4           <>  0
      THEN
      
         l_request_id5  :=    Fnd_Request.submit_request 
                                 (   'SWGCNV'
                                    ,'SWGCNV_STAT_PERIOD_UPDATE'
                                    ,'SWGCNV_STAT_PERIOD_UPDATE'
                                    ,NULL
                                    ,NULL
                                    ,p_sales_center
                                 );
         COMMIT;
      ELSE
         l_error_reqid := ' GOT ERROR '||l_request_id4;
         RAISE  ERROR_ENCOUNTERED;
      END IF; --

      Fnd_File.put_line(Fnd_File.LOG,l_request_id5);
      LOOP
      
         l_status_b5 :=    Fnd_Concurrent.wait_for_request 
                              (   l_request_id5
                                 ,15
                                 ,15
                                 ,l_phase5
                                 ,l_status5
                                 ,l_dev_phase5
                                 ,l_dev_status5
                                 ,l_message5
                              );
                              
         EXIT WHEN l_dev_phase5 = 'COMPLETE';
         
      END LOOP;
      Fnd_File.put_line(Fnd_File.LOG,'Status of the first conc prog  : '||l_dev_phase5||' '||l_dev_status5);
      
      --6th
      IF l_dev_phase5           =    'COMPLETE' AND
         l_dev_status5          =    'NORMAL'   AND
         l_request_id5          <>   0
      THEN
      
         l_request_id6  :=    Fnd_Request.submit_request 
                                 (   'SWGCNV'
                                    ,'SWGCNV_LAST_MSI_BILLTO'
                                    ,'SWGCNV_LAST_MSI_BILLTO'
                                    ,NULL
                                    ,NULL
                                    ,p_legacy_system
                                    ,p_sales_center
                                 );
         COMMIT;

      ELSE
         l_error_reqid := ' GOT ERROR '||l_request_id5;
         RAISE  ERROR_ENCOUNTERED;
      END IF; --
      
      Fnd_File.put_line(Fnd_File.LOG,l_request_id6);
        
      LOOP
        
         l_status_b6 :=    Fnd_Concurrent.wait_for_request
                              (   l_request_id6
                                 ,15
                                 ,15
                                 ,l_phase6
                                 ,l_status6
                                 ,l_dev_phase6
                                 ,l_dev_status6
                                 ,l_message6
                              );
                              
         EXIT WHEN l_dev_phase6 = 'COMPLETE';
         
      END LOOP;
         
      Fnd_File.put_line(Fnd_File.LOG,'Status of the first conc prog  : '||l_dev_phase6||' '||l_dev_status6);
    
   EXCEPTION
      WHEN ERROR_ENCOUNTERED THEN
         Fnd_File.put_line(Fnd_File.LOG,'ERROR : '||l_error_reqid);
      WHEN NO_DATA_FOUND THEN
         Fnd_File.put_line(Fnd_File.LOG,'No Data found : '||SQLERRM);
         out_errnum_n := 2;
         out_errbuf_s := SQLERRM;
      WHEN OTHERS THEN
         Fnd_File.put_line(Fnd_File.LOG,'Others : '||SQLERRM);
         out_errnum_n := 2;
         out_errbuf_s := SQLERRM;
   END SWGCNV_SEQ_PROG;
   
   ------------------------------------------
   --Procedure To Add Tax Lines
   ------------------------------------------
   Procedure Swgcnv_Add_Tax_Lines 
      (   ou_errbuff_s       OUT    VARCHAR2
         ,ou_errcode_n       OUT    NUMBER
         ,in_sales_center_s  IN     VARCHAR2
         ,in_division_id_n   IN     VARCHAR2
         ,in_system_code_s   IN     VARCHAR2
      )
   IS                               
      CURSOR Cur_Ar
      IS
      SELECT *
      FROM   swgcnv_dd_ar_interface
      WHERE  cust_trx_type_name    <>   'PAYMENT'
      AND    ar_proc_flag          =    'N'
      --AND    sales_center          =    'NCH'  --take out...
      --AND    division              =    in_division_id_n
      ORDER  BY  trx_number, interface_line_attribute1;
                
      --MTS 20129 process tax when included as separate tax line instead of amount in attribute10
      CURSOR cur_tax_amt 
      IS 
      SELECT 
         trx_number,
         line_amount,
         line_count,
         sum(tax_amount) tax,
         CASE WHEN line_amount = 0 THEN  
              0
         ELSE
              sum(tax_amount)/line_amount
         END        tax_rate
      FROM  
         (         
         SELECT    trx_number,
                   attribute10 tax_amount,
                   --amount tax_amount,
         (SELECT MAX(int1.line_number)
           FROM  swgcnv_dd_ar_interface int1
           WHERE int1.trx_number   = int.trx_number
           AND   int1.line_type    = 'LINE'
           AND   SIGN(int1.amount) = (SELECT SIGN(SUM(int2.attribute10))
                                      FROM swgcnv_dd_ar_interface int2
                                      WHERE int2.trx_number = int1.trx_number
                                      AND   int2.line_type = 'TAX'))   line_count,
           --AND  sales_center    = IN_SALES_CENTER_S
           --AND  division        = IN_DIVISION_ID_N)
          (SELECT sum(amount)
           FROM swgcnv.swgcnv_dd_ar_interface int1
           WHERE int.trx_number = int1.trx_number
           AND int1.line_type   = 'LINE'
           AND   SIGN(INT1.AMOUNT) = (SELECT SIGN(SUM(int2.attribute10))
                                      FROM   swgcnv_dd_ar_interface int2
                                      WHERE  int2.trx_number = int1.trx_number
                                      AND    int2.line_type  = 'TAX'))  line_amount
           --AND  sales_center    = IN_SALES_CENTER_S
           --AND  division        = IN_DIVISION_ID_N) line_amount
           FROM swgcnv.swgcnv_dd_ar_interface int
           WHERE  line_type        = 'TAX'
           AND    ar_proc_flag     =    'N'
           --AND    sales_center    = IN_SALES_CENTER_S
           --AND    division        = IN_DIVISION_ID_N
           )
     GROUP BY trx_number, line_amount, line_count
     ORDER BY trx_number;    

     CURSOR cur_line_tax_amt (in_tax_rate_n NUMBER,in_trx_number_s VARCHAR2)
     IS
     SELECT
       trx_number,
       line_number,
       amount,
       ROUND(amount * in_tax_rate_n,2)  tax,
       attribute10
     FROM  swgcnv_dd_ar_interface
     WHERE trx_number   =   in_trx_number_s
     AND   ar_proc_flag =   'N'
     --AND   sales_center =   in_sales_center_s
     --AND   division     =   in_division_id_n
     AND   line_type    =   'LINE'
     ORDER BY   ABS(amount) desc;
  
      TYPE Tbl_Type_Ar_Rec  IS  TABLE OF  Cur_Ar%ROWTYPE
      INDEX BY BINARY_INTEGER;


      TYPE tbl_type_cur_tax_amt_rec IS TABLE OF cur_tax_amt%ROWTYPE
      INDEX BY BINARY_INTEGER;
  
      l_line_cnt_n         NUMBER   :=  0;
      l_rec_cnt_n          NUMBER   :=  0;
      l_tax_rate_n         NUMBER;
      l_dummy_trx_no_s     VARCHAR2(50)  :=   'XYZ';
  
      l_Tbl_Line_Rec       Tbl_Type_Ar_Rec;
      l_Tbl_Tax_Rec        Tbl_Type_Ar_Rec;
      l_Tbl_Empty_Rec      Tbl_Type_Ar_Rec;
      l_tbl_tax_amt_rec    tbl_type_cur_tax_amt_rec;
      l_tot_tax_amt_n      NUMBER;
      l_tax_amt_n          NUMBER;
      l_exit_flag_c        VARCHAR2(1);
  
   BEGIN

      ou_errbuff_s   :=   'SUCCESS';
      ou_errcode_n   :=   0;
  
      Fnd_Stats.GATHER_TABLE_STATS('SWGCNV', 'SWGCNV_DD_AR_INTERFACE',90);
    
      OPEN cur_tax_amt;       --MTS 20129
      FETCH cur_tax_amt BULK COLLECT INTO l_tbl_tax_amt_rec;
      CLOSE cur_tax_amt;

      FOR idx IN 1 .. l_tbl_tax_amt_rec.COUNT LOOP
          l_tot_tax_amt_n := 0;
          l_exit_flag_c := 'N';
          FOR cur_line_tax_amt_rec IN cur_line_tax_amt(l_tbl_tax_amt_rec(idx).tax_rate,l_tbl_tax_amt_rec(idx).trx_number) LOOP
              IF SIGN(cur_line_tax_amt_rec.amount) = SIGN(l_tbl_tax_amt_rec(idx).tax) THEN --MTS IBM01 for transactions with mixed signs apply tax only when sign of tax amount = sign of line amount

                 IF ABS(l_tot_tax_amt_n + cur_line_tax_amt_rec.tax) > ABS(l_tbl_tax_amt_rec(idx).tax) THEN
                    l_exit_flag_c := 'Y';
                    l_tax_amt_n := l_tbl_tax_amt_rec(idx).tax - l_tot_tax_amt_n;   
                 ELSE 
                    l_tot_tax_amt_n := l_tot_tax_amt_n + cur_line_tax_amt_rec.tax;
                    l_tax_amt_n :=  cur_line_tax_amt_rec.tax;
                 END IF;
                 
                
                 UPDATE swgcnv_dd_ar_interface
                 SET    attribute10 = l_tax_amt_n
                 WHERE
                        trx_number = cur_line_tax_amt_rec.trx_number
                 AND    line_number = cur_line_tax_amt_rec.line_number;
              END IF;
             IF l_exit_flag_c = 'Y' THEN
                EXIT;
             END IF;
          END LOOP;
          
          DELETE swgcnv_dd_ar_interface
          WHERE  trx_number = l_tbl_tax_amt_rec(idx).trx_number
          AND    line_type  = 'TAX'; 
            
      END LOOP;
--SGB
     IF l_tbl_tax_amt_rec.COUNT = 0 THEN
      Fnd_File.put_line(Fnd_File.OUTPUT,'INFO:  Processing AR Conversion with individual tax Lines');
      Fnd_File.put_line(Fnd_File.OUTPUT,'INFO:  No processing of tax when included as separate tax line instead of amount in attribute10');
    END IF;
  
      l_Tbl_Line_Rec   :=   l_Tbl_Empty_Rec;
      l_Tbl_Tax_Rec    :=   l_Tbl_Empty_Rec;

      OPEN  Cur_Ar;
  
      FETCH  Cur_Ar
      BULK   COLLECT
      INTO   l_Tbl_Line_Rec;
  
      CLOSE  Cur_Ar;
    
      Fnd_File.Put_Line(FND_FILE.LOG,'Processing Records: '||l_Tbl_Line_Rec.COUNT);
    
      BEGIN
    
         FOR  i IN 1..l_Tbl_Line_Rec.COUNT
         LOOP

            IF ( l_dummy_trx_no_s  <>   l_Tbl_Line_Rec(i).trx_number ) THEN
  
               SELECT max(line_number)       --WTRFLX3 fix
               INTO   l_line_cnt_n
               FROM   swgcnv_dd_ar_interface
               WHERE  trx_date                       =   l_Tbl_Line_Rec(i).trx_date
               AND    trx_number                     =   l_Tbl_Line_Rec(i).trx_number
               AND    orig_system_bill_customer_ref  =   l_Tbl_Line_Rec(i).orig_system_bill_customer_ref -- Added Pankaj
               AND    cust_trx_type_name             =   l_Tbl_Line_Rec(i).cust_trx_type_name            -- Added Pankaj
               ;--commented for WTRFLX3 AND    sales_center                   =   in_sales_center_s;
      
               l_dummy_trx_no_s   :=   l_Tbl_Line_Rec(i).trx_number;
               l_line_cnt_n       :=   l_line_cnt_n  +   1;
    
            ELSE  
    
               l_line_cnt_n       :=   l_line_cnt_n  +   1;
      
            END IF;
      
            -- Add Tax Line For Existing Line 
            BEGIN  
    
               IF ( NVL(l_Tbl_Line_Rec(i).Amount,0) <> 0 ) THEN
      
                  l_tax_rate_n   :=   ROUND( ( NVL(l_Tbl_Line_Rec(i).attribute10,0) * 100 ) / l_Tbl_Line_Rec(i).Amount,2);
        
               ELSE 
      
                  l_tax_rate_n   :=   0;  
        
               END IF;   
        
               l_Tbl_Tax_Rec(i).Cust_Trx_Type_Name             :=     l_Tbl_Line_Rec(i).Cust_Trx_Type_Name;
               l_Tbl_Tax_Rec(i).interface_line_context         :=     l_Tbl_Line_Rec(i).interface_line_context;
               l_Tbl_Tax_Rec(i).orig_system_bill_customer_ref  :=     l_Tbl_Line_Rec(i).orig_system_bill_customer_ref;
               l_Tbl_Tax_Rec(i).orig_system_bill_address_ref   :=     l_Tbl_Line_Rec(i).orig_system_bill_address_ref;
               l_Tbl_Tax_Rec(i).orig_system_ship_customer_ref  :=     l_Tbl_Line_Rec(i).orig_system_ship_customer_ref;
               l_Tbl_Tax_Rec(i).orig_system_ship_address_ref   :=     l_Tbl_Line_Rec(i).orig_system_ship_address_ref;
               l_Tbl_Tax_Rec(i).interface_line_attribute1      :=     l_Tbl_Line_Rec(i).interface_line_attribute1;
               l_Tbl_Tax_Rec(i).interface_line_attribute2      :=     l_line_cnt_n;
               l_Tbl_Tax_Rec(i).line_type                      :=     'TAX';
               l_Tbl_Tax_Rec(i).trx_date                       :=     l_Tbl_Line_Rec(i).trx_date;
               l_Tbl_Tax_Rec(i).gl_date                        :=     l_Tbl_Line_Rec(i).gl_date;
               l_Tbl_Tax_Rec(i).trx_number                     :=     l_Tbl_Line_Rec(i).trx_number;
               l_Tbl_Tax_Rec(i).line_number                    :=     l_line_cnt_n;
               l_Tbl_Tax_Rec(i).description                    :=     'TAX LINE';
               l_Tbl_Tax_Rec(i).amount                         :=     l_Tbl_Line_Rec(i).attribute10;
               l_Tbl_Tax_Rec(i).currency_code                  :=     'USD';
               l_Tbl_Tax_Rec(i).term_name                      :=      NULL;
               l_Tbl_Tax_Rec(i).item_code                      :=      NULL;
               l_Tbl_Tax_Rec(i).quantity                       :=      l_Tbl_Line_Rec(i).quantity;
               l_Tbl_Tax_Rec(i).uom_code                       :=      NULL;
               l_Tbl_Tax_Rec(i).quantity_ordered               :=      NULL;
               l_Tbl_Tax_Rec(i).unit_selling_price             :=      NULL;
               l_Tbl_Tax_Rec(i).unit_standard_price            :=      NULL;
               l_Tbl_Tax_Rec(i).reason_code                    :=      NULL;
               l_Tbl_Tax_Rec(i).tax_rate                       :=      l_tax_rate_n;
               l_Tbl_Tax_Rec(i).tax_code                       :=      l_Tbl_Line_Rec(i).tax_code;
               l_Tbl_Tax_Rec(i).primary_salesrep_number        :=      NULL;
               l_Tbl_Tax_Rec(i).comments                       :=      NULL;
               l_Tbl_Tax_Rec(i).attribute10                    :=      l_Tbl_Line_Rec(i).Amount;
               l_Tbl_Tax_Rec(i).tax_exempt_flag                :=      NULL;
               l_Tbl_Tax_Rec(i).tax_exempt_reason_code         :=      NULL;
               l_Tbl_Tax_Rec(i).tax_exempt_number              :=      NULL;
               l_Tbl_Tax_Rec(i).sales_order                    :=      NULL;
               l_Tbl_Tax_Rec(i).sales_order_line               :=      NULL;
               l_Tbl_Tax_Rec(i).sales_order_date               :=      NULL;
               l_Tbl_Tax_Rec(i).sales_order_source             :=      NULL;
               l_Tbl_Tax_Rec(i).sales_order_revision           :=      NULL;
               l_Tbl_Tax_Rec(i).purchase_order                 :=      NULL;
               l_Tbl_Tax_Rec(i).purchase_order_revision        :=      NULL;
               l_Tbl_Tax_Rec(i).purchase_order_date            :=      NULL;
               l_Tbl_Tax_Rec(i).reference_line_context         :=      'DD CONVERSION';
               l_Tbl_Tax_Rec(i).reference_line_attribute1      :=      l_Tbl_Line_Rec(i).interface_line_attribute1;
               l_Tbl_Tax_Rec(i).reference_line_attribute2      :=      l_Tbl_Line_Rec(i).interface_line_attribute2;
               l_Tbl_Tax_Rec(i).sales_center                   :=      l_Tbl_Line_Rec(i).sales_center;
               l_Tbl_Tax_Rec(i).division                       :=      l_Tbl_Line_Rec(i).division;
               l_Tbl_Tax_Rec(i).attribute1                     :=      l_Tbl_Line_Rec(i).attribute1;
               l_Tbl_Tax_Rec(i).attribute2                     :=      l_Tbl_Line_Rec(i).attribute2;
               l_Tbl_Tax_Rec(i).tax_status                     :=      l_Tbl_Line_Rec(i).tax_status;
               l_Tbl_Tax_Rec(i).item_sub_code                  :=      NULL;
               l_Tbl_Tax_Rec(i).due_date                       :=      l_Tbl_Line_Rec(i).due_date;
               l_Tbl_Tax_Rec(i).ar_proc_flag                   :=      'N';
               l_Tbl_Tax_Rec(i).sub_cust_num                   :=      l_Tbl_Line_Rec(i).sub_cust_num;
        
            EXCEPTION
               WHEN OTHERS THEN
                  Fnd_File.Put_Line(FND_FILE.LOG,'Error Preparing Tax Table: '||SQLERRM(SQLCODE));
                  ROLLBACK;

                  ou_errbuff_s    :=  'WARNING';
                  ou_errcode_n    :=   1;
          
                  EXIT;

            END;             
        
        
         END LOOP;
      
         Fnd_File.Put_Line(FND_FILE.LOG,'Inserting Records: '||l_Tbl_Tax_Rec.COUNT);
    
         FORALL i IN  l_Tbl_Tax_Rec.FIRST..l_Tbl_Tax_Rec.LAST
         INSERT INTO SWGCNV_DD_AR_INTERFACE VALUES l_Tbl_Tax_Rec(i);        
         
         COMMIT;            
         
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
        
            ou_errbuff_s   :=   'WARNING';
            ou_errcode_n   :=   1;
        
            Fnd_File.Put_Line(FND_FILE.LOG,'Error Inserting Tax Line For Trx Number: '||l_dummy_trx_no_s);
            Fnd_File.Put_Line(FND_FILE.LOG,'Error: '||SQLERRM(SQLCODE));
      END;
      
      Fnd_File.Put_Line(FND_FILE.LOG,'Completed');
      
   EXCEPTION
      WHEN OTHERS THEN
         ou_errbuff_s   :=   'ERROR';
         ou_errcode_n   :=   2;
  
         Fnd_File.Put_Line(FND_FILE.LOG,'Error: '||SQLERRM(SQLCODE));
         ROLLBACK;  
   END Swgcnv_Add_Tax_Lines;       

   ----------------------------------------------------
   -- Procedure To Update Customer / Address References
   -- Moved Standalone Procedure SWGCNV_UPD_AR_STAGING_P 
   -- To Package
   ----------------------------------------------------
   PROCEDURE   SWGCNV_UPD_CUST_REF
      (   ou_errbuf_s         OUT     VARCHAR2
         ,ou_errcode_n        OUT     NUMBER
         ,in_sales_center_s   IN      VARCHAR2
         ,in_system_name_s    IN      VARCHAR2
         ,in_division_s       IN      VARCHAR2
         ,in_mode_c           IN      VARCHAR2
         ,in_debug_flag_c     IN      VARCHAR2    DEFAULT     'N'
      )
   IS

      CURSOR   cur_AR_data -- ( in_division_s VARCHAR2  Commented by VSP as per EB-1596
                           -- ,in_sales_ctr_s VARCHAR2  Commented by VSP as per EB-1596
                           -- )                         Commented by VSP as per EB-1596
      IS
      SELECT ROWID
            ,CUST_TRX_TYPE_NAME
            ,INTERFACE_LINE_CONTEXT
            ,ORIG_SYSTEM_BILL_CUSTOMER_REF
            ,ORIG_SYSTEM_BILL_ADDRESS_REF
            ,ORIG_SYSTEM_SHIP_CUSTOMER_REF
            ,ORIG_SYSTEM_SHIP_ADDRESS_REF
            ,TRX_NUMBER
            ,LINE_NUMBER
            ,DESCRIPTION
            ,AMOUNT
            ,sub_cust_num
      FROM   swgcnv_dd_ar_interface
      -- WHERE  division      =  in_division_s   Commented by VSP as per EB-1596
      -- AND    sales_center  =  in_sales_ctr_s  Commented by VSP as per EB-1596
      ORDER BY ORIG_SYSTEM_BILL_CUSTOMER_REF;

      CURSOR cur_bill_loc ( in_cust_num_s VARCHAR2
                           ,in_bill_addr_s VARCHAR2
                          )
      IS
      /*
      SELECT nvl(sdcb.billing_location_number,'X')
      FROM   SWGCNV_DD_CUSTOMER_BILLTO       sdcb
            ,swgcnv_dd_addresses             sda
      WHERE  sda.customer_number     =       in_cust_num_s
      AND    sda.address_id          =       sdcb.bill_to_address_id
      AND    sda.customer_id         =       sdcb.customer_id
      AND    sda.customer_number     =       sdcb.customer_number
      --AND   in_bill_addr_s     LIKE (sda.address1||'%'||nvl(sda.ADDRESS2,' ')
      --                                 ||'%'||nvl(sda.ADDRESS3,' ')||'%'||nvl(sda.ADDRESS4,' ')
      --                                 ||'%'||sda.CITY||'%'||sda.STATE||'%'||sda.PROVINCE||'%'||sda.COUNTY
      --                                 ||'%'||sda.POSTAL_CODE||'%'||sda.COUNTRY||'%'
      --                                )
      AND   (
            (in_bill_addr_s   IS NOT NULL
      AND   in_bill_addr_s    LIKE (sda.address1||'%'||nvl(sda.ADDRESS2,' ')
                                    ||'%'||nvl(sda.ADDRESS3,' ')||'%'||nvl(sda.ADDRESS4,' ')
                                    ||'%'||sda.CITY||'%'||sda.STATE||'%'||sda.POSTAL_CODE||'%'
                                   )
         )
         OR in_bill_addr_s   IS NULL
       )
      AND   rownum=1 -- Only SINGLE BILL-TOs for ARS01 conversion; 
      */
      SELECT   nvl( decode(instr(hzcas.orig_system_reference,'HEADER'),
               0,substr(hzcas.orig_system_reference,instr(hzcas.orig_system_reference,'-',1,4)+1) ,    
               substr(hzcas.orig_system_reference,instr(hzcas.orig_system_reference,'-',1,4)+1,
                   instr(hzcas.orig_system_reference,'-',1,5)-1-instr(hzcas.orig_system_reference,'-',1,4)
                  ) 
               ),'X')     bill_location  --DD-ARS01-SAC-125546-6844-HEADER
               ,substr(hzcas.orig_system_reference,instr(hzcas.orig_system_reference,'-',1,2)+1,
                    instr(hzcas.orig_system_reference,'-',1,3)-1-instr(hzcas.orig_system_reference,'-',1,2)
                   )  sales_center,
               hzcsu.attribute9 division_id

      FROM     hz_cust_site_uses          hzcsu
               ,hz_cust_acct_sites         hzcas
      WHERE    hzcas.cust_acct_site_id       =  hzcsu.cust_acct_site_id
      AND      hzcsu.site_use_code           =  'BILL_TO'
      AND      hzcas.cust_account_id         =  ( SELECT oracle_customer_id 
                                                  FROM   swgcnv_dd_temp_customers
                                                  WHERE  legacy_customer_number  =  in_cust_num_s
                                                )
      AND      ROWNUM                        =   1;

      CURSOR cur_ship_loc ( in_cust_num_s VARCHAR2
                           ,in_ship_addr_s VARCHAR2
                          )
      IS
      /*
      SELECT nvl(sdcs.delivery_location_number,'X')
      FROM   SWGCNV_DD_CUSTOMER_SHIPTO       sdcs    
            ,swgcnv_dd_addresses             sda
      WHERE  sda.customer_number     =   in_cust_num_s
      AND    sda.address_id          =   sdcs.ship_to_address_id
      AND    sda.customer_id         =   sdcs.customer_id
      AND    sda.customer_number     =   sdcs.customer_number
      --AND   in_ship_addr_s     like (sda.address1||'%'||nvl(sda.ADDRESS2,' ')
      --                                 ||'%'||nvl(sda.ADDRESS3,' ')||'%'||nvl(sda.ADDRESS4,' ')
      --                                 ||'%'||sda.CITY||'%'||sda.STATE||'%'||sda.PROVINCE||'%'||sda.COUNTY
      --                                 ||'%'||sda.POSTAL_CODE||'%'||sda.COUNTRY||'%'
      --                                )
      AND     in_ship_addr_s     like (sda.address1||'%'
                                --||nvl(sda.ADDRESS2,' ')
                                --||'%'||nvl(sda.ADDRESS3,' ')||'%'||nvl(sda.ADDRESS4,' ')
                                ||'%'||sda.CITY||'%'||sda.STATE||'%'||sda.POSTAL_CODE||'%'
                               );  
      */
      SELECT    nvl( decode(instr(hzcas.orig_system_reference,'HEADER'),
               0,substr(hzcas.orig_system_reference,instr(hzcas.orig_system_reference,'-',1,4)+1) ,    
               substr(hzcas.orig_system_reference,instr(hzcas.orig_system_reference,'-',1,4)+1,
                    instr(hzcas.orig_system_reference,'-',1,5)-1-instr(hzcas.orig_system_reference,'-',1,4)
                   ) 
               ),'X')       --DD-ARS01-SAC-125546-6844-HEADER
      FROM   hz_cust_site_uses       hzcsu
            ,hz_cust_acct_sites      hzcas
            ,hz_party_sites          hps
            ,hz_locations hl
      WHERE  hzcas.cust_acct_site_id   =   hzcsu.cust_acct_site_id
      AND    hzcsu.site_use_code       =   'SHIP_TO'
      AND    hzcas.cust_account_id     =   ( SELECT oracle_customer_id 
                                             FROM   swgcnv_dd_temp_customers
                                             WHERE  legacy_customer_number  =  in_cust_num_s
                                           )
      AND    hzcas.party_site_id       =   hps.party_site_id
      AND    hps.location_id           =   hl.location_id
      AND    in_ship_addr_s            LIKE (hl.address1||'%'
                                       --||nvl(sda.ADDRESS2,' ')
                                       --||'%'||nvl(sda.ADDRESS3,' ')||'%'||nvl(sda.ADDRESS4,' ')
                                       ||'%'||hl.CITY||'%'||hl.STATE||'%'||hl.POSTAL_CODE||'%');
                                
      CURSOR   cur_ship_loc2 ( in_cust_num_s VARCHAR2
                              ,in_ship_addr_s VARCHAR2
                             )
      IS
      SELECT   nvl( decode(instr(hzcas.orig_system_reference,'HEADER'),
               0,substr(hzcas.orig_system_reference,instr(hzcas.orig_system_reference,'-',1,4)+1) ,    
               substr(hzcas.orig_system_reference,instr(hzcas.orig_system_reference,'-',1,4)+1,
                     instr(hzcas.orig_system_reference,'-',1,5)-1-instr(hzcas.orig_system_reference,'-',1,4)
                  ) 
               ),'X')       --DD-ARS01-SAC-125546-6844-HEADER
      FROM   hz_cust_site_uses             hzcsu
            ,hz_cust_acct_sites            hzcas
      WHERE hzcas.cust_acct_site_id =    hzcsu.cust_acct_site_id
      AND   hzcsu.site_use_code     =   'SHIP_TO'
      AND   hzcas.cust_account_id   =  (  SELECT oracle_customer_id 
                                          FROM   swgcnv_dd_temp_customers
                                          WHERE  legacy_customer_number    =  in_cust_num_s
                                       )
      AND   ROWNUM                    =   1;

      l_system_name_s         VARCHAR2(20);
      l_sales_center_s        VARCHAR2(3);
      l_division_s            VARCHAR2(20);
      l_debug_c               VARCHAR2(1);
      l_mode_c                VARCHAR2(1);
      l_bill_loc_s            VARCHAR2(20);
      l_ship_loc_s            VARCHAR2(20);
      l_legacy_ship_addr_s    VARCHAR2(2000);
      l_error_msg_s           VARCHAR2(2000);
      l_msg_s                 VARCHAR2(2000);
      l_bill_sales_center_s   VARCHAR2(3);
      l_bill_division_id_s    VARCHAR2(10);

      l_rec_cnt_n             NUMBER    :=  0;
      l_rec_cnt_s_n           NUMBER    :=  0;
      l_rec_cnt_e_n           NUMBER    :=  0;

      error_encountered EXCEPTION;

      CURSOR   cur_btm_cust -- (   in_division_s    VARCHAR2   Commented by VSP as per EB-1596
                            --  ,in_sales_ctr_s   VARCHAR2     Commented by VSP as per EB-1596
                            -- )                               Commented by VSP as per EB-1596
      IS
      SELECT  orig_system_bill_customer_ref cust_num
      FROM    swgcnv_dd_ar_interface
      -- WHERE sales_center    =  in_sales_ctr_s             Commented by VSP as per EB-1596 
      -- AND   division        =  in_division_s              Commented by VSP as per EB-1596
      MINUS
      SELECT  orig_system_bill_customer_ref cust_num
      FROM    swgcnv_dd_ar_interface
      WHERE   orig_system_bill_customer_ref  IN ( SELECT legacy_customer_number FROM swgcnv_dd_temp_customers );
      -- AND     sales_center        =     in_sales_ctr_s    Commented by VSP as per EB-1596
      -- AND     division            =     in_division_s;    Commented by VSP as per EB-1596

      l_btm_s VARCHAR2(90);

   BEGIN
  
      MO_GLOBAL.SET_POLICY_CONTEXT('S',2);

      ou_errbuf_s     :=   NULL;
      ou_errcode_n    :=   0;
  
      l_error_msg_s   :=   NULL;
      l_msg_s         :=   NULL;

      l_system_name_s     :=    in_system_name_s;
      l_sales_center_s    :=    in_sales_center_s;
      l_division_s        :=    in_division_s;
      l_debug_c           :=    in_debug_flag_c;
      l_mode_c            :=    in_mode_c;
  
      -- Commented For ARS03 Conversion
      /* 

      UPDATE  swgcnv_dd_ar_interface
      SET     gl_date      =   NULL
             ,tax_status   =   'B'
      WHERE   division     =   l_division_s
      AND     sales_center =   l_sales_center_s;

      UPDATE  swgcnv_dd_ar_interface
      SET     CUST_TRX_TYPE_NAME      =       'CREDIT MEMO'
      WHERE  division                 =        l_division_s
      AND    sales_center             =        l_sales_center_s
      AND    amount                   <        0
      AND    CUST_TRX_TYPE_NAME       =       'INVOICE';

      -- For Receipts (CUST_TRX_TYPE_NAME='PAYMENT'), the amounts should be < 0

      UPDATE swgcnv_dd_ar_interface
      --SET    amount = (-1)*amount
      SET    CUST_TRX_TYPE_NAME       =      'INVOICE'
            ,description              =       nvl(description,'- ')||' :Payment Reversal'
      WHERE  division                 =       l_division_s
      AND    sales_center             =       l_sales_center_s
      AND    amount                   >       0
      AND    CUST_TRX_TYPE_NAME       =       'PAYMENT';

      UPDATE swgcnv_dd_ar_interface
      SET    gl_date                  =       to_date('28-JUL-2007') --to_date('01-MAR-2007') -- change to 07/23/07 for go-live, CONV2_I3 - 07/09/07
      WHERE  division                 =       l_division_s
      AND    sales_center             =       l_sales_center_s
      AND    CUST_TRX_TYPE_NAME       =       'PAYMENT';

      UPDATE swgcnv_dd_ar_interface
      SET    description              =       CUST_TRX_TYPE_NAME
      WHERE  division                 =       l_division_s
      AND    sales_center             =       l_sales_center_s
      AND    description              IS      NULL;

      COMMIT;

      l_msg_s  :=    'Updated gl_date,tax_status,cust_trx_type_name in AR interface table: swgcnv_dd_ar_interface ';

      DBMS_OUTPUT.PUT_LINE(l_msg_s);
      Fnd_File.Put_Line(Fnd_File.LOG, l_msg_s);
      
      */
      -- Commented For ARS03 Conversion

      FOR cur_btm_cust_rec IN cur_btm_cust -- (   l_division_s    Commented by VSP as per EB-1596
                                           --  ,l_sales_center_s  Commented by VSP as per EB-1596
                                           -- )                   Commented by VSP as per EB-1596
      LOOP
    
         BEGIN
         
            l_btm_s := NULL;
        
            BEGIN
         
               SELECT distinct bill_to_master
               INTO   l_btm_s
               FROM   swgcnv_dd_cb_prestaging_cust
               WHERE  customer_number    =   cur_btm_cust_rec.cust_num;

            EXCEPTION 
               WHEN OTHERS THEN
                  l_btm_s := NULL;
                  l_msg_s := 'Unexpected error during select of bill to master for Customer number: '||cur_btm_cust_rec.cust_num||': '||SQLERRM;
                  DBMS_OUTPUT.PUT_LINE(l_msg_s);
                  Fnd_File.Put_Line(Fnd_File.LOG, l_msg_s);
            
                  UPDATE  swgcnv_dd_ar_interface
                  SET     ar_proc_flag  =   'E'
                  WHERE   orig_system_bill_customer_ref   =   cur_btm_cust_rec.cust_num;
                  -- AND     division                        =   l_division_s       Commented by VSP as per EB-1596
                  -- AND     sales_center                    =   l_sales_center_s;  Commented by VSP as per EB-1596
            
                  COMMIT;

            END;
        
            IF l_btm_s IS NOT NULL THEN
        
               UPDATE swgcnv_dd_ar_interface
               SET    ORIG_SYSTEM_BILL_CUSTOMER_REF   =   l_btm_s
                     ,ORIG_SYSTEM_SHIP_CUSTOMER_REF   =   l_btm_s
               WHERE   -- division                        =   l_division_s          Commented by VSP as per EB-1596
               -- AND     sales_center                    =   l_sales_center_s      Commented by VSP as per EB-1596
                    ORIG_SYSTEM_BILL_CUSTOMER_REF   =   cur_btm_cust_rec.cust_num;

               COMMIT;

            END IF;
        
         EXCEPTION 
            WHEN OTHERS THEN
               l_msg_s := 'Unexpected error during update of customer number to bill to master for Customer number: '||cur_btm_cust_rec.cust_num||': '||SQLERRM;
               DBMS_OUTPUT.PUT_LINE(l_msg_s);
               Fnd_File.Put_Line(Fnd_File.LOG, l_msg_s);
          
               UPDATE  swgcnv_dd_ar_interface
               SET     ar_proc_flag  =   'E'
               WHERE   orig_system_bill_customer_ref   =   cur_btm_cust_rec.cust_num;
               -- AND     division                        =   l_division_s          Commented by VSP as per EB-1596
               -- AND     sales_center                    =   l_sales_center_s;     Commented by VSP as per EB-1596
            
               COMMIT;
          
         END;
      
      END LOOP;

      COMMIT;

      l_msg_s := 'Updated customer number to bill to master in AR interface table: swgcnv_dd_ar_interface ';

      DBMS_OUTPUT.PUT_LINE(l_msg_s);
      Fnd_File.Put_Line(Fnd_File.LOG, l_msg_s);

      FOR cur_AR_data_rec IN cur_AR_data -- (  l_division_s
                                         -- ,l_sales_center_s
                                         -- )
      LOOP
    
         BEGIN
      
            --SAVEPOINT at_first;

            l_rec_cnt_n     :=      l_rec_cnt_n + 1;

            l_bill_loc_s    :=      NULL;
            l_ship_loc_s    :=      NULL;
  
            OPEN cur_bill_loc (   cur_AR_data_rec.ORIG_SYSTEM_BILL_CUSTOMER_REF
                                 ,to_char(NULL)
                              );
                          
            FETCH  cur_bill_loc 
            INTO   l_bill_loc_s
                  ,l_bill_sales_center_s
                  ,l_bill_division_id_s;
        
            CLOSE cur_bill_loc;

            /*     
            
            OPEN cur_ship_loc (   cur_AR_data_rec.ORIG_SYSTEM_BILL_CUSTOMER_REF
                                 ,cur_AR_data_rec.ORIG_SYSTEM_SHIP_ADDRESS_REF
                              );
                          
            FETCH cur_ship_loc 
            INTO  l_ship_loc_s;
        
            CLOSE cur_ship_loc;

            IF l_ship_loc_s is NULL THEN
        
               OPEN cur_ship_loc2(  cur_AR_data_rec.ORIG_SYSTEM_BILL_CUSTOMER_REF
                                   ,cur_AR_data_rec.ORIG_SYSTEM_SHIP_ADDRESS_REF
                                 );
                                
               FETCH cur_ship_loc2 
               INTO  l_ship_loc_s;
            
               CLOSE cur_ship_loc2;

            END IF;
            
            */

            --l_ship_loc_s  := swgcnv_cnv_util_pkg.swgcnv_get_del_loc(l_system_name_s,cur_AR_data_rec.ORIG_SYSTEM_BILL_CUSTOMER_REF);

            l_ship_loc_s    :=  swgcnv_cnv_util_pkg.swgcnv_get_del_loc(l_system_name_s,cur_AR_data_rec.sub_cust_num);

            IF (l_bill_loc_s = 'X' OR l_ship_loc_s = 'X' OR l_bill_loc_s IS NULL OR l_ship_loc_s IS NULL) THEN

               l_msg_s  := 'Either bill/ship to loc. is NULL for legacy Customer Number/Trx_Number/Bill Loc./Ship Loc.: '
                           ||cur_AR_data_rec.ORIG_SYSTEM_BILL_CUSTOMER_REF||'/'||cur_AR_data_rec.TRX_NUMBER
                           ||'/'||l_bill_loc_s||'/'||l_ship_loc_s;

               IF NVL(l_debug_c,'N')   =   'Y'     THEN

                  DBMS_OUTPUT.PUT_LINE(l_msg_s);
                  Fnd_File.Put_Line(Fnd_File.LOG, l_msg_s);

               END IF;

               RAISE error_encountered;

            END IF;

            UPDATE swgcnv_dd_ar_interface
            SET    ORIG_SYSTEM_BILL_ADDRESS_REF    =       l_bill_loc_s
                  ,ORIG_SYSTEM_SHIP_ADDRESS_REF    =       l_ship_loc_s
                  ,ar_proc_flag                    =       'N'
           --MTS 20129       ,sales_center                    =       l_bill_sales_center_s
            WHERE  rowid                           =       cur_AR_data_rec.rowid; 

            COMMIT;

            l_rec_cnt_s_n  :=    l_rec_cnt_s_n + 1;
        
            l_msg_s  := 'Updated location (bill/ship) info for legacy Customer Number/Trx_Number/Bill Loc./Ship Loc.: '
                        ||cur_AR_data_rec.ORIG_SYSTEM_BILL_CUSTOMER_REF||'/'||cur_AR_data_rec.TRX_NUMBER
                        ||'/'||l_bill_loc_s||'/'||l_ship_loc_s;
           
            IF NVL(l_debug_c,'N')   =   'Y'  THEN

               DBMS_OUTPUT.PUT_LINE(l_msg_s);
               Fnd_File.Put_Line(Fnd_File.LOG, l_msg_s);

            END IF;
    
         EXCEPTION 
            WHEN error_encountered THEN

               l_msg_s  :=  'Either bill/ship to loc. is NULL for legacy Customer Number/Trx_Number/Bill Loc./Ship Loc.: '
                           ||cur_AR_data_rec.ORIG_SYSTEM_BILL_CUSTOMER_REF||'/'||cur_AR_data_rec.TRX_NUMBER
                           ||'/'||l_bill_loc_s||'/'||l_ship_loc_s;

               --IF NVL(l_debug_c,'N')     =   'Y'     THEN

               DBMS_OUTPUT.PUT_LINE(l_msg_s);
               Fnd_File.Put_Line(Fnd_File.LOG, l_msg_s);

               --END IF;

               l_rec_cnt_e_n := l_rec_cnt_e_n + 1;
            
               UPDATE  swgcnv_dd_ar_interface
               SET     ar_proc_flag   =   'E'
               WHERE   rowid          =    cur_AR_data_rec.rowid;
            
               COMMIT;

            WHEN OTHERS THEN
       
               --ROLLBACK TO SAVEPOINT at_first;

               l_error_msg_s  := 'Error during update of bill/ship to loc. for legacy Customer Number/Trx_Number/Bill Loc./Ship Loc.: '
                                 ||cur_AR_data_rec.ORIG_SYSTEM_BILL_CUSTOMER_REF||'/'||cur_AR_data_rec.TRX_NUMBER
                                 ||'/'||l_bill_loc_s||'/'||l_ship_loc_s||': '||SQLERRM;

               --IF NVL(l_debug_c,'N')   =    'Y'    THEN

               DBMS_OUTPUT.PUT_LINE(l_error_msg_s);
               Fnd_File.Put_Line(Fnd_File.LOG, l_error_msg_s);

               --END IF;

               l_rec_cnt_e_n := l_rec_cnt_e_n + 1;

               ou_errbuf_s   :=   l_error_msg_s ;
               ou_errcode_n  :=   1;
          
               UPDATE  swgcnv_dd_ar_interface
               SET     ar_proc_flag   =   'E'
               WHERE   rowid          =    cur_AR_data_rec.rowid;
          
               COMMIT;
          

         END;

      END LOOP;
  
      l_msg_s   :=  'No of AR records processed for update of bill/ship to loc. : '||to_char(l_rec_cnt_n);
      
      DBMS_OUTPUT.PUT_LINE(l_msg_s);
      Fnd_File.Put_Line(Fnd_File.LOG, l_msg_s);

      l_msg_s   :=  'No of AR records successfully updated for bill/ship to loc. : '||to_char(l_rec_cnt_s_n);
      
      DBMS_OUTPUT.PUT_LINE(l_msg_s);
      Fnd_File.Put_Line(Fnd_File.LOG, l_msg_s);

      l_msg_s   :=  'No of AR records failed update of bill/ship to loc. : '||to_char(l_rec_cnt_e_n);
     
      DBMS_OUTPUT.PUT_LINE(l_msg_s);
      Fnd_File.Put_Line(Fnd_File.LOG, l_msg_s);

   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK;
         l_error_msg_s    :=      'Unexpected Error during update of bill/ship to loc. for AR records: '||SQLERRM;

         --IF NVL(l_debug_c,'N')  =   'Y'     THEN
         DBMS_OUTPUT.PUT_LINE(l_error_msg_s);
         Fnd_File.Put_Line(Fnd_File.LOG, l_error_msg_s);

         --END IF;

         ou_errbuf_s    :=    l_error_msg_s ;
         ou_errcode_n   :=    2;

         RETURN;

   END   SWGCNV_UPD_CUST_REF;
   
   PROCEDURE   Unapply_Receipt
      (   ou_errbuff_s        OUT   VARCHAR2
         ,ou_errcode_n        OUT   NUMBER
         ,in_system_code_s    IN    VARCHAR2
         ,in_sales_center_s   IN    VARCHAR2
         ,in_validate_only_c  IN    VARCHAR2  
      )
   IS
   
      CURSOR   Cur_Receipts 
         (   l_customer_id_n      NUMBER
            ,l_billto_site_id_n   NUMBER
         )
      IS   
      SELECT   hca.account_number
              ,acra.customer_site_use_id   Receipt_Billto
              ,acra.receipt_number
              ,acra.receipt_date
              ,acra.amount                 Receipt_Amount
              ,aps.customer_site_use_id    Applied_BillTo
              ,ract.trx_number 
              ,araa.amount_applied
              ,araa.amount_applied_from
              ,acra.cash_receipt_id
              ,araa.applied_payment_schedule_id
              ,araa.attribute14
      FROM     hz_cust_Accounts                 hca
              ,ra_customer_trx                  ract
              ,ar_payment_schedules             aps
              ,ar_receivable_applications       araa
              ,ar_cash_receipts                 acra
      WHERE    hca.cust_account_id           =     acra.pay_from_customer
      AND      ract.customer_trx_id          =     aps.customer_trx_id
      AND      aps.customer_site_use_id      =     acra.customer_site_use_id
      AND      aps.payment_schedule_id       =     araa.applied_payment_schedule_id
      AND      araa.application_type         =    'CASH'
      AND      araa.display                  =    'Y'
      AND      araa.status                   =    'APP'
      AND      araa.cash_receipt_id          =     acra.cash_receipt_id
      AND      acra.customer_site_use_id     =     l_billto_site_id_n
      AND      acra.pay_from_customer        =     l_customer_id_n;
      
      CURSOR   Cur_Customer
      IS
      SELECT sdcb.customer_number
            ,sdcb.bill_to_address_id
            ,sdtc.oracle_customer_id
            ,sdtc.oracle_customer_number
      FROM   swgcnv_dd_customer_billto     sdcb
            ,swgcnv_dd_temp_customers      sdtc
      WHERE  sdcb.customer_number        =        sdtc.legacy_customer_number
      AND    sdtc.receipt_proc_flag      =        'U'
      AND    sdtc.cust_import_flag       =        'Y'
      AND    sdtc.new_sales_center       =         in_sales_center_s
      AND    sdtc.system_code            =         in_system_code_s;
      
      CURSOR Cur_GetIds
         (   l_cust_acct_id_n    VARCHAR2
            ,l_addr_sys_ref_s    VARCHAR2
         )
      IS
      SELECT hcsu.site_use_id
      FROM   hz_cust_accounts          hca
            ,hz_cust_acct_sites_all    hcas
            ,hz_cust_site_uses_all     hcsu
      WHERE  1 =  1
      AND    hcsu.site_use_code          =   'BILL_TO' 
      AND    hcsu.orig_system_reference  =   l_addr_sys_ref_s
      AND    hcsu.cust_acct_site_id      =   hcas.cust_acct_site_id
      AND    hcas.cust_account_id        =   hca.cust_account_id
      AND    hca.cust_account_id         =   l_cust_acct_id_n;
      
      TYPE     Tbl_Type_Receipts  IS  TABLE  OF  Cur_Receipts%ROWTYPE
      INDEX    BY  BINARY_INTEGER;
      
      L_Receipt_Tbl         Tbl_Type_Receipts;
      
      l_return_status_c     VARCHAR2(1);
      l_err_flag_c          VARCHAR2(1);      
      l_msg_data_s          VARCHAR2(240);
      l_cust_sys_ref_s      VARCHAR2(240);
      l_addr_sys_ref_s      VARCHAR2(240); 

      l_billto_id_n         NUMBER;
      l_msg_count_n         NUMBER;
      l_tot_rec_read_n      NUMBER     :=    0;
      l_err_count_n         NUMBER     :=    0;
      l_proc_count_n        NUMBER     :=    0;
      
      l_start_time_d        DATE;

   BEGIN

      ou_errbuff_s   :=    'SUCCESS';
      ou_errcode_n   :=     0;
      
      l_start_time_d    :=    SYSDATE;
      
      Fnd_File.Put_Line(FND_FILE.OUTPUT,'Account Number|Receipt BillTo|Receipt Number|Receipt Date|Receipt Amount|Applied BillTo|Applied Trx No|Amount Applied|');                
      
      FOR Cust_Rec IN Cur_Customer
      LOOP
      
         l_err_flag_c      :=   'N';
         
         l_tot_rec_read_n  :=    l_tot_rec_read_n  +  1;

         Fnd_File.Put_Line(FND_FILE.LOG,'Processing Legacy Customer: '||Cust_Rec.Customer_Number);
         Fnd_File.Put_Line(FND_FILE.LOG,'Processing Legacy Bill To : '||Cust_Rec.bill_to_address_id);
         Fnd_File.Put_Line(FND_FILE.LOG,'Processing Oracle Customer: '||Cust_Rec.Oracle_Customer_Number);
         
         l_cust_sys_ref_s     :=    'DD-' || in_system_code_s || '-' || in_sales_center_s || '-' || Cust_Rec.Customer_Number;
         l_addr_sys_ref_s     :=    'DD-' || in_system_code_s || '-' || in_sales_center_s || '-' || Cust_Rec.Customer_Number
                                          || '-' || Cust_Rec.bill_to_address_id || '-' || 'HEADER';
                                      
                                      
         Fnd_File.Put_Line(FND_FILE.LOG,'Customer Orig Sys Ref: '||l_cust_sys_ref_s);
         Fnd_File.Put_Line(FND_FILE.LOG,'Customer Addr Sys Ref: '||l_addr_sys_ref_s);
         
         OPEN Cur_GetIds( Cust_Rec.Oracle_Customer_Id
                         ,l_addr_sys_ref_s
                        );

         FETCH Cur_GetIds
         INTO  l_billto_id_n;
              
         IF ( Cur_GetIds%NOTFOUND ) THEN
         
            CLOSE Cur_GetIds;
            
            l_err_flag_c      :=   'Y';
            Fnd_File.Put_Line(FND_FILE.LOG,'Unable To Find Oracle Account Id');
            
         ELSE   
         
            CLOSE Cur_GetIds;
      
            OPEN   Cur_Receipts ( Cust_Rec.Oracle_Customer_Id
                                 ,l_billto_id_n
                                );
                                
                                
            FETCH  Cur_Receipts
            BULK   COLLECT
            INTO   L_Receipt_Tbl;
      
            CLOSE  Cur_Receipts;
      
            IF ( L_Receipt_Tbl.COUNT  >  0  )  THEN
         
               Fnd_File.Put_Line(FND_FILE.LOG,'Number Of Eligible Records To Process: '||L_Receipt_Tbl.COUNT);
        
               Fnd_File.Put_Line(FND_FILE.LOG,'Printing Eligible Records');
            
               FOR  i  IN  1..L_Receipt_Tbl.COUNT
               LOOP
        
                  Fnd_File.Put_Line(FND_FILE.OUTPUT,L_Receipt_Tbl(i).account_number ||'|'||
                                                    L_Receipt_Tbl(i).receipt_billto ||'|'||
                                                    L_Receipt_Tbl(i).receipt_number ||'|'||
                                                    L_Receipt_Tbl(i).receipt_date   ||'|'||
                                                    L_Receipt_Tbl(i).receipt_amount ||'|'||
                                                    L_Receipt_Tbl(i).applied_billto ||'|'||
                                                    L_Receipt_Tbl(i).trx_number     ||'|'||
                                                    L_Receipt_Tbl(i).amount_applied ||'|'
                                    );

               END LOOP;

               Fnd_File.Put_Line(FND_FILE.LOG,'Processing Receipts To Unapply');
        
               FOR  i  IN  1..L_Receipt_Tbl.COUNT
               LOOP
        
                  Fnd_File.Put_Line(FND_FILE.LOG,'Processing '||L_Receipt_Tbl(i).receipt_number||'-'||L_Receipt_Tbl(i).trx_number);
          
                  Ar_Receipt_Api_Pub.Unapply ( 
                                                 p_api_version                    =>    1.0
                                                ,p_init_msg_list                  =>    FND_API.G_TRUE
                                                ,p_commit                         =>    FND_API.G_FALSE
                                                ,p_validation_level               =>    FND_API.G_VALID_LEVEL_FULL
                                                ,x_return_status                  =>    l_return_status_c
                                                ,x_msg_count                      =>    l_msg_count_n
                                                ,x_msg_data                       =>    l_msg_data_s
                                                ,p_cash_receipt_id                =>    L_Receipt_Tbl(i).cash_receipt_id
                                                ,p_applied_payment_schedule_id    =>    L_Receipt_Tbl(i).applied_payment_schedule_id
                                                ,p_reversal_gl_date               =>    TRUNC(SYSDATE)
                                             );
                                       
                  IF ( l_return_status_c  <>  'S' ) THEN

                     Fnd_File.Put_Line(FND_FILE.OUTPUT,'Error Unapplying Receipt-Transaction: '||L_Receipt_Tbl(i).receipt_number||'-'||L_Receipt_Tbl(i).trx_number);
                     l_err_flag_c     :=    'Y';

                     IF ( l_msg_count_n  =  1 ) THEN
             
                        Fnd_File.Put_Line(FND_FILE.OUTPUT,'Error Message: '||l_msg_data_s);
               
                     ELSIF ( l_msg_count_n  >  1 ) THEN
             
                        LOOP
               
                           l_msg_data_s    :=    Fnd_Msg_Pub.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
                 
                           IF ( l_msg_data_s  IS  NULL )  THEN
                 
                              EXIT;
                   
                           END IF;

                           Fnd_File.Put_Line(FND_FILE.OUTPUT,'Error Message: '||l_msg_data_s);

                        END LOOP;
               
                     END IF;
             
                  END IF;
                  
                  IF (  L_Receipt_Tbl(i).attribute14   IS   NULL  )   THEN                          
                                       
                     UPDATE   ar_receivable_applications
                     SET      attribute15     =    'NA'
                             ,attribute14     =    'NA'
                     WHERE    cash_receipt_id               =    L_Receipt_Tbl(i).cash_receipt_id
                     AND      applied_payment_schedule_id   =    L_Receipt_Tbl(i).applied_payment_schedule_id
                     AND      status                        =   'APP'
                     AND      ABS(amount_applied)           =    ABS(L_Receipt_Tbl(i).amount_applied);
               
                  ELSE   
            
                     UPDATE   ar_receivable_applications
                     SET      attribute15     =    NULL
                             ,attribute14     =    NULL
                     WHERE    cash_receipt_id               =    L_Receipt_Tbl(i).cash_receipt_id
                     AND      applied_payment_schedule_id   =    L_Receipt_Tbl(i).applied_payment_schedule_id
                     AND      status                        =   'APP'
                     AND      amount_applied                =   -1 * L_Receipt_Tbl(i).amount_applied;
               
                  END IF;
                  
               END LOOP;
               
               Fnd_File.Put_Line(FND_FILE.LOG,'Unapplying Completed For Legacy Customer Number: '||Cust_Rec.Customer_Number);

            ELSE 
  
               Fnd_File.Put_Line(FND_FILE.OUTPUT,'No Eligible Records To Process For Legacy Customer Number: '||Cust_Rec.Customer_Number);  
        
            END IF;
         
         END IF;
         
         IF ( l_err_flag_c  =  'Y' ) THEN
         
            ROLLBACK;
            
            UPDATE Swgcnv_Dd_Temp_Customers
            SET    receipt_proc_flag    =   'E'
            WHERE  legacy_customer_number  =  Cust_Rec.Customer_Number;            
            
            COMMIT;
            
            l_err_count_n     :=    l_err_count_n  +  1;
            
         ELSE
         
            l_proc_count_n     :=    l_proc_count_n  +  1;
         
            IF ( in_validate_only_c    =   'Y' ) THEN
               
               ROLLBACK;
               
            ELSE
            
               UPDATE Swgcnv_Dd_Temp_Customers
               SET    receipt_proc_flag    =   'Y'
               WHERE  legacy_customer_number  =  Cust_Rec.Customer_Number;

               COMMIT;
               
            END IF;

         END IF;
         
      END LOOP;   
      
      Fnd_File.Put_Line (FND_FILE.OUTPUT,'                                    ');
      Fnd_File.Put_Line (FND_FILE.OUTPUT,'                                    ');
      Fnd_File.Put_Line (FND_FILE.OUTPUT,'*************************  RUN STATISTICS *******************************');
      Fnd_File.Put_Line (FND_FILE.OUTPUT,'Total Records Read                                  :'|| l_tot_rec_read_n);
      Fnd_File.Put_Line (FND_FILE.OUTPUT,'Total Customers Processed For Receipt Unapplication :'|| l_proc_count_n);
      Fnd_File.Put_Line (FND_FILE.OUTPUT,'Total Customers Receipt Unapplication Errored       :'|| l_err_count_n);
      Fnd_File.Put_Line (FND_FILE.OUTPUT,' ------------------------------------------------------------------------');
      Fnd_File.Put_Line (FND_FILE.OUTPUT,' Start Time : ' || TO_CHAR(l_start_time_d, 'MM/DD/RRRR HH24:MI:SS'));
      Fnd_File.Put_Line (FND_FILE.OUTPUT,' End Time   : ' || TO_CHAR(SYSDATE, 'MM/DD/RRRR HH24:MI:SS'));
      Fnd_File.Put_Line (FND_FILE.OUTPUT,'*************************************************************************');      

   EXCEPTION

      WHEN OTHERS THEN
        ROLLBACK;
        Fnd_File.Put_Line(FND_FILE.LOG,'ERROR PROCESSING RECEIPT UNAPPLICATION PROCESS');
        Fnd_File.Put_Line(FND_FILE.LOG,'ERROR: '||SQLERRM(SQLCODE));
        
        ou_errbuff_s    :=    'ERROR';
        ou_errcode_n    :=    1;
        
   END Unapply_Receipt;   
   
   PROCEDURE   Apply_CashCredit
      (   out_errbuf_s        OUT   VARCHAR2
         ,out_errnum_n        OUT   NUMBER
         ,in_type_s           IN    VARCHAR2
         ,in_system_code_s    IN    VARCHAR2
         ,in_division_n       IN    NUMBER
         ,in_location_n       IN    NUMBER
         ,in_customer_n       IN    NUMBER
         ,in_debug_s          IN    VARCHAR2
      )
   IS

      CURSOR swg_ar_cust( in_orig_sys_ref_s      VARCHAR2 )
      IS
      SELECT cust.cust_account_id
            ,cust.account_number
            ,site.site_use_id
            ,site.location
            ,ABS(cr.amount_due_remaining) amount_due_remaining
            ,cr.payment_schedule_id
            ,cr.class
            ,cr.customer_trx_id
            ,cr.cash_receipt_id
            ,cr.trx_date
            ,cr.invoice_currency_code
            ,cr.trx_number
      FROM   ar_autocash_hierarchies   hier
            ,hz_customer_profiles      prof
            ,hz_cust_site_uses_all     site
            ,hz_cust_acct_sites_all    addr
            ,hz_cust_accounts          cust
            ,ar_payment_schedules_all  cr
      WHERE  hier.HIERARCHY_NAME          =     'SWG APPLY TO OLDEST'
      AND    site.site_use_code           =     'BILL_TO'
      AND    site.attribute8              =     NVL(TO_CHAR(in_location_n),site.attribute8)
      AND    site.attribute9              =     NVL(TO_CHAR(in_division_n),site.attribute9)
      AND    addr.cust_acct_site_id       =     site.cust_acct_site_id
      AND    cust.cust_account_id         =     addr.cust_account_id
      AND    cust.cust_account_id         =     NVL(in_customer_n,cust.cust_account_id)
      AND    cust.orig_system_reference   LIKE  in_orig_sys_ref_s
      AND    prof.cust_account_id         =     addr.cust_account_id
      AND    prof.site_use_id             IS    NULL
      AND    prof.AUTOCASH_HIERARCHY_ID   =     hier.AUTOCASH_HIERARCHY_ID
      AND    cr.customer_site_use_id      =     site.site_use_id
      AND    cr.status                    =     'OP'
      AND    ((in_type_s   =  'A'   AND   cr.class    IN    ('PMT','CM'))
      OR      (in_type_s   =  'C'   AND   cr.class    =     'CM')
      OR      (in_type_s   =  'R'   AND   cr.class    =     'PMT')
             )
      AND    cr.amount_due_remaining < 0;

      CURSOR   swg_ar_inv_dm
         (   in_customer_id_n  NUMBER
            ,in_site_use_id_n  NUMBER
            ,in_pay_sched_id_n NUMBER
            ,in_trx_number_s   VARCHAR2
            ,in_ctype_s        VARCHAR2
         )
      IS 
      SELECT ABS(pay.amount_due_remaining) amount_due_remaining
            ,pay.payment_schedule_id
            ,pay.class
            ,pay.customer_trx_id
            ,pay.cash_receipt_id
            ,pay.trx_date
            ,pay.due_date
            ,pay.invoice_currency_code
            ,pay.trx_number
            ,DECODE(in_ctype_s,'CM',DECODE(pay.trx_number,in_trx_number_s,9999999999,TRUNC(sysdate)-pay.due_date),TRUNC(sysdate)-pay.due_date) order1
      FROM   ar_payment_schedules_all pay
      WHERE  pay.customer_id              =     in_customer_id_n
      AND    pay.customer_site_use_id     =     in_site_use_id_n
      AND    pay.status                   =     'OP'
      AND    pay.class                    IN    ('INV','DM')
      AND    pay.amount_due_remaining     >     0
      ORDER  BY order1 DESC;

      CURSOR  swg_rollback_segment
      IS
      SELECT pgm.ROLLBACK_SEGMENT
      FROM   fnd_concurrent_requests      req
            ,fnd_concurrent_programs      pgm
      WHERE  req.REQUEST_ID                  =  FND_GLOBAL.CONC_REQUEST_ID
      AND    pgm.CONCURRENT_PROGRAM_ID       =  req.CONCURRENT_PROGRAM_ID;

      l_rb_segment_s                      FND_CONCURRENT_PROGRAMS.ROLLBACK_SEGMENT%TYPE;
      l_debit_amt_n                       NUMBER      := 0;
      l_credit_amt_n                      NUMBER      := 0;
      l_applied_amt_n                     NUMBER      := 0;
      l_date_d                            DATE        := TRUNC(SYSDATE);
      l_application_id_n                  NUMBER;
      l_amount_applied_from_n             NUMBER;
      l_amount_applied_to_n               NUMBER;
      l_disc_unearned_n                   NUMBER;
      l_disc_earned_n                     NUMBER;
      l_rec_application_id_n              NUMBER;
      l_acctd_amount_applied_from_n       NUMBER;
      l_acctd_amount_applied_to_n         NUMBER;
      l_application_ref_id_n              NUMBER;
      l_application_ref_num_s             VARCHAR2(30);
      l_return_status_s                   VARCHAR2(1);
      l_msg_count_n                       NUMBER;
      l_msg_data_s                        VARCHAR2(2000);
      l_print_b                           BOOLEAN        := FALSE;
      l_amtfmt_s                          VARCHAR2(14)   := '99999999990D00';
      l_print_amount_n                    NUMBER;

      CURSOR Cur_ar_app( in_cash_receipt_id_n   NUMBER )
      IS
      SELECT *
      FROM  ar_receivable_applications_all
      WHERE cash_receipt_id   =  in_cash_receipt_id_n
      AND   status            =  'ACC'
      AND   application_type  =  'CASH'
      AND   display           =  'Y';

      l_ar_recv_app_rec          Cur_ar_app%ROWTYPE;

      l_application_rec          Swg_Receipt_Pkg.Swg_Receipt_Application_Rec;
      l_attribute_rec            Ar_Receipt_Api_Pub.attribute_rec_type;
      l_global_attribute_rec     Ar_Receipt_Api_Pub.global_attribute_rec_type;
      l_cm_app_rec               Swg_Ar_Cm_Api_Pub_Pkg.cm_app_rec_type;
      
      l_orig_sys_ref_s           VARCHAR2(240);
      l_sales_center_s           VARCHAR2(3);
      io_status_c                VARCHAR2(1);
      io_message_s               VARCHAR2(1000);
      

   BEGIN

      Fnd_File.Put_Line(FND_FILE.OUTPUT,'DSW Credit Memo/Payment Applications');
      Fnd_File.Put_Line(FND_FILE.OUTPUT,'------------------------------------');
      Fnd_File.Put_Line(FND_FILE.OUTPUT,'');
      Fnd_File.Put_Line(FND_FILE.OUTPUT,'Customer#  Location#  Type CM/PMT#              CM/PMT Date CM/PMT Amount   INV#/DM#             INV/DM Date INV/DM Amount   Applied Amount  Error Description                                ');
      Fnd_File.Put_Line(FND_FILE.OUTPUT,'---------- ---------- ---- -------------------- ----------- --------------- -------------------- ----------- --------------- --------------- -------------------------------------------------');

      OPEN  swg_rollback_segment;
      FETCH swg_rollback_segment INTO l_rb_segment_s;
      CLOSE swg_rollback_segment;
      
      SELECT organization_code
      INTO   l_sales_center_s
      FROM   mtl_parameters
      WHERE  organization_id  =   in_location_n;
      
      l_orig_sys_ref_s  :=  'DD-'|| in_system_code_s || '-' || l_sales_center_s || '-%';
      
      Fnd_File.Put_Line(FND_FILE.LOG,'Orig System Reference: '||l_orig_sys_ref_s);

      FOR l_cust_rec IN swg_ar_cust( l_orig_sys_ref_s )
      LOOP
      
         Fnd_File.Put_Line(FND_FILE.LOG,'Processing Customer: '||l_cust_rec.account_number);

         l_credit_amt_n    :=    l_cust_rec.amount_due_remaining;
         l_applied_amt_n   :=    0;
         l_print_b         :=    FALSE;

         FOR l_debit_rec IN swg_ar_inv_dm
                              (   in_customer_id_n    =>    l_cust_rec.cust_account_id
                                 ,in_site_use_id_n    =>    l_cust_rec.site_use_id
                                 ,in_pay_sched_id_n   =>    l_cust_rec.payment_schedule_id
                                 ,in_trx_number_s     =>    l_cust_rec.trx_number
                                 ,in_ctype_s          =>    l_cust_rec.class
                              )
         LOOP
         
            EXIT WHEN l_credit_amt_n = 0;

            l_application_id_n               :=    NULL;
            l_amount_applied_from_n          :=    NULL;
            l_amount_applied_to_n            :=    NULL;
            l_disc_unearned_n                :=    NULL;
            l_disc_earned_n                  :=    NULL;
            l_rec_application_id_n           :=    NULL;
            l_acctd_amount_applied_from_n    :=    NULL;
            l_acctd_amount_applied_to_n      :=    NULL;
            l_amount_applied_from_n          :=    NULL;
            l_application_ref_id_n           :=    NULL;
            l_application_ref_num_s          :=    NULL;
            l_return_status_s                :=    NULL;
            l_msg_count_n                    :=    NULL;
            l_msg_data_s                     :=    NULL;
            l_applied_amt_n                  :=    0;
            l_print_amount_n                 :=    l_credit_amt_n;

            IF ( l_debit_rec.amount_due_remaining >= l_credit_amt_n ) THEN
            
               l_applied_amt_n   := l_credit_amt_n;
               l_credit_amt_n    := 0;
               
            ELSE
            
               l_applied_amt_n   :=  l_debit_rec.amount_due_remaining;
               l_credit_amt_n    :=  l_credit_amt_n - l_debit_rec.amount_due_remaining;
               
            END IF;

            IF ( l_cust_rec.class = 'CM' ) THEN

               BEGIN

                  --------------------------------------------------------------------------------------------------------
                  -- R12 Changes, by BB on 11/07/08, the following API does not create event_id for the application record
                  -- Need to create even_id for subledger accounting
                  -- Used new API to fix it
                  --------------------------------------------------------------------------------------------------------

                  io_status_c          :=    Null;
                  io_message_s         :=    Null;
                  l_application_id_n   :=    Null;
                  l_cm_app_rec         :=    Null;

                  l_cm_app_rec.cm_payment_schedule_id    :=    l_cust_rec.payment_schedule_id;
                  l_cm_app_rec.inv_payment_schedule_id   :=    l_debit_rec.payment_schedule_id;
                  l_cm_app_rec.gl_date                   :=    l_date_d;
                  l_cm_app_rec.amount_applied            :=    l_applied_amt_n;
                  l_cm_app_rec.comments                  :=    'CREDIT CASH APPLICATION';
                  l_cm_app_rec.called_from               :=    NULL;

                  Swg_Ar_Cm_Api_Pub_Pkg.Apply_On_Account
                     (   in_cm_app_rec             =>    l_cm_app_rec
                        ,io_status_c               =>    io_status_c
                        ,io_message_s              =>    io_message_s
                        ,io_rec_application_id_n   =>    l_application_id_n
                     );

                  IF io_status_c = 'S' THEN

                     COMMIT;
                        
                  ELSE

                     ROLLBACK;
                     io_status_c := 'E';

                     l_msg_data_s      :=    io_message_s;
                     l_credit_amt_n    :=    l_credit_amt_n + l_applied_amt_n;
                     l_applied_amt_n   :=    0;

                  END IF;

               EXCEPTION
                  WHEN OTHERS THEN
                     l_msg_data_s      :=    SQLERRM;
                     l_credit_amt_n    :=    l_credit_amt_n + l_applied_amt_n;
                     l_applied_amt_n   :=    0;
                     ROLLBACK;
               END;

            ELSIF( l_cust_rec.class = 'PMT' ) THEN

               BEGIN

                  OPEN  Cur_ar_app( l_cust_rec.cash_receipt_id );

                  FETCH Cur_ar_app
                  INTO  l_ar_recv_app_rec;

                  IF Cur_ar_app%NOTFOUND THEN
                  
                     l_ar_recv_app_rec := NULL;
                     
                  END IF;

                  CLOSE Cur_ar_app;

                  IF ( l_ar_recv_app_rec.receivable_application_id ) IS NOT NULL THEN

                     l_application_rec    :=    Null;

                     l_application_rec.receipt_id                    :=    l_cust_rec.cash_receipt_id;
                     l_application_rec.applied_payment_schedule_id   :=    l_debit_rec.payment_schedule_id;
                     l_application_rec.applied_customer_trx_id       :=    l_debit_rec.customer_trx_id;
                     l_application_rec.applied_amount                :=    l_applied_amt_n;
                     l_application_rec.apply_date                    :=    l_date_d;
                     l_application_rec.apply_gl_date                 :=    l_date_d;
                     l_application_rec.receipt_number                :=    Null;
                     l_application_rec.attribute_category            :=    Null;

                     Swg_Receipt_Pkg.Swg_Apply_On_Account_Receipt
                        (   in_application_rec     =>    l_application_rec
                           ,in_credit_amount_n     =>    l_credit_amt_n
                           ,in_debug_s             =>    'N'
                           ,out_status_s           =>    l_return_status_s
                           ,out_message_s          =>    l_msg_data_s
                        );

                  ELSE

                     Ar_Receipt_Api_Pub.Apply
                        (
                            p_api_version                 =>   1
                           ,p_init_msg_list               =>   fnd_api.g_true
                           ,p_commit                      =>   fnd_api.g_false
                           ,p_validation_level            =>   fnd_api.g_valid_level_full
                           ,x_return_status               =>   l_return_status_s
                           ,x_msg_count                   =>   l_msg_count_n
                           ,x_msg_data                    =>   l_msg_data_s
                           ,p_cash_receipt_id             =>   l_cust_rec.cash_receipt_id
                           ,p_receipt_number              =>   Null
                           ,p_customer_trx_id             =>   l_debit_rec.customer_trx_id
                           ,p_applied_payment_schedule_id =>   l_debit_rec.payment_schedule_id
                           ,p_amount_applied              =>   l_applied_amt_n
                           ,p_apply_date                  =>   l_date_d
                           ,p_apply_gl_date               =>   l_date_d
                           ,p_attribute_rec               =>   l_attribute_rec
                           ,p_global_attribute_rec        =>   l_global_attribute_rec
                           ,p_comments                    =>   Null
                        );

                     IF (l_return_status_s <> FND_API.G_RET_STS_SUCCESS) THEN

                        IF (l_msg_count_n > 1) THEN

                           FOR I IN 1..l_msg_count_n LOOP

                              l_msg_data_s   := l_msg_data_s
                                                   || To_Char(I)
                                                   || '. '
                                                   || SubStr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255)
                                                   || CHR(10);
                                                   
                           END LOOP;
                           
                        END IF;                        

                        IF (l_return_status_s = FND_API.G_RET_STS_UNEXP_ERROR) THEN
                        
                           l_return_status_s := FND_API.G_RET_STS_ERROR;
                           
                        END IF;

                     END IF;

                  END IF;


                  IF l_return_status_s = FND_API.G_RET_STS_SUCCESS THEN
                  
                     COMMIT;
                     
                  ELSE

                     l_credit_amt_n  := l_credit_amt_n + l_applied_amt_n;
                     l_applied_amt_n := 0;
                     ROLLBACK;

                  END IF;

               EXCEPTION
                  WHEN OTHERS THEN
                     l_msg_data_s      :=    SQLERRM;
                     l_credit_amt_n    :=    l_credit_amt_n + l_applied_amt_n;
                     l_applied_amt_n   :=    0;
                     ROLLBACK;
               END;

            END IF; -- ELSIF(l_cust_rec.class = 'PMT')

            --------------------------------------------------------------------------
            IF (l_rb_segment_s IS NOT NULL) THEN
            
               Dbms_Transaction.Use_Rollback_Segment( l_rb_segment_s );
                
            END IF;

            IF (l_print_b = FALSE) THEN
            
               Fnd_File.Put_Line(FND_FILE.OUTPUT,    RPAD(l_cust_rec.account_number,10,' ')
                                             ||' '|| RPAD(l_cust_rec.location,10,' ')
                                             ||' '|| RPAD(l_cust_rec.class,04,' ')
                                             ||' '|| RPAD(l_cust_rec.trx_number,20,' ')
                                             ||' '|| TO_CHAR(l_cust_rec.trx_date,'DD-MON-RRRR')
                                             ||' '|| TO_CHAR(l_print_amount_n,l_amtfmt_s)
                                             ||' '|| RPAD(l_debit_rec.trx_number,20,' ')
                                             ||' '|| TO_CHAR(l_debit_rec.trx_date,'DD-MON-RRRR')
                                             ||' '|| TO_CHAR(l_debit_rec.amount_due_remaining,l_amtfmt_s)
                                             ||' '|| TO_CHAR(l_applied_amt_n,l_amtfmt_s)
                                             ||' '|| l_msg_data_s);
               l_print_b   := TRUE;
               
            ELSE
            
               Fnd_File.Put_Line(FND_FILE.OUTPUT, RPAD(' ',59,' ')
                                          ||' '|| TO_CHAR(l_print_amount_n,l_amtfmt_s)
                                          ||' '|| RPAD(l_debit_rec.trx_number,20,' ')
                                          ||' '|| TO_CHAR(l_debit_rec.trx_date,'DD-MON-RRRR')
                                          ||' '|| TO_CHAR(l_debit_rec.amount_due_remaining,l_amtfmt_s)
                                          ||' '|| TO_CHAR(l_applied_amt_n,l_amtfmt_s)
                                          ||' '|| l_msg_data_s);
                                          
            END IF;
            
        END LOOP;
        
      END LOOP;

      out_errnum_n   := 0;
      out_errbuf_s   := NULL;

   EXCEPTION
      WHEN OTHERS THEN
         out_errnum_n   := 2;
         out_errbuf_s   := sqlerrm;
         Fnd_File.Put_Line(FND_FILE.LOG,'Error: '||SQLERRM(SQLCODE));
         ROLLBACK;
   END  Apply_CashCredit;   
-----------------------------------------
--Moved updates from update script to procedure --MTS 20129
PROCEDURE SWGCNV_UPDATE_AR_HISTORY                    
          (ou_errbuff_s            OUT        VARCHAR2
          ,ou_errcode_n            OUT        NUMBER
          ,in_legacy_system_s      IN         VARCHAR2) IS

--SELECT TRX AND CUSTOMER REF WHERE THERE ARE DUPE LINE NUMBERS OR DUPE TRX FOR DIFFERENT CUSTOMERs
CURSOR dupe_csr IS     
   SELECT   DISTINCT dah.trx_number,orig_system_ship_customer_ref
   FROM
      swgcnv_dd_ar_HISTORY dah
      ,
      (
      SELECT 
        dah.cust_trx_type_name,
        dah.trx_number,
        dah.line_number,                  
        COUNT(*)
      FROM
        swgcnv_dd_ar_history dah
      GROUP BY dah.cust_trx_type_name, dah.trx_number, dah.line_number
      HAVING COUNT(*) > 1) dupes
   WHERE dah.trx_number = dupes.trx_number
   AND   dah.line_number = dupes.line_number
   AND   dah.cust_trx_type_name = dupes.cust_trx_type_name
   AND   dah.cust_trx_type_name <> 'PAYMENT'
   ORDER BY 1,2;

CURSOR location_csr IS
       SELECT
            map.old_code legacy_sales_center,
            Swg_Hierarchy_Pkg.Get_Parent (  
                                               'ROUTE'
                                               ,map.new_code
                                               ,NULL
                                               ,'LOCATION'
                                               ,SYSDATE
                                               ,'CODE'
                                   ,'HTL')  as sales_center,
               Swg_Hierarchy_Pkg.Get_Parent (  
                                   'ROUTE'
                                   ,map.new_code
                                   ,NULL
                                   ,'DIVISION'
                                   ,SYSDATE
                                   ,'ID'
                                   ,'HTL'
                                  ) AS division            
     FROM   swgcnv_map map 
    WHERE   TYPE_CODE     =   'ROUTES'
      AND   SYSTEM_CODE   =   IN_LEGACY_SYSTEM_S
      AND   NEW_CODE     !=   'NOT MAPPED';

CURSOR update_loc_div_csr
IS
SELECT DISTINCT  ah.orig_system_ship_address_ref ,
                 cust.sales_center,
                 cust.division
FROM
  swgcnv_dd_ar_history ah,
  swgcnv_dd_cb_prestaging_cust cust
WHERE
  cust.customer_number = ah.orig_system_ship_address_ref
AND (cust.sales_center <> ah.sales_center OR cust.division <> ah.division);

--Transactions with multiple transaction dates

CURSOR fix_date_csr
IS
SELECT trx_number,
       orig_system_ship_customer_ref,
       cust_trx_type_name,
       MIN(trx_date) trx_date,
       COUNT(*)
FROM
  (SELECT DISTINCT
          trx_number,
          orig_system_ship_customer_ref,
          trx_date,
          cust_trx_type_name
  FROM    swgcnv_dd_ar_history)
  GROUP BY trx_number, orig_system_ship_customer_ref,cust_trx_type_name
HAVING COUNT(*) > 1;

CURSOR  incorrect_prc_csr
IS
SELECT  quantity,
        quantity_ordered,
        unit_selling_price,
        amount,
        rowid
FROM    swgcnv_dd_ar_history 
WHERE   nvl(amount,0) <> (nvl(unit_selling_price,0) * nvl(quantity,0))
AND     cust_trx_type_name IN ('INVOICE','CREDIT MEMO','DEBIT MEMO');

CURSOR dual_sign_csr
IS
SELECT ar.trx_number,
       ar.interface_line_attribute1,
       ar.orig_system_ship_customer_ref,
       SUM(ar.amount) + SUM(ar.attribute10) trx_total
FROM   swgcnv_dd_ar_history ar
WHERE  cust_trx_type_name  !=  'PAYMENT'
GROUP BY  ar.trx_number,
          ar.interface_line_attribute1,
          ar.orig_system_ship_customer_ref;

CURSOR cycle_day_csr
IS
SELECT DISTINCT
       ah.trx_number,
       ah.trx_date,
       bt.customer_number,
       map.new_code bill_cycle_day
FROM   swgcnv_dd_customer_billto bt,
       swgcnv_map                map,
       swgcnv_map                map1,
       swgcnv_dd_ar_history     ah
WHERE  map.old_code       = bt.billing_cycle_day
AND    bt.customer_number = ah.orig_system_bill_customer_ref
AND    map.system_code    = in_legacy_system_s
AND    map.type_code      = 'STMTCYCL'
AND    map1.old_code      = ah.sales_center
AND    map1.new_code      = map.old_sub_code
AND    map1.type_code     = 'STATE'
AND    map1.system_code   = in_legacy_system_s
;

CURSOR fix_tax_trx_csr
IS    
SELECT 
         orig_system_bill_customer_ref,
         trx_number,
         line_number,
         (SELECT  MAX(ah1.line_number)
            FROM  swgcnv_dd_ar_history ah1
           WHERE  ah1.trx_number                   = ah.trx_number
             AND  ah1.orig_system_bill_address_ref = ah.orig_system_bill_address_ref) max_line_num
FROM     swgcnv_dd_ar_history ah
WHERE    line_type =  'TAX'
AND      (SELECT  MAX(ah1.line_number)
            FROM  swgcnv_dd_ar_history ah1
           WHERE  ah1.trx_number                   = ah.trx_number
             AND  ah1.orig_system_bill_address_ref = ah.orig_system_bill_address_ref) <> line_number;
          
CURSOR  fix_tax_trx_lines_csr (in_trx_number_s VARCHAR2, in_bill_cust_ref_s VARCHAR2)
IS
SELECT  trx_number,
        line_number,
        line_type,
        rowid
FROM    swgcnv_dd_ar_history
WHERE   trx_number = in_trx_number_s
AND     orig_system_bill_customer_ref = in_bill_cust_ref_s
ORDER BY  trx_number,line_type,line_number;

CURSOR ar_csr
IS
SELECT *
FROM   SWGCNV.swgcnv_dd_ar_history;

CURSOR billed_unbilled_csr
IS
SELECT DISTINCT 
       orig_system_bill_customer_ref,
       decode(cust.stmt_type,'P','P','M') stmt_type,
       ah.trx_number,
       ah.trx_date,
       ah.sales_center
FROM   swgcnv_dd_ar_history ah,
       swgcnv_dd_cb_prestaging_cust cust
WHERE  cust.customer_number = ah.orig_system_bill_customer_ref;
         
l_line_num_n          NUMBER;
l_sav_trx_s           VARCHAR2(50) := ' ';
l_sav_ship_ref_s      VARCHAR2(50) := ' ';
l_dupe_cnt_n          NUMBER;
l_message_s           VARCHAR2(2000);
l_period_start_date_d DATE;
l_correct_price_n     NUMBER := 0;
l_tax_status_s        VARCHAR2(50);
l_billed_status_s     VARCHAR2(1);

PROCEDURE swg_log (in_text_s   IN   VARCHAR2)
   IS
    
BEGIN
     fnd_file.put_line (fnd_file.LOG, in_text_s);
END;

PROCEDURE swg_output (in_text_s   IN   VARCHAR2)
   IS
    
BEGIN
     fnd_file.put_line (fnd_file.OUTPUT, in_text_s);
END;
BEGIN

--WO20457
--In prestaging, if bill to master missing, used one of the ship to and made it bill to master..
--So now bill to master and AR file bill tos out of sync
UPDATE swgcnv_dd_ar_history ah
SET    ah.orig_system_bill_customer_ref = (  SELECT NVL(cust.bill_to_master,cust.customer_number) 
                                             FROM   swgcnv_dd_cb_prestaging_cust cust 
                                             WHERE  cust.customer_number = ah.orig_system_ship_address_ref );

UPDATE swgcnv_dd_ar_history ah
SET orig_system_bill_address_ref  = orig_system_bill_customer_ref,
    orig_system_ship_customer_ref = orig_system_bill_customer_ref
WHERE (ah.orig_system_bill_customer_ref  <> ah.orig_system_bill_address_ref 
OR  ah.orig_system_bill_customer_ref  <> ah.orig_system_ship_customer_ref );

--update sales_center and division

FOR location_rec IN location_csr LOOP
    UPDATE swgcnv_dd_ar_history
    SET   sales_center = location_rec.sales_center,
          division     = location_rec.division
    WHERE sales_center = location_rec.legacy_sales_center;
END LOOP;

FOR update_loc_div_rec IN update_loc_div_csr LOOP
    UPDATE swgcnv_dd_ar_history
    SET   sales_center = update_loc_div_rec.sales_center,
          division     = update_loc_div_rec.division
    WHERE orig_system_ship_address_ref  = update_loc_div_rec.orig_system_ship_address_ref; 
END LOOP;
    
--append sales_center and legacy code to front of trx_number and interface_line_attribute1
UPDATE swgcnv_dd_ar_history
SET    trx_number = sales_center||'-'||in_legacy_system_s||'-'||trx_number;

UPDATE swgcnv_dd_ar_HISTORY
SET    sub_cust_num  = orig_system_ship_address_ref;

FOR dual_sign_rec IN dual_sign_csr LOOP

    IF dual_sign_rec.trx_total < 0 THEN

       UPDATE swgcnv_dd_ar_history
       SET    cust_trx_type_name            = 'CREDIT MEMO'
       WHERE  trx_number                    = dual_sign_rec.trx_number
       AND    orig_system_ship_customer_ref = dual_sign_rec.orig_system_ship_customer_ref
       --WTRFLX3 AND cust_trx_type_name <> 'CREDIT MEMO';
       AND cust_trx_type_name IN ( 'DEBIT MEMO','INVOICE' );

    ELSE

       UPDATE  swgcnv_dd_ar_history
       SET     cust_trx_type_name            = 'INVOICE'
       WHERE   trx_number                    = dual_sign_rec.trx_number
       AND     orig_system_ship_customer_ref = dual_sign_rec.orig_system_ship_customer_ref
       --WTRFLX3 AND cust_trx_type_name NOT IN ( 'DEBIT MEMO','INVOICE' )
       AND cust_trx_type_name               <>  'PAYMENT';

    END IF;

END LOOP;

l_sav_trx_s      := ' ';
l_sav_ship_ref_s := ' ';

    l_message_s := '******************Duplicate Transactions******************';
    swg_output(l_message_s);
    l_message_s := 'cust#|old_trx_number|new_trx_number';
    swg_output(l_message_s);

--Renumber duplicate transaction numbers
FOR dupe_rec IN dupe_csr LOOP

    IF l_sav_trx_s <> dupe_rec.trx_number THEN

       l_sav_trx_s      := dupe_rec.trx_number;
       l_sav_ship_ref_s := dupe_rec.orig_system_ship_customer_ref;
       l_dupe_cnt_n     := 1;

   ELSIF l_sav_ship_ref_s <> dupe_rec.orig_system_ship_customer_ref THEN

       l_sav_ship_ref_s := dupe_rec.orig_system_ship_customer_ref;
       l_dupe_cnt_n     := l_dupe_cnt_n + 1;

   END IF;

    UPDATE swgcnv_dd_ar_history
    SET   trx_number                = REPLACE(trx_number,'-CM','CM')||'-'||l_dupe_cnt_n,
          interface_line_attribute1 = REPLACE(interface_line_attribute1,'-CM','CM')||'-'||l_dupe_cnt_n
    WHERE trx_number                = dupe_rec.trx_number
    AND   orig_system_ship_customer_ref = dupe_rec.orig_system_ship_customer_ref;

    l_message_s := dupe_rec.orig_system_ship_customer_ref||'|'||dupe_rec.trx_number||'|'||REPLACE(dupe_rec.trx_number,'-CM','CM')||'-'||l_dupe_cnt_n;
    swg_output(l_message_s);

END LOOP;

    UPDATE swgcnv_dd_ar_history
    SET interface_line_attribute1 = trx_number
    WHERE NVL(interface_line_attribute1,' ') != trx_number;

    l_message_s := '******************Multiple Date Transactions******************';
    swg_output(l_message_s);
    l_message_s := 'trx_number|date';
    swg_output(l_message_s);

--set all lines to same transaction date if a transaction has multiple dates

FOR fix_date_rec IN fix_date_csr LOOP

      UPDATE swgcnv_dd_ar_history
      SET   trx_date = fix_date_rec.trx_date,
            gl_date = fix_date_rec.trx_date,
            due_date = fix_date_rec.trx_date
      WHERE trx_number = fix_date_rec.trx_number
      AND   orig_system_ship_customer_ref = fix_date_rec.orig_system_ship_customer_ref
      AND   cust_trx_type_name            = fix_date_rec.cust_trx_type_name;

      l_message_s := fix_date_rec.trx_number||'|'||fix_date_rec.trx_date;
      swg_output(l_message_s);

END LOOP;

--
FOR incorrect_prc_rec IN incorrect_prc_csr LOOP

  l_correct_price_n := 0;

  l_correct_price_n := (nvl(incorrect_prc_rec.amount,0) / nvl(incorrect_prc_rec.quantity,nvl(incorrect_prc_rec.quantity_ordered,0)));

  IF nvl(l_correct_price_n,0) = nvl(incorrect_prc_rec.unit_Selling_price,0)  THEN

    Null;

  ELSIF nvl(l_correct_price_n,0) <> nvl(incorrect_prc_rec.unit_Selling_price,0)  THEN

    UPDATE swgcnv_dd_ar_history
    SET    unit_selling_price =   l_correct_price_n, 
           ar_proc_flag       =   'N'
    WHERE  rowid              =   incorrect_prc_rec.rowid;
     
  END IF;

END LOOP;

   --UPDATE gl_date based on trx_date and current gl period start date

   SELECT  start_date
   INTO    l_period_start_date_d
   FROM    gl_periods
   WHERE   period_set_name = 'SWG Calendar'
   AND     TRUNC(SYSDATE) BETWEEN start_date AND end_date;

   UPDATE swgcnv_dd_ar_history
   SET    gl_date  = trx_date
   WHERE  trx_date >= l_period_start_date_d;

   l_message_s := 'Update GL date to trx_date '||SQL%ROWCOUNT||' rows updated';
   swg_output(l_message_s); 

   UPDATE swgcnv_dd_ar_history
   SET    gl_date  = l_period_start_date_d
   WHERE  trx_date < l_period_start_date_d;

   l_message_s := 'Update GL date to period start_date '||SQL%ROWCOUNT||' rows updated';
   swg_output(l_message_s); 

   UPDATE SWGCNV_DD_AR_HISTORY      
   SET    amount      = ROUND(amount,2),
          attribute10 = ROUND(attribute10,2);

--Renumber transactions with tax lines so tax line is last line in transactions
FOR fix_tax_trx_rec IN fix_tax_trx_csr LOOP

    l_line_num_n := 1;

    FOR fix_tax_trx_lines_rec IN fix_tax_trx_lines_csr(fix_tax_trx_rec.trx_number ,fix_tax_trx_rec.orig_system_bill_customer_ref) LOOP

     BEGIN
        UPDATE  swgcnv_dd_ar_history
        SET     line_number = l_line_num_n,
                interface_line_attribute2 = l_line_num_n
        WHERE   ROWID = fix_tax_trx_lines_rec.ROWID;

        l_line_num_n := l_line_num_n + 1;

     EXCEPTION WHEN OTHERS THEN
        swg_log('error updating tax line '||SQLERRM);
     END;

    END LOOP;

   END LOOP;

   UPDATE  swgcnv_dd_ar_history
   SET     tax_code = 'DDCONV_TAX'
   WHERE   NVL(tax_code,' ') <> 'DDCONV_TAX';

   l_message_s := 'Update tax_code DDCONV_TAX '||SQL%ROWCOUNT||' rows updated';
   swg_output(l_message_s);         


   UPDATE  swgcnv_dd_ar_history
      SET  orig_system_ship_customer_ref = orig_system_bill_customer_ref;

   --Update tax status for billed and unbilled transactions
   swgcnv_unbilled_billed  (  
                              l_billed_status_s,
                              in_legacy_system_s
                           );   


IF l_billed_status_s = 'E' THEN
    Fnd_File.Put_Line(FND_FILE.OUTPUT,'UNBILLED/BILLED VALUE NOT MAPPED=> '||in_legacy_system_s);
    ou_errbuff_s    :=   'ERROR : UNBILLED/BILLED NOT ESTABLISHED IN MAPPING TABLE';
    ou_errcode_n    :=   2;
    RETURN;
END IF;

--Delete STMT stuff, clean up for future processing
DELETE swgcnv.Swgcnv_dd_Stmt_Interface;

--Insert modified data into swgcnv_dd_ar_interface
DELETE FROM SWGCNV.SWGCNV_DD_AR_INTERFACE;

FOR ar_rec IN ar_csr LOOP

    INSERT INTO SWGCNV.swgcnv_dd_ar_interface
    VALUES
		(ar_rec.cust_trx_type_name,
		ar_rec.interface_line_context,
		ar_rec.orig_system_bill_customer_ref,
		ar_rec.orig_system_bill_address_ref,
		ar_rec.orig_system_ship_customer_ref,
		ar_rec.orig_system_ship_address_ref,
		ar_rec.interface_line_attribute1,
		ar_rec.interface_line_attribute2,
		ar_rec.line_type,
		ar_rec.trx_date,
		ar_rec.gl_date,
		ar_rec.trx_number,
		ar_rec.line_number,
		ar_rec.description,
		ar_rec.amount,
		ar_rec.currency_code,
		ar_rec.term_name,
		ar_rec.item_code,
		ar_rec.quantity,
		ar_rec.uom_code,
		ar_rec.quantity_ordered,
		ar_rec.unit_selling_price,
		ar_rec.unit_standard_price,
		ar_rec.reason_code,
		ar_rec.tax_rate,
		ar_rec.tax_code,
		ar_rec.primary_salesrep_number,
		ar_rec.comments,
		ar_rec.attribute10,
		ar_rec.tax_exempt_flag,
		ar_rec.tax_exempt_reason_code,
		ar_rec.tax_exempt_number,
		ar_rec.sales_order,
		ar_rec.sales_order_line,
		ar_rec.sales_order_date,
		ar_rec.sales_order_source,
		ar_rec.sales_order_revision,
		ar_rec.purchase_order,
		ar_rec.purchase_order_revision,
		ar_rec.purchase_order_date,
		ar_rec.reference_line_context,
		ar_rec.reference_line_attribute1,
		ar_rec.reference_line_attribute2,
		ar_rec.sales_center,
		ar_rec.division,
		ar_rec.attribute1,
		ar_rec.attribute2,
		ar_rec.trxn_status,
		ar_rec.item_sub_code,
		ar_rec.due_date,
		ar_rec.ar_proc_flag,
		ar_rec.sub_cust_num);

END LOOP;
       
COMMIT;

END SWGCNV_UPDATE_AR_HISTORY;

PROCEDURE SWGCNV_AR_HISTORY_DIAGS
          (ou_errbuff_s            OUT        VARCHAR2
          ,ou_errcode_n            OUT        NUMBER
          ,in_legacy_system_s      IN         VARCHAR2) IS

   l_rec_cnt_n NUMBER;
   l_message_s VARCHAR2(2000);
 

   PROCEDURE swg_log (in_text_s   IN   VARCHAR2)
   IS
    
   BEGIN
        fnd_file.put_line (fnd_file.LOG, in_text_s);
   END;

   PROCEDURE swg_output (in_text_s   IN   VARCHAR2)
   IS
    
   BEGIN
        fnd_file.put_line (fnd_file.OUTPUT, in_text_s);
   END;

BEGIN
--dupe transactions
  BEGIN

    SELECT COUNT(*)
    INTO   l_rec_cnt_n
    FROM   swgcnv_dd_ar_history dah
    WHERE  dah.cust_trx_type_name <> 'PAYMENT'
    GROUP BY dah.cust_trx_type_name, dah.trx_number, dah.line_number
    HAVING COUNT(*) > 1;

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;
   
    IF l_rec_cnt_n > 0 THEN
       l_message_s := l_rec_cnt_n||' Duplicate Transaction Lines';
       swg_output(l_message_s);
    END IF;

  BEGIN

    SELECT  COUNT(*)
    INTO    l_rec_cnt_n
    FROM    swgcnv_dd_ar_history
    WHERE   NVL(interface_line_attribute1,' ') != trx_number;

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

  IF l_rec_cnt_n > 0 THEN
       l_message_s := l_rec_cnt_n||' rows where interface_line_attriubute1 != transaction_number';
       swg_output(l_message_s);
  END IF;

  BEGIN

    SELECT COUNT(DISTINCT ah.trx_number)
    INTO   l_rec_cnt_n
    FROM   swgcnv_dd_ar_history  ah,
       (SELECT    trx_number ,orig_system_ship_customer_ref
          FROM    swgcnv_dd_ar_history ah
         WHERE   amount < 0
           AND     line_type = 'LINE'
          AND EXISTS (SELECT  trx_number
                      FROM  swgcnv_dd_ar_history ah1
                     WHERE  amount >= 0
                       AND  ah.trx_number                    = ah1.trx_number
                       AND  ah.orig_system_ship_customer_ref = ah1.orig_system_ship_customer_ref
                       AND  ah.cust_trx_type_name            = ah1.cust_trx_type_name
                       AND  line_type                        = 'LINE')) neg
    WHERE  ah.trx_number                    = neg.trx_number
    AND    ah.orig_system_ship_customer_ref = neg.orig_system_ship_customer_ref;

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Transactions with both positive and negative lines';
      swg_output(l_message_s);
   END IF;

--TRX with multiple dates
  BEGIN

   SELECT  SUM(COUNT(DISTINCT trx_number))
   INTO    l_rec_cnt_n
   FROM  (SELECT DISTINCT
                 trx_number,
                 orig_system_ship_customer_ref,
                 cust_trx_type_name,
                 trx_date
        FROM swgcnv_dd_ar_history)
   GROUP BY trx_number, orig_system_ship_customer_ref,cust_trx_type_name
   HAVING COUNT(*) > 1;

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Transactions with multiple transaction dates';
      swg_output(l_message_s);
   END IF;

  --Price * qty != amount
  BEGIN

   SELECT COUNT(*) 
   INTO   l_rec_cnt_n
   FROM   swgcnv_dd_ar_history 
   WHERE  NVL(amount,0) <> ROUND((NVL(unit_selling_price,0) * NVL(quantity,0)),2)
   AND    cust_trx_type_name IN ('INVOICE','CREDIT MEMO','DEBIT MEMO');

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Transaction lines where price * qty <> amount';
      swg_output(l_message_s);
   END IF;

--Invoice lines with negative amounts
  BEGIN

   SELECT COUNT(*)
   INTO   l_rec_cnt_n
   FROM   swgcnv_dd_ar_history
   WHERE  cust_trx_type_name = 'INVOICE'
   AND    amount             < 0;

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Invoice lines with negative amounts';
      swg_output(l_message_s);
   END IF;

--Payments with positive amounts
  BEGIN

   SELECT COUNT(*)
   INTO   l_rec_cnt_n
   FROM   swgcnv_dd_ar_history
   WHERE  cust_trx_type_name = 'PAYMENT'
   AND    amount             > 0;

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Payments with positive amounts';
      swg_output(l_message_s);
   END IF;

--Credit memoes with positive amounts
  BEGIN

   SELECT  COUNT(*)
   INTO    l_rec_cnt_n
   FROM    swgcnv_dd_ar_history
   WHERE   cust_trx_type_name = 'CREDIT MEMO'
   AND     amount             > 0;

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' CREDIT MEMO with positive amounts';
      swg_output(l_message_s);
   END IF;

--Debit memoes with negative amounts
  BEGIN

   SELECT  COUNT(*)
   INTO    l_rec_cnt_n
   FROM    swgcnv_dd_ar_history
   WHERE   cust_trx_type_name = 'DEBIT MEMO'
   AND     amount             < 0;

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' DEBIT MEMO with negative amounts';
      swg_output(l_message_s);
   END IF;

  BEGIN

   SELECT  COUNT(*)
   INTO    l_rec_cnt_n
   FROM    swgcnv_dd_ar_history
   WHERE   NVL(cust_trx_type_name,' ') NOT IN ('PAYMENT','INVOICE','CREDIT MEMO','DEBIT MEMO');

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Invoice lines with invalid cust_trx_type_name';
      swg_output(l_message_s);
   END IF;

  BEGIN

   SELECT  COUNT(*)
   INTO    l_rec_cnt_n
   FROM    swgcnv_dd_ar_history
   WHERE   NVL(interface_line_context,' ') <> 'DD CONVERSION';

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Invoice lines with invalid interface_line_context';
      swg_output(l_message_s);
   END IF;
--
  BEGIN

   SELECT  COUNT(*)
   INTO    l_rec_cnt_n
   FROM    swgcnv_dd_ar_history
   WHERE   length(trim(translate(orig_system_bill_customer_ref, '0123456789',' '))) IS NOT NULL;

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Invoice lines with alpha orig_system_bill_customer_ref';
      swg_output(l_message_s);
   END IF;
--
  BEGIN

   SELECT COUNT(*)
   INTO   l_rec_cnt_n
   FROM   swgcnv_dd_ar_history
   WHERE  length(trim(translate(orig_system_bill_address_ref, '0123456789',' '))) IS NOT NULL;

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Invoice lines with alpha orig_system_bill_address_ref';
      swg_output(l_message_s);
   END IF;
--
  BEGIN

   SELECT  COUNT(*)
   INTO    l_rec_cnt_n
   FROM    swgcnv_dd_ar_history
   WHERE   length(trim(translate(orig_system_ship_customer_ref, '0123456789',' '))) IS NOT NULL;

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Invoice lines with alpha orig_system_ship_customer_ref';
      swg_output(l_message_s);
   END IF;
--
  BEGIN

   SELECT  COUNT(*)
   INTO    l_rec_cnt_n
   FROM    swgcnv_dd_ar_history
   WHERE   length(trim(translate(orig_system_ship_address_ref, '0123456789',' '))) IS NOT NULL;

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Invoice lines with alpha orig_system_ship_address_ref';
      swg_output(l_message_s);
   END IF;

--
  BEGIN

   SELECT  COUNT(*)
   INTO    l_rec_cnt_n
   FROM    swgcnv_dd_ar_history
   WHERE   interface_line_attribute1 <> trx_number;

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Invoice lines where interface_line_attribute1 <> trx_number';
      swg_output(l_message_s);
   END IF;
--
  BEGIN

   SELECT  COUNT(*)
   INTO    l_rec_cnt_n
   FROM    swgcnv_dd_ar_history
   WHERE   interface_line_attribute2 <> line_number;

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Invoice lines where interface_line_attribute2 <> line_number';
      swg_output(l_message_s);
   END IF;
--
  BEGIN

   SELECT  COUNT(*)
   INTO    l_rec_cnt_n
   FROM    swgcnv_dd_ar_history
   WHERE   NVL(line_type,' ') NOT IN ('LINE','TAX');

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Invoice lines with invalid LINE_TYPE';
      swg_output(l_message_s);
   END IF;


--
  BEGIN

   SELECT COUNT(*)
   INTO   l_rec_cnt_n
   FROM   swgcnv_dd_ar_history
   WHERE  NVL(currency_code,' ') <> 'USD'
   AND    NVL(line_type,' ') <> 'TAX';

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Invoice lines with invalid currency_code';
      swg_output(l_message_s);
   END IF;

--
  BEGIN

   SELECT COUNT(*)
   INTO   l_rec_cnt_n
   FROM   swgcnv_dd_ar_history
   WHERE  NVL(term_name,' ') <> 'IMMEDIATE'
   AND    NVL(line_type,' ') <> 'TAX';

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Invoice lines with invalid term_name';
      swg_output(l_message_s);
   END IF;

--
  BEGIN

   SELECT  COUNT(*)
   INTO    l_rec_cnt_n
   FROM    swgcnv_dd_ar_history
   WHERE   quantity is NULL
   AND     NVL(line_type,' ') <> 'TAX';

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Invoice lines with NULL quantity';
      swg_output(l_message_s);
   END IF;

--
  BEGIN

   SELECT  COUNT(*)
   INTO    l_rec_cnt_n
   FROM    swgcnv_dd_ar_history
   WHERE   quantity_ordered  is NULL
   AND     NVL(line_type,' ') <> 'TAX';

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Invoice lines with NULL quantity_ordered';
      swg_output(l_message_s);
   END IF;

  BEGIN

   SELECT COUNT(*)
   INTO   l_rec_cnt_n
   FROM   swgcnv_dd_ar_history
   WHERE  unit_selling_price  IS NULL
   AND    NVL(line_type,' ') <> 'TAX';

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Invoice lines with NULL unit_selling_price';
      swg_output(l_message_s);
   END IF;

--
  BEGIN

   SELECT  COUNT(*)
   INTO    l_rec_cnt_n
   FROM    swgcnv_dd_ar_history
   WHERE   NVL(tax_code,' ') <> 'DDCONV_TAX'
   AND     NVL(line_type,' ') <> 'TAX';

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Invoice lines with invalid tax_code';
      swg_output(l_message_s);
   END IF;

--
  BEGIN

   SELECT  COUNT(*)
   INTO    l_rec_cnt_n
   FROM    swgcnv_dd_ar_history
   WHERE   attribute10 IS NULL
   AND     line_type = 'TAX';

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' TAX lines with NULL attribute10';
      swg_output(l_message_s);
   END IF;

--
  BEGIN

   SELECT  COUNT(*)
   INTO    l_rec_cnt_n
   FROM    swgcnv_dd_ar_history
   WHERE   NVL(reference_line_context,' ') <> 'DD CONVERSION'
   AND     NVL(line_type,' ') <> 'TAX';

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Invoice lines with invalid reference_line_context';
      swg_output(l_message_s);
   END IF;

--
  BEGIN

   SELECT  COUNT(*)
   INTO    l_rec_cnt_n
   FROM    swgcnv_dd_ar_history
   WHERE   NVL(trxn_status,' ') NOT IN ('B','U','NA',NULL)
   AND     NVL(line_type,' ') <> 'TAX';

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Invoice lines with invalid tax_status';
      swg_output(l_message_s);
   END IF;

  BEGIN

   SELECT   COUNT(*)
   INTO     l_rec_cnt_n
   FROM
   (SELECT trx_number,
           orig_system_ship_address_ref
    FROM   swgcnv_dd_ar_history
    WHERE  cust_trx_type_name = 'INVOICE'
    INTERSECT
    SELECT trx_number,
           orig_system_ship_address_ref
    FROM   swgcnv_dd_ar_history
    WHERE  cust_trx_type_name = 'CREDIT MEMO'
   );

  EXCEPTION WHEN NO_DATA_FOUND THEN
    l_rec_cnt_n := 0;
  END;

   IF l_rec_cnt_n > 0 THEN
      l_message_s := l_rec_cnt_n||' Transactions with multiple transaction types';
      swg_output(l_message_s);
   END IF;
     

END SWGCNV_AR_HISTORY_DIAGS;


PROCEDURE SWGCNV_AR_PROC_AUTOINVOICE
                                       ( ou_errbuff_s            OUT        VARCHAR2
                                        ,ou_errcode_n            OUT        NUMBER
                                        ,in_legacy_system_s      IN         VARCHAR2)
IS 
  
 
   CURSOR sc_csr
   IS
   SELECT DISTINCT
          sales_center,
          division
   FROM   swgcnv_dd_ar_interface
   WHERE  ar_proc_flag = 'N';
  
    l_request_id_n      NUMBER;
    l_check_req_b       BOOLEAN;
    l_call_status_b     BOOLEAN;
    l_rphase_s          VARCHAR2(80);
    l_rstatus_s         VARCHAR2(80);
    l_dphase_s          VARCHAR2(30);
    l_dstatus_s         VARCHAR2(30);
    l_message_s         VARCHAR2(2000);
  
  
BEGIN

     FOR sc_rec IN sc_csr LOOP

              l_request_id_n    :=    Fnd_Request.Submit_Request
                                     ( application    =>    'SWGCNV'
                                      ,program        =>    'SWGCNV_AR_CONV'
                                      ,description    =>    NULL
                                      ,start_time     =>    NULL
                                      ,sub_request    =>    FALSE
                                      ,argument1      =>    in_legacy_system_s
                                      ,argument2      =>    sc_rec.division
                                      ,argument3      =>    sc_rec.sales_center
                                             );

             IF l_request_id_n = 0 THEN
                 DBMS_OUTPUT.PUT_LINE('ERROR: Unable to Submit Concurrent Request to Load Autoinvoice: '||SQLERRM);
             ELSE
                     COMMIT;
                     l_check_req_b    :=    TRUE;
                     WHILE l_check_req_b
                     LOOP
                        l_call_status_b    :=    Fnd_Concurrent.Get_Request_Status
                                                     (request_id  =>    l_request_id_n
                                                     ,phase       =>    l_rphase_s
                                                     ,status      =>    l_rstatus_s
                                                     ,dev_phase   =>    l_dphase_s
                                                     ,dev_status  =>    l_dstatus_s
                                                     ,message     =>    l_message_s);

                        IF NVL(l_dphase_s, '~') != 'COMPLETE' THEN
                                 dbms_lock.sleep (5);
                        ELSE
                            l_check_req_b    :=    FALSE;
                        END IF;
                     END LOOP;        -- While Loop
            END IF;          
      
           IF l_dstatus_s = 'NORMAL' THEN
            l_request_id_n :=  Fnd_Request.Submit_Request(
                                                      'AR',
                                                      'RAXMTR',
                                                      NULL,
                                                      NULL,
                                                      FALSE,
                                                      '1',
                                                      NVL(mo_global.get_current_org_id, -99),
                                                      1021,
                                                      'DD CONVERSION',
                                                      fnd_date.date_to_canonical(trunc(sysdate)),
                                                      '',
                                                      '',
                                                      '',
                                                      '',
                                                      '',
                                                      '',
                                                      '',
                                                      '',
                                                      '',
                                                      '',
                                                      '',
                                                      '',
                                                      '',
                                                      '',
                                                      '',
                                                      '',
                                                      '',
                                                      '',
                                                      '',
                                                      '',
                                                      'Y',
                                                      ''
                                                    );

             IF l_request_id_n = 0 THEN
                 DBMS_OUTPUT.PUT_LINE('ERROR: Unable to Submit Concurrent Request to Load Autoinvoice: '||SQLERRM);
             ELSE
                     COMMIT;
                     l_check_req_b    :=    TRUE;
                     WHILE l_check_req_b
                     LOOP
                       l_call_status_b    :=    Fnd_Concurrent.Get_Request_Status
                                                     (request_id    =>    l_request_id_n
                                                     ,phase         =>    l_rphase_s
                                                     ,status        =>    l_rstatus_s
                                                     ,dev_phase     =>    l_dphase_s
                                                     ,dev_status    =>    l_dstatus_s
                                                     ,message       =>    l_message_s);
                        IF NVL(l_dphase_s, '~') != 'COMPLETE' THEN
                                 dbms_lock.sleep (5);
                        ELSE
                            l_check_req_b    :=    FALSE;
                        END IF;
                     END LOOP;        -- While Loop
            END IF;
           END IF;          
        END LOOP;

  END SWGCNV_AR_PROC_AUTOINVOICE;

END Swgcnv_Ar_Conv_Pkg;
/
SHOW ERRORS;
EXIT;