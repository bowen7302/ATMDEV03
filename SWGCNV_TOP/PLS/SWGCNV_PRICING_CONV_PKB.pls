CREATE OR REPLACE PACKAGE BODY APPS.Swgcnv_Pricing_Conv
IS

/* $Header: Swgcnv_Pricing_Conv_pkb.pls   1.1 2008/31/10 18:00:00 AM           $ */
/*================================================================================+
| Copyright (c) 2007 DS Waters, Atlanta, GA 30152 USA All rights reserved.        |
+=================================================================================+
| FILENAME       Swgcnv_Pricing_Conv_pkb.pls                                      |
|                                                                                 |
| DESCRIPTION    UNKNOWN                                                          |
|                                                                                 |
| HISTORY                                                                         |
| Unknown         Unknown       Initial version                                   |
| Ajay            31-OCT-2008   R12 Change(replaced fnd_client_info)              |
| Shashi Begar    31-DEC-2009   Changes made for Guthrie conversion - Proj#1323   |
| Pankaj Umate    09-APR-2010   Daptiv # 1471. Conversion Mapping Table Migration |
+================================================================================*/

PROCEDURE    duplicate_inventory_item (out_errbuf_s        OUT    VARCHAR2
                    ,out_errnum_n        OUT    NUMBER
                                   ,in_legacy_system_s IN    VARCHAR2
                                        ,in_division_s        IN    VARCHAR2
                                        ,in_sales_center_s  IN    VARCHAR2
                                         )
IS
CURSOR    cur_cust
IS
SELECT    hcsu.site_use_id
,        hcsu.price_list_id
,        hzcpc.name                      profile_class
,        a.division                    legacy_division
,        a.legacy_customer_number    legacy_customer_number
,        a.system_code
,        a.new_sales_center
,        a.oracle_customer_id
,        hzca.account_number
,        hzp.party_name
,        b.*
FROM    swgcnv_dd_temp_customers      a
,         swgcnv_dd_special_price      b
,        hz_parties                    hzp
,        hz_cust_accounts            hzca
,        hz_cust_acct_sites           hcas
,        hz_cust_site_uses            hcsu
,        hz_customer_profiles         hzcp
,          hz_cust_profile_classes     hzcpc
WHERE     a.system_code            =  in_legacy_system_s
AND     a.division            =  in_division_s
AND     b.sales_center                =  in_sales_center_s
AND     a.legacy_customer_number     =  b.customer_number
AND     a.cust_import_flag        =  'Y'
AND     b.valid_flag                    =  'Y'
AND     b.special_price_proc_flag     =  'N'
AND    hzp.party_id            =  hzca.party_id
AND    hzca.cust_account_id        =  a.oracle_customer_id
AND     hcas.cust_account_id         =  hzca.cust_account_id
AND     hcsu.cust_acct_site_id         =  hcas.cust_acct_site_id
AND     hcsu.site_use_code            =  'SHIP_TO'
AND     hcsu.orig_system_reference    LIKE 'DD-'||in_legacy_system_s||'-'||in_sales_center_s||'-%'||b.customer_number||'-%'||LTRIM(b.delivery_location_number,0)||'%'
AND        hzcpc.profile_class_id         =  hzcp.profile_class_id
AND     hzcp.site_use_id             IS     NULL
AND     hzcp.cust_account_id        =  hzca.cust_account_id
AND    hzcpc.name                <> 'DD EMPLOYEE'
--AND rownum <3
;

CURSOR cur_price_cnt
IS
SELECT COUNT(*) cnt
FROM   swgcnv_dd_temp_customers      a
,        swgcnv_dd_special_price       b
WHERE  a.system_code             =  in_legacy_system_s
AND    a.division             =  in_division_s
AND    b.sales_center                 =  in_sales_center_s
AND    a.cust_import_flag         =    'Y'
AND    b.customer_number         =  a.legacy_customer_number
AND    b.valid_flag              =  'Y'
AND    b.special_price_proc_flag =  'N';

    TYPE    temp_cust_tbl_type    IS    TABLE    OF    cur_cust%ROWTYPE
    INDEX     BY    BINARY_INTEGER;

    l_temp_cust_rec                       cur_cust%ROWTYPE;
    l_price_list_id                    NUMBER;
    l_new_item_code                    VARCHAR2(20);
    l_inventory_item_id                NUMBER;
    l_related_item_id                NUMBER;
    l_pricing_mechanism                VARCHAR2(3);
    l_spl_price                    NUMBER;
        l_pstatus_c                    VARCHAR2(10);
        l_message_s                    VARCHAR2(2000);
        l_debug_c                    VARCHAR2(10);
    l_list_price                    NUMBER;
    l_spl_price_cnt                    NUMBER := 0;
    l_spl_price_proc_cnt                NUMBER := 0;
        l_spl_price_bottle_ignored_cnt                NUMBER := 0;
    l_spl_price_fail_cnt                NUMBER := 0;
    l_error_flag                    VARCHAR2(1) := 'N';
    l_error_msg                    VARCHAR2(400) := NULL;
        l_item_rec                                      Swgcnv_Cntrct_Vldt.item_info_rec_type;
        l_org_rec                                       Swgcnv_Cntrct_Vldt.org_info_rec_type;
        l_status_c                                      VARCHAR2(1);
        ERROR_ENCOUNTERED                               EXCEPTION;
        l_rel_item_code                                 VARCHAR2(100);
        l_convert_flag                    VARCHAR2(1);

BEGIN
   --Fnd_Client_Info.set_org_context(2);
   mo_global.set_policy_context('S', 2);   -- modified by Ajay on 9/2/2008 for R12

-- Output - Display number of pricing records touched
   FOR k IN cur_price_cnt
   LOOP
               l_spl_price_cnt := k.cnt;
   END LOOP;

--
    FOR l_temp_cust_rec IN cur_cust
    LOOP
        BEGIN

    l_related_item_id   := NULL;
    l_inventory_item_id := NULL;
    l_error_msg        := NULL;
    l_status_c        := NULL;
        l_error_flag        := 'N';
--1) For new item code

    Swgcnv_Cntrct_Vldt.Get_Maps_And_Details
           ( in_sacs_org_s                 => in_sales_center_s
           ,in_sacs_brand_s            => l_temp_cust_rec.item_sub_code
           ,in_sacs_item_s            => LTRIM(RTRIM(l_temp_cust_rec.item_code))
           ,in_eff_date_d            => TRUNC(SYSDATE)
           ,io_item_rec                => l_item_rec
           ,io_org_rec                => l_org_rec
           ,io_status_c                => l_status_c
           ,io_message_s            => l_error_msg
           ,in_debug_c                => 'N' --Swgcnv_Cntrct_Vldt.G_DEBUG
           ,in_system_code_c                => in_legacy_system_s); --Added on for ARS01-- Syed
          -- ,in_system_code_c                => 'SACS'); --Commented out for ARS01--022307 
--Fnd_File.Put_Line(Fnd_File.LOG,' 1-l_error_flag :'|| l_error_flag );
            IF l_status_c != Swgcnv_Cntrct_Vldt.G_STS_SUCCESS THEN
                l_error_flag := 'Y';
                --Fnd_File.Put_Line(Fnd_File.LOG,' 2_error_flag :'|| l_error_flag );
                l_new_item_code := NULL;
                l_error_msg    :=    in_legacy_system_s||'-'||LTRIM(RTRIM(l_temp_cust_rec.item_code)) ||'Sub Code'||
                    l_temp_cust_rec.item_sub_code||'Sales Center'||in_sales_center_s
                                        || 'Error returned from Get_Maps_And_Details: '
                                        || l_error_msg;
        --Fnd_File.Put_Line(Fnd_File.LOG, l_error_msg);
                RAISE ERROR_ENCOUNTERED;
        ELSE
        l_new_item_code := l_item_rec.item_code;
        Fnd_File.Put_Line(Fnd_File.LOG,'new item code  '||l_new_item_code );
            END IF;

--2) Inventory Item id
        BEGIN
             SELECT inventory_item_id
             INTO   l_inventory_item_id
             FROM   mtl_system_items_b           a
             ,    org_organization_definitions b
             WHERE  a.segment1          = l_new_item_code
             AND    a.organization_id   = b.organization_id
             AND    b.organization_code = in_sales_center_s;
             Fnd_File.Put_Line(Fnd_File.LOG,'l_inventory_item_id:  '||l_inventory_item_id );
        EXCEPTION
             WHEN NO_DATA_FOUND THEN
                   l_error_flag := 'Y';
                  l_error_msg  := 'Item Code '||l_new_item_code||' is not available for this '||in_sales_center_s;
                  --Fnd_File.put_line(Fnd_File.LOG,l_error_msg);
                  --Fnd_File.Put_Line(Fnd_File.LOG,' 3_l_error_flag :'|| l_error_flag );
                      RAISE ERROR_ENCOUNTERED;
             WHEN OTHERS THEN
                     l_error_flag := 'Y';
                  l_error_msg  := 'Item Code '||l_new_item_code||' is got errored : '||SQLERRM;
                  --Fnd_File.put_line(Fnd_File.LOG,l_error_msg);
                  --Fnd_File.Put_Line(Fnd_File.LOG,' 4_l_error_flag :'|| l_error_flag );
                      RAISE ERROR_ENCOUNTERED;
        END;

--3) For related item id  . Populate it with realted item for 4 items else populate it with original item
        IF SUBSTR(l_new_item_code,1,1) = '4' THEN
        BEGIN
            SELECT  Related_Item_Id
            INTO    l_related_item_id
            FROM    Mtl_Related_Items rel
                            ,    org_organization_definitions b
             WHERE  rel.organization_id   = b.organization_id
             AND    b.organization_code   = 'MAS'
                 AND    rel.inventory_Item_Id =    l_inventory_item_id;
                 Fnd_File.Put_Line(Fnd_File.LOG,' l_related_item_id:  '|| l_related_item_id );
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            l_error_flag := 'Y';
            l_error_msg  := 'Related Item Id does not exist for Item : '|| l_inventory_item_id||' '||l_new_item_code;
            --Fnd_File.Put_Line(Fnd_File.LOG,' 5_l_error_flag :'|| l_error_flag );
                        RAISE ERROR_ENCOUNTERED;
        WHEN OTHERS THEN
            l_error_flag := 'Y';
            l_error_msg  := 'Error fetching Related Item Id for Item : '|| l_inventory_item_id||' '||l_new_item_code;
            --Fnd_File.Put_Line(Fnd_File.LOG,' 6_l_error_flag :'|| l_error_flag );
                        RAISE ERROR_ENCOUNTERED;
        END;
           ELSE
           --Fnd_File.Put_Line(Fnd_File.LOG,' Else ' );
            l_related_item_id     :=    l_inventory_item_id;
        END IF;

        UPDATE     swgcnv_dd_special_price
        SET     inventory_item_id     = l_related_item_id
        WHERE   customer_number       = l_temp_cust_rec.customer_number
        AND     delivery_location_number = l_temp_cust_rec.delivery_location_number
        AND     item_code         = l_temp_cust_rec.item_code
        AND     item_sub_code         = l_temp_cust_rec.item_sub_code
                AND     sales_center             = in_sales_center_s;
--Fnd_File.Put_Line(Fnd_File.LOG,' Updated:  ');
--Fnd_File.Put_Line(Fnd_File.LOG,' 7_l_error_flag :'|| l_error_flag );
--4) profile class and pricing mechanism
        IF l_temp_cust_rec.profile_class IN ('DD KEY','DD NATIONAL ACCOUNTS') THEN
                   l_pricing_mechanism :=  'NEW';
                l_spl_price            :=  l_temp_cust_rec.special_price;
                l_pstatus_c             :=    NULL;
                l_message_s             :=    NULL;
                l_debug_c             :=    NULL;
                --Fnd_File.Put_Line(Fnd_File.LOG,' l_temp_cust_rec.special_price l_spl_price :'|| l_temp_cust_rec.special_price );
                Swg_Pricing_Pkg.swg_get_list_price ( in_price_list_id_n        => l_temp_cust_rec.price_list_id
                                   , in_item_id_n        => l_related_item_id
                                    , in_pricing_date_d        => TRUNC(SYSDATE)
                                    , io_list_price_n         => l_list_price
                                    , io_status_c        => l_pstatus_c
                                    , io_message_s        => l_message_s
                                   , in_debug_c            => l_debug_c
                                                       );
--Fnd_File.Put_Line(Fnd_File.LOG,' 8_l_error_flag :'|| l_error_flag );
--Fnd_File.Put_Line(Fnd_File.LOG,'NEW l_list_price:  '|| l_list_price );
--Fnd_File.Put_Line(Fnd_File.LOG,'NEW l_pstatus_c:  '|| l_pstatus_c );
--Fnd_File.Put_Line(Fnd_File.LOG,'NEW l_message_s:  '|| l_message_s );
--Fnd_File.Put_Line(Fnd_File.LOG,'NEW l_debug_c:  '|| l_debug_c );

                                                   
                IF l_pstatus_c != 'S' THEN
                --Fnd_File.Put_Line(Fnd_File.LOG,'NEW  l_pstatus_c != S' );
                     l_error_flag := 'Y';
                     l_error_msg  := 'Getting List Price from price list failed for this item id : '|| l_related_item_id ;
                                     RAISE ERROR_ENCOUNTERED;
                END IF;
        ELSE
                    l_pricing_mechanism :=  'AMT';
                l_pstatus_c             :=    NULL;
                l_message_s             :=    NULL;
                l_debug_c             :=    NULL;
                Swg_Pricing_Pkg.swg_get_list_price ( in_price_list_id_n        => l_temp_cust_rec.price_list_id
                                   , in_item_id_n        => l_related_item_id
                                    , in_pricing_date_d        => TRUNC(SYSDATE)
                                    , io_list_price_n         => l_list_price
                                    , io_status_c        => l_pstatus_c
                                    , io_message_s        => l_message_s
                                   , in_debug_c            => l_debug_c
                                                       );
--Fnd_File.Put_Line(Fnd_File.LOG,' AMT l_temp_cust_rec.price_list_id: '||l_temp_cust_rec.price_list_id );                                                   
--Fnd_File.Put_Line(Fnd_File.LOG,' 9_l_error_flag :'|| l_error_flag );
--Fnd_File.Put_Line(Fnd_File.LOG,'AMT l_temp_cust_rec.price_list_id :  '|| l_temp_cust_rec.price_list_id );
--Fnd_File.Put_Line(Fnd_File.LOG,'AMT l_related_item_id:  '|| l_related_item_id );
--Fnd_File.Put_Line(Fnd_File.LOG,'AMT l_list_price:  '|| l_list_price );
--Fnd_File.Put_Line(Fnd_File.LOG,'AMT l_pstatus_c:  '|| l_pstatus_c );
--Fnd_File.Put_Line(Fnd_File.LOG,'AMT l_message_s:  '|| l_message_s );
--Fnd_File.Put_Line(Fnd_File.LOG,'AMT l_debug_c:  '|| l_debug_c );
--Fnd_File.Put_Line(Fnd_File.LOG,' AMT l_temp_cust_rec.price_list_id: '||l_temp_cust_rec.price_list_id );
--Fnd_File.Put_Line(Fnd_File.LOG,' AMT l_list_price: '||l_list_price );                
                                                   
                l_spl_price           :=    NVL(l_list_price,0) - NVL(l_temp_cust_rec.special_price,0);
Fnd_File.Put_Line(Fnd_File.LOG,' AMT  l_spl_price :'|| l_spl_price );
                IF l_pstatus_c != 'S' THEN
                --Fnd_File.Put_Line(Fnd_File.LOG,' AMT l_pstatus_c != S' );
                   l_error_flag := 'Y';
                   l_error_msg  := 'Getting List Price from price list failed for this item id : '|| l_related_item_id;
                                   RAISE ERROR_ENCOUNTERED;
                END IF;
         END IF;

--5) No of spl pricing records that will be inserted
Fnd_File.Put_Line(Fnd_File.LOG,' l_error_flag :'|| l_error_flag );
     IF  l_error_flag <> 'Y' THEN
       --Fnd_File.Put_Line(Fnd_File.LOG,'l_error_flag <> Y' );
                      l_convert_flag := NULL;
                                 IF l_spl_price = 0 AND l_pricing_mechanism = 'AMT' THEN
                                 Fnd_File.Put_Line(Fnd_File.LOG,' IF l_spl_price =0 : '||l_spl_price );
                                  --Fnd_File.Put_Line(Fnd_File.LOG,'IF l_spl_price = 0 AND l_pricing_mechanism = AMT THEN ' );
                         l_convert_flag   := 'N';
                        --Fnd_File.Put_Line(Fnd_File.LOG,'l_convert_flag: '||l_convert_flag);
                 ELSE
                    l_convert_flag   := 'Y';
                    --Fnd_File.Put_Line(Fnd_File.LOG,'Else l_convert_flag: '||l_convert_flag);
                 END IF;

-- Find Related Item code
            BEGIN
                SELECT   segment1
                INTO     l_rel_item_code
                FROM      mtl_system_items_b it
                                         ,org_organization_definitions b
                WHERE     it.inventory_item_id  = l_related_item_id
                    AND     b.organization_id     = it.organization_id
                AND      b.organization_code   = 'MAS';
                --Fnd_File.Put_Line(Fnd_File.LOG,'segment1 l_rel_item_code: '||l_rel_item_code);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                                     l_convert_flag   := 'N';
                                     --Fnd_File.Put_Line(Fnd_File.LOG,'NO_DATA_FOUND segment1 l_convert_flag: '||l_convert_flag);
                     l_error_flag := 'Y';
                     l_error_msg  := 'Related Item Not Found';
                                     RAISE ERROR_ENCOUNTERED;
                WHEN OTHERS THEN
                                     l_convert_flag   := 'N';
                     l_error_flag := 'Y';
                     l_error_msg  := 'Related Item Error Not Found' || SQLERRM ;
                     --Fnd_File.Put_Line(Fnd_File.LOG,'OTHERS segment1 l_convert_flag: '||l_convert_flag);
                                     RAISE ERROR_ENCOUNTERED;
            END;
                 IF   l_convert_flag                 = 'Y' THEN
                      IF SUBSTR(l_rel_item_code,1,1) NOT IN (3,4)     THEN
                                        l_spl_price_proc_cnt := l_spl_price_proc_cnt + 1;
                                     --Fnd_File.Put_Line(Fnd_File.LOG,'l_spl_price_proc_cnt :'||l_spl_price_proc_cnt);
                                      ELSE
                                      --Fnd_File.Put_Line(Fnd_File.LOG,'Else 3, 4: ');
                                         l_spl_price_bottle_ignored_cnt := l_spl_price_bottle_ignored_cnt + 1;
                                         --Fnd_File.Put_Line(Fnd_File.LOG,'l_spl_price_bottle_ignored_cnt :'||l_spl_price_bottle_ignored_cnt);
                      END IF;
                                 END IF;
         END IF;
  EXCEPTION
  WHEN ERROR_ENCOUNTERED THEN
           Fnd_File.put_line(Fnd_File.LOG,l_error_msg);
           Insert_Exception ( 'PRICING - POPULATE'
                          ,l_temp_cust_rec.legacy_customer_number
                          ,NULL
                          ,l_error_msg
                          ,in_sales_center_s
                        );
               l_spl_price_fail_cnt := l_spl_price_fail_cnt + 1;

  END;
  END LOOP;
  Fnd_File.put_line(Fnd_File.output,'No. of Special Price Records           : '||l_spl_price_cnt);
  Fnd_File.put_line(Fnd_File.output,'No. of Special Price Records Processed : '||l_spl_price_proc_cnt);
  Fnd_File.put_line(Fnd_File.output,'No. of Special Price Bottles Ignored   : '||l_spl_price_bottle_ignored_cnt);
  Fnd_File.put_line(Fnd_File.output,'No. of Special Price Records Failed    : '||l_spl_price_fail_cnt);
  COMMIT;
EXCEPTION
       WHEN NO_DATA_FOUND THEN
        Fnd_File.put_line(Fnd_File.LOG,'No Data found : '||SQLERRM);
        out_errnum_n := 2;
        out_errbuf_s := SQLERRM;
       WHEN OTHERS THEN
        Fnd_File.put_line(Fnd_File.LOG,'No Data found : '||SQLERRM);
        out_errnum_n := 2;
        out_errbuf_s := SQLERRM;
END    duplicate_inventory_item;

PROCEDURE    pricing_conversion (out_errbuf_s      OUT    VARCHAR2
                                   ,out_errnum_n      OUT    NUMBER
                                   ,in_legacy_system_s        IN    VARCHAR2
                                 ,in_division_s          IN    VARCHAR2
                                 ,in_sales_center_s      IN    VARCHAR2
                                  )
IS
CURSOR    cur_cust
IS

SELECT    hcsu.site_use_id
,        hcsu.price_list_id
,        hzcpc.name                      profile_class
,        a.division                    legacy_division
,        a.legacy_customer_number    legacy_customer_number
,        a.system_code
,        a.new_sales_center
,        a.oracle_customer_id
,        hzca.account_number
,        hzp.party_name
,        b.*
FROM    swgcnv_dd_temp_customers      a
,         swgcnv_dd_special_price      b
,        hz_parties                    hzp
,        hz_cust_accounts            hzca
,        hz_cust_acct_sites           hcas
,        hz_cust_site_uses            hcsu
,        hz_customer_profiles         hzcp
,          hz_cust_profile_classes     hzcpc
WHERE     a.system_code                =  in_legacy_system_s
AND     a.division                    =  in_division_s
AND     b.sales_center                =  in_sales_center_s
AND     a.legacy_customer_number     =  b.customer_number
AND     a.cust_import_flag            =  'Y'
AND     b.valid_flag                =  'Y'
AND     b.special_price_proc_flag     =  'N'
AND        hzp.party_id                =  hzca.party_id
AND        hzca.cust_account_id        =  a.oracle_customer_id
AND     hcas.cust_account_id         =  hzca.cust_account_id
AND     hcsu.cust_acct_site_id         =  hcas.cust_acct_site_id
AND     hcsu.site_use_code                =  'SHIP_TO'
AND     hcsu.orig_system_reference    LIKE 'DD-'||in_legacy_system_s||'-'||in_sales_center_s||'-%'||b.customer_number||'-%'||LTRIM(b.delivery_location_number,0)||'%'
AND        hzcpc.profile_class_id         =  hzcp.profile_class_id
AND     hzcp.site_use_id             IS     NULL
AND     hzcp.cust_account_id        =  hzca.cust_account_id
AND        hzcpc.name                    <> 'DD EMPLOYEE';

CURSOR cur_price_cnt
IS
SELECT COUNT(*) cnt
FROM   swgcnv_dd_temp_customers      a
,        swgcnv_dd_special_price       b
WHERE  a.system_code             =  in_legacy_system_s
AND    a.division                 =  in_division_s
AND    b.sales_center         =  in_sales_center_s
AND    a.cust_import_flag         =    'Y'
AND    b.customer_number         =  a.legacy_customer_number
AND    b.valid_flag              =  'Y'
AND    b.special_price_proc_flag =  'N';

    TYPE    temp_cust_tbl_type    IS    TABLE    OF    cur_cust%ROWTYPE
    INDEX     BY    BINARY_INTEGER;

    l_temp_cust_rec                       cur_cust%ROWTYPE;
    l_price_list_id                    NUMBER;
    l_new_item_code                    VARCHAR2(20);
    l_inventory_item_id                NUMBER;
    l_related_item_id                NUMBER;
    l_pricing_mechanism                VARCHAR2(3);
    l_spl_price                    NUMBER;
        l_Pstatus_c                    VARCHAR2(10);
        l_message_s                    VARCHAR2(2000);
        l_debug_c                    VARCHAR2(10);
    l_list_price                    NUMBER;
    l_spl_price_cnt                    NUMBER := 0;
    l_spl_price_proc_cnt                    NUMBER := 0;
    l_spl_price_fail_cnt                    NUMBER := 0;
    l_error_flag                    VARCHAR2(1) := 'N';
    --l_error_msg                    VARCHAR2(400) := NULL; --commented 030107 syed
    l_error_msg                    VARCHAR2(2000) := NULL;
    l_convert_flag                    VARCHAR2(1) :=  NULL;
    l_segment1                    VARCHAR2(30);
        l_spl_price_bottle_ignored_cnt                NUMBER := 0;
        l_item_rec                                      Swgcnv_Cntrct_Vldt.item_info_rec_type;
        l_org_rec                                       Swgcnv_Cntrct_Vldt.org_info_rec_type;
        l_status_c                                      VARCHAR2(1);
        ERROR_ENCOUNTERED                               EXCEPTION;
        l_rel_item_code                                 VARCHAR2(100);
BEGIN
   --Fnd_Client_Info.set_org_context(2);
   mo_global.set_policy_context('S', 2);   -- modified by Ajay on 9/2/2008 for R12

-- Output - Display number of pricing records touched
   FOR k IN cur_price_cnt
   LOOP
               l_spl_price_cnt := k.cnt;
   END LOOP;

--
    FOR l_temp_cust_rec IN cur_cust
    LOOP
        BEGIN

    l_related_item_id   := NULL;
    l_inventory_item_id := NULL;
    l_error_msg        := NULL;
    l_status_c        := NULL;
        l_error_flag        := 'N';
--1) For new item code

    Swgcnv_Cntrct_Vldt.Get_Maps_And_Details
           ( in_sacs_org_s                 => in_sales_center_s
           ,in_sacs_brand_s            => l_temp_cust_rec.item_sub_code
           ,in_sacs_item_s            => LTRIM(RTRIM(l_temp_cust_rec.item_code))
           ,in_eff_date_d            => TRUNC(SYSDATE)
           ,io_item_rec                => l_item_rec
           ,io_org_rec                => l_org_rec
           ,io_status_c                => l_status_c
           ,io_message_s            => l_error_msg
           ,in_debug_c                => 'N'--Swgcnv_Cntrct_Vldt.G_DEBUG
           ,in_system_code_c                => in_legacy_system_s);--Added for ARS01 --Syed--
          -- ,in_system_code_c                => 'SACS'); --Commented out for ARS01--022307 

Fnd_File.put_line(Fnd_File.LOG,'l_temp_cust_rec.item_sub_code:'||l_temp_cust_rec.item_sub_code);
Fnd_File.put_line(Fnd_File.LOG,'LTRIM(RTRIM(l_temp_cust_rec.item_code)):'||LTRIM(RTRIM(l_temp_cust_rec.item_code)));
--Fnd_File.put_line(Fnd_File.LOG,'l_inventory_item_id --2):'||l_inventory_item_id);

            IF l_status_c != Swgcnv_Cntrct_Vldt.G_STS_SUCCESS THEN
                l_error_flag := 'Y';
                l_new_item_code := NULL;
                l_error_msg    :=    in_legacy_system_s||'-'||'Customer ' || l_temp_cust_rec.customer_number||'-'||LTRIM(RTRIM(l_temp_cust_rec.item_code)) ||'Sub Code'||
                    l_temp_cust_rec.item_sub_code||'Sales Center'||in_sales_center_s
                                        || 'Error returned from Get_Maps_And_Details: '
                                        || l_error_msg;
        Fnd_File.Put_Line(Fnd_File.LOG, l_error_msg);
                RAISE ERROR_ENCOUNTERED;
        ELSE
        l_new_item_code := l_item_rec.item_code;
        Fnd_File.Put_Line(Fnd_File.LOG,in_legacy_system_s||'-'||'Customer ' || l_temp_cust_rec.customer_number||'-'
                    ||LTRIM(RTRIM(l_temp_cust_rec.item_code)) ||'Sub Code'||
                    l_temp_cust_rec.item_sub_code||'Sales Center'||in_sales_center_s||
                    'new item code  '||l_new_item_code );
            END IF;

--2) Inventory Item id
        BEGIN
                     Fnd_File.put_line(Fnd_File.LOG,'l_new_item_code --2):'||l_new_item_code);
                       
             SELECT inventory_item_id
             INTO   l_inventory_item_id
             FROM   mtl_system_items_b           a
             ,    org_organization_definitions b
             WHERE  a.segment1          = l_new_item_code
             AND    a.organization_id   = b.organization_id
             AND    b.organization_code = in_sales_center_s;

            Fnd_File.put_line(Fnd_File.LOG,'l_inventory_item_id --2):'||l_inventory_item_id);

        EXCEPTION
             WHEN NO_DATA_FOUND THEN
                   l_error_flag := 'Y';
                  l_error_msg  := 'Item Code '||l_new_item_code||' is not available for this '||in_sales_center_s;
                  Fnd_File.put_line(Fnd_File.LOG,l_error_msg);
                      RAISE ERROR_ENCOUNTERED;
             WHEN OTHERS THEN
                     l_error_flag := 'Y';
                  l_error_msg  := 'Item Code '||l_new_item_code||' is got errored : '||SQLERRM;
                  Fnd_File.put_line(Fnd_File.LOG,l_error_msg);
                      RAISE ERROR_ENCOUNTERED;
        END;

--3) For related item id  . Populate it with realted item for 4 items else populate it with original item
        IF SUBSTR(l_new_item_code,1,1) = '4' THEN
        BEGIN
            SELECT  Related_Item_Id
            INTO    l_related_item_id
            FROM    Mtl_Related_Items rel
                            ,    org_organization_definitions b
             WHERE  rel.organization_id   = b.organization_id
             AND    b.organization_code   = 'MAS'
                 AND    rel.inventory_Item_Id =    l_inventory_item_id;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            l_error_flag := 'Y';
            l_error_msg  := 'Related Item Id does not exist for Item : '|| l_inventory_item_id||' '||l_new_item_code;
                        RAISE ERROR_ENCOUNTERED;
        WHEN OTHERS THEN
            l_error_flag := 'Y';
            l_error_msg  := 'Error fetching Related Item Id for Item : '|| l_inventory_item_id||' '||l_new_item_code;
                        RAISE ERROR_ENCOUNTERED;
        END;
           ELSE
            l_related_item_id     :=    l_inventory_item_id;
        END IF;

        UPDATE     swgcnv_dd_special_price
        SET     inventory_item_id     = l_related_item_id
        WHERE   customer_number       = l_temp_cust_rec.customer_number
        AND     delivery_location_number = l_temp_cust_rec.delivery_location_number
        AND     item_code         = l_temp_cust_rec.item_code
        AND     nvl(item_sub_code,'X')         = nvl(l_temp_cust_rec.item_sub_code,'X') --Added Null handling
        AND     sales_center             = in_sales_center_s;

--4) profile class and pricing mechanism
        IF l_temp_cust_rec.profile_class IN ('DD KEY','DD NATIONAL ACCOUNTS') THEN
                   l_pricing_mechanism :=  'NEW';
                l_spl_price            :=  l_temp_cust_rec.special_price;
                Swg_Pricing_Pkg.swg_get_list_price ( in_price_list_id_n        => l_temp_cust_rec.price_list_id
                                   , in_item_id_n        => l_related_item_id
                                    , in_pricing_date_d  => l_temp_cust_rec.valid_from_date   --TRUNC(SYSDATE)  --SSB Proj# 1323
                                    , io_list_price_n    => l_list_price
                                    , io_status_c        => l_pstatus_c
                                    , io_message_s       => l_message_s
                                   , in_debug_c          => l_debug_c
                                                       );

                IF l_pstatus_c != 'S' THEN
                     l_error_flag := 'Y';
                     l_error_msg  := 'Getting List Price from price list failed for this item id : '|| l_inventory_item_id||' '||l_new_item_code;
                                     RAISE ERROR_ENCOUNTERED;
                END IF;
        ELSE
                    l_pricing_mechanism :=  'AMT';
                l_pstatus_c             :=    NULL;
                l_message_s             :=    NULL;
                l_debug_c             :=    NULL;
                Swg_Pricing_Pkg.swg_get_list_price ( in_price_list_id_n        => l_temp_cust_rec.price_list_id
                                   , in_item_id_n        => l_related_item_id
                                    , in_pricing_date_d  => l_temp_cust_rec.valid_from_date   --TRUNC(SYSDATE)  --SSB Proj# 1323
                                    , io_list_price_n    => l_list_price
                                    , io_status_c        => l_pstatus_c
                                    , io_message_s       => l_message_s
                                   , in_debug_c          => l_debug_c
                                                       );

                l_spl_price           :=    NVL(l_list_price,0) - NVL(l_temp_cust_rec.special_price,0);

                IF l_pstatus_c != 'S' THEN
                   l_error_flag := 'Y';
                   l_error_msg  := 'Getting List Price from price list failed for this item id : '|| l_inventory_item_id;
                                   RAISE ERROR_ENCOUNTERED;
                END IF;
         END IF;

--5) No of spl pricing records that will be inserted

     IF  l_error_flag <> 'Y' THEN
                      l_convert_flag := NULL;
                                 IF l_spl_price = 0 AND l_pricing_mechanism = 'AMT' THEN
                         l_convert_flag   := 'N';
                 ELSE
                    l_convert_flag   := 'Y';
                 END IF;

-- Find Related Item code
            BEGIN
                SELECT   segment1
                INTO     l_rel_item_code
                FROM      mtl_system_items_b it
                                         , org_organization_definitions b
                WHERE     it.inventory_item_id  = l_related_item_id
                    AND     b.organization_id     = it.organization_id
                AND      b.organization_code   = 'MAS';
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                                     l_convert_flag   := 'N';
                     l_error_flag := 'Y';
                     l_error_msg  := 'Related Item Not Found';
                                     RAISE ERROR_ENCOUNTERED;
                WHEN OTHERS THEN
                                     l_convert_flag   := 'N';
                     l_error_flag := 'Y';
                     l_error_msg  := 'Related Item Error Not Found' || SQLERRM ;
                                     RAISE ERROR_ENCOUNTERED;
            END;
                                 /* Do not create pricing for -ve spl price and spl price > 50 for equipments */

                                 IF   SUBSTR(l_rel_item_code,1,1) = '6' THEN
                                      IF l_spl_price < 0 OR l_spl_price > 50 THEN
                                         l_convert_flag   := 'N';
                                      END IF;
                                 END IF;
                               
            
                Fnd_File.put_line(Fnd_File.LOG,'l_convert_flag:'||l_convert_flag);
                Fnd_File.put_line(Fnd_File.LOG,'oracle_customer_id:'||l_temp_cust_rec.oracle_customer_id);
                Fnd_File.put_line(Fnd_File.LOG,'site_use_id:'||l_temp_cust_rec.site_use_id);
                Fnd_File.put_line(Fnd_File.LOG,'l_related_item_id:'||l_related_item_id);
                                Fnd_File.put_line(Fnd_File.LOG,'l_inventory_item_id:'||l_inventory_item_id);
                Fnd_File.put_line(Fnd_File.LOG,'l_temp_cust_rec.valid_from_date:'||to_char(l_temp_cust_rec.valid_from_date));
                


                 IF   l_convert_flag                 = 'Y' THEN
                    --  IF SUBSTR(l_rel_item_code,1,1) NOT IN (3,4) THEN --Commented out only for ARS01-030207- Syd/Ashok

                      IF SUBSTR(l_rel_item_code,1,1) NOT IN (4) THEN
                                       

                                        l_error_msg:='Bfr Insert into swg_special_pricing ';
 
                ----------------------------------------------------------
                    
                    -- Below fix is for ARS01/ARS02-- By syed 030207/062507--
                
                   -- if  l_rel_item_code in('30232001','30236001','30231001','30231012','31000007')-- for ARS01
                    if  l_rel_item_code in('30232001','30231001')    --ARS02 Only                 
                                    THEN
                           l_pricing_mechanism :=  'NEW';
                        l_spl_price            :=  l_temp_cust_rec.special_price;
                        l_pstatus_c             :=    NULL;
                        l_message_s             :=    NULL;
                        l_debug_c             :=    NULL;
                        Swg_Pricing_Pkg.swg_get_list_price ( 
                                     in_price_list_id_n        => l_temp_cust_rec.price_list_id
                                   , in_item_id_n        => l_related_item_id
                                    , in_pricing_date_d        => TRUNC(SYSDATE)
                                    , io_list_price_n         => l_list_price
                                    , io_status_c        => l_pstatus_c
                                    , io_message_s        => l_message_s
                                   , in_debug_c            => l_debug_c
                                                       );

                    IF l_pstatus_c != 'S' THEN
                             l_error_flag := 'Y';
                             l_error_msg  := 'Getting List Price from price list failed for this item id : '|| l_inventory_item_id||' '||l_new_item_code;
                                             RAISE ERROR_ENCOUNTERED;
                    END IF;    
                                    end if;


                                -- Above  fix is for ARS01/ARS02-- By syed 030207/062507--
                        ----------------------------------------------------------
                            l_error_msg:='Bfr Insert into swg_special_pricing ';

                              INSERT    INTO     swg_special_pricing( special_pricing_id
                                                       ,customer_id
                                                       ,ship_to_site_use_id
                                                       ,inventory_item_id
                                                       ,start_date_active
                                                       ,end_date_active
                                                       ,pricing_mechanism
                                                       ,special_price
                                                       ,bid_flag
                                                       ,special_price_reason
                                                        ,pricing_source
                                                       ,created_by
                                                       ,creation_date
                                                       ,last_updated_by
                                                       ,last_update_date
                                                       ,attribute5
                                                       ,attribute6
                                                       ,attribute7
                                                       ,attribute8
                                                       ,attribute9
                                                       ,creation_time_list_price
                                                      )
                            VALUES                    (swg_special_pricing_s1.NEXTVAL
                                                    ,l_temp_cust_rec.oracle_customer_id
                                                    ,l_temp_cust_rec.site_use_id
                                                    ,NVL(l_related_item_id,l_inventory_item_id)
                                                    ,l_temp_cust_rec.valid_from_date
                                                    ,l_temp_cust_rec.valid_to_date
                                                    ,l_pricing_mechanism
                                                    ,l_spl_price
                                                    ,'N'
                                                    ,'CONVERSION'
                                                     ,'CONVERSION'
                                                    ,'-1'
                                                    ,SYSDATE
                                                    ,'-1'
                                                    ,SYSDATE
                                                     ,l_temp_cust_rec.sales_center
                                                     ,l_temp_cust_rec.customer_number
                                                     ,l_temp_cust_rec.delivery_location_number
                                                     ,l_temp_cust_rec.item_code
                                                     ,l_list_price||'-'||l_temp_cust_rec.special_price
                                                     ,l_list_price
                                                    );
                    --6) Update special_price_proc_flag
                        UPDATE swgcnv_dd_special_price
                    SET    special_price_proc_flag = 'Y'
                    WHERE  sales_center = l_temp_cust_rec.sales_center
                        AND    customer_number = l_temp_cust_rec.customer_number
                                        AND    delivery_location_number = l_temp_cust_rec.delivery_location_number
                                        AND    item_code = l_temp_cust_rec.item_code
                                        AND    nvl(item_sub_code,'X') = nvl(l_temp_cust_rec.item_sub_code,'X'); --Added null handling

                                       l_spl_price_proc_cnt := l_spl_price_proc_cnt + 1;
                                      ELSE
                                         l_spl_price_bottle_ignored_cnt := l_spl_price_bottle_ignored_cnt + 1;
                      END IF;
                                 END IF;
         END IF;
  EXCEPTION
  WHEN ERROR_ENCOUNTERED THEN
           Fnd_File.put_line(Fnd_File.LOG,l_error_msg);
           Insert_Exception ( 'PRICING - CONV'
                          ,l_temp_cust_rec.legacy_customer_number
                          ,NULL
                          ,l_error_msg
                          ,in_sales_center_s
                        );
               l_spl_price_fail_cnt := l_spl_price_fail_cnt + 1;
 WHEN OTHERS THEN --Added on 030107--Syed

                   l_error_msg :=l_error_msg ||':'||SQLERRM;
             Fnd_File.put_line(Fnd_File.LOG,l_error_msg);
           Insert_Exception ( 'PRICING - CONV'
                          ,l_temp_cust_rec.legacy_customer_number
                          ,NULL
                          ,substr(l_error_msg ||l_temp_cust_rec.oracle_customer_id||' : '||l_temp_cust_rec.site_use_id||' : '||NVL(l_related_item_id,l_inventory_item_id)||' : '||to_char(l_temp_cust_rec.valid_from_date),1,2000)
                          ,in_sales_center_s
                        );   

  END;
  END LOOP;
  Fnd_File.put_line(Fnd_File.output,'No. of Special Price Records          : '||l_spl_price_cnt);
  Fnd_File.put_line(Fnd_File.output,'No. of Special Price Records Processed : '||l_spl_price_proc_cnt);
  Fnd_File.put_line(Fnd_File.output,'No. of Special Price Bottles Ignored  : '||l_spl_price_bottle_ignored_cnt);
  Fnd_File.put_line(Fnd_File.output,'No. of Special Price Records Failed   : '||l_spl_price_fail_cnt);
  COMMIT;
EXCEPTION
       WHEN NO_DATA_FOUND THEN
        Fnd_File.put_line(Fnd_File.LOG,'No Data found : '||SQLERRM);
        out_errnum_n := 2;
        out_errbuf_s := SQLERRM;
       WHEN OTHERS THEN
               -- Fnd_File.put_line(Fnd_File.LOG,'No Data found : '||SQLERRM); --Commented on 030107--syed
        Fnd_File.put_line(Fnd_File.LOG,' When Others : '||l_error_msg||':'||SQLERRM); --Added on 030107 by syed
        out_errnum_n := 2;
        out_errbuf_s := SQLERRM;
END        pricing_conversion;

PROCEDURE    Insert_Exception ( in_conversion_type_s        IN    VARCHAR2
                              ,in_conversion_key_value_s    IN    VARCHAR2
                              ,in_conversion_key_sub1_s    IN    VARCHAR2
                              ,in_error_message_s        IN    VARCHAR2
                              ,in_conversion_key_sub2_s    IN    VARCHAR2
                             )
IS
BEGIN
    INSERT
    INTO    swgcnv_conversion_exceptions
            ( conversion_type
             ,conversion_key_value
             ,conversion_sub_key1
             ,error_message
             ,conversion_sub_key2
            )
    VALUES    ( in_conversion_type_s
             ,in_conversion_key_value_s
             ,in_conversion_key_sub1_s
             ,in_error_message_s
             ,in_conversion_key_sub2_s
            );
EXCEPTION
    WHEN OTHERS THEN
         Fnd_File.put_line(Fnd_File.LOG,'eRROR Calling insert_exception procedure : '||SQLERRM);
END        Insert_Exception;
--
-- Commented for OPS10 and needs to be recomment based on next sacs conversions
PROCEDURE swgcnv_bottle_deposit (out_errbuf_s          OUT    VARCHAR2
                                      ,out_errnum_n          OUT    NUMBER
                                     ,in_legacy_system_s   IN    VARCHAR2
                                       ,in_sales_center_s      IN    VARCHAR2
                                  )
IS
CURSOR cur_customer_info(in_warehouse_id NUMBER)
IS
SELECT    a.oracle_customer_id         customer_id
--,        a.new_sales_center             sales_center
,        b.sales_center                sales_center
,        a.legacy_customer_number    legacy_customer_number
,        b.delivery_location_number
,        b.bottle_deposit_amt
,        hcsu.site_use_id
,        hcsu.price_list_id
,        rate_schedule
FROM    swgcnv_dd_temp_customers     a
,         swgcnv_dd_customer_shipto   b
,        hz_cust_acct_sites           hcas
,        hz_cust_site_uses            hcsu
WHERE     a.legacy_customer_number     =  b.customer_number
AND     b.bot_deposit_proc_flag        =  'N'
AND     hcas.cust_account_id         =  a.oracle_customer_id
AND     hcsu.cust_acct_site_id         =  hcas.cust_acct_site_id
AND     hcsu.site_use_code                =  'SHIP_TO'
AND     b.sales_center                =  in_sales_center_s
AND     hcsu.warehouse_id            =  in_warehouse_id
--AND     rate_schedule               <> 2000
AND     hcsu.orig_system_reference  LIKE 'DD-'||in_legacy_system_s||'-'||in_sales_center_s||'-%'||LTRIM(b.delivery_location_number,0)||'%'
AND     nvl(b.bottle_deposit_amt,-999)        <> 6; --Added on 022507 handling null-- Syed--
--AND     b.bottle_deposit_amt        <> 6;  --Commented on 022507 --

CURSOR cur_item_info
IS
SELECT mtl.inventory_item_id
,       mtl.segment1
,       mtl.description
,       a.old_code
FROM  swgcnv_map   a
,     mtl_system_items_b mtl
WHERE a.system_code   = in_legacy_system_s
AND   a.type_code     = 'BOTDEPOSIT'
AND   a.old_code      = in_sales_center_s
AND   mtl.segment1    = a.new_code
AND   mtl.organization_id = 5;

        l_pricelist_cnt NUMBER:= 0;
        l_customer_cnt  NUMBER:= 0;
        l_error_cnt     NUMBER:= 0;
        l_warehouse_id  NUMBER:= 0;
        l_bot_price        NUMBER:= 0;
        l_pstatus_c        VARCHAR2(10);
        l_message_s        VARCHAR2(2000);
        l_debug_c        VARCHAR2(10);
        l_list_price    NUMBER;


BEGIN

--Fnd_Client_Info.set_org_context(2);
   mo_global.set_policy_context('S', 2);   -- modified by Ajay on 9/2/2008 for R12

SELECT organization_id
INTO   l_warehouse_id
FROM   org_organization_definitions
WHERE  organization_code = in_sales_center_s;

FOR l_cust_rec IN cur_customer_info(l_warehouse_id)
LOOP
    FOR l_item_rec IN cur_item_info
    LOOP


if l_cust_rec.rate_schedule = 2000 then
-- pricing
                l_pstatus_c             :=    NULL;
                l_message_s             :=    NULL;
                l_debug_c             :=    NULL;
                l_list_price        :=  NULL;
                l_bot_price            :=  0;
                Swg_Pricing_Pkg.swg_get_list_price ( in_price_list_id_n    => l_cust_rec.price_list_id
                                                      , in_item_id_n        => l_item_rec.inventory_item_id
                                                   , in_pricing_date_d    => TRUNC(SYSDATE)
                                                       , io_list_price_n     => l_list_price
                                                       , io_status_c        => l_pstatus_c
                                                       , io_message_s        => l_message_s
                                                      , in_debug_c            => l_debug_c
                                                       );
--Pricing

        BEGIN
        INSERT    INTO     swg_special_pricing(special_pricing_id
                                               ,customer_id
                                            ,ship_to_site_use_id
                                            ,inventory_item_id
                                            ,start_date_active
                                            ,end_date_active
                                            ,pricing_mechanism
                                            ,special_price
                                            ,bid_flag
                                            ,special_price_reason
                                            ,pricing_source
                                            ,created_by
                                            ,creation_date
                                            ,last_updated_by
                                            ,last_update_date
                                            ,attribute5
                                            ,attribute6
                                            ,attribute7
                                            ,creation_time_list_price
                                           )
                                    VALUES
                                           (swg_special_pricing_s1.NEXTVAL
                                           ,l_cust_rec.customer_id
                                           ,l_cust_rec.site_use_id
                                           ,l_item_rec.inventory_item_id
                                           ,TRUNC(SYSDATE)
                                           ,NULL
                                           ,'NEW'
                                           ,0
                                           ,'N'
                                           ,'CONVERSION'
                                           ,'CONVERSION'
                                           ,-1
                                           ,SYSDATE
                                           ,-1
                                           ,SYSDATE
                                           ,l_cust_rec.sales_center
                                           ,l_cust_rec.legacy_customer_number
                                           ,l_cust_rec.delivery_location_number
                                           ,NVL(l_list_price,0)
                                           );
                    l_pricelist_cnt    :=    l_pricelist_cnt + 1;
                -- Process flag
            EXCEPTION
            WHEN OTHERS THEN
                     Fnd_File.put_line(Fnd_File.LOG,'Insert failed : '||l_cust_rec.legacy_customer_number );
                     l_error_cnt := l_error_cnt + 1;
            END;
else
-- pricing
                l_pstatus_c             :=    NULL;
                l_message_s             :=    NULL;
                l_debug_c             :=    NULL;
                l_list_price        :=  NULL;
                l_bot_price            :=  0;
                Swg_Pricing_Pkg.swg_get_list_price ( in_price_list_id_n    => l_cust_rec.price_list_id
                                                      , in_item_id_n        => l_item_rec.inventory_item_id
                                                   , in_pricing_date_d    => TRUNC(SYSDATE)
                                                       , io_list_price_n     => l_list_price
                                                       , io_status_c        => l_pstatus_c
                                                       , io_message_s        => l_message_s
                                                      , in_debug_c            => l_debug_c
                                                       );
--Pricing
     IF (l_cust_rec.sales_center = 'CHO' and l_cust_rec.bottle_deposit_amt = 0) then
         null;
     else
        BEGIN
        INSERT    INTO     swg_special_pricing(special_pricing_id
                                               ,customer_id
                                            ,ship_to_site_use_id
                                            ,inventory_item_id
                                            ,start_date_active
                                            ,end_date_active
                                            ,pricing_mechanism
                                            ,special_price
                                            ,bid_flag
                                            ,special_price_reason
                                            ,pricing_source
                                            ,created_by
                                            ,creation_date
                                            ,last_updated_by
                                            ,last_update_date
                                            ,attribute5
                                            ,attribute6
                                            ,attribute7
                                            ,creation_time_list_price
                                           )
                                    VALUES
                                           (swg_special_pricing_s1.NEXTVAL
                                           ,l_cust_rec.customer_id
                                           ,l_cust_rec.site_use_id
                                           ,l_item_rec.inventory_item_id
                                           ,TRUNC(SYSDATE)
                                           ,NULL
                                           ,'NEW'
                                           ,l_cust_rec.bottle_deposit_amt
                                           ,'N'
                                           ,'CONVERSION'
                                           ,'CONVERSION'
                                           ,-1
                                           ,SYSDATE
                                           ,-1
                                           ,SYSDATE
                                           ,l_cust_rec.sales_center
                                           ,l_cust_rec.legacy_customer_number
                                           ,l_cust_rec.delivery_location_number
                                           ,NVL(l_list_price,0)
                                           );
                    l_pricelist_cnt    :=    l_pricelist_cnt + 1;
                -- Process flag
            EXCEPTION
            WHEN OTHERS THEN
                     Fnd_File.put_line(Fnd_File.LOG,'Insert failed : '||l_cust_rec.legacy_customer_number );
                     l_error_cnt := l_error_cnt + 1;
            END;
        end if; --cho sales center
end if; --employee
  END LOOP; --item info
            BEGIN
                UPDATE swgcnv_dd_customer_shipto
                SET       bot_deposit_proc_flag    = 'Y'
                WHERE  customer_number         = l_cust_rec.legacy_customer_number
                AND    delivery_location_number = l_cust_rec.delivery_location_number
                AND    sales_center             = l_cust_rec.sales_center;
            EXCEPTION
            WHEN OTHERS THEN
                Fnd_File.put_line(Fnd_File.LOG,'Updation Failed : '||SQLERRM);
            END;
                    l_customer_cnt    :=    l_customer_cnt  + 1;
END LOOP; -- customer
    Fnd_File.put_line(Fnd_File.LOG,'No. of Customers        : '||l_customer_cnt);
    Fnd_File.put_line(Fnd_File.LOG,'No. of Pricelist Lines  : '||l_pricelist_cnt);
    COMMIT;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
       dbms_output.put_line('No Data Found : '||SQLERRM);
           Fnd_File.put_line(Fnd_File.LOG,'No Data Found : '||SQLERRM);
  WHEN OTHERS THEN
         dbms_output.put_line('eRROR         : '||SQLERRM);
           Fnd_File.put_line(Fnd_File.LOG,'eRROR         : '||SQLERRM);
END swgcnv_bottle_deposit;
 -- needs to be recomments after sacs10
--
PROCEDURE swgcnv_tier_pricing  (out_errbuf_s        OUT    VARCHAR2
                                     ,out_errnum_n        OUT    NUMBER
                                  ,in_legacy_system_s  IN    VARCHAR2
                               ,in_division_s        IN    VARCHAR2
                                ,in_sales_center_s    IN    VARCHAR2
                                  )
IS
CURSOR cur_cust_info(in_warehouse_id NUMBER)
IS
SELECT hzcas.cust_account_id
,       hzcas.cust_acct_site_id
,       hzcsu.site_use_id
,       hzcsu.site_use_code
,       hzp.party_type
,       b.rate_schedule
,       hzca.account_number
,       b.delivery_location_number
,       b.customer_number
,       b.ship_to_start_date
FROM  hz_parties                    hzp
,      hz_cust_accounts              hzca
,      hz_cust_acct_sites          hzcas
,      hz_cust_site_uses              hzcsu
,     swgcnv_dd_customer_shipto   b
,      swgcnv_dd_temp_customers      a
WHERE hzcas.orig_system_reference LIKE 'DD-'||in_legacy_system_s||'-'||in_sales_center_s||'%'||LTRIM(b.delivery_location_number,0)||'%'
AND   hzp.party_id                  =  hzca.party_id
AND   hzca.cust_account_id          =  hzcas.cust_account_id
AND   a.oracle_customer_id          =  hzca.cust_account_id
AND   a.legacy_customer_number      =  b.customer_number
AND   b.division                  =  in_division_s
AND   b.sales_center              =  in_sales_center_s
AND   hzcsu.cust_acct_site_id     =  hzcas.cust_acct_site_id
AND   hzcsu.site_use_code          =  'SHIP_TO'
AND   hzcsu.warehouse_id          =  in_warehouse_id
AND   b.tier_price_proc_flag      = 'N'
AND   b.rate_schedule             IN ('0001'
                                       ,'0002'
                                     ,'0003'
                                     ,'0004'
                                     ,'0005'
                                     ,'0006'
                                     ,'0007'
                                     ,'0008'
                                     ,'0009'
                                     ,'0010'
                                     ,'0011'
                                   );
     l_organization_id_n    NUMBER;
     l_price_point_id        NUMBER;
     l_list_price            NUMBER;
     l_cnt                    NUMBER := 0;
     l_error_cnt            NUMBER := 0;
     l_error_msg              VARCHAR2(400) := NULL;
     l_zero_cnt                NUMBER := 0;

BEGIN

--Fnd_Client_Info.set_org_context(2);
   mo_global.set_policy_context('S', 2);   -- modified by Ajay on 9/2/2008 for R12

--Organization_id
BEGIN
  SELECT organization_id
  INTO   l_organization_id_n
  FROM   org_organization_definitions
  WHERE  organization_code = in_sales_center_s;
EXCEPTION
  WHEN OTHERS THEN
       DBMS_OUTPUT.PUT_LINE('Error while getting the organization id : '||SQLERRM);
       Fnd_File.put_line(Fnd_File.LOG,'Error while getting the organization id : '||SQLERRM);
END;


FOR i IN cur_cust_info(l_organization_id_n)
LOOP

--Price point id
BEGIN
  SELECT price_point_id
  INTO   l_price_point_id
  FROM   swg_price_points
  WHERE  price_point           =   i.rate_schedule
  AND    customer_type           =   i.party_type
  AND    organization_id       =   l_organization_id_n;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
         dbms_output.put_line('No Data found for this '||i.rate_schedule||'-'||i.party_type||'-'||l_organization_id_n);
       Fnd_File.put_line(Fnd_File.LOG,'No Data found for this '||i.rate_schedule||'-'||i.party_type||'-'||l_organization_id_n);
  WHEN OTHERS THEN
       dbms_output.put_line('Error while retreving the price_point_id '||i.rate_schedule||'-'||i.party_type||'-'||l_organization_id_n||' '||SQLERRM);
       Fnd_File.put_line(Fnd_File.LOG,'Error while retreving the price_point_id '||i.rate_schedule||'-'||i.party_type||'-'||l_organization_id_n||' '||SQLERRM);
END;

BEGIN
     SELECT creation_time_list_price
     INTO   l_list_price
     FROM   swg_special_pricing
     WHERE  customer_id          = i.cust_account_id
     AND    ship_to_site_use_id  = i.site_use_id
     AND    pricing_mechanism     = 'AMT'
     AND    ROWNUM = 1;
EXCEPTION

  WHEN OTHERS THEN
--       dbms_output.put_line('Error while retreving the list price : '||i.cust_account_id||'-'||i.site_use_id);
       l_list_price := 0;
       l_zero_cnt := l_zero_cnt + 1;
END;


BEGIN
     INSERT INTO swg_special_pricing( special_pricing_id
                                           ,customer_id
                                           ,ship_to_site_use_id
                                           ,inventory_item_id
                                           ,start_date_active
                                           ,end_date_active
                                           ,pricing_mechanism
                                           ,special_price
                                           ,bid_flag
                                           ,special_price_reason
                                            ,pricing_source
                                           ,created_by
                                           ,creation_date
                                           ,last_updated_by
                                           ,last_update_date
                                           ,attribute5
                                           ,attribute6
                                           ,attribute7
                                           ,attribute8
                                           ,attribute9
                                           ,creation_time_list_price
                                        ,price_point_id
                                          )
                VALUES
                                          ( swg_special_pricing_s1.NEXTVAL
                                         ,i.cust_account_id
                                         ,i.site_use_id
                                         ,0
                                        ,NVL(i.ship_to_start_date,SYSDATE)
                                         ,NULL
                                         ,'TIER'
                                         ,0
                                         ,'N'
                                        ,'CUST SATIS-RECURRING'
                                         ,'CONVERSION'
                                         ,'-1'
                                         ,SYSDATE
                                         ,'-1'
                                         ,SYSDATE
                                         ,in_sales_center_s
                                         ,i.customer_number                      --l_legacy_spcl_price_rec.customer_number
                                         ,i.delivery_location_number           --l_legacy_spcl_price_rec.delivery_location_number
                                         ,0                                   --l_legacy_spcl_price_rec.item_code
                                         ,0                                   --l_legacy_spcl_price_rec.standard_price ||l_orcl_list_price
                                         ,l_list_price                       --l_legacy_spcl_price_rec.standard_price
                                        ,l_price_point_id
                                        );

                        UPDATE swgcnv_dd_customer_shipto
                        SET       tier_price_proc_flag      = 'Y'
                        WHERE  sales_center              = in_sales_center_s
                        AND    delivery_location_number  = i.delivery_location_number
                        AND    customer_number             = i.customer_number;

                    l_cnt := l_cnt + 1;
EXCEPTION
  WHEN OTHERS THEN
     dbms_output.put_line('Error while inserting data into pricing table : '||SQLERRM);
     Fnd_File.put_line(Fnd_File.LOG,'Error while inserting data into pricing table : '||SQLERRM);
                         UPDATE swgcnv_dd_customer_shipto
                        SET       tier_price_proc_flag      = 'E'
                        WHERE  sales_center              = in_sales_center_s
                        AND    delivery_location_number  = i.delivery_location_number
                        AND    customer_number             = i.customer_number;
    l_error_cnt := l_error_cnt + 1;
END;

END LOOP;
COMMIT;
dbms_output.put_line('No.of Records are inserted               : '||l_cnt);
dbms_output.put_line('No.of Records are zero price list        : '||l_zero_cnt);
dbms_output.put_line('No.of Records are failed while inserting : '||l_error_cnt);
Fnd_File.put_line(Fnd_File.LOG,'No.of Records are inserted               : '||l_cnt);
Fnd_File.put_line(Fnd_File.LOG,'No.of Records are zero price list        : '||l_zero_cnt);
Fnd_File.put_line(Fnd_File.LOG,'No.of Records are failed while inserting : '||l_error_cnt);
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      dbms_output.put_line('No data found : '||SQLERRM);
      Fnd_File.put_line(Fnd_File.LOG,'No data found : '||SQLERRM);
   WHEN OTHERS THEN
      dbms_output.put_line('eRROR   : '||SQLERRM);
      Fnd_File.put_line(Fnd_File.LOG,'eRROR   : '||SQLERRM);
END swgcnv_tier_pricing;
--
PROCEDURE swgcnv_price_point_proc (out_errbuf_s                  OUT    VARCHAR2
                                   ,out_errnum_n              OUT    NUMBER
                                   ,in_sales_center_from_s IN    VARCHAR2
                                  ,in_sales_center_to_s      IN    VARCHAR2
                                    )
IS

CURSOR    cur_org          (in_org_code_s         VARCHAR2)
IS
SELECT    organization_id
FROM    mtl_parameters
WHERE    organization_code    =    in_org_code_s;

CURSOR    cur_price_points (in_org_id_n         NUMBER)
IS
SELECT    a.*
FROM    swg_price_points    a
WHERE    organization_id        =    in_org_id_n;

CURSOR    cur_pp_details   (in_price_point_id_n NUMBER)
IS
SELECT    a.*
FROM    swg_price_point_details    a
WHERE    price_point_id        =    in_price_point_id_n;

CURSOR    cur_ddy_org
IS
SELECT  organization_id
,        organization_code
FROM    mtl_parameters
WHERE   organization_code    = UPPER(in_sales_center_to_s);

CURSOR    cur_pp_exists ( in_org_id_n            NUMBER
                          ,in_price_point_s        VARCHAR2
                          ,in_customer_type_s    VARCHAR2
                         )
IS
SELECT    'Y'
FROM    swg_price_points
WHERE    organization_id        =    in_org_id_n
AND        price_point            =    in_price_point_s
AND        customer_type        =    in_customer_type_s;

    l_copy_from_org_s            VARCHAR2(3)    :=    UPPER(in_sales_center_from_s);
    l_org_id_n                    NUMBER;
    l_exists_c                    VARCHAR2(1);
    l_new_price_points_id        NUMBER;
    l_detail_cnt                NUMBER:= 0;
    l_header_cnt                NUMBER:= 0;

BEGIN
--1st Step
    OPEN    cur_org ( l_copy_from_org_s );
    FETCH    cur_org
    INTO    l_org_id_n;
            IF cur_org%NOTFOUND THEN
               l_org_id_n    :=    NULL;
               dbms_output.put_line ('Copy Organization Code is not valid' );
               RETURN;
            END IF;
    CLOSE    cur_org;

--2nd Step
FOR    l_org_rec    IN    cur_ddy_org
LOOP
dbms_output.put_line ( '---------------------------------------------');
dbms_output.put_line ( 'Processing Organization: ' || l_org_rec.organization_code);
dbms_output.put_line ( '---------------------------------------------');
Fnd_File.put_line(Fnd_File.LOG,'Processing Organization: ' || l_org_rec.organization_code);
    FOR    l_price_point_rec IN cur_price_points (l_org_id_n)
    LOOP
            OPEN    cur_pp_exists (l_org_rec.organization_id
                                  ,l_price_point_rec.price_point
                                  ,l_price_point_rec.customer_type
                                  );
            FETCH    cur_pp_exists
            INTO    l_exists_c;
                    IF cur_pp_exists%NOTFOUND THEN
                    l_exists_c    :=    'N';
                    END IF;
            CLOSE    cur_pp_exists;
        IF l_exists_c    =    'N'    THEN
--Header
               SELECT    swg_price_points_s1.NEXTVAL
                INTO        l_new_price_points_id
               FROM     dual;
                INSERT
                INTO    swg_price_points
                VALUES    ( l_new_price_points_id
                        , (SELECT REPLACE (l_price_point_rec.description
                                            ,l_copy_from_org_s
                                          ,l_org_rec.organization_code
                                          )
                           FROM dual)
                        ,l_price_point_rec.price_point
                        ,l_price_point_rec.customer_type
                        ,l_org_rec.organization_id
                        ,l_price_point_rec.start_date_active
                        ,l_price_point_rec.end_date_active
                        ,l_price_point_rec.attribute1
                        ,l_price_point_rec.attribute2
                        ,l_price_point_rec.attribute3
                        ,l_price_point_rec.attribute4
                        ,l_price_point_rec.attribute5
                        ,'-1'
                        ,SYSDATE
                        ,'-1'
                        ,SYSDATE
                        ,l_price_point_rec.last_update_login
                        );
                        l_header_cnt := l_header_cnt + 1;
--Details
                FOR    l_pp_dtls_rec    IN    cur_pp_details (l_price_point_rec.price_point_id)
                LOOP
                        INSERT
                        INTO    swg_price_point_details
                        VALUES    (swg_price_point_details_s1.NEXTVAL
                                ,l_new_price_points_id
                                ,l_pp_dtls_rec.item_category
                                ,l_pp_dtls_rec.method
                                ,l_pp_dtls_rec.value
                                ,l_pp_dtls_rec.from_qty
                                ,l_pp_dtls_rec.to_qty
                                ,l_pp_dtls_rec.start_date_active
                                ,l_pp_dtls_rec.end_date_active
                                ,l_pp_dtls_rec.attribute1
                                ,l_pp_dtls_rec.attribute2
                                ,l_pp_dtls_rec.attribute3
                                ,l_pp_dtls_rec.attribute4
                                ,l_pp_dtls_rec.attribute5
                                ,'-1'
                                ,SYSDATE
                                ,'-1'
                                ,SYSDATE
                                ,l_pp_dtls_rec.last_update_login
                                );
                                l_detail_cnt := l_detail_cnt + 1;
                END LOOP; --l_pp_dtls_rec
      END IF; --l_exists_c
    END LOOP; --l_price_point_rec
        Fnd_File.put_line(Fnd_File.LOG,'No. of Header  Records : '||l_header_cnt||' for Sales Center : '||l_org_rec.organization_code);
        Fnd_File.put_line(Fnd_File.LOG,'No. of Details Records : '||l_detail_cnt||' for Sales Center : '||l_org_rec.organization_code);
        l_header_cnt  := 0;
        l_detail_cnt  := 0;
END LOOP;--l_org_rec
COMMIT;
EXCEPTION
       WHEN NO_DATA_FOUND THEN
            Fnd_File.put_line(Fnd_File.LOG,'No Data found : '||SQLERRM);
            out_errnum_n := 2;
            out_errbuf_s := SQLERRM;
       WHEN OTHERS THEN
            Fnd_File.put_line(Fnd_File.LOG,'No Data found : '||SQLERRM);
            out_errnum_n := 2;
            out_errbuf_s := SQLERRM;
END swgcnv_price_point_proc;

PROCEDURE swgcnv_delete_conv_pricing(out_errbuf_s        OUT    VARCHAR2
                    ,out_errnum_n        OUT    NUMBER
                    ,p_sales_center_in  IN  VARCHAR2 ) AS

CURSOR c1 IS
   SELECT tc.oracle_customer_id
     FROM swgcnv_dd_temp_customers tc
          , swgcnv_dd_customer_shipto ship
    WHERE tc.legacy_customer_number = ship.customer_number
      AND ship.sales_center = p_sales_center_in;

l_del_count NUMBER := 0;

BEGIN
--   LOCK TABLE swg_special_pricing in exclusive mode nowait;
   FOR c1_rec IN c1 LOOP
       DELETE FROM swg_special_pricing WHERE customer_id  = c1_rec.oracle_customer_id;
       l_del_count := l_del_count + SQL%ROWCOUNT;
   END LOOP;
   Fnd_File.put_line(Fnd_File.LOG,'Number of Records Deleted : '||l_del_count);

EXCEPTION
WHEN OTHERS THEN
   Fnd_File.put_line(Fnd_File.LOG,'Error Occurred During Deletion: '||SQLERRM);
END swgcnv_delete_conv_pricing;
/* Bottle deposit for OPS10 -- ONLY FOR EMPLOYEE */
/*
PROCEDURE swgcnv_bottle_deposit (out_errbuf_s          OUT    VARCHAR2
                                      ,out_errnum_n          OUT    NUMBER
                                     ,in_legacy_system_s   IN    VARCHAR2
                                       ,in_sales_center_s      IN    VARCHAR2
                                  )
IS
CURSOR cur_customer_info(in_warehouse_id NUMBER)
IS
SELECT    a.oracle_customer_id         customer_id
,        b.sales_center                sales_center
,        a.legacy_customer_number    legacy_customer_number
,        b.delivery_location_number
,        b.bottle_deposit_amt
,        hcsu.site_use_id
,        hcsu.price_list_id
FROM    swgcnv_dd_temp_customers     a
,         swgcnv_dd_customer_shipto   b
,        hz_cust_acct_sites           hcas
,        hz_cust_site_uses            hcsu
WHERE     a.legacy_customer_number     =  b.customer_number
AND     b.bot_deposit_proc_flag        =  'N'
AND     hcas.cust_account_id         =  a.oracle_customer_id
AND     hcsu.cust_acct_site_id         =  hcas.cust_acct_site_id
AND     hcsu.site_use_code                =  'SHIP_TO'
AND     b.sales_center                =  in_sales_center_s
AND     hcsu.warehouse_id            =  in_warehouse_id
AND     rate_schedule               = 2000
AND     hcsu.orig_system_reference  LIKE 'DD-'||in_legacy_system_s||'-'||in_sales_center_s||'-%'||LTRIM(b.delivery_location_number,0)||'%'
;

CURSOR cur_item_info
IS
SELECT mtl.inventory_item_id
,       mtl.segment1
,       mtl.description
,       a.old_code
FROM  swgcnv_map   a
,     mtl_system_items_b mtl
WHERE a.system_code   = in_legacy_system_s
AND   a.type_code     = 'BOTDEPOSIT'
AND   a.old_code      = in_sales_center_s
AND   mtl.segment1    = a.new_code
AND   mtl.organization_id = 5;

        l_pricelist_cnt NUMBER:= 0;
        l_customer_cnt  NUMBER:= 0;
        l_error_cnt     NUMBER:= 0;
        l_warehouse_id  NUMBER:= 0;
        l_bot_price        NUMBER:= 0;
        l_pstatus_c        VARCHAR2(10);
        l_message_s        VARCHAR2(2000);
        l_debug_c        VARCHAR2(10);
        l_list_price    NUMBER;


BEGIN

--Fnd_Client_Info.set_org_context(2);
   mo_global.set_policy_context('S', 2);   -- modified by Ajay on 9/2/2008 for R12

SELECT organization_id
INTO   l_warehouse_id
FROM   org_organization_definitions
WHERE  organization_code = in_sales_center_s;

FOR l_cust_rec IN cur_customer_info(l_warehouse_id)
LOOP
    FOR l_item_rec IN cur_item_info
    LOOP

-- pricing
                l_pstatus_c             :=    NULL;
                l_message_s             :=    NULL;
                l_debug_c             :=    NULL;
                l_list_price        :=  NULL;
                l_bot_price            :=  0;
                Swg_Pricing_Pkg.swg_get_list_price ( in_price_list_id_n    => l_cust_rec.price_list_id
                                                      , in_item_id_n        => l_item_rec.inventory_item_id
                                                   , in_pricing_date_d    => TRUNC(SYSDATE)
                                                       , io_list_price_n     => l_list_price
                                                       , io_status_c        => l_pstatus_c
                                                       , io_message_s        => l_message_s
                                                      , in_debug_c            => l_debug_c
                                                       );
--Pricing

        BEGIN
        INSERT    INTO     swg_special_pricing(special_pricing_id
                                               ,customer_id
                                            ,ship_to_site_use_id
                                            ,inventory_item_id
                                            ,start_date_active
                                            ,end_date_active
                                            ,pricing_mechanism
                                            ,special_price
                                            ,bid_flag
                                            ,special_price_reason
                                            ,pricing_source
                                            ,created_by
                                            ,creation_date
                                            ,last_updated_by
                                            ,last_update_date
                                            ,attribute5
                                            ,attribute6
                                            ,attribute7
                                            ,creation_time_list_price
                                           )
                                    VALUES
                                           (swg_special_pricing_s1.NEXTVAL
                                           ,l_cust_rec.customer_id
                                           ,l_cust_rec.site_use_id
                                           ,l_item_rec.inventory_item_id
                                           ,TRUNC(SYSDATE)
                                           ,NULL
                                           ,'NEW'
                                           ,0
                                           ,'N'
                                           ,'CONVERSION'
                                           ,'CONVERSION'
                                           ,-1
                                           ,SYSDATE
                                           ,-1
                                           ,SYSDATE
                                           ,l_cust_rec.sales_center
                                           ,l_cust_rec.legacy_customer_number
                                           ,l_cust_rec.delivery_location_number
                                           ,NVL(l_list_price,0)
                                           );
                    l_pricelist_cnt    :=    l_pricelist_cnt + 1;
                -- Process flag
            EXCEPTION
            WHEN OTHERS THEN
                     Fnd_File.put_line(Fnd_File.LOG,'Insert failed : '||l_cust_rec.legacy_customer_number );
                     l_error_cnt := l_error_cnt + 1;
            END;
  END LOOP; --item info
            BEGIN
                UPDATE swgcnv_dd_customer_shipto
                SET       bot_deposit_proc_flag    = 'Y'
                WHERE  customer_number         = l_cust_rec.legacy_customer_number
                AND    delivery_location_number = l_cust_rec.delivery_location_number
                AND    sales_center             = l_cust_rec.sales_center;
            EXCEPTION
            WHEN OTHERS THEN
                Fnd_File.put_line(Fnd_File.LOG,'Updation Failed : '||SQLERRM);
            END;
                    l_customer_cnt    :=    l_customer_cnt  + 1;
END LOOP; -- customer
    Fnd_File.put_line(Fnd_File.LOG,'No. of Customers        : '||l_customer_cnt);
    Fnd_File.put_line(Fnd_File.LOG,'No. of Pricelist Lines  : '||l_pricelist_cnt);
    COMMIT;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
       dbms_output.put_line('No Data Found : '||SQLERRM);
           Fnd_File.put_line(Fnd_File.LOG,'No Data Found : '||SQLERRM);
  WHEN OTHERS THEN
         dbms_output.put_line('eRROR         : '||SQLERRM);
           Fnd_File.put_line(Fnd_File.LOG,'eRROR         : '||SQLERRM);
END swgcnv_bottle_deposit;
----
*/
END Swgcnv_Pricing_Conv;
/
show err;
exit;
