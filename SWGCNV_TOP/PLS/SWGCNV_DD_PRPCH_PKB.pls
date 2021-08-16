create or replace PACKAGE BODY      Swgcnv_Dd_Prpch_Pkg AS

/* $Header: SWGCNV_DD_PRPCH_PKB.pls  1.1 2010/04/09 09:33:33 PU $ */
/*===========================================================================================+
| Copyright (c) 2005 DS Waters, Atlanta, GA 30328 USA All rights reserved.                   |
+============================================================================================+
|                                                                                            |
| Name:           SWGCNV_DD_PRPCH_PKG                                                        |
|                                                                                            |
| File:           SWGCNV_DD_PRPCH_PKB.pls                                                    |
|                                                                                            |
| Description:    Package For Projected Purchases Headers, Routes and Cycle Days Creation    |
|                                                                                            |
| Company:        DS Waters                                                                  |
| Author:         Unknown                                                                    |
| Date:           Unknown                                                                    |
|                                                                                            |
| Modification History:                                                                      |
| Date            Author           Description                                               |
| ----            ------           -----------                                               |
| Unknown         Unknown          Production Release                                        |
| 04/24/2008      Pankaj Umate     Modified For PURPLM Conversion. Daptiv No: 368            |
| 08/06/2008      Pankaj Umate     Modified For WTRFLX1 Conversion. Daptiv No: 555           |
| 10/23/2008      Pankaj Umate     Modified For RHDIST Maysville Conversion. Daptiv No: 721  |
| 12/09/2008      Pankaj Umate     Modified For ARS03 Conversion. Daptiv No: 753             |
| 04/09/2010      Pankaj Umate     Daptiv # 1471. Conversion Mapping Table Migration         |
| 05/09/2012      Stephen Bowen    Add chk to not move in Rental/Misc Items into Proj Purch  |
| 05/17/2012      Mike Schenk      20129 Make Coffee default service type                    |
| 11/02/2012      Bala Palani      20885 Get will call flag default from customer data file  |
| 11/12/2012      Stephen Bowen    20937 Grab def service from route, ignore ME items for PP |
| 06/25/2013      Bala Palani      21652 Agian Get will_call_flag default from customer data file  |
| 04/06/2014      Mike Schenk      Jira 431 add ship_to's to existing Oracle customer        |
| 08/31/2014      Suganthi Uthaman EB-954 Fix Average Order Calculation Formula              |
| 11/24/2015      Rajesh Mannuru   CCI-1716 Will Call Changes                                |
| 05/18/2016      Sateesh Kumar    EB-1877 Conversion Code Upgrade changes.                  |
| 09/22/2016      Sateesh Kumar    EB-2037 Conversion - Running for Multiple Locations       |
|                                          - Equipment, Avg Order                            |
| 05/03/2017      Stephen Bowen    EB-2310 Modified running for Multiple Locations           |
+===========================================================================================*/

   l_tmp_srvc_tbl            srvc_item_tbl_type;
   l_tmp_srvc_empty_tbl            srvc_item_tbl_type;
   
      TYPE  request_rec_type  IS  RECORD
  ( request_id      NUMBER
   ,sales_center    varchar2(100));
   
       TYPE  request_tbl_type  IS  TABLE OF  request_rec_type
    INDEX BY  BINARY_INTEGER;


-------------------------------------------------------------------------------------------------
--Procedure add and search service
--

PROCEDURE    srch_and_add_srvc(in_srvc_item_id_n    IN    NUMBER)
IS

    l_found_b    BOOLEAN        :=    FALSE;
    l_idx_bi    BINARY_INTEGER;

BEGIN
     FOR  l_idx_bi    IN    1..l_tmp_srvc_tbl.COUNT
     LOOP
          IF l_tmp_srvc_tbl (l_idx_bi)        =    in_srvc_item_id_n    THEN
         l_found_b    :=    TRUE;
         EXIT;
      END IF;
     END LOOP;

    IF NOT    l_found_b    THEN
             l_idx_bi            :=    l_tmp_srvc_tbl.COUNT + 1;
            l_tmp_srvc_tbl (l_idx_bi)    :=    in_srvc_item_id_n;
    END IF;

END    srch_and_add_srvc;

-------------------------------------------------------------------------------------------------
--- Added As  per  EB-2037

 PROCEDURE    Projected_Pchase_multis  (out_errbuf_s          OUT      VARCHAR2
                                       ,out_errnum_n          OUT      NUMBER
                                       ,in_system_name_s       IN      VARCHAR2
                                       ,in_sales_center_s      IN      VARCHAR2
                                       ,in_validate_only_c     IN      VARCHAR2    DEFAULT  'Y'
   )
IS

   l_request_id_n         NUMBER;
   l_request_tbl          request_tbl_type;
   l_request_empty_tbl    request_tbl_type;

   l_idx_bi               BINARY_INTEGER;
   l_check_req_b          BOOLEAN;

   l_call_status_b        BOOLEAN;
   l_rphase_s             VARCHAR2(80);
   l_rstatus_s            VARCHAR2(80);
   l_dphase_s             VARCHAR2(30);
   l_dstatus_s            VARCHAR2(30);
   l_message_s            VARCHAR2(2000);

   ERROR_ENCOUNTERED      EXCEPTION;

CURSOR    cur_cust(in_sales_center_s  varchar2)
IS    --EB-2310
SELECT   unique sales_center 
FROM (
       SELECT   avg.sales_center
       FROM     swgcnv_dd_avrg_order      avg
       UNION
       SELECT   new_sales_center sales_center 
       FROM     swgcnv_dd_temp_customers    a 
     ) b
WHERE    b.sales_center =  nvl( null, b.sales_center )
;

 l_sc_center_s             VARCHAR2(100);
 l_cnt_n                   number;

BEGIN

 out_errbuf_s   :=NULL;
 out_errnum_n   :=0;
 l_cnt_n        :=0;

   IF in_sales_center_s = 'ALL' THEN
      l_sc_center_s :=  NULL;
   ELSE
      l_sc_center_s :=  in_sales_center_s;
   END IF;

   ---------------------------------------------------
   -- Submit the Child Process ( Process by Sales Center )
   ----------------------------------------------------
   l_idx_bi   :=  0;
   l_request_tbl  :=  l_request_empty_tbl;

FOR rec_special in cur_cust(l_sc_center_s) LOOP

l_cnt_n:=l_cnt_n+1;
l_request_id_n  :=  Fnd_Request.Submit_Request
                                ( application =>   'SWGCNV'
                                 ,program     =>   'SWGCNV_BRNCH_PPH'
                                 ,description =>    NULL
                                 ,start_time  =>    NULL
                                 ,sub_request =>    FALSE
                                 ,argument1   =>    in_system_name_s
                                 ,argument2   =>    rec_special.sales_center
                                 ,argument3   =>    in_validate_only_c
                                 );

      IF l_request_id_n = 0 THEN

         out_errbuf_s     :=  'ERROR: Unable to Submit Child DSW Branch Contracts Conversion, Process Sales center: '||rec_special.sales_center;
         out_errnum_n    :=   2;
         RAISE  ERROR_ENCOUNTERED;

      ELSE

         l_idx_bi                                 := l_idx_bi  + 1;
         l_request_tbl(l_idx_bi).request_id       := l_request_id_n;
         l_request_tbl(l_idx_bi).sales_center     := rec_special.sales_center;

     END IF;

 COMMIT;    -- Concurrent Request Commit
END LOOP;

IF l_cnt_n=0 THEN
         out_errbuf_s     :=  'ERROR: Sales Center Does Not Exists in Stageing Table: '||in_sales_center_s;
         out_errnum_n    :=   1;
         RAISE  ERROR_ENCOUNTERED;
END IF;

 ---------------------------------------------------
   -- Check all the child process has been completed
   ----------------------------------------------------
   l_check_req_b  :=  TRUE;

   WHILE l_check_req_b
   LOOP

      FOR l_req_idx_bi  IN  1..l_request_tbl.COUNT
      LOOP

         l_call_status_b  :=  Fnd_Concurrent.Get_Request_Status
                                    (   request_id     =>    l_request_tbl(l_req_idx_bi).request_id
                                       ,phase          =>    l_rphase_s
                                       ,status         =>    l_rstatus_s
                                       ,dev_phase      =>    l_dphase_s
                                       ,dev_status     =>    l_dstatus_s
                                       ,message        =>    l_message_s
                                    );


         IF NVL(l_dphase_s, '~') != 'COMPLETE' THEN
            EXIT;
         END IF;

      END LOOP;

      IF NVL(l_dphase_s, '~') != 'COMPLETE' THEN

         DBMS_LOCK.SLEEP (45);

      ELSE

         l_check_req_b  :=  FALSE;

      END IF;

   END LOOP;    -- While Loop

EXCEPTION
   WHEN ERROR_ENCOUNTERED THEN
      RETURN;
   WHEN OTHERS THEN
      out_errbuf_s     :=  'UNEXPECTED ERROR: '||SQLERRM;
      out_errnum_n    := 2;
      RETURN;

END Projected_Pchase_multis;

----Code Ended as per  EB-2037


-------------------------------------------------------------------------------------------------


PROCEDURE PROJECTED_PCHASE_CONVERT
                                   ( ou_errbuf_s            OUT     VARCHAR2
                                    ,ou_errcode_n           OUT     NUMBER
                                    ,in_system_code         IN      VARCHAR2
                                    ,in_sales_center        IN      VARCHAR2
                                    ,in_validate_only_c     IN      VARCHAR2    DEFAULT 'Y')
IS

    G_SWG_CNV_DD_PREFIX        CONSTANT    VARCHAR2(3)    :=    'DD-';

    CURSOR  Main_Cur
    IS
    SELECT  a.ROWID           row_id,
            i.customer_id     legacy_customer_id,
            a.*
    FROM    swgcnv_dd_temp_customers    a,
            swgcnv_dd_customer_interface    i
    WHERE   a.system_code               =    in_system_code
    AND     a.new_sales_center          =    in_sales_center
    AND     a.cust_import_flag          =    'Y'
    AND     a.proj_pchase_proc_flag     =    'N'
    AND     i.sales_center              =    a.new_sales_center
    AND     i.customer_number           =    a.legacy_customer_number;


    CURSOR  cur_cust ( in_orig_system_customer_ref_s    IN    VARCHAR2   )
    IS
    SELECT   cust.cust_account_id,
             addr.cust_acct_site_id,
             site.site_use_id,
             c.name
    FROM     hz_cust_profile_classes    c
            ,hz_customer_profiles       p
            ,hz_cust_accounts           cust
            ,hz_cust_acct_sites_all     addr
            ,hz_cust_site_uses_all      site
    WHERE   addr.orig_system_reference     =    in_orig_system_customer_ref_s
    AND     cust.cust_account_id           =    addr.cust_account_id
    AND     addr.org_id                    =    2
    AND     addr.cust_acct_site_id         =    site.cust_acct_site_id
    AND     site.site_use_code             =    'SHIP_TO'
    AND     site.org_id                    =    2
    AND     p.cust_account_id              =    cust.cust_account_id
    AND     p.site_use_id                  IS NULL
    AND     c.profile_class_id             =    p.profile_class_id;

    CURSOR  cur_shipto_info (in_customer_id        IN    NUMBER)
    IS
    SELECT  a.route_number,
            a.customer_number,
            a.delivery_location_number,
            a.route_delivery_frequency,
            a.sales_center,
            a.next_regular_deliver_date,
            a.delivery_instructions,
            a.route_message,
            a.ship_to_start_date,
            a.frequency,
            a.customer_id,
            a.shipto_site_id,
            a.billing_site_id,
            a.ship_to_address_id,
            b.bill_to_address_id,
            a.delivery_ticket_print_flag,
            a.will_Call_flag
    FROM    swgcnv_dd_customer_shipto      A
            ,swgcnv_dd_customer_billto     b
    WHERE a.customer_id            = in_customer_id
    AND   b.customer_id            = a.customer_id
    AND   a.billing_site_id        = b.billto_site_id;


    CURSOR  cur_orcl_srvc_type
                               (in_system_code    IN        VARCHAR2,
                               in_route_number    IN        VARCHAR2,
                               in_sales_center    IN        VARCHAR2)
    IS
    SELECT  service_inventory_item
    FROM    swgrtm_route_svc_types
    WHERE   rte_id = ( SELECT  rte_id
                       FROM    swgrtm_routes
                       WHERE   legacy_system   = in_system_code
                       AND     legacy_route_id = in_sales_center||': '||LTRIM(RTRIM(in_route_number)));

    --WO3333
    CURSOR  cur_orcl_srvc_type_default(
                                        in_route_number    IN        VARCHAR2
                                      )
    IS
    SELECT  service_inventory_item
    FROM    swgrtm_route_svc_types t, swgrtm_routes r
    WHERE   t.rte_id       =    r.rte_id
    AND     r.route_number =    in_route_number
    ORDER BY service_inventory_item;
    
    CURSOR cur_avrg_order(    in_customer_number    IN    VARCHAR2,
                              in_delivery_location  IN    VARCHAR2,
                              in_sales_center       IN    VARCHAR2,
                              in_organization_id_n  IN    VARCHAR)
    IS
    SELECT TO_NUMBER (flv.attribute5) srvc_item_id
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type  = 'ITEM_TYPE'
    AND    TO_NUMBER (flv.attribute5) IN (1300, 1302, 1304)
    --Dont consider ME items, no applicable service type  WO20937
    AND    flv.lookup_code  NOT IN ('ME')
    AND    EXISTS ( SELECT /*+ INDEX(avrg,SWGCNV_DD_AVRG_ORDER_N1) */ NULL
                    FROM   swgcnv_dd_avrg_order    avrg
                          ,swgcnv_map              swgmap
                          ,mtl_system_items        msi
                    WHERE flv.lookup_code                  =    msi.item_type
                    AND   msi.segment1                     =    swgmap.new_code
                    AND   msi.organization_id              =   in_organization_id_n
                    --AND SYSDATE BETWEEN NVL (swgmap.effctv_from, SYSDATE - 1) AND NVL (swgmap.effctv_to, SYSDATE + 1)
                    AND   swgmap.system_code               =    in_system_code  
                    --AND NVL (swgmap.old_sub_code_1, in_sales_center) =    avrg.sales_center
                    --AND NVL (swgmap.old_sub_code, 'X')   =    NVL (avrg.item_sub_code, 'X')
                    AND   swgmap.old_code                  =     avrg.item_code                  
                    AND   swgmap.type_code                 =    'ITEM'
                    AND   avrg.valid_flag                  =    'Y'
                    AND   avrg.customer_number             =    in_customer_number
                    AND   avrg.delivery_location_number    =    in_delivery_location
                    AND   avrg.sales_center                =    in_sales_center
                   );

    CURSOR cur_eqpmnt(   in_customer_number    IN    VARCHAR2,
                         in_delivery_location  IN    VARCHAR2,
                         in_sales_center       IN    VARCHAR2,
                         in_organization_id_n  IN    VARCHAR)
    IS
    SELECT TO_NUMBER (flv.attribute5) service_item_id
    FROM  fnd_lookup_values flv
    WHERE flv.lookup_type = 'ITEM_TYPE'
    --Dont consider ME items, no applicable service type  WO20937
    AND   flv.lookup_code  NOT IN ('ME')
    AND   TO_NUMBER (flv.attribute5) IN (1300, 1302, 1304)
    AND   EXISTS ( SELECT /*+ INDEX(eqp,SWGCNV_DD_EQPMNT_INTERFACE_N1) */ NULL
                   FROM   swgcnv_dd_eqpmnt_interface eqp
                         ,swgcnv_map swgmap
                         ,mtl_system_items msi 
                   WHERE msi.item_type                  =    flv.lookup_code
                   AND   msi.segment1                   =    swgmap.new_code
                   AND   msi.organization_id            =   in_organization_id_n
                   AND   swgmap.type_code               =   'ITEM'
                   AND   swgmap.system_code             =   in_system_code
                   AND   swgmap.old_code                =    eqp.model
                   AND   eqp.valid_flag                 =   'Y'
                   AND   eqp.placement_code             =   'RENTED'
                   AND   eqp.customer_number            =   in_customer_number
                   AND   eqp.delivery_location_number   =   in_delivery_location
                   AND   eqp.sales_center               =   in_sales_center
                  );
    --
    -- Variable defination
    --

    l_shipto_info_rec                 cur_shipto_info%ROWTYPE;

    l_orcl_pp_rec                     swgdd.swgrtm_projected_purchases%ROWTYPE;
    l_orcl_pp_route_rec               swgdd.swgrtm_proj_pchase_routes%ROWTYPE;
    l_orcl_pp_item_rec                swgdd.swgrtm_projected_pchase_items%ROWTYPE;
    l_orcl_fdays_rec                  swgdd.swgrtm_contr_line_fdays%ROWTYPE;
    l_orcl_note_rec                   swgdd.swgrtm_notes%ROWTYPE;
    l_orcl_open_hours_rec             swgdd.swgrtm_open_hours%ROWTYPE;

    l_profile_class_s                 ar.hz_cust_profile_classes.name%TYPE;

    l_type_c                          VARCHAR2(1);
    l_diary_status_s                  VARCHAR2(6);
    new_srvc_code                     VARCHAR2(50);
    l_new_code_s                      VARCHAR2(100);
    l_state_s                         VARCHAR2(100);
    l_new_sub_code_s                  VARCHAR2(100);
    l_start_time_s                    VARCHAR2(100);
    l_delivery_instructions_s         VARCHAR2(240);
    l_orig_system_customer_ref_s      VARCHAR2(1000);

    l_totl_recd_read_n                NUMBER    :=    0;
    l_totl_recd_inserted_n            NUMBER    :=    0;
    l_totl_recd_errors_n              NUMBER    :=    0;
    l_pp_written                      NUMBER;
    l_pp_route_written                NUMBER;
    l_contr_written                   NUMBER;
    l_notes_written                   NUMBER   := 0;
    l_open_hours_written              NUMBER;
    l_customer_id_n                   NUMBER;
    l_conversion_userid_n             NUMBER;
    l_deliveries_per_cycle_n          NUMBER;
    l_assigned_day_n                  NUMBER;
    l_day_n                           NUMBER;
    io_pph_id_n                       NUMBER;
    io_ppr_id_n                       NUMBER;
    l_site_id_n                       NUMBER;

    l_default_cycle_id_n              NUMBER  := 1;
    l_cycle_id_n                      NUMBER;
    l_e3w_cycle_id_n                  NUMBER     := 21;

    l_index_bi                        BINARY_INTEGER;
    l_idx_bi                          BINARY_INTEGER;

    l_oracle_cycle_day                NUMBER;
    l_dd_mas_org_id_n                 NUMBER  := Cs_Std.GET_ITEM_VALDN_ORGZN_ID;
    l_route_sales_center              VARCHAR2(4); --Added for ARS02 Abita Conversion 070907
    
    -- RM_JIRA_CCI-1716 Changes Begin
    
    l_status_s    VARCHAR2(150);
    l_message_s   VARCHAR2(2000);
    
    -- RM_JIRA_CCI-1716 Changes End

    ERROR_ENCOUNTERED                 EXCEPTION;

BEGIN

    ou_errbuf_s         :=    NULL;
    ou_errcode_n        :=    0;
    
    --execute immediate 'alter session set events ''10046 trace name context forever, level 12''';

    l_start_time_s    :=    TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS');

    --------------------------------------------------------------------------------
    --check for organization Id and conversion id

    BEGIN
        SELECT   organization_id
         INTO    g_master_organization_id_n
         FROM    org_organization_definitions
         WHERE   organization_code    =    in_sales_center;
    EXCEPTION
        WHEN OTHERS    THEN
            l_error_mesg_s    :=    'Organization Id not defined for: '||in_sales_center ;
            RAISE    ERROR_ENCOUNTERED;
    END;

    Fnd_File.Put_Line(Fnd_File.LOG,'Organization id for '||in_sales_center||': '||g_master_organization_id_n);

    --check for conversion user id

    BEGIN
        SELECT  user_id
        INTO    l_conversion_userid_n
        FROM    fnd_user
        WHERE   user_name    =    'SWGCNV';
    EXCEPTION
        WHEN OTHERS THEN
        l_error_mesg_s    :=    'SWGCNV not defined as an user';
        RAISE    ERROR_ENCOUNTERED;
    END;

    -----------------------------------------------------------------------------

     --main loop

     FOR  main_rec  IN    main_cur
     LOOP

     --shipping loop

     Fnd_File.Put_Line(Fnd_File.LOG,'Oracle Customer Number: '||main_rec.oracle_customer_number);


          FOR l_shipto_info_rec    IN    cur_shipto_info ( main_rec.legacy_customer_id)
          LOOP
          
               BEGIN

                    Fnd_File.Put_Line(Fnd_File.LOG,'Legacy customer number: '||l_shipto_info_rec.customer_number);
                    Fnd_File.Put_Line(Fnd_File.LOG,'Legacy Ship to: '||l_shipto_info_rec.delivery_location_number);

                    ----------------------- Logic for Projected purchase header starts------------------


                    l_tmp_srvc_tbl            :=    l_tmp_srvc_empty_tbl;


                    l_totl_recd_read_n        :=    l_totl_recd_read_n + 1;
                    
                    IF in_system_code  LIKE 'SHIPTO%' THEN  --MTS 431
                       BEGIN
                          SELECT su.orig_system_reference
                          INTO l_orig_system_customer_ref_s
                          FROM   
                             hz_cust_site_uses_all su,
                             hz_cust_acct_sites_all sites    
                          WHERE su.orig_system_reference like 'DD-'||in_system_code||'-'||l_shipto_info_rec.sales_center||'%'||l_shipto_info_rec.delivery_location_number
                          and   su.cust_acct_site_id = sites.cust_acct_site_id
                          AND   sites.cust_account_id = l_shipto_info_rec.customer_id;
                       EXCEPTION WHEN OTHERS THEN
                          l_orig_system_customer_ref_s := NULL;
                       END;
                    ELSE
                       l_orig_system_customer_ref_s    :=     G_SWG_CNV_DD_PREFIX        ||
                                                              main_rec.system_code        || '-' ||
                                                              l_shipto_info_rec.sales_center    || '-' ||
                                                              main_rec.legacy_customer_number || '-' ||
                                                              l_shipto_info_rec.delivery_location_number;
                    END IF;
                                                           
                    Fnd_File.Put_Line(Fnd_File.LOG,'l_orig_system_customer_ref_s:'||l_orig_system_customer_ref_s);

                    --get the Oracle customer and address from oracle

                    OPEN   cur_cust ( l_orig_system_customer_ref_s );
                    FETCH  cur_cust
                    INTO   l_customer_id_n,
                           l_shipto_site_use_id_n,
                           l_site_id_n,
                           l_profile_class_s;

                    IF   cur_cust%NOTFOUND
                    THEN
                         l_orig_system_customer_ref_s     :=  G_SWG_CNV_DD_PREFIX        ||
                                                              main_rec.system_code        || '-' ||
                                                              l_shipto_info_rec.sales_center    || '-' ||
                                                              main_rec.legacy_customer_number || '-' ||
                                                              l_shipto_info_rec.bill_to_address_id ||'-HEADER'; -- 07/20/05 modified to match customer conversion

                         Fnd_File.Put_Line(Fnd_File.LOG,'l_orig_system_customer_ref_s (version 2):'||l_orig_system_customer_ref_s);

                         CLOSE  cur_cust;
                         OPEN   cur_cust ( l_orig_system_customer_ref_s );
                         FETCH  cur_cust
                         INTO   l_customer_id_n,
                                l_shipto_site_use_id_n,
                                l_site_id_n,
                                l_profile_class_s;

                         IF   cur_cust%NOTFOUND
                         THEN
                              l_customer_id_n        := NULL;
                              l_shipto_site_use_id_n    := NULL;
                         END IF;
                         
                    END IF;
                    CLOSE  cur_cust;

                    IF     l_customer_id_n    IS NULL
                    THEN
                              l_error_mesg_s    :=    'Customer Id not found. '||CHR(10) ||
                                                      'Legacy Customer Number: ' ||main_rec.legacy_customer_number;
                              RAISE ERROR_ENCOUNTERED;
                     END IF;

                     IF    l_shipto_site_use_id_n IS NULL
                     THEN
                           l_error_mesg_s    :=    'Ship To Site Id not found. '||CHR(10) ||
                                                   'legacy Customer Number: ' ||main_rec.legacy_customer_number;
                           RAISE ERROR_ENCOUNTERED;
                     END IF;

                     Fnd_File.Put_Line(Fnd_File.LOG,'Oracle Ship to: '||l_site_id_n);

                     --
                     FOR l_cur_avrg_order_rec     IN    cur_avrg_order(l_shipto_info_rec.customer_number  ,
                                                                       l_shipto_info_rec.delivery_location_number,
                                                                       l_shipto_info_rec.sales_center     ,
                                                                       g_master_organization_id_n )
                     LOOP
                      
                         Fnd_File.Put_Line(Fnd_File.LOG,'Service(avrg order): '||l_cur_avrg_order_rec.srvc_item_id);

                         srch_and_add_srvc ( l_cur_avrg_order_rec.srvc_item_id);

                         IF l_tmp_srvc_tbl.COUNT = 3 THEN
                         
                            Fnd_File.Put_Line(Fnd_File.LOG,'tmp srce tbl count = 3 (avrg order)');
                            EXIT;
                         END IF;

                     END LOOP;

                     IF l_tmp_srvc_tbl.COUNT != 3
                     THEN

                           FOR l_cur_eqpmnt_rec    IN    cur_eqpmnt(   l_shipto_info_rec.customer_number  ,
                                                                       l_shipto_info_rec.delivery_location_number,
                                                                       l_shipto_info_rec.sales_center     ,
                                                                       l_dd_mas_org_id_n )
                           LOOP
                           
                             Fnd_File.Put_Line(Fnd_File.LOG,'Service (eqp): '||l_cur_eqpmnt_rec.service_item_id);
                             srch_and_add_srvc ( l_cur_eqpmnt_rec.service_item_id );

                             IF l_tmp_srvc_tbl.COUNT = 3 THEN
                                Fnd_File.Put_Line(Fnd_File.LOG,'tmp srce tbl count = 3 (eqp)');
                                EXIT;
                             END IF;


                           END LOOP;

                     END IF;

                     IF l_tmp_srvc_tbl.COUNT = 0 THEN

                            --Default service driven by route WO3333
                            OPEN  cur_orcl_srvc_type_default ( l_shipto_info_rec.route_number );
                            FETCH cur_orcl_srvc_type_default INTO new_srvc_code;
                            CLOSE cur_orcl_srvc_type_default;

                            IF new_srvc_code IS NULL THEN

                               l_error_mesg_s    :=    'Default Service not found for route: '||
                                                       l_shipto_info_rec.route_number ;
                               RAISE ERROR_ENCOUNTERED;

                            END IF;

                            Fnd_File.Put_Line(Fnd_File.LOG,'tmp srce tbl count = 0, customer getting service '||new_srvc_code);

                            srch_and_add_srvc ( new_srvc_code );

                     END IF;

                     FOR l_idx_bi IN 1..l_tmp_srvc_tbl.COUNT
                     LOOP

                         BEGIN


                           -- Get the mapping for delivery_frequency  from mapping table

                           BEGIN

                              swgcnv_conversion_pkg.swg_map_lookup
                                                                   ( main_rec.system_code
                                                                   ,'DELFREQ'
                                                                   ,UPPER(l_shipto_info_rec.route_delivery_frequency)
                                                                   ,NULL
                                                                   ,l_new_code_s
                                                                   ,l_new_sub_code_s
                                                                   ,NULL);
                              IF       l_new_code_s IS NULL
                              THEN
                                  l_error_mesg_s    :=    'Delivery Frequency not found in Map table: '||
                                                           l_shipto_info_rec.route_delivery_frequency;
                                  RAISE ERROR_ENCOUNTERED;
                              END IF;

                              EXCEPTION
                              WHEN   OTHERS  THEN
                              l_error_mesg_s    :=    'Delivery Frequency not found in Map table: '||
                                                       l_shipto_info_rec.route_delivery_frequency;
                              RAISE ERROR_ENCOUNTERED;
                              END;

                              Fnd_File.Put_Line(Fnd_File.LOG,'delfreq '||l_new_code_s);

                              l_orcl_pp_rec.service_inventory_item    :=      l_tmp_srvc_tbl(l_idx_bi);

                              --EB-1877
                             /* IF l_shipto_info_rec.delivery_ticket_print_flag = 'Y' THEN
                                  l_orcl_pp_rec.ticket_print_flag := 'R';
                              ELSE
                                  l_orcl_pp_rec.ticket_print_flag := 'O';
                              END IF;

                              IF l_profile_class_s IN ('DD RESI HIGH','DD RESI LOW') THEN -- Override SACS value for Residentials
                                  l_orcl_pp_rec.ticket_print_flag := 'O';                 -- Do Not Print ticket
                              END IF;*/   
                              
                              IF l_profile_class_s IN ('DD RESI HIGH','DD RESI LOW') THEN
                              	l_orcl_pp_rec.ticket_print_flag := 'O';  
                              ELSE 
                              	 l_orcl_pp_rec.ticket_print_flag        :=l_shipto_info_rec.delivery_ticket_print_flag;  
 
                            END IF;
 
                              --EB-1877
                              l_orcl_pp_rec.cust_acct_site_id        :=    l_shipto_site_use_id_n;
                              l_orcl_pp_rec.delivered_this_cycle     :=    'Y';
                              l_orcl_pp_rec.start_date_active        :=    TO_CHAR(TO_DATE(NVL(
                                                                                                l_shipto_info_rec.ship_to_start_date,SYSDATE),
                                                                                                'DD-MON-RRRR'),'DD-MON-RRRR');

                              --get the delivery frequency Id and the delivery cycle
                              IF l_new_code_s = 'E3W' THEN
                              
                                 l_cycle_id_n    := l_e3w_cycle_id_n;
                                 
                              ELSIF l_new_code_s = 'E1W' THEN
                              
                                BEGIN

                                      /* PU 04/24/2008

                                      SELECT  cycle_id
                                      INTO    l_cycle_id_n
                                      FROM    swgrtm_routes
                                      WHERE   legacy_system   = main_rec.system_code
                                      AND     legacy_route_id = l_shipto_info_rec.sales_center||': '||LTRIM(RTRIM(l_shipto_info_rec.route_number));

                                      */

                                      -- Added PU 04/24/2008

                                      SELECT cycle_id
                                      INTO   l_cycle_id_n
                                      FROM   swgrtm_routes
                                      WHERE  route_number  =  LTRIM(RTRIM(l_shipto_info_rec.route_number));

                                      -- Added PU 04/24/2008

                                      IF l_cycle_id_n  =  NULL
                                      THEN
                                          l_error_mesg_s    :=    'Error getting route cycle id for an E1W customer based on the route: ' ||
                                                                   l_shipto_info_rec.route_number || CHR(10) || SQLERRM;
                                          RAISE    ERROR_ENCOUNTERED;
                                      END IF;
                                 
                                EXCEPTION
                                WHEN   OTHERS  THEN
                                       l_error_mesg_s        :=    'Error getting route cycle id for an E1W customer based on the route: ' ||
                                                              l_shipto_info_rec.route_number || CHR(10) || SQLERRM;
                                       RAISE    ERROR_ENCOUNTERED;
                                END;
                                
                              ELSE
                              
                                       l_cycle_id_n    := l_default_cycle_id_n;
                                       
                              END IF;

                              BEGIN
                                  SELECT    dfy_id,
                                            deliveries_per_cycle
                                    INTO    l_orcl_pp_rec.dfy_id,
                                            l_deliveries_per_cycle_n
                                    FROM    swgrtm_delivery_frequencies
                                   WHERE    frequency_code         =    l_new_code_s
                                     AND    status                 =    'ACTIVE'
                                     AND    cycle_id               =    l_cycle_id_n;

                               EXCEPTION
                               WHEN OTHERS THEN
                                      l_error_mesg_s    :=    'Error getting Frequency from swgrtm_delivery_frequencies for ' ||
                                                               l_new_code_s || CHR(10) || SQLERRM;
                                      RAISE  ERROR_ENCOUNTERED;
                              END;


                              --New code Added by Ravi for Will call flag as per Liz

                              -- Commneted below code since not applicable for Conversions anymore  
                              -- By Bala Palani for IBM01 Phase-4 (W.O: 20885)
                              /*
                              IF l_orcl_pp_rec.service_inventory_item = '1304' THEN
                                   Fnd_File.Put_Line(Fnd_File.LOG,'Service = 1304 will call flag set to Y');
                                   l_orcl_pp_rec.will_call_flag    := 'Y';

                              ELSIF l_orcl_pp_rec.will_call_flag IS NULL THEN

                                   l_orcl_pp_rec.will_call_flag    := 'N';

                              END IF;

                              */
                              
                              --
                              -- Will_call_flag fix, re-opened the Will_call_flag column to fetch data directly 
                              -- from the swgcnv_dd_customer_shipto table as per WO: 21652
                              --
                              -- Commented below RM_JIRA_CCI-1716 Changes
                              
                              --l_orcl_pp_rec.Will_call_flag      :=    l_shipto_info_rec.Will_call_flag;      -- added by Bala Palani as per WO: 21652
                              l_orcl_pp_rec.Will_call_flag      :=    NULL;  -- Added RM_JIRA_CII-1716 Changes
                              l_orcl_pp_rec.created_by          :=    l_conversion_userid_n;
                              l_orcl_pp_rec.creation_date       :=    SYSDATE;
                              l_orcl_pp_rec.last_updated_by     :=    l_conversion_userid_n;
                              l_orcl_pp_rec.last_update_date    :=    SYSDATE;
                              l_orcl_pp_rec.last_update_login   :=    -1;

                              ---------------------procedure that calls the projected purchase header

                              BEGIN
                                   SELECT    swgrtm_projected_purchases_seq.NEXTVAL
                                     INTO    l_orcl_pp_rec.ppe_id
                                     FROM    DUAL;
                                   
                                   -- RM_JIRA_CCI-1716 Changes Begin    
                                   --Fnd_File.Put_Line(Fnd_File.LOG,' before insert will_call_flag: '||l_orcl_pp_rec.will_call_flag);
                                   Fnd_File.Put_Line(Fnd_File.LOG,' before insert will_call_flag: '||l_shipto_info_rec.Will_call_flag);
                                   -- RM_JIRA_CCI-1716 Changes End
                                   
                                   pp_insert ( l_orcl_pp_rec);
                                   
                                   -- RM_JIRA_CCI-1716 Changes Begin

                                   IF  l_shipto_info_rec.Will_call_flag = 'Y' THEN

                                       l_status_s    :=    NULL;    
                                       l_message_s   :=    NULL;    
                                    
                                       swg_service_holds_pkg.create_on_request_holds ( in_shipto_id_n    =>     NULL    
                                                                                      ,in_ppe_id_n       =>     l_orcl_pp_rec.ppe_id
                                                                                      ,in_force_hold_c   =>     'Y'
                                                                                      ,in_commit_c       =>     'N'
                                                                                      ,ou_status_s       =>     l_status_s
                                                                                      ,ou_message_s      =>     l_message_s
                                                                                     );
                                   

                                   END IF;

                                   -- RM_JIRA_CCI-1716 Changes End                                   

                                   l_pp_written        :=    NVL(l_pp_written,0)    +    1;
                                   
                              EXCEPTION
                              WHEN DUP_VAL_ON_INDEX   THEN
                                            l_error_mesg_s     :=  'Error: Duplicate record';

                                            Fnd_File.Put_Line(Fnd_File.LOG,l_error_mesg_s); -- 2006/03/14 (Jabel): dequoted l_error_mesgs_s
                                            RAISE    ERROR_ENCOUNTERED; -- Added  By Syd on 07/17/07 to handled the duplicated (goto next record)
                              WHEN OTHERS THEN
                                            l_error_mesg_s    :=  'Error Inserting into Projected Purchases: '||SQLERRM;
                                            RAISE    ERROR_ENCOUNTERED;
                              END;

                              --------------------- Logic for Project Purchase Routes Creation ---------------------------

                              SELECT  swgrtm_projected_purchases_seq.CURRVAL
                              INTO    l_orcl_pp_route_rec.ppe_id
                              FROM    DUAL;

                              -- Below sql stmt is for ARS02 Abita conversions fixes to get route sales center on 070907
                              BEGIN
                                    SELECT ltrim(rtrim(substr(LEGACY_ROUTE_ID,1,3))) into l_route_sales_center 
                                      FROM swgrtm_routes
                                     WHERE legacy_system         =    main_rec.system_code
                                       AND ltrim(rtrim(substr(LEGACY_ROUTE_ID,5)))=LTRIM(RTRIM(l_shipto_info_rec.route_number));  
                              EXCEPTION
                              WHEN OTHERS
                              THEN
                                 l_route_sales_center :=l_shipto_info_rec.sales_center;
                              END;
                              
                              -- Above sql stmt is for ARS02 Abita conversions fixes to get route sales center on 070907

                              BEGIN

                                   /* PU 04/24/2008

                                   SELECT     rte_id
                                     INTO     l_orcl_pp_route_rec.rte_id
                                     FROM     swgrtm_routes
                                    WHERE     legacy_system           =    main_rec.system_code
                                      AND     legacy_route_id         =    l_route_sales_center ||': '||LTRIM(RTRIM(l_shipto_info_rec.route_number));
                                    --AND     legacy_route_id         =      l_shipto_info_rec.sales_center||': '||LTRIM(RTRIM(l_shipto_info_rec.route_number)); --Commneted out for ARS02 on 070907

                                   */

                                -- Added PU 04/24/2008

                                SELECT rte_id
                                INTO   l_orcl_pp_route_rec.rte_id
                                FROM   swgrtm_routes
                                WHERE  route_number    =   LTRIM(RTRIM(l_shipto_info_rec.route_number));

                                -- Added PU 04/24/2008

                                IF      l_orcl_pp_route_rec.rte_id  =  NULL
                                THEN
                                      l_error_mesg_s    :=    'Error getting route from legacy route for ' ||
                                                               l_shipto_info_rec.route_number || CHR(10) || SQLERRM;
                                      RAISE    ERROR_ENCOUNTERED;
                                END IF;

                                Fnd_File.Put_Line(Fnd_File.LOG,'Oracle route id: '||l_orcl_pp_route_rec.rte_id);
                                
                              EXCEPTION
                              WHEN   OTHERS  THEN
                                  l_error_mesg_s        :=    'Error getting route from legacy route for ' ||
                                                               l_shipto_info_rec.route_number || CHR(10) || SQLERRM;
                                  RAISE    ERROR_ENCOUNTERED;
                              END;

                              l_orcl_pp_route_rec.start_date_active    :=    TO_CHAR(TO_DATE(NVL(l_shipto_info_rec.ship_to_start_date,SYSDATE),
                                                       'DD-MON-RRRR'),'DD-MON-RRRR');

                              l_orcl_pp_route_rec.end_date_active    :=    NULL;
                              l_orcl_pp_route_rec.created_by         :=    l_conversion_userid_n;
                              l_orcl_pp_route_rec.creation_date      :=    SYSDATE;
                              l_orcl_pp_route_rec.last_updated_by    :=    l_conversion_userid_n;
                              l_orcl_pp_route_rec.last_update_date   :=    SYSDATE;
                              l_orcl_pp_route_rec.last_update_login  :=    -1;

                              BEGIN
                                   SELECT    swgrtm_proj_pur_routes_seq.NEXTVAL
                                   INTO    l_orcl_pp_route_rec.ppr_id
                                   FROM    DUAL;

                                   pp_route_insert ( l_orcl_pp_route_rec);

                                   l_pp_route_written    :=    NVL(l_pp_route_written,0)    +    1;

                             EXCEPTION
                             WHEN OTHERS THEN
                                      l_error_mesg_s    :=  'Error inserting into Projected Purchase Routes: '|| SQLERRM;
                                      RAISE    ERROR_ENCOUNTERED;
                             END;

                              --------------------------- Create the contr. line frequency days -------------------------------

                              IF   l_orcl_pp_rec.dfy_id IS NOT NULL -- AND NVL(l_shipto_info_rec.route_service_day,'0') != '00' Commented for Sacs7 Muthu
                              THEN
                              
                                   FOR i IN      ( SELECT   * 
                                                     FROM   swgcnv_dd_cycledays
                                                    WHERE   customer_id      = l_shipto_info_rec.customer_id
                                                      AND   shipping_site_id = l_shipto_info_rec.shipto_site_id
                                                 )
                                   LOOP
                                   
                                        Fnd_File.Put_Line(Fnd_File.LOG,'Legacy Cycle day: '||i.cycle_day);

                                        SELECT  swgrtm_contr_line_fday_seq.NEXTVAL
                                        INTO    l_orcl_fdays_rec.cld_id
                                        FROM    DUAL;

                                        SELECT    swgrtm_proj_pur_routes_seq.CURRVAL
                                        INTO    l_orcl_fdays_rec.ppr_id
                                        FROM    DUAL;

                                        -- Get the mapping for delivery_frequency  from mapping table

                                        BEGIN
                                        
                                             -- added for SACS7 conversion
                                             swgcnv_conversion_pkg.swg_map_lookup
                                                                                     (p_swg_system_code      => main_rec.system_code
                                                                                     ,p_swg_type_code        => 'STATE'
                                                                                     ,p_swg_old_code         => l_shipto_info_rec.sales_center
                                                                                     ,p_swg_old_sub_code     => NULL
                                                                                     ,r_swg_new_code         => l_new_code_s
                                                                                     ,r_swg_new_sub_code     => l_new_sub_code_s
                                                                                     ,p_txn_date             => NULL);

                                             IF      l_new_code_s IS NULL
                                             THEN
                                                     l_error_mesg_s    :=    'State not found in mapping table for branch: '||
                                                                              l_shipto_info_rec.sales_center;
                                                     RAISE ERROR_ENCOUNTERED;
                                             END IF;

                                             l_state_s       := l_new_code_s;

                                             l_new_code_s    := NULL;

                                             -- Take Route Service Day From Mapping for WTRFLX Conversion. PN 555
                                             
                                             l_new_code_s:= LTRIM(RTRIM(i.cycle_day));   -- WO : 21652  by Bala Palani

                                             /*  commented for  WO : 21652  by Bala Palani
                                             
                                             swgcnv_conversion_pkg.swg_map_lookup
                                                                                     (p_swg_system_code      => main_rec.system_code
                                                                                     ,p_swg_type_code        => 'RTSRVDAY'
                                                                                     ,p_swg_old_code         => LTRIM(RTRIM(i.cycle_day))
                                                                                     ,p_swg_old_sub_code     => l_state_s
                                                                                     ,r_swg_new_code         => l_new_code_s
                                                                                     ,r_swg_new_sub_code     => l_new_sub_code_s
                                                                                     ,p_txn_date             => NULL);

                                             IF       l_new_code_s IS NULL
                                             THEN
                                                     l_error_mesg_s    :=    'Cycle day not found in Map table: '||
                                                     LTRIM(RTRIM(i.cycle_day));
                                                     RAISE ERROR_ENCOUNTERED;
                                             END IF;
                                             */
                                             
                                        EXCEPTION
                                        WHEN   OTHERS  THEN

                                            l_error_mesg_s    :=    'Cycle day not found in Map table: '||LTRIM(RTRIM(i.cycle_day));
                                            RAISE ERROR_ENCOUNTERED;
                                        END;

                                        l_oracle_cycle_day    :=    l_new_code_s;

                                        Fnd_File.Put_Line(Fnd_File.LOG,'Oracle Cycle day: '||l_oracle_cycle_day);


                                        l_orcl_fdays_rec.arrival_time_estimate    :=    SYSDATE;
                                        l_orcl_fdays_rec.cycle_day                :=    l_oracle_cycle_day;
                                        l_orcl_fdays_rec.sequence_number          :=    i.route_sequence;
                                        l_orcl_fdays_rec.start_date_active        :=    TO_CHAR(TO_DATE(NVL(l_shipto_info_rec.ship_to_start_date,SYSDATE),'DD-MON-RRRR'),'DD-MON-RRRR');
                                        l_orcl_fdays_rec.end_date_active          :=    NULL;
                                        l_orcl_fdays_rec.created_by               :=    l_conversion_userid_n;
                                        l_orcl_fdays_rec.creation_date            :=    SYSDATE;
                                        l_orcl_fdays_rec.last_updated_by          :=    l_conversion_userid_n;
                                        l_orcl_fdays_rec.last_update_date         :=    SYSDATE;
                                        l_orcl_fdays_rec.last_update_login        :=    -1;
                                        l_orcl_fdays_rec.cycle_id                 := l_cycle_id_n;


                                        IF NVL(LENGTH(i.driving_instructions),0) <= 500 THEN

                                                l_orcl_fdays_rec.driving_directions   := i.driving_instructions;

                                        ELSE

                                                l_orcl_fdays_rec.driving_directions   := SUBSTR(i.driving_instructions,1,499)||'>';

                                                INSERT INTO swgcnv_driving_instructions
                                                    (cld_id
                                                    ,driving_instructions)
                                                VALUES
                                                    (l_orcl_fdays_rec.cld_id
                                                    ,SUBSTR(i.driving_instructions,60));

                                        END IF;

                                        BEGIN
                                               contr_line_fdays_insert ( l_orcl_fdays_rec );
                                               l_contr_written            :=    NVL(l_contr_written,0)    +    1;
                                        EXCEPTION
                                        WHEN OTHERS THEN
                                                l_error_mesg_s        :=    'Error inserting into Contr Fdays '||SQLERRM;
                                                RAISE    ERROR_ENCOUNTERED;
                                        END;
                                        
                                   END LOOP;

                              END IF;

                              -------------------------- Notes creation -------------------------------

                              -- Check the delivery_instructions value

                              IF l_shipto_info_rec.delivery_instructions IS NOT NULL THEN

                                    SELECT  swgrtm_notes_seq.NEXTVAL
                                    INTO    l_orcl_note_rec.nte_id
                                    FROM    DUAL;

                                    SELECT  swgrtm_projected_purchases_seq.CURRVAL
                                    INTO    l_orcl_note_rec.purchase_id
                                    FROM    DUAL;

                                    l_orcl_note_rec.note_text         :=    l_shipto_info_rec.delivery_instructions;
                                    l_orcl_note_rec.note_type         :=    'MESSAGE';
                                    l_orcl_note_rec.message_type      :=    'DELIVERY';
                                    l_orcl_note_rec.from_date         :=    l_shipto_info_rec.ship_to_start_date;--TO_DATE(l_shipto_info_rec.ship_to_start_date,'DD-MON-RRRR');   --default
                                    l_orcl_note_rec.created_by        :=    l_conversion_userid_n;
                                    l_orcl_note_rec.creation_date     :=    SYSDATE;
                                    l_orcl_note_rec.last_updated_by   :=    l_conversion_userid_n;
                                    l_orcl_note_rec.last_update_date  :=    SYSDATE;
                                    l_orcl_note_rec.last_update_login :=    -1;

                                    BEGIN
                                        INSERT
                                        INTO    swgdd.swgrtm_notes
                                               ( nte_id
                                             ,note_text
                                             ,note_type
                                             ,from_date
                                             ,purchase_id
                                             ,TO_DATE
                                             ,created_by
                                             ,creation_date
                                             ,last_updated_by
                                             ,last_update_date
                                             ,last_update_login
                                             ,message_type
                                               )
                                        VALUES
                                               ( l_orcl_note_rec.nte_id
                                             ,l_orcl_note_rec.note_text
                                             ,l_orcl_note_rec.note_type
                                             ,l_orcl_note_rec.from_date
                                             ,l_orcl_note_rec.purchase_id
                                             ,NULL
                                             ,l_orcl_note_rec.created_by
                                             ,l_orcl_note_rec.creation_date
                                             ,l_orcl_note_rec.last_updated_by
                                             ,l_orcl_note_rec.last_update_date
                                             ,l_orcl_note_rec.last_update_login
                                             ,l_orcl_note_rec.message_type
                                              );

                                        l_notes_written        :=    NVL(l_notes_written,0)    +    1;
                                        
                                    EXCEPTION
                                    WHEN  OTHERS  THEN
                                            Fnd_File.Put_Line(Fnd_File.LOG,'In the exception block of NOTES '||SQLERRM);
                                            l_error_mesg_s    :=    'Error inserting into swgrtm_notes delivery instructions' || CHR(10) ||SQLERRM;
                                            RAISE    ERROR_ENCOUNTERED;
                                    END;

                              END IF; -- l_shipto_info_rec.delivery_instructions

                              -- Check the route message value

                              IF l_shipto_info_rec.route_message IS NOT NULL THEN

                                    SELECT  swgrtm_notes_seq.NEXTVAL
                                    INTO    l_orcl_note_rec.nte_id
                                    FROM    DUAL;

                                    SELECT  swgrtm_projected_purchases_seq.CURRVAL
                                    INTO    l_orcl_note_rec.purchase_id
                                    FROM    DUAL;

                                    -- 2005/11/21 (Jabel D. Morales): changed message type from 'DELIVERY' to 'SERVICE'
                                    -- OPS10 issue 7
                                    l_orcl_note_rec.note_text      :=    l_shipto_info_rec.route_message;
                                        l_orcl_note_rec.note_type      :=    'MESSAGE';
                                        l_orcl_note_rec.message_type      :=    'SERVICE';  -- 2005/11/21 (Jabel D. Morales)
                                        l_orcl_note_rec.from_date      :=    l_shipto_info_rec.ship_to_start_date;--TO_DATE(l_shipto_info_rec.ship_to_start_date,'DD-MON-RRRR');   --default
                                        l_orcl_note_rec.created_by      :=    l_conversion_userid_n;
                                        l_orcl_note_rec.creation_date      :=    SYSDATE;
                                        l_orcl_note_rec.last_updated_by      :=    l_conversion_userid_n;
                                        l_orcl_note_rec.last_update_date  :=    SYSDATE;
                                        l_orcl_note_rec.last_update_login :=    -1;

                                    BEGIN
                                        INSERT
                                        INTO    swgdd.swgrtm_notes
                                               ( nte_id
                                             ,note_text
                                             ,note_type
                                             ,from_date
                                             ,purchase_id
                                             ,TO_DATE
                                             ,created_by
                                             ,creation_date
                                             ,last_updated_by
                                             ,last_update_date
                                             ,last_update_login
                                             ,message_type
                                               )
                                        VALUES
                                               ( l_orcl_note_rec.nte_id
                                             ,l_orcl_note_rec.note_text
                                             ,l_orcl_note_rec.note_type
                                             ,l_orcl_note_rec.from_date
                                             ,l_orcl_note_rec.purchase_id
                                             ,NULL
                                             ,l_orcl_note_rec.created_by
                                             ,l_orcl_note_rec.creation_date
                                             ,l_orcl_note_rec.last_updated_by
                                             ,l_orcl_note_rec.last_update_date
                                             ,l_orcl_note_rec.last_update_login
                                             ,l_orcl_note_rec.message_type
                                              );

                                        l_notes_written        :=    NVL(l_notes_written,0)    +    1;
                                        
                                    EXCEPTION
                                    WHEN  OTHERS  THEN
                                            Fnd_File.Put_Line(Fnd_File.LOG,'In the exception block of NOTES '||SQLERRM);
                                            l_error_mesg_s    :=    'Error inserting into swgrtm_notes route message' || CHR(10) ||SQLERRM;
                                             RAISE    ERROR_ENCOUNTERED;
                                    END;

                              END IF; -- l_shipto_info_rec.route_message


                              ------------------Update the temp tables with process flag set to 'Y' ------------------------------------

                              UPDATE   swgcnv_dd_temp_customers
                              SET         proj_pchase_proc_flag    =    'Y'
                              WHERE    ROWID            =    main_rec.row_id;

                              IF in_validate_only_c != 'Y' THEN
                                    COMMIT;
                              ELSE
                                    ROLLBACK;
                              END IF;

                              l_totl_recd_inserted_n        :=    l_totl_recd_inserted_n    +    1;

                              ---------------------------------------------------------------------------------

                              ------------> start the PPH process

                           EXCEPTION
                           WHEN    NO_DATA_FOUND     THEN

                              ou_errcode_n    := 1;
                              Fnd_File.Put_Line(Fnd_File.LOG,'NO_DATA_FOUND: '||l_error_mesg_s);
                              ROLLBACK;
                              l_totl_recd_errors_n    :=    l_totl_recd_errors_n    +    1;
                              
                              INSERT
                              INTO     swgcnv_conversion_exceptions
                                        ( conversion_type
                                        ,conversion_key_value
                                        ,conversion_sub_key1
                                        ,error_message
                                        ,conversion_sub_key2
                                        )
                              VALUES   ('PCHASE'
                                        ,main_rec.legacy_customer_number
                                        ,l_shipto_info_rec.delivery_location_number
                                        ,l_error_mesg_s
                                        ,main_rec.new_sales_center
                                         );
                              COMMIT;

                              WHEN     ERROR_ENCOUNTERED     THEN

                                ou_errcode_n    := 1;

                                ROLLBACK;

                                Fnd_File.Put_Line(Fnd_File.LOG,'ERROR_ENCOUNTERED: '||l_error_mesg_s);
                                
                                l_totl_recd_errors_n    :=    l_totl_recd_errors_n    +    1;
                                
                                INSERT
                                INTO    swgcnv_conversion_exceptions
                                        ( conversion_type
                                        ,conversion_key_value
                                        ,conversion_sub_key1
                                        ,error_message
                                        ,conversion_sub_key2
                                        )
                                VALUES( 'PCHASE'
                                        ,main_rec.legacy_customer_number
                                        ,l_shipto_info_rec.delivery_location_number
                                        ,l_error_mesg_s
                                        ,main_rec.new_sales_center
                                        );
                                COMMIT;

                              WHEN     OTHERS     THEN

                                ou_errcode_n    := 2;

                                ROLLBACK;
                                l_totl_recd_errors_n    :=    l_totl_recd_errors_n    +    1;
                                l_error_mesg_s        :=    l_error_mesg_s || SQLERRM;
                                Fnd_File.Put_Line(Fnd_File.LOG,'UNEXPECTED ERROR: '||l_error_mesg_s);
                                
                                INSERT
                                INTO  swgcnv_conversion_exceptions
                                        ( conversion_type
                                        ,conversion_key_value
                                        ,conversion_sub_key1
                                        ,error_message
                                        ,conversion_sub_key2
                                        )
                                VALUES( 'PCHASE'
                                        ,main_rec.legacy_customer_number
                                        ,l_shipto_info_rec.delivery_location_number
                                        ,l_error_mesg_s
                                        ,main_rec.new_sales_center
                                        );
                                COMMIT;

                           END;

               END LOOP;                  -- this is end loop for pl/sql table

               -------------------------


               EXCEPTION
               WHEN     ERROR_ENCOUNTERED     THEN

                 ou_errcode_n    := 1;
                 Fnd_File.Put_Line(Fnd_File.LOG,'ERROR_ENCOUNTERED: '||l_error_mesg_s);
                 ROLLBACK;
                 l_totl_recd_errors_n    :=    l_totl_recd_errors_n    +    1;
                 
                 INSERT
                 INTO    swgcnv_conversion_exceptions
                        ( conversion_type
                       ,conversion_key_value
                       ,conversion_sub_key1
                       ,error_message
                        ,conversion_sub_key2
                        )
                 VALUES( 'PCHASE'
                       ,main_rec.legacy_customer_number
                       ,l_shipto_info_rec.delivery_location_number
                       ,l_error_mesg_s
                     ,main_rec.new_sales_center
                        );
                 COMMIT;

               WHEN     OTHERS     THEN

                 ou_errcode_n    := 2;

                 ROLLBACK;
                 l_totl_recd_errors_n    :=    l_totl_recd_errors_n    +    1;
                 l_error_mesg_s        :=    l_error_mesg_s || SQLERRM;

                 Fnd_File.Put_Line(Fnd_File.LOG,'UNEXPECTED ERROR: '||l_error_mesg_s);
                 
                 INSERT
                 INTO  swgcnv_conversion_exceptions
                        ( conversion_type
                       ,conversion_key_value
                       ,conversion_sub_key1
                       ,error_message
                        ,conversion_sub_key2
                        )
                 VALUES( 'PCHASE'
                       ,main_rec.legacy_customer_number
                       ,l_shipto_info_rec.delivery_location_number
                       ,l_error_mesg_s
                      ,main_rec.new_sales_center
                        );
                 COMMIT;
                 
                END;

          END LOOP;              --end loop for shipto cursor

        ------------------------

     END LOOP;                   --end loop for main cursor


    -----------------------------  Display output the result set ----------------------------------

   Fnd_File.Put_Line(Fnd_File.OUTPUT,'                                                                      ');
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'                                                                      ');
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'*---------------------------------------------------------------------*');
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'Records read                                   : ' || l_Totl_Recd_Read_n);
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'Records inserted in projected purchases        : ' || l_pp_written);
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'Records inserted in projected purchases route  : ' || l_pp_route_written);
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'Records inserted in contr line frequency days  : ' || l_contr_written     );
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'Records inserted in notes            : ' || l_notes_written     );
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'Records in error                   : ' || l_Totl_Recd_Errors_n);
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'*---------------------------------------------------------------------*');
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'Start Time                         : ' || l_Start_Time_s);
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'End Time                           : ' || TO_CHAR(SYSDATE, 'DD-MON-RRRR HH24:MI:SS'));

END    PROJECTED_PCHASE_CONVERT;

-------------------------- End of procedure projected purchase convert -----------------------
----
----Individual Procedures
----


PROCEDURE    pp_insert
( in_orcl_pp_rec    IN    swgrtm_projected_purchases%ROWTYPE
 )
IS
    BEGIN


    INSERT
    INTO   swgrtm_projected_purchases
        ( ppe_id
         ,cust_acct_site_id
         ,service_inventory_item
         ,dfy_id
         ,next_regular_deliver_date
         ,will_call_flag
         ,delivered_this_cycle
         ,created_by
         ,creation_date
         ,last_updated_by
         ,last_update_date
         ,last_update_login
         ,start_date_active
         ,ticket_print_flag
        )
    VALUES
        ( in_orcl_pp_rec.ppe_id
         ,in_orcl_pp_rec.cust_acct_site_id
         ,in_orcl_pp_rec.service_inventory_item
         ,in_orcl_pp_rec.dfy_id
         ,in_orcl_pp_rec.next_regular_deliver_date
         ,in_orcl_pp_rec.will_call_flag
         ,in_orcl_pp_rec.delivered_this_cycle
         ,in_orcl_pp_rec.created_by
         ,in_orcl_pp_rec.creation_date
         ,in_orcl_pp_rec.last_updated_by
         ,in_orcl_pp_rec.last_update_date
         ,in_orcl_pp_rec.last_update_login
         ,in_orcl_pp_rec.start_date_active
         ,in_orcl_pp_rec.ticket_print_flag
        );
END    pp_insert;

--------------------------------------------------------------------------------------

PROCEDURE    pp_route_insert
( in_orcl_pp_route_rec    IN    swgrtm_proj_pchase_routes%ROWTYPE
)
IS

    BEGIN

    INSERT
    INTO    swgrtm_proj_pchase_routes
        ( ppr_id
         ,ppe_id
         ,rte_id
         ,start_date_active
         ,end_date_active
         ,created_by
         ,creation_date
         ,last_updated_by
         ,last_update_date
         ,last_update_login
        )
    VALUES
        ( in_orcl_pp_route_rec.ppr_id
         ,in_orcl_pp_route_rec.ppe_id
         ,in_orcl_pp_route_rec.rte_id
         ,in_orcl_pp_route_rec.start_date_active
         ,in_orcl_pp_route_rec.end_date_active
         ,in_orcl_pp_route_rec.created_by
         ,in_orcl_pp_route_rec.creation_date
         ,in_orcl_pp_route_rec.last_updated_by
         ,in_orcl_pp_route_rec.last_update_date
         ,in_orcl_pp_route_rec.last_update_login
        );
END    pp_route_insert;

--------------------------------------------------------------------------------------

PROCEDURE    contr_line_fdays_insert
( in_orcl_contr_fdays_rec    IN    swgrtm_contr_line_fdays%ROWTYPE
)
IS
    BEGIN

    INSERT
    INTO    swgrtm_contr_line_fdays
        ( cld_id
         ,ppr_id
         ,arrival_time_estimate
         ,cycle_day
         ,sequence_number
         ,start_date_active
         ,end_date_active
         ,created_by
         ,creation_date
         ,last_updated_by
         ,last_update_date
         ,last_update_login
        ,cycle_id
        ,driving_directions)
    VALUES
        ( in_orcl_contr_fdays_rec.cld_id
         ,in_orcl_contr_fdays_rec.ppr_id
         ,in_orcl_contr_fdays_rec.arrival_time_estimate
         ,in_orcl_contr_fdays_rec.cycle_day
         ,in_orcl_contr_fdays_rec.sequence_number
         ,in_orcl_contr_fdays_rec.start_date_active
         ,in_orcl_contr_fdays_rec.end_date_active
         ,in_orcl_contr_fdays_rec.created_by
         ,in_orcl_contr_fdays_rec.creation_date
         ,in_orcl_contr_fdays_rec.last_updated_by
         ,in_orcl_contr_fdays_rec.last_update_date
         ,in_orcl_contr_fdays_rec.last_update_login
        ,in_orcl_contr_fdays_rec.cycle_id
        ,in_orcl_contr_fdays_rec.driving_directions);

END    contr_line_fdays_insert;

-------------------------------------------------------------------------------------------------
--- Added As  per  EB-2037

 PROCEDURE    SWGCNV_DD_PPIT_PKG_MULTIS  (out_errbuf_s            OUT      VARCHAR2
                                     ,out_errnum_n           OUT      NUMBER
                                     ,in_system_name_s       IN      VARCHAR2
                                     ,in_sales_center_s      IN       VARCHAR2
                                     ,in_validate_only_c     IN       VARCHAR2    DEFAULT  'Y'
   )
IS

   l_request_id_n         NUMBER;
   l_request_tbl          request_tbl_type;
   l_request_empty_tbl    request_tbl_type;

   l_idx_bi               BINARY_INTEGER;
   l_check_req_b          BOOLEAN;

   l_call_status_b        BOOLEAN;
   l_rphase_s             VARCHAR2(80);
   l_rstatus_s            VARCHAR2(80);
   l_dphase_s             VARCHAR2(30);
   l_dstatus_s            VARCHAR2(30);
   l_message_s            VARCHAR2(2000);

   ERROR_ENCOUNTERED      EXCEPTION;

CURSOR    cur_cust(in_sales_center_s  varchar2)
IS
SELECT   unique avg.sales_center
FROM     swgcnv_dd_avrg_order      avg
where avg.sales_center =  NVL( in_sales_center_s, avg.sales_center ) ;


 l_sc_center_s             VARCHAR2(100);
 l_cnt_n                   number;

BEGIN

 out_errbuf_s   :=NULL;
 out_errnum_n   :=0;
 l_cnt_n:=0;

   IF in_sales_center_s = 'ALL' THEN
      l_sc_center_s :=  NULL;
   ELSE
      l_sc_center_s :=  in_sales_center_s;
   END IF;

   ---------------------------------------------------
   -- Submit the Child Process ( Process by Sales Center )
   ----------------------------------------------------
   l_idx_bi   :=  0;
   l_request_tbl  :=  l_request_empty_tbl;

FOR rec_special in cur_cust(l_sc_center_s) LOOP

l_cnt_n:=l_cnt_n+1;
l_request_id_n  :=  Fnd_Request.Submit_Request
                                ( application =>   'SWGCNV'
                                 ,program     =>   'SWGCNV_BRNCH_PPI'
                                 ,description =>    NULL
                                 ,start_time  =>    NULL
                                 ,sub_request =>    FALSE
                                 ,argument1   =>    in_system_name_s
                                 ,argument2   =>    rec_special.sales_center
                                 ,argument3   =>    in_validate_only_c
                                 );

      IF l_request_id_n = 0 THEN

         out_errbuf_s     :=  'ERROR: Unable to Submit Child DSW Branch Contracts Conversion, Process Sales center: '||rec_special.sales_center;
         out_errnum_n    :=   2;
         RAISE  ERROR_ENCOUNTERED;

      ELSE

         l_idx_bi                                 := l_idx_bi  + 1;
         l_request_tbl(l_idx_bi).request_id       := l_request_id_n;
         l_request_tbl(l_idx_bi).sales_center     := rec_special.sales_center;

     END IF;

 COMMIT;    -- Concurrent Request Commit
END LOOP;

IF l_cnt_n=0 THEN
         out_errbuf_s     :=  'ERROR: Sales Center Does Not Exists in Stageing Table: '||in_sales_center_s;
         out_errnum_n    :=   1;
         RAISE  ERROR_ENCOUNTERED;
END IF;

 ---------------------------------------------------
   -- Check all the child process has been completed
   ----------------------------------------------------
   l_check_req_b  :=  TRUE;

   WHILE l_check_req_b
   LOOP

      FOR l_req_idx_bi  IN  1..l_request_tbl.COUNT
      LOOP

         l_call_status_b  :=  Fnd_Concurrent.Get_Request_Status
                                    (   request_id     =>    l_request_tbl(l_req_idx_bi).request_id
                                       ,phase          =>    l_rphase_s
                                       ,status         =>    l_rstatus_s
                                       ,dev_phase      =>    l_dphase_s
                                       ,dev_status     =>    l_dstatus_s
                                       ,message        =>    l_message_s
                                    );


         IF NVL(l_dphase_s, '~') != 'COMPLETE' THEN
            EXIT;
         END IF;

      END LOOP;

      IF NVL(l_dphase_s, '~') != 'COMPLETE' THEN

         DBMS_LOCK.SLEEP (45);

      ELSE

         l_check_req_b  :=  FALSE;

      END IF;

   END LOOP;    -- While Loop

EXCEPTION
   WHEN ERROR_ENCOUNTERED THEN
      RETURN;
   WHEN OTHERS THEN
      out_errbuf_s     :=  'UNEXPECTED ERROR: '||SQLERRM;
      out_errnum_n    := 2;
      RETURN;

END SWGCNV_DD_PPIT_PKG_MULTIS;

----Code Ended as per  EB-2037


-------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
--
--
-- Procedure for PPI
-----------------------------------------------------------------------------

PROCEDURE SWGCNV_DD_PPIT_PKG
(
 ou_errbuf_s            OUT        VARCHAR2
,ou_errcode_n            OUT        NUMBER
,in_system_code            IN      VARCHAR2
,in_sales_center        IN        VARCHAR2
,in_validate_only_c        IN        VARCHAR2    DEFAULT 'Y')

IS

    G_SWG_CNV_DD_PREFIX        CONSTANT    VARCHAR2(3)    :=    'DD-';

    CURSOR  Main_Cur
    IS
    SELECT  a.ROWID     row_id
    , a.*
    FROM    swgcnv_dd_temp_customers    a
    WHERE   a.system_code            =    in_system_code
    AND     a.new_sales_center        =     in_sales_center
    AND     a.cust_import_flag        =    'Y'
    AND     a.proj_pchase_proc_flag        =    'Y'    --04/17/03 added
    AND     a.proj_pchase_item_proc_flag        =    'N';

    CURSOR cur_pchase_item( in_customer_number_n    IN VARCHAR2)
    IS
    SELECT  s.ship_to_address_id,o.*
    FROM swgcnv_dd_avrg_order         o
    ,swgcnv_dd_customer_shipto    s
    WHERE s.customer_number        = in_customer_number_n
    AND o.customer_number        = s.customer_number
    AND o.customer_number        = in_customer_number_n
    AND o.delivery_location_number    = s.delivery_location_number
    AND o.sales_center        = s.sales_center
    AND o.valid_flag            =       'Y';

    CURSOR cur_distinct_item
    IS
    SELECT  DISTINCT o.item_code, o.item_sub_code, o.sales_center
    FROM    swgcnv_dd_avrg_order         o;

    CURSOR cur_ppe_info(in_cust_acct_site_id IN NUMBER)
    IS
    SELECT ppe_id,service_inventory_item
    FROM swgrtm_projected_purchases
    WHERE cust_acct_site_id            = in_cust_acct_site_id
    ORDER BY 2;

    l_cust_acct_site_id     NUMBER;


    TYPE distinct_item_rec_type       IS RECORD
        (inventory_item_id   NUMBER
     ,attribute5         VARCHAR2(100));

    TYPE distinct_item_tbl_type IS TABLE OF distinct_item_rec_type
    INDEX BY VARCHAR2(100);

    g_distinct_item_tbl_type        distinct_item_tbl_type;


--declaration of variables

    cur_pchase_item_rec        cur_pchase_item%ROWTYPE;




    l_totl_recd_read_n                NUMBER    :=    0;
    l_totl_recd_inserted_n            NUMBER    :=    0;
    l_totl_recd_errors_n            NUMBER    :=    0;

    l_ppe_id_n                    NUMBER;
    attri5                    NUMBER;
    l_conversion_userid_n            NUMBER;
    l_pitem_id                    NUMBER;
    l_sitem_id                    NUMBER;
    g_master_organization_id_n          NUMBER;
    l_site_use_id_n                     NUMBER;

    l_status_c                    VARCHAR2(1);
    l_start_time_s                    VARCHAR2(30);
    l_item_id_n                        VARCHAR2(100);
    l_new_code_s                    VARCHAR2(100);
    l_new_sub_code_s                    VARCHAR2(100);
    l_orig_system_customer_ref_s            VARCHAR2(240);
    l_error_mesg_s                    VARCHAR2(2000);
    l_addr_ref                         VARCHAR2(1000);

    l_no_ppe                        VARCHAR2(1);
    l_item_rec              Swgcnv_Cntrct_Vldt.item_info_rec_type;
    l_org_rec               Swgcnv_Cntrct_Vldt.org_info_rec_type;

    ERROR_ENCOUNTERED                EXCEPTION;

BEGIN

    ou_errbuf_s            :=    NULL;
    ou_errcode_n        :=    0;
    l_start_time_s        :=    TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS');

--------------------------check for user name

    BEGIN
    SELECT    user_id
    INTO    l_conversion_userid_n
    FROM    fnd_user
    WHERE    user_name    =    'SWGCNV';
       EXCEPTION
    WHEN OTHERS THEN
        Fnd_File.Put_Line(Fnd_File.LOG,'SWGCNV user name not define.');
        ou_errcode_n    := 2;
        RETURN;
    END;

    BEGIN
     SELECT    organization_id
        INTO    g_master_organization_id_n
        FROM    org_organization_definitions
        WHERE    organization_code    =    in_sales_center;
    EXCEPTION
    WHEN OTHERS    THEN
        l_error_mesg_s    :=    'Organization Id not defined for: ||in_sales_center' ;
           RAISE    ERROR_ENCOUNTERED;
    END;

---------------------------

    FOR cur_distinct_item_rec IN cur_distinct_item LOOP

       l_error_mesg_s := NULL;
           l_new_code_s      := NULL;


           Swgcnv_Cntrct_Vldt.Get_Maps_And_Details
           ( in_sacs_org_s                 => cur_distinct_item_rec.sales_center
           ,in_sacs_brand_s            => cur_distinct_item_rec.item_sub_code
           ,in_sacs_item_s            => LTRIM(RTRIM(cur_distinct_item_rec.item_code))
           ,in_eff_date_d            => TRUNC(SYSDATE)
           ,io_item_rec                => l_item_rec
           ,io_org_rec                => l_org_rec
           ,io_status_c                => l_status_c
           ,io_message_s            => l_error_mesg_s
           ,in_debug_c                => Swgcnv_Cntrct_Vldt.G_DEBUG
           -- ,in_system_code_c                => 'SACS'); -- in_system_code hardcoded for SACS7 Muthu
           ,in_system_code_c                => in_system_code); -- in_system_code hardcoded for SACS7 Muthu -- 2006/03/09 Jabel

            IF l_status_c != Swgcnv_Cntrct_Vldt.G_STS_SUCCESS THEN
               -- l_error_mesg_s    :=    'SACS -'||LTRIM(RTRIM(cur_distinct_item_rec.item_code)) -- Commented on 02/27/07 by Ashok
               --                         || 'Error returned from Get_Maps_And_Details: '
               --                         || l_error_mesg_s;

                l_error_mesg_s    :=    in_system_code||'-'||LTRIM(RTRIM(cur_distinct_item_rec.item_code))
                                        || 'Error returned from Get_Maps_And_Details: '
                                        || l_error_mesg_s;
        Fnd_File.Put_Line(Fnd_File.LOG, l_error_mesg_s);
        ELSE

                l_new_code_s    :=  l_item_rec.item_code;
        Fnd_File.Put_Line(Fnd_File.LOG,'new item code  '||l_new_code_s );

               BEGIN
           SELECT msi.inventory_item_id
              ,TO_NUMBER(flv.attribute5)
             INTO g_distinct_item_tbl_type(cur_distinct_item_rec.item_code||cur_distinct_item_rec.item_sub_code||cur_distinct_item_rec.sales_center).inventory_item_id
              ,g_distinct_item_tbl_type(cur_distinct_item_rec.item_code||cur_distinct_item_rec.item_sub_code||cur_distinct_item_rec.sales_center).attribute5
                  FROM fnd_lookup_values     flv,
                   mtl_system_items         msi,
              org_organization_definitions org
                   WHERE flv.lookup_type       =     'ITEM_TYPE'
                     AND flv.lookup_code        =     msi.item_type
              AND msi.segment1          =     l_new_code_s
                  AND msi.organization_id   =     org.organization_id
          AND org.organization_code =     cur_distinct_item_rec.sales_center;
               EXCEPTION
               WHEN OTHERS THEN
                    l_error_mesg_s    :=    'Item type error : Oracle Item Code -'||l_new_code_s;
            Fnd_File.Put_Line(Fnd_File.LOG, l_error_mesg_s);
               END;
            END IF;

    END LOOP;

    FOR  main_rec  IN    main_cur    -- main Loop
    LOOP

      Fnd_File.Put_Line(Fnd_File.LOG,'Oracle Customer Number: '|| main_rec.oracle_customer_number);
      Fnd_File.Put_Line(Fnd_File.LOG,'Legacy Customer Number: '|| main_rec.legacy_customer_number);

      FOR cur_pchase_item_rec IN cur_pchase_item(main_rec.legacy_customer_number)
      LOOP
      BEGIN     -- for legacy loop
      l_error_mesg_s := NULL;

          Fnd_File.Put_Line(Fnd_File.LOG,'Legacy Delivery Location: '||cur_pchase_item_rec.delivery_location_number);
          Fnd_File.Put_Line(Fnd_File.LOG,'legacy item code '||cur_pchase_item_rec.item_code );

          l_totl_recd_read_n        :=    l_totl_recd_read_n + 1;

          l_orig_system_customer_ref_s    :=    G_SWG_CNV_DD_PREFIX        ||
                         main_rec.system_code        || '-' ||
                        cur_pchase_item_rec.sales_center    || '-' ||
                        main_rec.legacy_customer_number; 
                                    /*
                                      || '-' ||
                            LPAD(to_char(cur_pchase_item_rec.ship_to_address_id),9,'0');  -- added on 7/21/05 Kim
                                    */ -- Commented out by Ashok on 03/02/07

          Fnd_File.Put_Line(Fnd_File.LOG,'l_orig_system_customer_ref_s: '||l_orig_system_customer_ref_s);

       IF g_distinct_item_tbl_type.EXISTS(cur_pchase_item_rec.item_code||cur_pchase_item_rec.item_sub_code||cur_pchase_item_rec.sales_center) THEN
          l_item_id_n := g_distinct_item_tbl_type(cur_pchase_item_rec.item_code||cur_pchase_item_rec.item_sub_code||cur_pchase_item_rec.sales_center).inventory_item_id;
          attri5 := g_distinct_item_tbl_type(cur_pchase_item_rec.item_code||cur_pchase_item_rec.item_sub_code||cur_pchase_item_rec.sales_center).attribute5;
       ELSE
          l_error_mesg_s := 'legacy item code '||cur_pchase_item_rec.item_code
                                ||' - Item Mapping does not exists' ;
              Fnd_File.Put_Line(Fnd_File.LOG,l_error_mesg_s );
          RAISE ERROR_ENCOUNTERED;
       END IF;

        l_no_ppe    := 'N';

      BEGIN
          l_addr_ref    :=    l_orig_system_customer_ref_s||'-'||cur_pchase_item_rec.delivery_location_number; -- Last part added by Ashok on 03/02/07
          Fnd_File.Put_Line(Fnd_File.LOG, 'l_orig_system_addr_ref_s (second): '||l_addr_ref);
          SELECT     ppe_id
            ,site.site_use_id
        INTO     l_ppe_id_n
            ,l_site_use_id_n
        FROM     swgrtm_projected_purchases    pp
            , hz_cust_acct_sites              addr
            , hz_cust_site_uses        site
           WHERE     pp.cust_acct_site_id          =     addr.cust_acct_site_id
         AND       addr.orig_system_reference      =    l_addr_ref
         AND    addr.cust_acct_site_id      =    site.cust_acct_site_id
         AND    site.site_use_code        =    'SHIP_TO'
         AND       pp.service_inventory_item       =       attri5;

              Fnd_File.Put_Line(Fnd_File.LOG,'Oracle Ship to: '||l_site_use_id_n);
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
          Fnd_File.Put_Line(Fnd_File.LOG,'no projected purchase header Id FOUND');
          BEGIN
             l_addr_ref    :=    G_SWG_CNV_DD_PREFIX        ||
                         main_rec.system_code        || '-' ||
                        cur_pchase_item_rec.sales_center    || '-' ||
                        main_rec.legacy_customer_number || '-' ||
                            to_char(cur_pchase_item_rec.ship_to_address_id) ||'-HEADER';
             SELECT ppe_id
           INTO l_ppe_id_n
           FROM swgrtm_projected_purchases    pp
              , hz_cust_acct_sites       addr
              , hz_cust_site_uses    site
              WHERE   pp.cust_acct_site_id  = addr.cust_acct_site_id
                AND   addr.orig_system_reference    =    l_addr_ref
            AND   addr.cust_acct_site_id        =    site.cust_acct_site_id
            AND   site.site_use_code         =    'SHIP_TO'
            AND   pp.service_inventory_item     =  attri5;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
             l_ppe_id_n := NULL;
             l_no_ppe := 'Y';
              END;
       END;

                IF l_no_ppe = 'Y' THEN
                -- Get the cust_acct_site_id
                BEGIN
                l_addr_ref    :=    l_orig_system_customer_ref_s||'-'||cur_pchase_item_rec.delivery_location_number; -- Last part added by Ashok on 03/02/07

                SELECT     addr.cust_acct_site_id
                INTO     l_cust_acct_site_id
                FROM     hz_cust_acct_sites              addr,
                         hz_cust_site_uses        site
                WHERE     addr.orig_system_reference      =    l_addr_ref
                AND    addr.cust_acct_site_id      =    site.cust_acct_site_id
                AND    site.site_use_code        =    'SHIP_TO';

                EXCEPTION
                WHEN NO_DATA_FOUND    THEN

                      BEGIN
                      IF in_system_code  LIKE 'SHIPTO%' THEN  --MTS 431
                        BEGIN
                          SELECT sites.orig_system_reference
                          INTO l_addr_ref
                          FROM   
                             hz_cust_site_uses_all su,
                             hz_cust_acct_sites_all sites    
                          WHERE sites.orig_system_reference like 'DD-'||in_system_code||'-'||cur_pchase_item_rec.sales_center||'%'||cur_pchase_item_rec.delivery_location_number
                       --   AND   sites.cust_account_id = cur_pchase_item_rec.customer_id
                       ;
                       EXCEPTION WHEN OTHERS THEN
                          l_addr_ref := NULL;
                       END;
                      ELSE
                                      l_addr_ref    :=    G_SWG_CNV_DD_PREFIX        ||
                         main_rec.system_code        || '-' ||
                        cur_pchase_item_rec.sales_center    || '-' ||
                        main_rec.legacy_customer_number || '-' ||
                            to_char(cur_pchase_item_rec.ship_to_address_id) ||'-HEADER';
                      END IF;
                    SELECT     addr.cust_acct_site_id
                    INTO     l_cust_acct_site_id
                    FROM     hz_cust_acct_sites_all          addr,
                             hz_cust_site_uses_all        site
                          WHERE   addr.orig_system_reference    = l_addr_ref
                          AND    addr.cust_acct_site_id        =    site.cust_acct_site_id
                          AND    site.site_use_code          =    'SHIP_TO';
                          EXCEPTION
                            WHEN NO_DATA_FOUND    THEN

                        l_error_mesg_s    :=    'Cust_account_site_id not found '||l_addr_ref;
                        RAISE ERROR_ENCOUNTERED;
                                        END;

                END;

                  -- Get the PPE_ID

                  FOR ppe_info_rec IN cur_ppe_info(l_cust_acct_site_id)
                  LOOP
                    IF ppe_info_rec.service_inventory_item = '1300' THEN

                        l_ppe_id_n    :=    ppe_info_rec.ppe_id;

                    ELSIF ppe_info_rec.service_inventory_item = '1302' THEN

                        l_ppe_id_n    :=    ppe_info_rec.ppe_id;

                    ELSE l_ppe_id_n        :=    ppe_info_rec.ppe_id;

                    END IF;

                    EXIT;
                  END LOOP;
            END IF; -- l_no_ppe

       -- Check the PPe_id is NULL

       IF l_ppe_id_n IS NULL  THEN
          l_error_mesg_s :=    'PPE_ID Not found '||l_addr_ref;
          RAISE ERROR_ENCOUNTERED;
       END IF;

       -- Generate sequence

       SELECT swgrtm_projected_pur_items_seq.NEXTVAL
       INTO      l_pitem_id
       FROM      dual;

       --Added check to not move in Rental/Misc Items into Proj Purch  SGB
       SELECT substr( segment1,1,1) 
       INTO   l_sitem_id
       FROM   mtl_system_items a
       WHERE  a.organization_id   = 5 
       AND    a.inventory_item_id = l_item_id_n;

       IF l_sitem_id NOT IN ( '3','4','6') THEN

    --insert into the PPIT tables

      BEGIN
        INSERT
       INTO    swgrtm_projected_pchase_items
        ( ppi_id
         ,purchase_id
         ,requested_qty
         ,tax_rate
         ,average_qty
         ,method
         ,item_id
         ,organization_id
         ,unit_price
         ,created_by
         ,creation_date
         ,last_updated_by
         ,last_update_date
         ,last_update_login
         ,stop_average_qty_calculation  -- Added for EB-954 by SU
        )
        VALUES
        ( l_pitem_id
         ,l_ppe_id_n
         ,NULL
         ,cur_pchase_item_rec.tax_rate
         ,cur_pchase_item_rec.average_qty
         ,'AVERAGE'
         ,l_item_id_n
         ,g_master_organization_id_n
         ,cur_pchase_item_rec.unit_price
         ,l_conversion_userid_n
         ,SYSDATE
         ,l_conversion_userid_n
         ,SYSDATE
         ,-1
         ,'Y'    -- Added for EB-954 by SU
        );
       EXCEPTION
           WHEN DUP_VAL_ON_INDEX    THEN
        /* SACS7 Changes Muthu - Add the qty in case of duplicate item mappings */
        UPDATE swgrtm_projected_pchase_items
           SET average_qty = average_qty + cur_pchase_item_rec.average_qty
              ,last_update_date = SYSDATE
         WHERE ppi_id = l_pitem_id;
            l_error_mesg_s    := NULL;
      END;

    END IF;

--update the temp customer table with process flag set to 'Y'

    UPDATE   swgcnv_dd_temp_customers    B
    SET         b.proj_pchase_item_proc_flag    =    'Y'
    WHERE    b.ROWID                =    main_rec.row_id;

    IF in_validate_only_c != 'Y' THEN
        COMMIT;
    ELSE
        ROLLBACK;
    END IF;

    l_totl_recd_inserted_n    :=    l_totl_recd_inserted_n    +    1;

--main exception

    EXCEPTION
        WHEN    ERROR_ENCOUNTERED THEN

            ou_errcode_n    := 1;

             ROLLBACK;
            l_totl_recd_errors_n    :=    l_totl_recd_errors_n    +    1;
            l_error_mesg_s        :=    l_error_mesg_s    || ':'||SQLERRM;

            Fnd_File.Put_Line(Fnd_File.LOG,l_error_mesg_s);

        UPDATE   swgcnv_dd_temp_customers    tc
        SET         tc.proj_pchase_item_proc_flag    =    'E'
        WHERE    tc.ROWID                =    main_rec.row_id;

             INSERT
            INTO    swgcnv_conversion_exceptions
                ( conversion_type
                 ,conversion_key_value
                 ,conversion_sub_key1
                 ,error_message
                 ,conversion_sub_key2)
             VALUES    ('PCHASE ITEMS'
                ,main_rec.legacy_customer_number
                ,cur_pchase_item_rec.delivery_location_number||'-'||cur_pchase_item_rec.item_code
                ,l_error_mesg_s
                ,cur_pchase_item_rec.sales_center);
            COMMIT;

        WHEN    OTHERS     THEN
            ou_errcode_n    := 2;

             ROLLBACK;

            l_totl_recd_errors_n    :=    l_totl_recd_errors_n    +    1;
            l_error_mesg_s        :=    l_error_mesg_s || ':'||SQLERRM;

            Fnd_File.Put_Line(Fnd_File.LOG,l_error_mesg_s);

        UPDATE   swgcnv_dd_temp_customers    tc
        SET         tc.proj_pchase_item_proc_flag    =    'E'
        WHERE    tc.ROWID                =    main_rec.row_id;

            INSERT
            INTO    swgcnv_conversion_exceptions
                ( conversion_type
                  ,conversion_key_value
                 ,conversion_sub_key1
                 ,error_message
                 ,conversion_sub_key2)
             VALUES    ('PCHASE ITEMS'
                ,main_rec.legacy_customer_number
                ,cur_pchase_item_rec.delivery_location_number||'-'||cur_pchase_item_rec.item_code
                ,l_error_mesg_s
                ,cur_pchase_item_rec.sales_center);
            COMMIT;

    END;

    END LOOP;  -------end for the legacy loop

    END LOOP;  -------end main loop



----------------------- display the result set -----------------------------------

   Fnd_File.Put_Line(Fnd_File.OUTPUT,'                                   ');
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'*-----------RUN STATISTICS----------------*');
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'Records read       : ' || l_Totl_Recd_Read_n);
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'Records inserted   : ' || l_Totl_Recd_Inserted_n);
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'Records in error   : ' || l_Totl_Recd_Errors_n);
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'*-----------------------------------------*');
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'Start Time         : ' || l_Start_Time_s);
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'End Time           : ' || TO_CHAR(SYSDATE, 'DD-MON-RRRR HH24:MI:SS'));
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'*-----------------------------------------*');
EXCEPTION
WHEN OTHERS THEN
 Fnd_File.Put_Line(Fnd_File.LOG,'Error:'||SQLERRM);
END   swgcnv_dd_ppit_pkg;


PROCEDURE   INSERT_PPE_TAX_LOG
(ou_errbuf_s            OUT        VARCHAR2
,ou_errcode_n            OUT     NUMBER
,in_system_code_s       IN      VARCHAR2
,in_sales_center_s      IN      VARCHAR2)
IS

    l_start_time_s          VARCHAR2(30);
    l_error_message_s       VARCHAR2(2000);

    l_update_count_n        NUMBER          := 0;



BEGIN

    ou_errcode_n    := 0;
    ou_errbuf_s     := NULL;

    l_start_time_s    :=    TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS');

    INSERT INTO swgt_fix_ppe_tax_log
        (sales_center
        ,route_number
        ,rte_id
        ,processed_flag)
--    VALUES
        SELECT SUBSTR(legacy_route_id,1,3)
            ,route_number
            ,rte_id
            ,'N'
        FROM swgdd.swgrtm_routes
        WHERE legacy_system             = in_system_code_s
        AND SUBSTR(legacy_route_id,1,3) = in_sales_center_s;


    l_update_count_n    := SQL%rowcount;

    COMMIT;

    Fnd_File.Put_Line(Fnd_File.OUTPUT,'                                   ');
    Fnd_File.Put_Line(Fnd_File.OUTPUT,'*-----------'||in_sales_center_s||'----------------*');
    Fnd_File.Put_Line(Fnd_File.OUTPUT,'*-----------RUN STATISTICS----------------*');
    Fnd_File.Put_Line(Fnd_File.OUTPUT,'Update Count:     '||l_update_count_n);
    Fnd_File.Put_Line(Fnd_File.OUTPUT,'*-----------------------------------------*');
    Fnd_File.Put_Line(Fnd_File.OUTPUT,'Start Time         : ' || l_Start_Time_s);
    Fnd_File.Put_Line(Fnd_File.OUTPUT,'End Time           : ' || TO_CHAR(SYSDATE, 'DD-MON-RRRR HH24:MI:SS'));
    Fnd_File.Put_Line(Fnd_File.OUTPUT,'*-----------------------------------------*');

EXCEPTION
    WHEN OTHERS THEN

        l_error_message_s   := 'UNEXPECTED ERROR in INSERT_PPE_TAX_LOG: '||SQLERRM;

        ROLLBACK;

        ou_errcode_n        := 2;
        ou_errbuf_s         := l_error_message_s;


END         INSERT_PPE_TAX_LOG;

END   Swgcnv_Dd_Prpch_Pkg;
/
SHOW ERRORS;
EXIT;