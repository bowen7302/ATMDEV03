create or replace 
PACKAGE BODY Swgcnv_Dd_Customer_Pub_Pkg
AS

/* $Header: SWGCNV_DD_CUSTOMER_PUB_PKB.pls  1.1 2010/04/09 09:33:33 PU $ */
/*==========================================================================================+
| Copyright (c) 2005 DS Waters, Atlanta, GA 30328 USA All rights reserved.                  |
+===========================================================================================+
|  Name:           SWGCNV_DD_CUSTOMER_PUB_PKG                                               |
|  File:           SWGCNV_DD_CUSTOMER_PUB_PKB.pls                                           |
|                                                                                           |
|  Description:    Package Body For Customer Conversion                                     |
|  Company:        DS Waters                                                                |
|  Author:         Unknown                                                                  |
|  Date:           Unknown                                                                  |
|                                                                                           |
|  Modification History:                                                                    |
|  Date            Author            Description                                            |
|  ----            ------            -----------                                            |
|  Unknown         Unknown           Production Release                                     |
|  07/29/2008      Pankaj Umate      Modified For WTRFLX1 Conversion. Daptiv No: 555        |
|  01/09/2009      Pankaj Umate      Changes To Fix Orig System Reference Fix Problem in    |
|                                    Customer Standard Page.Daptiv Project # 768            |
|  11/29/2009      Pankaj Umate      Modified For SAGE Conversion. Daptiv Project # 1299    |
|  04/09/2010      Pankaj Umate      Daptiv # 1471. Conversion Mapping Table Migration      |
|  04/24/2012      Bala Palani       Modified ATTRIBUTE14 (line 671) for IBM01 WO:20129     |
|  07/24/2012      Stephen Bowen     WO:20457 Update tbl with Shipto_id for easy reference  |
|  06/07/2012      Bala Palani       WO:20457 added leg.cust number to orig_sys_ref         |
|  01/07/2014      Stephen Bowen     Added Restricted Price List Usage  EB-367/21850        |
|                                                                                           |  
|                                                                                           |
+==========================================================================================*/

    /*-----------------------------------------------------------------------------
              PACKAGE BODY RECORD TYPES
    -------------------------------------------------------------------------------*/

    TYPE  request_rec_type  IS  RECORD
  ( request_id      NUMBER
   ,proc_seq        NUMBER
  );

    /*------------------------------------------------------------------------------
              PACKAGE BODY TABLE TYPES
    --------------------------------------------------------------------------------*/

    TYPE  request_tbl_type  IS  TABLE OF  request_rec_type
    INDEX BY  BINARY_INTEGER;


PROCEDURE insert_exceptions
( in_customer_number_s   IN    VARCHAR2
 ,in_address_code_s      IN    VARCHAR2
 ,in_error_message_s     IN    VARCHAR2
 ,in_sales_center        IN    VARCHAR2
)
IS
BEGIN

    INSERT
    INTO  swgcnv_conversion_exceptions
    ( conversion_type
     ,conversion_key_value
     ,conversion_sub_key1
     ,conversion_sub_key2
     ,error_message
    )
    VALUES  ( 'CUSTOMER'
     ,in_customer_number_s
     ,in_address_code_s
     ,in_sales_center
     ,in_error_message_s
    );

END   insert_exceptions;

-----------------------------------------------------------

PROCEDURE swg_format_string
(io_msg_count_n   IN OUT NUMBER
,io_msg_data_s    IN OUT VARCHAR2)
IS

BEGIN

  IF (io_msg_count_n > 1)
  THEN

    FOR I IN 1..io_msg_count_n
    LOOP

      io_msg_data_s   := io_msg_data_s || TO_CHAR(I) || '. '
                                || SUBSTR(Fnd_Msg_Pub.Get(p_encoded => Fnd_Api.G_FALSE ), 1, 255)
                                ||CHR(10);

    END LOOP;

  END IF;
END;

-----------------------------------------------------------

PROCEDURE swg_cust_debug( in_debug_c VARCHAR2,in_debug_s  VARCHAR2)
IS
BEGIN
  IF NVL(in_debug_c,'N')  = 'Y' THEN

  --    dbms_output.put_line(in_debug_s);
        Fnd_File.Put_Line(Fnd_File.LOG, in_debug_s);

  END IF;
END;

--------------------------------------------------------------------

PROCEDURE       Initialize
(in_system_name_s               IN  VARCHAR2
,in_sales_center_s              IN  VARCHAR2
,in_debug_c                     IN  VARCHAR2
,ou_status_c                    OUT VARCHAR2
,ou_message_s                   OUT VARCHAR2)
IS
    CURSOR  cur_svc_interested_in
    IS
    SELECT m.old_code
          ,m.new_code
    FROM swgcnv_map    m
    WHERE m.system_code     = in_system_name_s
    AND m.type_code         = 'SVCINTRST';

    CURSOR  cur_cust_mrkt
    IS
    SELECT m.old_code
          ,m.new_code
    FROM swgcnv_map    m
    WHERE m.system_code     = in_system_name_s
    AND m.type_code         = 'CUSTMARKET';

    CURSOR  cur_cust_prfl
    IS
    SELECT m.old_code
          ,m.new_code
    FROM swgcnv_map    m
    WHERE m.system_code     = in_system_name_s
    AND m.type_code         = 'CUSTPROFL';

    CURSOR  cur_acct_stts
    IS
    SELECT m.old_code
          ,m.new_code
    FROM swgcnv_map    m
    WHERE m.system_code     = in_system_name_s
    AND m.type_code         = 'ACCNTSTTS';

    CURSOR  cur_tax_cls
    IS
    SELECT m.old_code||m.old_sub_code   old_code
          ,m.new_code
    FROM swgcnv_map    m
    WHERE m.system_code     = in_system_name_s
    AND m.type_code         = 'CUSTTAXCLS';

    CURSOR  cur_profile_class
    IS
    SELECT pc.name
          ,pc.profile_class_id
          ,pc.interest_charges
          ,pc.interest_period_days
    FROM hz_cust_profile_classes    pc;
  
  CURSOR cur_assoc_pricelist_id
  IS
  SELECT list_header_id 
    FROM   qp_list_headers_tl
    WHERE  name = 'DS WATERS ASSOCIATE';
  

    CURSOR  cur_stmt_cycle_map
    IS
    SELECT m.old_code||m.old_sub_code   old_code
          ,m.new_code
    FROM swgcnv_map    m
        ,swgcnv_map    m2
    WHERE m.system_code     = in_system_name_s
    AND m.type_code         = 'STMTCYCL'
    AND m2.system_code      =  in_system_name_s
    AND m2.type_code        = 'STATE' 
    AND m.old_sub_code      = m2.new_code
    AND m2.old_code         = in_sales_center_s;


    CURSOR  cur_stmt_cycle_id
    IS
    SELECT sc.statement_cycle_id
         , sc.name
    FROM ar_statement_cycles    sc;
  
    CURSOR  cur_state_sc
    IS
    SELECT m.new_code
    FROM  swgcnv_map    m
    WHERE m.system_code      =  in_system_name_s
    AND   m.type_code        = 'STATE'
    AND   m.old_code         = in_sales_center_s;


   -- Added by Ashok Krishnamurthy on 06/15/07 for ARS02 conversion (populate Details DFF -- ATTRIBUTE5 -- at Customer Header level) Begin

   CURSOR  cur_cust_mrkt_dtls
    IS
    SELECT m.old_code
          ,m.new_code
    FROM swgcnv_map    m
    WHERE m.system_code     = in_system_name_s
    AND m.type_code         = 'CUSTMKTDTL';

   -- Added by Ashok Krishnamurthy on 06/15/07 for ARS02 conversion (populate Details DFF -- ATTRIBUTE5 -- at Customer Header level) End  
  
BEGIN

    ou_status_c := G_SUCCESS_C;
    swg_cust_debug( 'Y', 'INITIALIZE');

    FOR l_svcintrst_rec IN cur_svc_interested_in
    LOOP
        swg_cust_debug
                (in_debug_c     => 'Y'
                ,in_debug_s     => 'Old Code::'||l_svcintrst_rec.old_code
                                    || ', New Code::'|| l_svcintrst_rec.new_code);
        g_svc_intrst(l_svcintrst_rec.old_code).new_code := l_svcintrst_rec.new_code;

    END LOOP;

    FOR l_custmrkt_rec IN cur_cust_mrkt
    LOOP
        swg_cust_debug
                (in_debug_c     => in_debug_c
                ,in_debug_s     => 'Old Code::'|| l_custmrkt_rec.old_code
                                    || ', New Code::'|| l_custmrkt_rec.new_code);
        g_cust_mrkt(l_custmrkt_rec.old_code).new_code := l_custmrkt_rec.new_code;

    END LOOP;

    -- Added by Ashok Krishnamurthy on 06/15/07 for ARS02 conversion (populate Details DFF -- ATTRIBUTE5 -- at Customer Header level) Begin

    FOR l_custmrkt_dtl_rec IN cur_cust_mrkt_dtls
    LOOP
        swg_cust_debug
                (in_debug_c     => in_debug_c
                ,in_debug_s     => 'Old Code::'|| l_custmrkt_dtl_rec.old_code
                                    || ', New Code::'|| l_custmrkt_dtl_rec.new_code);
        g_cust_mrkt_dtls(l_custmrkt_dtl_rec.old_code).new_code := l_custmrkt_dtl_rec.new_code;

    END LOOP;

    -- Added by Ashok Krishnamurthy on 06/15/07 for ARS02 conversion (populate Details DFF -- ATTRIBUTE5 -- at Customer Header level) End

    FOR l_custprfl_rec IN cur_cust_prfl
    LOOP
        swg_cust_debug
                (in_debug_c     => in_debug_c
                ,in_debug_s     => 'Old Code::'|| l_custprfl_rec.old_code
                                    || ', New Code::'|| l_custprfl_rec.new_code);
        g_cust_prfl(l_custprfl_rec.old_code).new_code := l_custprfl_rec.new_code;

    END LOOP;

    FOR l_acctstts_rec IN cur_acct_stts
    LOOP
        swg_cust_debug
                (in_debug_c     => in_debug_c
                ,in_debug_s     => 'Old Code::'|| l_acctstts_rec.old_code
                                    || ', New Code::'|| l_acctstts_rec.new_code);
        g_acct_stts(l_acctstts_rec.old_code).new_code := l_acctstts_rec.new_code;

    END LOOP;

    FOR l_taxcls_rec IN cur_tax_cls
    LOOP
        swg_cust_debug
                (in_debug_c     => in_debug_c
                ,in_debug_s     => 'Old Code::'|| l_taxcls_rec.old_code
                                    || ', New Code::'|| l_taxcls_rec.new_code);
        g_tax_cls(l_taxcls_rec.old_code).new_code := l_taxcls_rec.new_code;

    END LOOP;

    FOR l_prfl_cls_rec IN cur_profile_class
    LOOP

        g_prfl_cls(l_prfl_cls_rec.name).profile_class_id    := l_prfl_cls_rec.profile_class_id;
        g_prfl_cls(l_prfl_cls_rec.name).interest_charges    := l_prfl_cls_rec.interest_charges;
        g_prfl_cls(l_prfl_cls_rec.name).interest_period_days   := l_prfl_cls_rec.interest_period_days;

    END LOOP;
  
    FOR l_assoc_pricelist_id IN cur_assoc_pricelist_id
    LOOP
      g_assoc_price_list_id := l_assoc_pricelist_id.list_header_id;
    END LOOP; 

    FOR l_stmt_cycle_map_rec IN cur_stmt_cycle_map
    LOOP
        swg_cust_debug
                (in_debug_c     => in_debug_c
                ,in_debug_s     => 'Old Code::'|| l_stmt_cycle_map_rec.old_code
                                    || ', New Code::'|| l_stmt_cycle_map_rec.new_code);
        g_stmt_cycle_map(l_stmt_cycle_map_rec.old_code).new_code := l_stmt_cycle_map_rec.new_code;

    END LOOP;

    FOR l_stmt_cycle_id_rec IN cur_stmt_cycle_id
    LOOP
        swg_cust_debug
                (in_debug_c     => in_debug_c
                ,in_debug_s     => 'Statement Cycle Id::'|| l_stmt_cycle_id_rec.statement_cycle_id
                                    || ', Name: '|| l_stmt_cycle_id_rec.name);
        g_stmt_cycle_id(l_stmt_cycle_id_rec.name).stmt_cycle_id := l_stmt_cycle_id_rec.statement_cycle_id;
    IF l_stmt_cycle_id_rec.name = 'MONTHLY-28' THEN
       g_ddnational_stmt_cycle_id := l_stmt_cycle_id_rec.statement_cycle_id;
    END IF;

    END LOOP; 
  
    FOR l_state_sc IN cur_state_sc
    LOOP
        swg_cust_debug
                (in_debug_c     => in_debug_c
                ,in_debug_s     => 'Sales Center:'|| in_sales_center_s
                                    || ', State:'|| l_state_sc.new_code );
        g_state_sc := l_state_sc.new_code ;

    END LOOP; 
  
EXCEPTION
    WHEN OTHERS THEN
        ou_status_c     := G_UNEXP_ERROR_C;
        ou_message_s    := 'Unexpected Error: Initialize::'||SQLERRM;

END             Initialize;

/*---------------------------------------------------------------------------------------*/

PROCEDURE assign_sequences
( in_split_proc_cnt_n   IN  NUMBER
 ,in_sales_center_s         IN  VARCHAR2
 ,ou_child_proc_cnt_n   OUT NUMBER
 ,ou_status_c     OUT VARCHAR2
 ,ou_message_s      OUT VARCHAR2
)
IS

    CURSOR  cur_cust    (in_sc_s    VARCHAR2)
    IS
    SELECT  customer_id
    FROM  swgcnv_dd_customer_interface
    WHERE   sales_center    = in_sc_s;
--    AND ROWNUM <= 10;

    l_total_cust_cnt_n    NUMBER    :=  0;
    l_count_n         NUMBER    :=  0;
    l_seq_n             NUMBER    :=  0;
    l_split_cnt_n       NUMBER    :=  0;

BEGIN

    SELECT  COUNT(customer_id)
    INTO  l_total_cust_cnt_n
    FROM  swgcnv_dd_customer_interface
    WHERE   sales_center    = in_sales_center_s;
--    AND ROWNUM <= 10;

    IF l_total_cust_cnt_n = 0 THEN
      ou_status_c     :=  G_ERROR_C;
      ou_message_s  :=  'No customers found in SWGCNV_DD_CUSTOMER_INTERFACE';
      RETURN;
    END IF;

    l_split_cnt_n :=  CEIL (l_total_cust_cnt_n / in_split_proc_cnt_n);

    l_seq_n   :=  1;

    FOR l_cust_rec  IN  cur_cust (in_sales_center_s)
    LOOP

      l_count_n :=  l_count_n + 1;

      UPDATE  swgcnv_dd_customer_interface
      SET seq             = l_seq_n
      WHERE customer_id   = l_cust_rec.customer_id
        AND sales_center    = in_sales_center_s;


      IF l_count_n  > l_split_cnt_n THEN
          l_count_n :=  0;
          l_seq_n :=  l_seq_n + 1;
      END IF;

    END LOOP;

    COMMIT;

    ou_status_c     :=  G_SUCCESS_C;
    ou_message_s    :=  NULL;

    IF l_split_cnt_n > in_split_proc_cnt_n THEN

      ou_child_proc_cnt_n :=  in_split_proc_cnt_n;

    ELSE

      ou_child_proc_cnt_n :=  l_split_cnt_n;

    END IF;

EXCEPTION
    WHEN OTHERS THEN
        ou_message_s  :=  'Error in splitting: ' || SQLERRM;
        ou_status_c   :=  G_ERROR_C;
    
        ROLLBACK;

END   assign_sequences;

--------------------------------------------------------------------
FUNCTION        Is_Cust_Converted
                (in_customer_number_s       IN  VARCHAR2
                ,in_sales_center_s          IN  VARCHAR2
                ,in_system_name_s           IN  VARCHAR2)
RETURN  BOOLEAN
IS
    --
    -- function determines if the customer has already been converted
    --

    l_exists_c      VARCHAR2(1);

BEGIN

    SELECT 'Y'
    INTO l_exists_c
    FROM swgcnv_dd_temp_customers
    WHERE system_code               = in_system_name_s 
    AND new_sales_center            = in_sales_center_s
    AND legacy_customer_number      = in_customer_number_s;

    RETURN (TRUE);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN (FALSE);

    WHEN OTHERS THEN
        swg_cust_debug('Y', 'Unexpected Error in SWGCNV_DD_CUSTOMER_PUB_PKG.'
                            ||'Is_Cust_Converted.  ' ||SQLERRM);

        RETURN (FALSE);   

END             Is_Cust_Converted;     
    
--------------------------------------------------------------------

PROCEDURE       Populate_Cust_Acct_Rec
                        (in_system_name_s       IN  VARCHAR2
                        ,in_cust_rec            IN  swgcnv_dd_customer_interface%ROWTYPE
                        ,in_cust_ref_s          IN  VARCHAR2
                        ,in_debug_c             IN  VARCHAR2
                        ,ou_status_c            OUT VARCHAR2
                        ,ou_message_s           OUT VARCHAR2)
IS

    --
    -- procedure populates the customer account rec
    --
    l_customer_type_s       VARCHAR2(1)     := 'R';
    l_customer_status_s     VARCHAR2(1)     := 'A';
    l_attribute_category_s  VARCHAR2(20)    := 'DIRECT DELIVERY';
    l_svc_intrst_s      VARCHAR2(20)    := 'SVCINTRST';
    l_cust_mrkt_s           VARCHAR2(20)    := 'CUSTMARKET';

    l_new_code_s        VARCHAR2(100);
    l_new_sub_code_s      VARCHAR2(100);
    l_error_message_s   VARCHAR2(2000);

    -- Added by Ashok Krishnamurthy on 06/15/07 for ARS02 conversion (populate Details DFF -- ATTRIBUTE5 -- at Customer Header level) Begin

    l_cust_mrkt_dtl_s           VARCHAR2(20)  := 'CUSTMKTDTL';

    -- Added by Ashok Krishnamurthy on 06/15/07 for ARS02 conversion (populate Details DFF -- ATTRIBUTE5 -- at Customer Header level) End

BEGIN

    ou_status_c := G_SUCCESS_C;

    -- get the customer type depends on person flag

    IF LTRIM(RTRIM(in_cust_rec.person_flag)) = 'Y' THEN
      
        g_person_rec.person_first_name  := LTRIM(RTRIM(in_cust_rec.person_first_name));
        g_person_rec.person_last_name := LTRIM(RTRIM(in_cust_rec.person_last_name));
      
    ELSE
        g_person_rec.person_first_name        := NULL;
        g_person_rec.person_last_name       := NULL;
        g_organization_rec.organization_name  := LTRIM(RTRIM(in_cust_rec.customer_name));
        
    END IF;

    g_person_rec.created_by_module              := g_created_by_module;
    g_organization_rec.created_by_module        := g_created_by_module;

    g_cust_account_rec.customer_type            := l_customer_type_s;
    g_cust_account_rec.status                   := l_customer_status_s;
    g_cust_account_rec.created_by_module        := g_created_by_module;
    g_cust_account_rec.orig_system_reference    := in_cust_ref_s;
    g_cust_account_rec.attribute_category       := l_attribute_category_s;
    g_cust_account_rec.attribute1               := in_cust_rec.preferred_customer_flag;


    -- call the map procedure to get the oracle value for service interested in (SVCINTRST)

    --    l_new_code_s := NULL;

    swg_cust_debug(in_debug_c, 'Populate_Cust_Acct_Rec');

    IF g_svc_intrst(LTRIM(RTRIM(in_cust_rec.service_interested_in))).new_code = 'NOT MAPPED' THEN 
        l_error_message_s :=  l_svc_intrst_s
                                    ||' is not mapped in oracle mapping table '
                                    ||'old code '
                                    ||LTRIM(RTRIM(in_cust_rec.service_interested_in))
                                    || CHR(10) ||SQLERRM;

            -- Worthwhile to consider not raising the error, but continuing validation further?
        ou_status_c     := G_ERROR_C;
        ou_message_s    := l_error_message_s;
        RETURN;
    ELSE 
        g_cust_account_rec.attribute3   := g_svc_intrst(LTRIM(RTRIM(in_cust_rec.service_interested_in))).new_code;
    END IF;

    swg_cust_debug(in_debug_c,'Calling swgcnv_map procedure for '||l_svc_intrst_s);

    -- call the map procedure to get the oracle value for how did you hear about us (CUSTMARKET)

    l_new_code_s := NULL;

    swg_cust_debug(in_debug_c,'calling swgcnv_map procedure for '||l_cust_mrkt_s);

    IF  g_cust_mrkt(LTRIM(RTRIM(in_cust_rec.how_did_you_hear_about_us))).new_code = 'NOT MAPPED' THEN
    
      l_error_message_s :=  l_cust_mrkt_s
                                    || ' is not mapped in oracle mapping table '
                                    || 'old code '
                                    || LTRIM(RTRIM(in_cust_rec.how_did_you_hear_about_us))
                                    || CHR(10) ||SQLERRM;

            ou_status_c     := G_ERROR_C;
            ou_message_s    := l_error_message_s;
            RETURN;
    ELSE
        g_cust_account_rec.attribute4   := g_cust_mrkt(LTRIM(RTRIM(in_cust_rec.how_did_you_hear_about_us))).new_code;
    END IF;

    -- Added by Ashok Krishnamurthy on 06/15/07 for ARS02 conversion (populate Details DFF -- ATTRIBUTE5 -- at Customer Header level) Begin

    -- call the map procedure to get the oracle value for Details (CUSTMKTDTL)

    l_new_code_s := NULL;

    swg_cust_debug(in_debug_c,'calling swgcnv_map procedure for '||l_cust_mrkt_dtl_s);

    g_cust_account_rec.attribute5   := g_cust_mrkt_dtls(LTRIM(RTRIM(in_cust_rec.how_did_you_hear_about_us))).new_code;

    -- Added by Ashok Krishnamurthy on 06/15/07 for ARS02 conversion (populate Details DFF -- ATTRIBUTE5 -- at Customer Header level) End


    g_cust_account_rec.attribute1       := LTRIM(RTRIM(in_cust_rec.preferred_customer_flag));
    g_cust_account_rec.attribute6       := LTRIM(RTRIM(in_cust_rec.service_location));
    g_cust_account_rec.attribute7   := LTRIM(RTRIM(in_cust_rec.no_of_people_using_service));
    --  g_cust_account_rec.attribute8   := LTRIM(RTRIM(in_cust_rec.what_prompted_interest));        -- discontinued
    --  g_cust_account_rec.attribute9   := LTRIM(RTRIM(in_cust_rec.current_product_or_service));    -- discontinued
    g_cust_account_rec.attribute10    := LTRIM(RTRIM(in_cust_rec.monthly_invoice_format));        -- Billing Communication
    g_cust_account_rec.attribute11    := LTRIM(RTRIM(in_cust_rec.signed_delviery_receipt));       --Signature Requirements
    g_cust_account_rec.attribute12    := 'MAIL' ; -- Hardcode it to MAIL. Sacs7. LTRIM(RTRIM(in_cust_rec.billing_communications));
    -- g_cust_account_rec.attribute14   := TO_CHAR(TO_DATE(LTRIM(RTRIM(in_cust_rec.customer_start_date)),'DD-MON-RR'),'YYYY/MM/DD HH24:MI:SS');  

    g_cust_account_rec.attribute14    := TO_CHAR(TO_DATE(LTRIM(RTRIM(in_cust_rec.customer_start_date)),'DD-MON-RR'));  -- Added by Bala Palani (WO: 20129)

    g_cust_account_rec.attribute17      :=  'Y';  --Suppress Price on HH Ticket? 
    g_cust_account_rec.attribute18      :=  'Y';  --RSR Override Suppress Price?
   
    --
    -- Attributes added before RIMMW conversion
    --
    --    g_cust_account_rec.attribute5       --Details
    --    g_cust_account_rec.attribute13      --Existing Promos
    --    g_cust_account_rec.attribute15      --Lead Type
    --    g_cust_account_rec.attribute16      --DNIS#
    --    g_cust_account_rec.attribute19      --Price Change Allowed on HH?
    --    g_cust_account_rec.attribute20      --Receipt Printing on HH?
    --    g_cust_account_rec.attribute2       --Serial Control Allowed on HH?
EXCEPTION 
    WHEN OTHERS THEN
        ou_status_c     := G_UNEXP_ERROR_C;
        ou_message_s    := 'UNEXPECTED ERROR in Populate_Cust_Acct_Rec: '||SQLERRM;
        RETURN;
END             Populate_Cust_Acct_Rec;

--------------------------------------------------------------------

PROCEDURE       Populate_Cust_Profile_Rec
(in_system_name_s       IN  VARCHAR2
,in_collector_id_n      IN  NUMBER
,in_cust_rec            IN  swgcnv_dd_customer_interface%ROWTYPE
,in_debug_c             IN  VARCHAR2
,ou_status_c            OUT VARCHAR2
,ou_message_s           OUT VARCHAR2
,ou_profile_class_s     OUT VARCHAR2)
IS

    --
    -- procedure populates the customer profile rec
    --

    CURSOR cur_acct_status(in_customer_id IN NUMBER)
    IS
    SELECT account_status                 -- ie. Approved
          ,customer_profile_class_name    -- ie. DD COMM LOW
    FROM swgcnv_dd_customer_billto
    WHERE customer_id   = in_customer_id
    AND ROWNUM          = 1;

--     CURSOR cur_profile_class(in_class_name IN VARCHAR2)
--     IS
--     SELECT profile_class_id
--     FROM hz_cust_profile_classes
--     WHERE name          = in_class_name;       -- ie.DD COMM LOW

    l_cust_profl_s              VARCHAR2(20)    := 'CUSTPROFL';
    l_acct_stts_s           VARCHAR2(20)  := 'ACCNTSTTS';
    l_acct_status           VARCHAR2(100);
    l_profile_class           VARCHAR2(100);
    l_old_cust_prfl_s           VARCHAR2(100);
    l_new_code_s            VARCHAR2(100);
    l_new_sub_code_s          VARCHAR2(100);
    l_error_message_s       VARCHAR2(2000);

    l_profile_class_id        NUMBER;

BEGIN

    ou_status_c := G_SUCCESS_C;

    --
    -- Get the profile class and account status for the customer
    --

  OPEN cur_acct_status(in_cust_rec.customer_id);

  FETCH cur_acct_status
        INTO l_acct_status
        ,l_profile_class;

  IF  cur_acct_status%NOTFOUND THEN

        l_acct_status :=  NULL;
        l_profile_class :=  NULL;

    END IF;

    CLOSE cur_acct_status;

    -- call the map procedure to get the oracle value for CUSTPROFL

    swg_cust_debug(in_debug_c,'calling swgcnv_map procedure for '||l_cust_profl_s);

    l_old_cust_prfl_s   := l_profile_class;

    IF g_cust_prfl(l_profile_class).new_code = 'NOT MAPPED' THEN
        l_error_message_s :=  l_cust_profl_s
                                    ||' is not mapped in oracle mapping table '
                                    ||'old code '||LTRIM(RTRIM(l_profile_class));
    ELSE
        l_profile_class := g_cust_prfl(l_profile_class).new_code;
    END IF;

    --
    -- Get the profile class id given the profile class name
    --
    swg_cust_debug(in_debug_c,'get the oracle profile class id for '||l_profile_class);

    l_profile_class_id  := g_prfl_cls(l_profile_class).profile_class_id;

    IF  l_profile_class_id IS NULL  THEN

        l_error_message_s :=  'Profile class not found ' ||l_profile_class;

        ou_status_c     := G_ERROR_C;
        ou_message_s    := l_error_message_s;

        RETURN;
            
    END IF;

    -- call the map procedure to get the oracle value for ACCNTSTTS

    swg_cust_debug(in_debug_c,'calling swgcnv_map procedure for ACCNTSTTS::'||l_acct_status);

    IF g_acct_stts(LTRIM(RTRIM(l_acct_status))).new_code = 'NOT MAPPED' THEN

        l_error_message_s :=  l_acct_stts_s 
                                    || 'is not mapped in oracle mapping table '
                                    || 'old code '||l_acct_status;

        ou_status_c     := G_ERROR_C;
        ou_message_s    := l_error_message_s;

        RETURN;
    ELSE

        l_acct_status :=  g_acct_stts(LTRIM(RTRIM(l_acct_status))).new_code;

    END IF;
    
    --
    -- Assign the profile class values
    --
    g_customer_profile_rec.created_by_module        := g_created_by_module;
    g_customer_profile_rec.status                   := 'A';
    g_customer_profile_rec.profile_class_id         := l_profile_class_id;
    g_customer_profile_rec.account_status           := l_acct_status;
    g_customer_profile_rec.collector_id             := in_collector_id_n;
    g_cust_profile_amt_rec.created_by_module        := g_created_by_module;
    ou_profile_class_s                              := l_old_cust_prfl_s;

END             Populate_Cust_Profile_Rec;

--------------------------------------------------------------------

PROCEDURE       Create_Phone
(in_lgcy_cust_rec           IN  swgcnv_dd_customer_interface%ROWTYPE
,in_lgcy_address_id_n       IN  NUMBER
--,in_cust_rec                IN  swgcnv_dd_customer_interface%ROWTYPE
,in_cust_rec                IN  swgcnv_customer_rec_type
--,in_customer_id_n           IN  NUMBER
,in_cust_acct_site_id_n     IN  NUMBER 
,in_debug_c                 IN  VARCHAR2
,ou_status_c                OUT VARCHAR2
,ou_message_s               OUT VARCHAR2)
IS


    CURSOR  cur_phone
                        (in_customer_id IN NUMBER
                        ,in_address_id  IN NUMBER)
    IS
    SELECT  DISTINCT 
         c.customer_id
    ,c.address_id
    ,c.contact_first_name
    ,c.contact_last_name
    ,c.telephone_area_code
    ,c.telephone
    ,c.telephone_extension
    ,c.telephone_type
    ,c.email_address
    FROM  swgcnv_dd_customer_contact  c
    WHERE c.address_id    = in_address_id
    --AND c.customer_id   = in_customer_id
    ;

    l_contact_rec             swgcnv_contact_rec_type;
    l_contact_point_rec       swgcnv_contact_point_rec_type;
    l_error_message_s         VARCHAR2(2000);

BEGIN

    ou_status_c := G_SUCCESS_C;

    FOR l_phone IN  cur_phone (in_lgcy_cust_rec.customer_id,in_lgcy_address_id_n)
    LOOP
        IF ((l_phone.contact_first_name IS NOT NULL)
      OR (l_phone.contact_last_name IS NOT NULL)) THEN

            swg_cust_debug
                        (in_debug_c     => in_debug_c
                        ,in_debug_s     => 'Entered into Cur Phone');

            g_phone_seq_n   :=  g_phone_seq_n + 1;


            l_contact_rec.insert_update_flag        :=  'I';
            l_contact_rec.contact_person_first_name :=  l_phone.contact_first_name;
            l_contact_rec.contact_person_last_name  :=  l_phone.contact_last_name;
            l_contact_rec.account_party_id          :=  in_cust_rec.party_id;

            IF in_lgcy_cust_rec.person_flag = 'Y' THEN

                l_contact_rec.account_party_type  :=  'PERSON';

            ELSIF in_lgcy_cust_rec.person_flag  = 'N' THEN

                l_contact_rec.account_party_type  :=  'ORGANIZATION';

            END IF;

            l_contact_rec.orig_system_reference :=  g_location_rec.orig_system_reference  || '-' ||
                                  l_phone.contact_first_name  || '-' ||
                                l_phone.contact_last_name || '-' ||
                                                    g_phone_seq_n;

            l_contact_rec.cust_account_id   :=  in_cust_rec.cust_account_id;
            l_contact_rec.cust_acct_site_id   :=  in_cust_acct_site_id_n;


            -- Call the contact phone API

            SWGCNV_CONTACT_API(l_contact_rec);

            swg_cust_debug
                        (in_debug_c     => in_debug_c
                        ,in_debug_s     => 'swgcnv_contact_api return status  '
                                            ||l_contact_rec.return_status);


            IF (l_contact_rec.return_status != Fnd_Api.G_RET_STS_SUCCESS) THEN

                l_error_message_s :=  'SWGCNV_CONTACT_API API Error '||l_contact_rec.msg_data;

                ou_status_c     := G_ERROR_C;
                ou_message_s    := l_error_message_s;
                RETURN;

                --RAISE ERROR_ENCOUNTERED;
            END IF;


            IF (l_contact_rec.return_status = Fnd_Api.G_RET_STS_SUCCESS)  THEN

                -- Call the contact point API

                l_contact_point_rec.contact_point_type  := l_phone.telephone_type;
                l_contact_point_rec.phone_area_code     := l_phone.telephone_area_code;
                l_contact_point_rec.phone_number      := l_phone.telephone;
                l_contact_point_rec.phone_extension     := l_phone.telephone_extension;
                l_contact_point_rec.email_address     := l_phone.email_address;
                l_contact_point_rec.email_format      := 'MAILHTML';
                l_contact_point_rec.related_party_id  := l_contact_rec.related_party_id;

                -- Satyaki says add an original system reference for phone numbers!!!!!!!!!!!!!!!!!!!
                l_contact_point_rec.orig_system_reference :=   l_contact_rec.orig_system_reference||'-'|| l_phone.telephone_area_code||'-'|| l_phone.telephone;

                SWGCNV_CONTACT_POINT_API(l_contact_point_rec);

                swg_cust_debug
                            (in_debug_c     => in_debug_c
                            ,in_debug_s     => 'swgcnv_contact_point_api return status  '
                                                ||l_contact_point_rec.return_status);

                IF (l_contact_point_rec.return_status != Fnd_Api.G_RET_STS_SUCCESS) THEN

                    l_error_message_s :=  'SWGCNV_CONTACT_POINT_API API Error '||l_contact_point_rec.msg_data;

                    ou_status_c     := G_ERROR_C;
                    ou_message_s    := l_error_message_s;

                    RETURN;

                END IF;

            END IF;

        END IF;

    END LOOP;  -- l_billto_phone
EXCEPTION
  WHEN OTHERS THEN
       swg_cust_debug
                            (in_debug_c     => in_debug_c
                            ,in_debug_s     => 'Exception in create_phone');
       RAISE;
END         Create_Phone;

--------------------------------------------------------------------

PROCEDURE   Process_Ship_Tos
   (   in_system_name_s           IN  VARCHAR2
      ,in_lgcy_cust_rec           IN  swgcnv_dd_customer_interface%ROWTYPE
      ,in_lgcy_bill_addr_id_n     IN  NUMBER
      ,in_lgcy_billto_site_id_n   IN  NUMBER
      ,in_cust_rec                IN  swgcnv_customer_rec_type
      ,in_cust_acct_site_id_n     IN  NUMBER
      ,in_cust_sales_center_s     IN  VARCHAR2  
      ,in_cust_sales_center_id_n  IN  NUMBER
      ,in_bill_sales_center_s     IN  VARCHAR2
      ,in_bill_sales_center_id_n  IN  NUMBER
      ,in_billto_orig_sys_ref_s   IN  VARCHAR2
      ,in_billto_location_id_n    IN  NUMBER            
      ,in_billto_site_use_id_n    IN  NUMBER
      ,in_bill_price_list_id_n    IN  NUMBER
      ,in_bill_warehouse_id_n     IN  NUMBER
      ,in_profile_class_s         IN  VARCHAR2
      --,in_address_rec             IN  swgcnv_address_rec_type
      ,in_debug_c                 IN  VARCHAR2
      ,ou_address_code_s          OUT VARCHAR2
      ,ou_status_c                OUT VARCHAR2
      ,ou_message_s               OUT VARCHAR2
      ,ou_route_s                 OUT VARCHAR2
   )
IS

  -- 2005/11/22 (Jabel D. Morales): added customer_id relation to avoid duplicate addresses
   CURSOR cur_shipto
               (  in_customer_id  IN  NUMBER
                 ,in_billto_id  IN  NUMBER
               )
   IS
   SELECT  shipto.*
            ,addr.Address1
            ,addr.Address2
            ,addr.Address3
            ,addr.Address4
            ,addr.City
            ,addr.State
            ,addr.Province
            ,addr.County
            ,addr.Postal_Code
            ,addr.Country
            ,addr.Latitude
            ,addr.Longitude
            ,addr.Complex_Type
            ,addr.Variable_Unload_Time
            ,addr.Fixed_Unload_Time
            ,addr.Dock_Type
   FROM   swgcnv_dd_addresses      addr
         ,swgcnv_dd_customer_shipto shipto
   WHERE  shipto.customer_id       =  in_customer_id
   AND   shipto.billing_site_id   = in_billto_id
   AND   shipto.ship_to_address_id  = addr.address_id
   AND    shipto.customer_id        =  addr.customer_id -- 2005/11/22 (Jabel D. Morales)
   ORDER BY shipto.delivery_location_number;

   l_ship_to_count_n          NUMBER;
   l_ship_organization_id_n   NUMBER;
   l_orcl_route_id          NUMBER;
   l_new_org_id            NUMBER;

   l_status_c                 VARCHAR2(1);
   l_dd_value_c               VARCHAR2(2)   :=  'DD';
   l_new_org_s              VARCHAR2(3);
   l_ship_new_sales_center     VARCHAR2(10);
   l_err_shipto_code_s       VARCHAR2(10);
   l_err_address_code_s       VARCHAR2(30);
   l_new_code_s            VARCHAR2(100);
   l_new_sub_code_s          VARCHAR2(100);
   l_error_message_s          VARCHAR2(2000);
   l_message_s                VARCHAR2(2000);

   l_address_rec              swgcnv_address_rec_type;
   l_site_use_rec            swgcnv_site_use_rec_type;

   l_billto_orig_sys_ref_s    g_cust_site_use_rec.orig_system_reference%TYPE;

   l_default_route_s          VARCHAR2(10)    := 'D23';

BEGIN

   ou_status_c    :=    G_SUCCESS_C;
   ou_route_s     :=    NULL;

   l_billto_orig_sys_ref_s    :=    in_billto_orig_sys_ref_s; 
   swg_cust_debug(in_debug_c, 'in_billto_orig_sys_ref_s::'||in_billto_orig_sys_ref_s);

   -- Create the Shipto Records for the customer 
   swg_cust_debug
      (  in_debug_c     => in_debug_c
        ,in_debug_s     => 'Entered procedure::Process_Ship_Tos'
      );

   l_ship_to_count_n  :=  0;

   FOR l_shipto_rec IN cur_shipto 
      (  in_lgcy_cust_rec.customer_id
        ,in_lgcy_billto_site_id_n
      )
   LOOP

      swg_cust_debug
         (  in_debug_c     => in_debug_c
           ,in_debug_s     => 'Entered Shipto loop for '
                               ||in_lgcy_cust_rec.customer_id
         );

      --l_err_address_code_s  :=  l_shipto_rec.delivery_location_number;
      ou_address_code_s       :=  LTRIM(RTRIM(l_shipto_rec.delivery_location_number));

      g_ship_recs_read_n      :=  g_ship_recs_read_n  + 1;
      l_ship_to_count_n        := l_ship_to_count_n    +  1;

      -- Initialize the variables

      g_location_rec          :=     NULL;
      g_party_site_rec        :=     NULL;
      g_cust_acct_site_rec     :=    NULL;
      g_cust_site_use_rec    :=    NULL;
      --l_contact_rec      :=    NULL;
      --l_contact_point_rec :=  NULL;

      -- Get the Organization Id for the New Sales center
      IF in_bill_sales_center_s  =  l_shipto_rec.sales_center THEN

         l_ship_organization_id_n   :=    in_bill_sales_center_id_n;
         l_ship_new_sales_center    :=    in_bill_sales_center_s;
  
         g_cust_site_use_rec.price_list_id      := in_bill_price_list_id_n;

         g_cust_site_use_rec.warehouse_id       := in_bill_warehouse_id_n;

      ELSIF in_cust_sales_center_s = l_shipto_rec.sales_center THEN

         l_ship_organization_id_n    := in_cust_sales_center_id_n;
         l_ship_new_sales_center     := in_cust_sales_center_s;
    
         g_cust_site_use_rec.price_list_id   := g_price_list_id_n;
         g_cust_site_use_rec.warehouse_id    := g_warehouse_id_n;          

      ELSE

     BEGIN
      SELECT organization_id
                  ,organization_code
            INTO   l_ship_organization_id_n
                  ,l_ship_new_sales_center
            FROM   mtl_parameters
      WHERE  organization_code   =  l_shipto_rec.sales_center;

      EXCEPTION
            WHEN NO_DATA_FOUND THEN
               l_error_message_s  :=  'Organization Not found in Oracle for '
                                    || l_shipto_rec.sales_center;

               ou_status_c       := G_ERROR_C;
               ou_message_s      := l_error_message_s;
               RETURN;
      WHEN OTHERS THEN
               l_error_message_s  :=  'Unexpected Error: finding the organization for::'
                                    || l_shipto_rec.sales_center
                                    || '...'||SQLERRM;

               ou_status_c       := G_ERROR_C;
               ou_message_s      := l_error_message_s;

               RETURN;    
               --RAISE  ERROR_ENCOUNTERED;
      END;

      END IF;

      IF ( l_shipto_rec.price_list_name IS NOT NULL ) THEN  -- Stephen Bowen as per EB-367/21850

         g_cust_site_use_rec.price_list_id  :=  l_shipto_rec.price_list_name;

      END IF;

      -- Check if shipto addresss and billto addresses are same, if they are same then
      -- don't create the shipto addresses Else create new shipto addresses

      IF l_shipto_rec.ship_to_address_id != in_lgcy_bill_addr_id_n THEN

          swg_cust_debug(in_debug_c,'Shipto address and billto address are not same ');

          -- Assign the address API values

          g_location_rec.created_by_module        :=   g_created_by_module;
          g_party_site_rec.created_by_module      :=   g_created_by_module;
          g_cust_acct_site_rec.created_by_module  :=   g_created_by_module;

          g_location_rec.country                 :=   LTRIM(RTRIM(l_shipto_rec.country));
          g_location_rec.address1                :=   LTRIM(RTRIM(l_shipto_rec.address1));
          g_location_rec.address2                :=   LTRIM(RTRIM(l_shipto_rec.address2));
          g_location_rec.address3                :=   LTRIM(RTRIM(l_shipto_rec.address3));
          g_location_rec.address4                :=   LTRIM(RTRIM(l_shipto_rec.address4));
          g_location_rec.city                    :=   LTRIM(RTRIM(l_shipto_rec.city));
          g_location_rec.postal_code             :=   LTRIM(RTRIM(l_shipto_rec.postal_code));
          g_location_rec.state                   :=   LTRIM(RTRIM(l_shipto_rec.state));
          g_location_rec.province                :=   LTRIM(RTRIM(l_shipto_rec.province));
          g_location_rec.county                  :=   LTRIM(RTRIM(l_shipto_rec.county));

          g_location_rec.orig_system_reference   := l_dd_value_c      || '-' ||
                      in_system_name_s  || '-' ||
                      l_shipto_rec.sales_center || '-' ||
                      LTRIM(RTRIM(in_lgcy_cust_rec.customer_number))|| '-' ||
                      LTRIM(RTRIM(l_shipto_rec.delivery_location_number));

          -- Get the Sagent Data
          g_location_rec.attribute_category  :=     'SAGENT DATA';
          g_location_rec.attribute1          :=     l_shipto_rec.latitude;
          g_location_rec.attribute2          :=     l_shipto_rec.longitude;
          g_location_rec.attribute3          :=     l_shipto_rec.complex_type;
          g_location_rec.attribute4          :=     l_shipto_rec.variable_unload_time;
          g_location_rec.attribute5          :=     l_shipto_rec.fixed_unload_time;
          g_location_rec.attribute6          :=     l_shipto_rec.dock_type;



          -- Call the location API

          Hz_Location_V2pub.create_location
          (   p_init_msg_list => Fnd_Api.G_TRUE
         ,p_location_rec  => g_location_rec
         ,x_location_id   => l_address_rec.location_id
         ,x_return_status => l_address_rec.return_status
         ,x_msg_count     => l_address_rec.msg_count
         ,x_msg_data      => l_address_rec.msg_data
          );

          swg_format_string
          (io_msg_count_n => l_address_rec.msg_count
          ,io_msg_data_s  => l_address_rec.msg_data
          );

          swg_cust_debug
         (in_debug_c     => in_debug_c
         ,in_debug_s     => 'shipto create_location return status  '
              ||l_address_rec.return_status
         );


         IF (l_address_rec.return_status != Fnd_Api.G_RET_STS_SUCCESS) THEN

             l_error_message_s :=  'create_location API Error '||l_address_rec.msg_data;

             ou_status_c       := G_ERROR_C;
             ou_message_s      := l_error_message_s;

             RETURN;     
             --RAISE ERROR_ENCOUNTERED;
         END IF;


         IF (l_address_rec.return_status = Fnd_Api.G_RET_STS_SUCCESS)  THEN

           g_party_site_rec.location_id           := l_address_rec.location_id;
           g_party_site_rec.party_id               := in_cust_rec.party_id;
           g_party_site_rec.orig_system_reference := g_location_rec.orig_system_reference;
           g_party_site_rec.addressee              := l_shipto_rec.addressee;

           -- Call the party site API

           Hz_Party_Site_V2pub.create_party_site
            (   p_init_msg_list     => Fnd_Api.G_TRUE
                ,p_party_site_rec    => g_party_site_rec
                ,x_party_site_id     => l_address_rec.party_site_id
                ,x_party_site_number => l_address_rec.party_site_number
                ,x_return_status     => l_address_rec.return_status
                ,x_msg_count         => l_address_rec.msg_count
                ,x_msg_data        => l_address_rec.msg_data
            );

               swg_format_string
            (io_msg_count_n => l_address_rec.msg_count
            ,io_msg_data_s  => l_address_rec.msg_data
            );

           swg_cust_debug
            (in_debug_c     => in_debug_c
            ,in_debug_s     => 'shipto create_party_site return status '
                   ||l_address_rec.return_status
             );

               
         END IF;

         IF (l_address_rec.return_status != Fnd_Api.G_RET_STS_SUCCESS) THEN

          l_error_message_s :=  'create_party_site API Error '||l_address_rec.msg_data;
            ou_status_c         := G_ERROR_C;
            ou_message_s        := l_error_message_s;
            RETURN;
            --RAISE ERROR_ENCOUNTERED;
        END IF;

        IF (l_address_rec.return_status = Fnd_Api.G_RET_STS_SUCCESS)  THEN

          g_cust_acct_site_rec.status               :=    'A';
          g_cust_acct_site_rec.party_site_id           :=    l_address_rec.party_site_id;
          g_cust_acct_site_rec.cust_account_id        :=    in_cust_rec.cust_account_id;
          g_cust_acct_site_rec.orig_system_reference  :=    g_location_rec.orig_system_reference;

          -- Get the Sagent Data

          g_cust_acct_site_rec.attribute_category :=     'SAGENT DATA';
          g_cust_acct_site_rec.attribute1         :=     l_shipto_rec.latitude;
          g_cust_acct_site_rec.attribute2         :=     l_shipto_rec.longitude;
          g_cust_acct_site_rec.attribute3         :=     l_shipto_rec.complex_type;
          g_cust_acct_site_rec.attribute4         :=     l_shipto_rec.variable_unload_time;
          g_cust_acct_site_rec.attribute5         :=     l_shipto_rec.fixed_unload_time;
          g_cust_acct_site_rec.attribute6         :=     l_shipto_rec.dock_type;
          g_cust_acct_site_rec.translated_customer_name := SUBSTR(l_shipto_rec.sub_cust_number,1,50); -- Added by Ashok on 07/16/07 to store sub-cust reference (ARS02)

          -- Call the Address API
          Hz_Cust_Account_Site_V2pub.create_cust_acct_site
                 (   p_init_msg_list      => Fnd_Api.G_TRUE
                    ,p_cust_acct_site_rec => g_cust_acct_site_rec
                   ,x_cust_acct_site_id   => l_address_rec.cust_acct_site_id
                   ,x_return_status       => l_address_rec.return_status
                   ,x_msg_count           => l_address_rec.msg_count
                   ,x_msg_data            => l_address_rec.msg_data
                 );

              swg_format_string
                 (io_msg_count_n => l_address_rec.msg_count
                 ,io_msg_data_s  => l_address_rec.msg_data
                 );

              swg_cust_debug
                 (in_debug_c     => in_debug_c
                 ,in_debug_s     => 'Shipto create_cust_acct_site return status  '
                  ||l_address_rec.return_status
                 );


      END IF;

      IF (l_address_rec.return_status != Fnd_Api.G_RET_STS_SUCCESS) THEN

        l_error_message_s :=  'Ship create_cust_acct_site API Error '
                                 ||l_address_rec.msg_data;
            ou_status_c       := G_ERROR_C;
            ou_message_s      := l_error_message_s;
            RETURN;
            --RAISE ERROR_ENCOUNTERED;
      END IF;

      END IF; --Shipto address and billto address are not same
      
      -- Check if shipto addresss and billto addresses are same, if they are same then
      -- use the billto address reference

      IF l_shipto_rec.ship_to_address_id = in_lgcy_bill_addr_id_n THEN

         swg_cust_debug
            (in_debug_c    => in_debug_c
            ,in_debug_s    => 'Shipto address and billto address are same'
            );

         swg_cust_debug(in_debug_c, 'bill to in_cust_acct_site_id_n::'||in_cust_acct_site_id_n);

         g_cust_site_use_rec.cust_acct_site_id    := in_cust_acct_site_id_n;--l_same_cust_acct_site_id;

         -- use the same billto orig system reference
         -- Commented For R12 UPGRADE. SAME ORIG SYSTEM REFERENCE FOR BILL TO AND SHIP TO IS GIVING
         -- PROBLEM IN CUSTOMER STANDARD PAGE WHEN UPDATING BUSINESS PURPOSE DATE.
         
         -- g_cust_site_use_rec.orig_system_reference := l_billto_orig_sys_ref_s; 
         --swg_cust_debug(in_debug_c, 'in_billto_orig_sys_ref_s::'||l_billto_orig_sys_ref_s);

         -- Added For R12 UPGRADE During ARS04 CONVERSION
         g_cust_site_use_rec.orig_system_reference :=    l_dd_value_c     || '-' ||
                                                         in_system_name_s   || '-' ||
                                                         l_shipto_rec.sales_center || '-' ||
                                                         LTRIM(RTRIM(in_lgcy_cust_rec.customer_number))|| '-' ||
                                                         LTRIM(RTRIM(l_shipto_rec.delivery_location_number));
                                                         
         swg_cust_debug(in_debug_c, 'in_billto_orig_sys_ref_s::'||g_cust_site_use_rec.orig_system_reference);
         -- Added For R12 UPGRADE During ARS04 CONVERSION

         -- Update the sagent information in location table

      UPDATE hz_locations
      SET  attribute_category = 'SAGENT DATA'
          ,attribute1         = l_shipto_rec.latitude
          ,attribute2         = l_shipto_rec.longitude
          ,attribute3         = l_shipto_rec.complex_type
          ,attribute4         = l_shipto_rec.variable_unload_time
          ,attribute5         = l_shipto_rec.fixed_unload_time
          ,attribute6         = l_shipto_rec.dock_type
      WHERE  location_id      =  in_billto_location_id_n;

      -- Update the sagent information in address table

      UPDATE hz_cust_acct_sites
      SET  attribute_category = 'SAGENT DATA'
          ,attribute1         = l_shipto_rec.latitude
          ,attribute2         = l_shipto_rec.longitude
          ,attribute3         = l_shipto_rec.complex_type
          ,attribute4         = l_shipto_rec.variable_unload_time
          ,attribute5         = l_shipto_rec.fixed_unload_time
          ,attribute6         = l_shipto_rec.dock_type
          ,translated_customer_name = SUBSTR(l_shipto_rec.sub_cust_number,1,50) -- Added by Ashok on 07/16/07 to store sub-cust reference (ARS02)
      WHERE cust_acct_site_id = in_cust_acct_site_id_n;


      ELSE

      g_cust_site_use_rec.cust_acct_site_id     :=  l_address_rec.cust_acct_site_id;
      g_cust_site_use_rec.orig_system_reference  :=   g_cust_acct_site_rec.orig_system_reference;

      END IF;
      
      -- WO 20438 Bala Palani
      
          g_cust_site_use_rec.orig_system_reference :=    l_dd_value_c || '-' || in_system_name_s   
                                                                       || '-' || l_shipto_rec.sales_center 
                                                                       || '-' || LTRIM(RTRIM(in_lgcy_cust_rec.customer_number))
                                                                       || '-' || LTRIM(RTRIM(l_shipto_rec.delivery_location_number))
                                                                       || '-' || LTRIM(RTRIM(NVL(l_shipto_rec.sub_cust_number, in_lgcy_cust_rec.customer_number)));
      

      swg_cust_debug(in_debug_c, 'l_address_rec.return_status::'||l_address_rec.return_status);

      --IF (l_address_rec.return_status = Fnd_Api.G_RET_STS_SUCCESS)  THEN

      g_cust_site_use_rec.created_by_module     := g_created_by_module;
      g_cust_site_use_rec.site_use_code       := 'SHIP_TO';
      g_cust_site_use_rec.status                := 'A';
      g_cust_site_use_rec.bill_to_site_use_id := in_billto_site_use_id_n;


      IF  LTRIM(RTRIM(in_lgcy_cust_rec.monthly_invoice_format)) = 'SINGLE SHIP-TO/BILL-TO'  THEN
         g_cust_site_use_rec.primary_flag  :=  'Y';
      ELSE
         g_cust_site_use_rec.primary_flag  :=  'N';
      END IF;

      -- Tax code
      g_cust_site_use_rec.tax_code  :=  'LOCATION';

      IF g_cust_site_use_rec.price_list_id IS NULL OR 
         g_cust_site_use_rec.warehouse_id  IS NULL THEN

         BEGIN

            l_new_org_s    :=    l_ship_new_sales_center;

            swg_cust_debug(in_debug_c,'Get the shipto sales center price list ');

        -- Get the the price list and warehouse

            SELECT hro.attribute1
              ,hro.organization_id
            INTO   g_cust_site_use_rec.price_list_id
                  ,g_cust_site_use_rec.warehouse_id
            FROM   hr_organization_units    hro
            WHERE  hro.organization_id  = (SELECT org.organization_id
                                          FROM   mtl_parameters org
                                          WHERE org.organization_code =  l_new_org_s
                                         );
                                         
          IF l_shipto_rec.rate_schedule = '2000' THEN
               g_cust_site_use_rec.price_list_id   :=    g_assoc_price_list_id;
        END IF;           

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               l_error_message_s  :=  'No data found getting price list for new sales center: '
                                    || l_new_org_s
                                    ||CHR(10)||SQLERRM;
               ou_status_c       := G_ERROR_C;
               ou_message_s      := l_error_message_s;
               RETURN;

         WHEN OTHERS THEN
               l_error_message_s  :=  'Error getting price list for new sales center: ' ||
                              l_new_org_s||CHR(10)||SQLERRM;
               ou_status_c       := G_UNEXP_ERROR_C;
               ou_message_s      := l_error_message_s;
               RETURN;
               --RAISE  ERROR_ENCOUNTERED;
         END;
         
      END IF; --warehouse or pricelist are null

      -- Check the price list

      IF g_cust_site_use_rec.price_list_id IS NULL THEN
      
         l_error_message_s   := 'Error getting price list for new sales center: '
                                  ||l_new_org_s;
         ou_status_c         := G_UNEXP_ERROR_C;
         ou_message_s        := l_error_message_s;
         RETURN;

      END IF;

      -- Shipto Descriptive flexfield
      -- call the map procedure to get the oracle value for CUSTTAXCLS

      l_new_code_s   :=    NULL;

      swg_cust_debug
         (in_debug_c     => in_debug_c
         ,in_debug_s     => 'calling swgcnv_map procedure for CUSTTAXCLS'
         );

      IF g_tax_cls(in_profile_class_s||l_shipto_rec.customer_tax_class).new_code IS NULL THEN
      
         l_error_message_s  :=  'CUSTTAXCLS is not mapped in oracle mapping table '
                              ||'old code '
                              ||LTRIM(RTRIM(l_shipto_rec.customer_tax_class))
                              || CHR(10) ||SQLERRM;
         ou_status_c       := G_UNEXP_ERROR_C;
         ou_message_s      := l_error_message_s;
         RETURN;

      -- 2005/11/18 (Jabel D. Morales): setting customer tax profile of Home Depto shiptos to 'DISTRIBUTOR'
      -- OPS10 issue 6
      ELSIF l_shipto_rec.rate_schedule = '6539' THEN -- Home Depot has rate schedule 6539
      l_new_code_s   := 'DISTRIBUTOR';
      ELSE
         l_new_code_s   := g_tax_cls(in_profile_class_s||l_shipto_rec.customer_tax_class).new_code;
      END IF;
      
      swg_cust_debug
         (in_debug_c     => in_debug_c
         ,in_debug_s     => 'New CUSTTAXCLS:'||l_new_code_s
         );

      g_cust_site_use_rec.attribute_category  :=   'Ship To';
      g_cust_site_use_rec.attribute1          :=    l_new_code_s;
      g_cust_site_use_rec.attribute2          :=    l_shipto_rec.po_number;
      g_cust_site_use_rec.attribute3          :=    TO_CHAR(TO_DATE(l_shipto_rec.po_effective_from_date,'DD-MON-RR'),'YYYY/MM/DD HH24:MI:SS');
      g_cust_site_use_rec.attribute4          :=    TO_CHAR(TO_DATE(l_shipto_rec.po_effective_to_date,'DD-MON-RR'),'YYYY/MM/DD HH24:MI:SS');
      g_cust_site_use_rec.attribute5          :=    l_shipto_rec.customer_reference_number;
      g_cust_site_use_rec.attribute6          :=    l_shipto_rec.po_total_dollars;
      g_cust_site_use_rec.attribute7          :=    l_shipto_rec.po_total_units;

      IF l_new_code_s = 'OTHER NOT FOR PROFIT' THEN 
       g_cust_site_use_rec.attribute8   :=    l_shipto_rec.tax_exempt_number;  --'NO TAX # IN RIM';--
       g_cust_site_use_rec.attribute9   :=    TO_CHAR(TO_DATE(l_shipto_rec.tax_exempt_exp_date,'DD-MON-RR'),'YYYY/MM/DD HH24:MI:SS');--TO_CHAR(TO_DATE(ADD_MONTHS(TRUNC(SYSDATE),4*12),'DD-MON-RR'),'YYYY/MM/DD HH24:MI:SS');--
      ELSE
         g_cust_site_use_rec.attribute8   :=    l_shipto_rec.tax_exempt_number;
      g_cust_site_use_rec.attribute9   :=    TO_CHAR(TO_DATE(l_shipto_rec.tax_exempt_exp_date,'DD-MON-RR'),'YYYY/MM/DD HH24:MI:SS');                    
      END IF;

      g_cust_site_use_rec.attribute10     :=    l_shipto_rec.tax_exempt_certificate_rcvd;
      g_cust_site_use_rec.attribute11     :=    TO_CHAR(TO_DATE(l_shipto_rec.ship_to_start_date,'DD-MON-RR'),'YYYY/MM/DD HH24:MI:SS');--TO_CHAR(TO_DATE(l_shipto_rec.customer_start_date,'DD-MON-RR'),'YYYY/MM/DD HH24:MI:SS');

      g_cust_site_use_rec.attribute12     :=    l_shipto_rec.suppress_price_hh_ticket;  -- 'Suppress Price on HH Ticket?'
      g_cust_site_use_rec.attribute13     :=    l_shipto_rec.rsr_overide_suppress_price;  -- 'RSR Override Suppress Price?'

      IF l_shipto_rec.delivery_ticket_print_flag = 'Y' THEN
      
         UPDATE hz_cust_accounts
         SET    attribute20      =  'R'    -- 'Receipt Printing on HH?'
         WHERE  cust_account_id  =  in_cust_rec.cust_account_id;
      ELSE
         UPDATE hz_cust_accounts
         SET    attribute20      =  'O'
         WHERE  cust_account_id  =  in_cust_rec.cust_account_id;
      END IF;

      IF g_customer_profile_rec.profile_class_id IN (1085, 1086) THEN -- Override Ticket Print Flag from SACS
         UPDATE hz_cust_accounts                                      -- Do not Print Ticket For Residentials
         SET    attribute20      =  'O'
         WHERE  cust_account_id  =  in_cust_rec.cust_account_id;
      END IF;

      -- Call the customer site use API
      
      swg_cust_debug
         (in_debug_c     => in_debug_c
         ,in_debug_s     => 'Calling Customer Site Use API'
         );
    
      Hz_Cust_Account_Site_V2pub.create_cust_site_use
         (   p_init_msg_list         =>   Fnd_Api.G_TRUE
            ,p_cust_site_use_rec     =>   g_cust_site_use_rec
            ,p_customer_profile_rec  =>   g_customer_profile_rec
            ,p_create_profile        =>   Fnd_Api.G_FALSE     --- Modified not to create
            ,p_create_profile_amt    =>   Fnd_Api.G_FALSE     --- profiles for shiptos
            ,x_site_use_id           =>   l_site_use_rec.site_use_id
            ,x_return_status         =>   l_site_use_rec.return_status
            ,x_msg_count             =>   l_site_use_rec.msg_count
            ,x_msg_data              =>   l_site_use_rec.msg_data
         );
         
      --WO20457      
      UPDATE swgcnv_dd_customer_shipto
      SET    oracle_ship_site_use_id  =  l_site_use_rec.site_use_id
      WHERE  customer_id              =  l_shipto_rec.customer_id
      AND    ship_to_address_id       =  l_shipto_rec.ship_to_address_id;

      swg_format_string
         (io_msg_count_n =>   l_site_use_rec.msg_count
         ,io_msg_data_s  =>   l_site_use_rec.msg_data
         );

      swg_cust_debug
         (in_debug_c     =>   in_debug_c
         ,in_debug_s     =>   'create_cust_site_use return status  '||l_site_use_rec.return_status
         );

      IF (l_site_use_rec.return_status != Fnd_Api.G_RET_STS_SUCCESS) THEN

         l_error_message_s  :=  'create_cust_site_use API Error '||l_site_use_rec.msg_data;

         ou_status_c       :=  G_UNEXP_ERROR_C;
         ou_message_s      :=  l_error_message_s;

         RETURN;
         --RAISE  ERROR_ENCOUNTERED;
      END IF;

      Create_Phone
         (   in_lgcy_cust_rec           => in_lgcy_cust_rec
            ,in_lgcy_address_id_n       => l_shipto_rec.ship_to_address_id
            ,in_cust_rec                => in_cust_rec
            ,in_cust_acct_site_id_n     => l_address_rec.cust_acct_site_id
            ,in_debug_c                 => in_debug_c
            ,ou_status_c                => l_status_c
            ,ou_message_s               => l_message_s
         );   
  
      IF l_status_c != G_SUCCESS_C THEN

         ou_status_c     := l_status_c;
         ou_message_s    := l_message_s;
         RETURN;

      END IF;

      ou_route_s  := l_shipto_rec.route_number;

   END LOOP;  -- l_shipto_rec

   IF l_ship_to_count_n = 0 THEN
      ou_route_s      := l_default_route_s;

      --
      -- Don't convert customer if they do not have any ship to's
      --

      ou_status_c     := G_ERROR_C;
      ou_message_s    := 'Error:  This bill to does not have any ship to records.';--||in_lgcy_billto_site_id_n;
   END IF;
EXCEPTION
  WHEN OTHERS THEN
      swg_cust_debug
        (in_debug_c     => in_debug_c
        ,in_debug_s     => 'Exception in Process_Ship_Tos'
        );
      RAISE;
END   Process_Ship_Tos;

--------------------------------------------------------------------

PROCEDURE   Process_Addresses
         (   in_system_name_s           IN  VARCHAR2
            ,in_lgcy_cust_rec           IN  swgcnv_dd_customer_interface%ROWTYPE
            ,in_cust_rec                IN  swgcnv_customer_rec_type
            ,in_cust_sales_center_s     IN  VARCHAR2  
            ,in_cust_sales_center_id_n  IN  NUMBER
            ,in_cust_collector_id_n     IN  NUMBER
            ,in_cust_division_id_n      IN  NUMBER
            ,in_profile_class_s         IN  VARCHAR2
            ,in_debug_c                 IN  VARCHAR2
            ,ou_address_code_s          OUT VARCHAR2
            ,ou_status_c                OUT VARCHAR2
            ,ou_message_s               OUT VARCHAR2
            ,ou_route_s                 OUT VARCHAR2
         )
IS

  -- 2005/11/22 (Jabel D. Morales): added customer_id relation to avoid duplicate addresses
   CURSOR cur_dd_cust_addr ( in_customer_id IN  NUMBER)
   IS
   SELECT  billto.*
            ,addr.address1
            ,addr.address2
            ,addr.address3
            ,addr.address4
            ,addr.city
            ,addr.state
            ,addr.province
            ,addr.county
            ,addr.postal_code
            ,addr.country
            ,addr.latitude
            ,addr.longitude
            ,addr.complex_type
            ,addr.variable_unload_time
            ,addr.fixed_unload_time
            ,addr.dock_type
   FROM      swgcnv_dd_addresses    addr
            ,swgcnv_dd_customer_billto  billto
   WHERE     billto.customer_id      =  in_customer_id
   AND      billto.bill_to_address_id = addr.address_id
   AND       billto.customer_id        =  addr.customer_id -- 2005/11/21 (Jabel D. Morales)
   ORDER BY  billto.billing_location_number;

   CURSOR cur_org_collect(in_sales_center IN VARCHAR2)
   IS
   SELECT collector_id
   FROM   ar_collectors
   WHERE  status  =   'A'
   AND    name     =  in_sales_center;

   l_status_c               VARCHAR2(1);
   l_dd_value_c             VARCHAR2(2)   :=  'DD';
   l_new_org_s              VARCHAR2(3);
   l_route_s                VARCHAR2(10);
   l_ship_address_code_s    VARCHAR2(30);
   l_new_sales_center       VARCHAR2(100);
   l_error_message_s        VARCHAR2(2000);
   l_message_s              VARCHAR2(2000);

   l_billto_collector_id    NUMBER;
   l_billto_recs_read_n     NUMBER    :=  0;
   l_organization_id_n      NUMBER   :=  0;
   l_division_id_n          NUMBER;

   l_price_list_id_n        NUMBER;
   l_warehouse_id_n         NUMBER;
   l_cust_profile_ovn       NUMBER;

   l_profile_class_s        swgcnv_dd_customer_billto.customer_profile_class_name%TYPE;

   l_address_rec            swgcnv_address_rec_type;
   l_empty_address_rec      swgcnv_address_rec_type;
   l_site_use_rec           swgcnv_site_use_rec_type;
   l_empty_site_use_rec     swgcnv_site_use_rec_type;
   --     l_contact_rec       swgcnv_contact_rec_type;
   --    l_contact_point_rec  swgcnv_contact_point_rec_type;

BEGIN

   l_profile_class_s   := in_profile_class_s; 

   swg_cust_debug
     (   in_debug_c     => in_debug_c
        ,in_debug_s     => 'Process_Addresses...profile class: '||l_profile_class_s
     );

   ou_status_c := G_SUCCESS_C;

   l_address_rec          :=     l_empty_address_rec;
   l_site_use_rec         :=     l_empty_site_use_rec;
   l_billto_recs_read_n    :=    0;
   ou_address_code_s       :=    NULL;

   swg_cust_debug
     (in_debug_c     => in_debug_c
     ,in_debug_s     => in_lgcy_cust_rec.customer_id
     );
     
  FOR l_addr_rec IN cur_dd_cust_addr (in_lgcy_cust_rec.customer_id)
  LOOP

    swg_cust_debug
        (in_debug_c     => in_debug_c
        ,in_debug_s     => 'Entered Billto Loop '||in_lgcy_cust_rec.customer_id
        );

    ou_address_code_s    :=  l_addr_rec.billing_location_number;

    l_billto_recs_read_n  :=   l_billto_recs_read_n + 1;
      g_bill_recs_read_n   :=  g_bill_recs_read_n     +  1;

    -- Initialize the variables

    g_location_rec        :=  NULL;
    g_party_site_rec      :=  NULL;
    g_cust_acct_site_rec   := NULL;
    g_cust_site_use_rec  := NULL;


      -- Call the mapping procedure to get the new organization

    l_new_org_s :=  l_addr_rec.sales_center;

      --
      -- if the new sales center for the bill to is the same as
      -- the customer level sales center then use the customer level
      -- collector, organization_id, and division
      -- 

      IF l_new_org_s = in_cust_sales_center_s THEN

         l_billto_collector_id   := in_cust_collector_id_n;
         l_organization_id_n     := in_cust_sales_center_id_n;
         l_new_sales_center      := l_new_org_s;
         l_division_id_n         := in_cust_division_id_n;
         l_price_list_id_n       := g_price_list_id_n;
         l_warehouse_id_n        := g_warehouse_id_n;

      ELSE    -- the customer sales center is different from the bill to sales center
    
         -- Get the collector Id for the new sales center
        
       OPEN cur_org_collect(l_new_org_s);

       FETCH cur_org_collect
         INTO  l_billto_collector_id;

       IF cur_org_collect%NOTFOUND THEN
            l_billto_collector_id   := NULL;
            --g_customer_profile_rec.collector_id :=  NULL;
         END IF;

         CLOSE cur_org_collect;

         IF l_billto_collector_id IS NULL THEN
--          IF g_customer_profile_rec.collector_id  IS NULL THEN

               l_error_message_s  := 'Collector not defined for new sales center: '
                                       || l_new_org_s;

               swg_cust_debug
                 (in_debug_c     => in_debug_c
                 ,in_debug_s     => 'Collector not defined for '||l_new_org_s);

               ou_status_c     := G_ERROR_C;
               ou_message_s    := l_error_message_s;
               RETURN;
 
               --RAISE  ERROR_ENCOUNTERED;

         END IF;

         -- Get the Organization Id for the New Sales center

       BEGIN

           SELECT organization_id
                  ,organization_code
           INTO    l_organization_id_n
                  ,l_new_sales_center
            FROM   mtl_parameters
           WHERE  organization_code = l_new_org_s;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               l_error_message_s   := 'No data found for organization::'
                                       || l_new_org_s;

               ou_status_c         := G_ERROR_C;
               ou_message_s        := l_error_message_s;

               RETURN;
            WHEN OTHERS THEN
               l_error_message_s  :=  'Unexpected Error retrieving organization data for '
                                    || l_new_org_s || '...'
                                    || SQLERRM;

               ou_status_c         := G_UNEXP_ERROR_C;
               ou_message_s        := l_error_message_s;
               RETURN;

               --RAISE  ERROR_ENCOUNTERED;
         END;

      l_division_id_n :=  Swg_Hierarchy_Pkg.get_parent 
                                 (  in_child_type_s        => 'LOCATION'
                          ,in_child_value_s       => NULL
                          ,in_child_id_n          => l_organization_id_n
                          ,in_level_rqrd_s        => 'DIVISION'
                          ,in_effective_date_d    => TRUNC(SYSDATE)
                          ,in_output_type_s       => 'ID'
                          ,in_output_style_s      => 'HTL'
                                 );
                                 
      IF l_division_id_n IS NULL THEN

            l_error_message_s :=  'Error getting division: hierarchy not defined for location: ' ||
                                 l_new_org_s;

            ou_status_c    := G_ERROR_C;
            ou_message_s   := l_error_message_s;

            swg_cust_debug
               (in_debug_c     => in_debug_c
               ,in_debug_s     => 'No value for division for  '||l_organization_id_n);

            RETURN;
            --RAISE ERROR_ENCOUNTERED;
            --  l_division_id_n :=  197;

         END IF; -- l_division_id_n

      END IF;

      -- Assign the address API values

      g_location_rec.created_by_module        :=   g_created_by_module;
      g_party_site_rec.created_by_module      :=   g_created_by_module;
      g_cust_acct_site_rec.created_by_module  :=   g_created_by_module;

      g_location_rec.country                 :=   LTRIM(RTRIM(l_addr_rec.country));
      g_location_rec.address1                :=   LTRIM(RTRIM(l_addr_rec.address1));
      g_location_rec.address2                :=   LTRIM(RTRIM(l_addr_rec.address2));
      g_location_rec.address3                :=   LTRIM(RTRIM(l_addr_rec.address3));
      g_location_rec.address4                :=   LTRIM(RTRIM(l_addr_rec.address4));
      g_location_rec.city                    :=   LTRIM(RTRIM(l_addr_rec.city));
      g_location_rec.postal_code             :=   LTRIM(RTRIM(l_addr_rec.postal_code));
      g_location_rec.state                   :=   LTRIM(RTRIM(l_addr_rec.state));
      g_location_rec.province                :=   LTRIM(RTRIM(l_addr_rec.province));
      g_location_rec.county                  :=   LTRIM(RTRIM(l_addr_rec.county));
      g_location_rec.orig_system_reference   := l_dd_value_c            || '-' ||
                                                   in_system_name_s         || '-' ||
                                                   l_addr_rec.sales_center || '-' ||
                                                   LTRIM(RTRIM(in_lgcy_cust_rec.customer_number))|| '-' ||
                                                   LTRIM(RTRIM(l_addr_rec.bill_to_address_id))   || '-' || 'HEADER';

      -- Call the location API

      Hz_Location_V2pub.create_location
         (  p_init_msg_list    => Fnd_Api.G_TRUE
        ,p_location_rec     => g_location_rec
        ,x_location_id      => l_address_rec.location_id
        ,x_return_status    => l_address_rec.return_status
        ,x_msg_count        => l_address_rec.msg_count
        ,x_msg_data         => l_address_rec.msg_data
         );

      swg_format_string
         (io_msg_count_n => l_address_rec.msg_count
         ,io_msg_data_s  => l_address_rec.msg_data);

      swg_cust_debug
        (in_debug_c     => in_debug_c
        ,in_debug_s     => 'create_location return status  '||l_address_rec.return_status);


      IF (l_address_rec.return_status != Fnd_Api.G_RET_STS_SUCCESS) THEN

         l_error_message_s    :=  'create_location API Error '||l_address_rec.msg_data;

         ou_status_c         :=  G_ERROR_C;
         ou_message_s        :=  l_error_message_s;

         RETURN;

         --RAISE  ERROR_ENCOUNTERED;
         
    END IF;

      IF (l_address_rec.return_status = Fnd_Api.G_RET_STS_SUCCESS)  THEN

         g_party_site_rec.location_id            :=    l_address_rec.location_id;
         g_party_site_rec.party_id              :=    in_cust_rec.party_id;
         g_party_site_rec.orig_system_reference :=    g_location_rec.orig_system_reference;
         g_party_site_rec.addressee             :=    NULL;

         -- Call the party site API

         Hz_Party_Site_V2pub.create_party_site
            (   p_init_msg_list     => Fnd_Api.G_TRUE
               ,p_party_site_rec    => g_party_site_rec
               ,x_party_site_id     => l_address_rec.party_site_id
               ,x_party_site_number => l_address_rec.party_site_number
               ,x_return_status     => l_address_rec.return_status
               ,x_msg_count         => l_address_rec.msg_count
               ,x_msg_data          => l_address_rec.msg_data
            );
            
         swg_format_string
            (  io_msg_count_n => l_address_rec.msg_count
              ,io_msg_data_s  => l_address_rec.msg_data
            );

         swg_cust_debug
            (  in_debug_c     => in_debug_c
              ,in_debug_s     => 'create_party_site return status  '
                                  ||l_address_rec.return_status
            );

      END IF;

    IF (l_address_rec.return_status != Fnd_Api.G_RET_STS_SUCCESS) THEN

      l_error_message_s :=  'create_party_site API Error '
                              ||l_address_rec.msg_data;

         ou_status_c         := G_ERROR_C;
         ou_message_s        := l_error_message_s;

         RETURN;
         --RAISE  ERROR_ENCOUNTERED;
    END IF;

      IF (l_address_rec.return_status = Fnd_Api.G_RET_STS_SUCCESS)  THEN

         g_cust_acct_site_rec.status                :=    'A';
         g_cust_acct_site_rec.party_site_id         :=    l_address_rec.party_site_id;
         g_cust_acct_site_rec.cust_account_id       :=    in_cust_rec.cust_account_id;
         g_cust_acct_site_rec.orig_system_reference :=    g_location_rec.orig_system_reference;

         Hz_Cust_Account_Site_V2pub.create_cust_acct_site
            (   p_init_msg_list      => Fnd_Api.G_TRUE
               ,p_cust_acct_site_rec => g_cust_acct_site_rec
               ,x_cust_acct_site_id  => l_address_rec.cust_acct_site_id
               ,x_return_status      => l_address_rec.return_status
               ,x_msg_count          => l_address_rec.msg_count
               ,x_msg_data         => l_address_rec.msg_data
            );

         swg_format_string
            (   io_msg_count_n => l_address_rec.msg_count
               ,io_msg_data_s  => l_address_rec.msg_data
            );

         swg_cust_debug
            (  in_debug_c     => in_debug_c
              ,in_debug_s     => 'create_cust_acct_site return status  '
                                 ||l_address_rec.return_status
            );

      END IF;

      IF (l_address_rec.return_status != Fnd_Api.G_RET_STS_SUCCESS) THEN

         l_error_message_s  :=  'Bill create_cust_acct_site API Error '
                              ||l_address_rec.msg_data;

         ou_status_c         := G_ERROR_C;
         ou_message_s        := l_error_message_s;

         RETURN;
         --RAISE  ERROR_ENCOUNTERED;
      END IF;

      IF (l_address_rec.return_status = Fnd_Api.G_RET_STS_SUCCESS)  THEN

         g_cust_site_use_rec.created_by_module  :=    g_created_by_module;
         g_cust_site_use_rec.cust_acct_site_id  :=    l_address_rec.cust_acct_site_id;
         g_cust_site_use_rec.site_use_code     :=    'BILL_TO';
         g_cust_site_use_rec.status             :=    'A';

         IF l_billto_recs_read_n = 1 THEN
            g_cust_site_use_rec.primary_flag := 'Y';
         ELSE
            g_cust_site_use_rec.primary_flag := 'N';
         END IF;

         g_cust_site_use_rec.attribute_category      :=  'Bill To';
         g_cust_site_use_rec.attribute1              :=  l_addr_rec.po_number;
         g_cust_site_use_rec.attribute2              :=  TO_CHAR(TO_DATE(l_addr_rec.po_effective_from_date,'DD-MON-RR'),'YYYY/MM/DD HH24:MI:SS');
         g_cust_site_use_rec.attribute3              :=  TO_CHAR(TO_DATE(l_addr_rec.po_effective_to_date,'DD-MON-RR'),'YYYY/MM/DD HH24:MI:SS');
         g_cust_site_use_rec.attribute4              :=  l_addr_rec.po_total_dollars;
         g_cust_site_use_rec.attribute5              :=  l_addr_rec.po_total_units;
         g_cust_site_use_rec.attribute6              :=  l_addr_rec.customer_reference_number;
         g_cust_site_use_rec.attribute7              :=  l_addr_rec.remit_to_address;
         g_cust_site_use_rec.attribute8              :=  l_organization_id_n;
         g_cust_site_use_rec.attribute9              :=  l_division_id_n;
         g_cust_site_use_rec.orig_system_reference   :=  g_cust_acct_site_rec.orig_system_reference;

         -- Billto Profile colloector
         g_customer_profile_rec.collector_id          :=  l_billto_collector_id;
      
      -- Sacs7 Changes Muthu 22-June-2005
      
         -- commented out on 7/18/2005 as per Valerie the business wants to default this flag based
         -- on the setup of the profile class     
         --     IF l_addr_rec.late_fee_flag = 'Y' THEN
         --        g_customer_profile_rec.interest_charges := l_addr_rec.late_fee_flag;
         --        g_customer_profile_rec.interest_period_days := NVL(g_customer_profile_rec.interest_period_days, 30) ; -- Defaulted 30 as per valerie.
         --     ELSIF (l_addr_rec.late_fee_flag = 'N') OR (l_addr_rec.late_fee_flag IS NULL) THEN
         --        g_customer_profile_rec.interest_charges := l_addr_rec.late_fee_flag;
         --        g_customer_profile_rec.interest_period_days := NULL ;
         --     END IF;
         
         -- Added For SAGE Conversion
         IF l_addr_rec.late_fee_flag = 'Y' THEN
          g_customer_profile_rec.interest_charges := l_addr_rec.late_fee_flag;
          g_customer_profile_rec.interest_period_days := NVL(g_customer_profile_rec.interest_period_days, 30) ; -- Defaulted 30 as per valerie.
         ELSIF (l_addr_rec.late_fee_flag = 'N') OR (l_addr_rec.late_fee_flag IS NULL) THEN
          g_customer_profile_rec.interest_charges := l_addr_rec.late_fee_flag;
          g_customer_profile_rec.interest_period_days := NULL ;
         END IF;         
         -- Added For SAGE Conversion
      
      IF g_prfl_cls('DD KEY').profile_class_id = g_customer_profile_rec.profile_class_id THEN
         
         g_customer_profile_rec.send_statements := 'Y';

         /* SGB
           g_stmt_cycle_id(g_stmt_cycle_map(l_addr_rec.billing_cycle_day||g_state_sc).new_code).stmt_cycle_id can cause no data found 
           CHECK mapping of States and compare to Statement Cycle States
         */
         g_customer_profile_rec.statement_cycle_id := g_stmt_cycle_id(g_stmt_cycle_map(l_addr_rec.billing_cycle_day||g_state_sc).new_code).stmt_cycle_id;
         g_customer_profile_rec.attribute_category := 'STATEMENT ACTION';
            
         IF l_addr_rec.statement_mailed = 'Y' THEN         
            g_customer_profile_rec.attribute1 := 'MAIL';
         ELSIF l_addr_rec.statement_mailed = 'N' THEN
            g_customer_profile_rec.attribute1 := 'DNM';
         END IF;
            
          IF l_addr_rec.cycle_type = 1 THEN
            g_customer_profile_rec.attribute14 := 'M';
         ELSIF l_addr_rec.cycle_type = 0 THEN
            g_customer_profile_rec.attribute14 := 'P';
         END IF;
            
      ELSIF g_prfl_cls('DD NATIONAL ACCOUNTS').profile_class_id = g_customer_profile_rec.profile_class_id THEN
         
         g_customer_profile_rec.send_statements      := 'Y';
         g_customer_profile_rec.statement_cycle_id  := g_ddnational_stmt_cycle_id;
         g_customer_profile_rec.attribute_category  := 'STATEMENT ACTION';
         g_customer_profile_rec.attribute1          := 'DNM';
         g_customer_profile_rec.attribute14           := 'M';
            
      ELSE
         g_customer_profile_rec.send_statements      := 'Y';
         g_customer_profile_rec.statement_cycle_id    := g_stmt_cycle_id(g_stmt_cycle_map(l_addr_rec.billing_cycle_day||g_state_sc).new_code).stmt_cycle_id;
         g_customer_profile_rec.attribute_category    := 'STATEMENT ACTION';         
            
         IF l_addr_rec.statement_mailed = 'Y' THEN
            g_customer_profile_rec.attribute1 := 'MAIL';
         ELSIF l_addr_rec.statement_mailed = 'N' THEN
            g_customer_profile_rec.attribute1 := 'DNM';
         END IF;
            
          IF l_addr_rec.cycle_type = 1 THEN
               g_customer_profile_rec.attribute14 := 'M';
         ELSIF l_addr_rec.cycle_type = 0 THEN
            g_customer_profile_rec.attribute14 := 'P';
         END IF;

            g_customer_profile_rec.attribute15    :=  'Y';  -- Auto WriteOff Allowed.  Added For PN 555
            g_customer_profile_rec.attribute13    :=  l_addr_rec.bsc_flag;  -- Fuel Surcharge Allowed. Added For PN 555

      END IF;

      /* recurring credit card customers should be mailed statements */
      IF g_prfl_cls('DD NATIONAL ACCOUNTS').profile_class_id <> g_customer_profile_rec.profile_class_id THEN
            BEGIN
               SELECT 'MAIL'
               INTO    g_customer_profile_rec.attribute1
               FROM    swgcnv_dd_customer_creditcard  cc
               WHERE   cc.customer_id = in_lgcy_cust_rec.customer_id
               AND     cc.recurring_customer = 'Y'
               AND     cc.billing_site_id = l_addr_rec.billto_site_id;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  NULL;
               WHEN TOO_MANY_ROWS THEN
                  g_customer_profile_rec.attribute1 := 'MAIL';
               WHEN OTHERS THEN
                  RAISE;
            END;
      END IF;

         -- Call the customer site use API

         Hz_Cust_Account_Site_V2pub.create_cust_site_use
            (   p_init_msg_list         =>   Fnd_Api.G_TRUE
               ,p_cust_site_use_rec     =>   g_cust_site_use_rec
               ,p_customer_profile_rec  =>   g_customer_profile_rec
               ,p_create_profile        =>   Fnd_Api.G_TRUE
               ,p_create_profile_amt    =>   Fnd_Api.G_TRUE
               ,x_site_use_id           =>   l_site_use_rec.site_use_id
               ,x_return_status         =>   l_site_use_rec.return_status
               ,x_msg_count           =>   l_site_use_rec.msg_count
               ,x_msg_data          =>   l_site_use_rec.msg_data
            );

         swg_format_string
            (io_msg_count_n => l_address_rec.msg_count
            ,io_msg_data_s  => l_address_rec.msg_data
            );

         swg_cust_debug
            (in_debug_c     => in_debug_c
            ,in_debug_s     => 'create_cust_site_use return status  '
                                        ||l_site_use_rec.return_status
            );

      END IF;

      IF (l_site_use_rec.return_status != Fnd_Api.G_RET_STS_SUCCESS) THEN

         l_error_message_s  :=  'create_cust_site_use API Error '||l_site_use_rec.msg_data;

         ou_status_c         := G_ERROR_C;
         ou_message_s        := l_error_message_s;

         RETURN;
         --RAISE  ERROR_ENCOUNTERED;
      END IF;

      /* Updates the customer profile to be the same as the bill to profile - Sacs7 Muthu */

      BEGIN
         SELECT cust_account_profile_id
               ,cust_account_id
               ,object_version_number
         INTO   g_customer_profile_rec.cust_account_profile_id
               ,g_customer_profile_rec.cust_account_id
               ,l_cust_profile_ovn
         FROM hz_customer_profiles
         WHERE cust_account_id   =  in_cust_rec.cust_account_id
         AND site_use_id         IS NULL;
      EXCEPTION
         WHEN OTHERS THEN
            swg_cust_debug
                    (in_debug_c     => in_debug_c
                    ,in_debug_s     => 'Error Retrieving Customer Profile');
            ou_status_c         := G_ERROR_C;
            ou_message_s        := l_error_message_s;
            RETURN;
      END;

      HZ_CUSTOMER_PROFILE_V2PUB.update_customer_profile
         (   p_init_msg_list          => FND_API.G_TRUE
          ,p_customer_profile_rec   => g_customer_profile_rec
        ,p_object_version_number  => l_cust_profile_ovn
            ,x_return_status          => l_site_use_rec.return_status
            ,x_msg_count              => l_site_use_rec.msg_count
            ,x_msg_data             => l_site_use_rec.msg_data
         );

      swg_format_string
         (io_msg_count_n => l_site_use_rec.msg_count
         ,io_msg_data_s  => l_site_use_rec.msg_data
         );

      swg_cust_debug
         (in_debug_c     => in_debug_c
         ,in_debug_s     => 'update_customer_profile return status  '
                                        ||l_site_use_rec.return_status
         );

      FOR i IN 1..l_site_use_rec.msg_count LOOP
         swg_cust_debug
           (in_debug_c     => in_debug_c
           ,in_debug_s     => 'update_customer_profile error  '
                                        || Fnd_Msg_Pub.get(i, 'F')
           );
      END LOOP;


      IF (l_site_use_rec.return_status != Fnd_Api.G_RET_STS_SUCCESS) THEN

         l_error_message_s  :=  'update_customer_profile API Error '||in_cust_rec.msg_data;
         ou_status_c         := G_ERROR_C;
         ou_message_s        := l_error_message_s;
         RETURN;
      ELSE
        g_customer_profile_rec.cust_account_profile_id := NULL;
         g_customer_profile_rec.cust_account_id := NULL;
      END IF;

      -- Set the billto site use id and other variable used in shipto loop
      --    l_bill_to_site_use_id   :=  l_site_use_rec.site_use_id;
      --    l_same_cust_acct_site_id  :=  l_address_rec.cust_acct_site_id;
      --    l_same_location_id       := l_address_rec.location_id;
      --    l_billto_orig_sys_ref   :=  g_cust_acct_site_rec.orig_system_reference;

      Create_Phone
         (   in_lgcy_cust_rec           => in_lgcy_cust_rec
            ,in_lgcy_address_id_n       => l_addr_rec.bill_to_address_id
            ,in_cust_rec                => in_cust_rec
            ,in_cust_acct_site_id_n     => l_address_rec.cust_acct_site_id
            ,in_debug_c                 => in_debug_c
            ,ou_status_c                => l_status_c
            ,ou_message_s               => l_message_s
         );

      IF l_status_c != G_SUCCESS_C THEN

         ou_status_c     := l_status_c;
         ou_message_s    := l_message_s;
         RETURN;

      END IF;

      l_route_s := NULL;

      Process_Ship_Tos
         (   in_system_name_s           => in_system_name_s
            ,in_lgcy_cust_rec           => in_lgcy_cust_rec
            ,in_lgcy_bill_addr_id_n     => l_addr_rec.bill_to_address_id
            ,in_lgcy_billto_site_id_n   => l_addr_rec.billto_site_id
            ,in_cust_rec                => in_cust_rec
            ,in_cust_acct_site_id_n     => l_address_rec.cust_acct_site_id
            ,in_cust_sales_center_s     => in_cust_sales_center_s
            ,in_cust_sales_center_id_n  => in_cust_sales_center_id_n
            ,in_bill_sales_center_s     => l_new_sales_center
            ,in_bill_sales_center_id_n  => l_organization_id_n
            ,in_billto_orig_sys_ref_s   => g_cust_acct_site_rec.orig_system_reference
            ,in_billto_location_id_n    => l_address_rec.location_id
            ,in_billto_site_use_id_n    => l_site_use_rec.site_use_id
            ,in_bill_price_list_id_n    => l_price_list_id_n
            ,in_bill_warehouse_id_n     => l_warehouse_id_n
            ,in_profile_class_s         => l_profile_class_s
            ,in_debug_c                 => in_debug_c
            ,ou_address_code_s          => l_ship_address_code_s
            ,ou_status_c                => l_status_c
            ,ou_message_s               => l_message_s
            ,ou_route_s                 => l_route_s
         );

      IF l_status_c != G_SUCCESS_C THEN
         ou_address_code_s   :=  NVL(l_ship_address_code_s,l_addr_rec.billing_location_number);
         ou_status_c         :=  l_status_c;
         ou_message_s        :=  l_message_s;
         RETURN;
      END IF;

      IF l_route_s IS NOT NULL THEN
         ou_route_s  := l_route_s;
      END IF;

  END LOOP; 
EXCEPTION
   WHEN OTHERS THEN
      swg_cust_debug
         (  in_debug_c     => in_debug_c
           ,in_debug_s     => 'Exception in Process_Addresses'
         );
      RAISE;
END   Process_Addresses;

--------------------------------------------------------------------

PROCEDURE Child_Program  
         (   ou_errbuf_s         OUT    VARCHAR2
            ,ou_errcode_n        OUT    NUMBER 
            ,in_sales_center_s   IN     VARCHAR2
            ,in_system_name_s    IN     VARCHAR2
            ,in_seq_num_n        IN     NUMBER
            --,in_route_num_s    IN     VARCHAR2
            ,in_debug_c          IN     VARCHAR2 DEFAULT 'N'
            ,in_validate_only_c  IN     VARCHAR2 DEFAULT 'Y' -- if set to Y then the 
            -- program will only commit
            -- the exceptions
         )
AS

   l_orcl_conv_rec            swgcnv_dd_temp_customers%ROWTYPE;

   l_system_name_s            VARCHAR2(10);
   l_dd_value_c               VARCHAR2(2)   :=  'DD';
   l_route_s                  VARCHAR2(10);
   l_err_customer_number_s    VARCHAR2(30);
   l_err_address_code_s       VARCHAR2(30);
   l_error_message_s          VARCHAR2(2000);
   l_customer_ref_s           VARCHAR2(1000);

   l_start_time_d             DATE;
   l_end_time_d               DATE;

   ERROR_ENCOUNTERED          EXCEPTION;

   l_already_converted_c      VARCHAR2(1);

   l_cust_recs_read_n         NUMBER   :=  0;
   l_shipto_recs_read_n       NUMBER    :=  0;
   l_organization_id_n        NUMBER   :=  0;

   l_orcl_conv_recs_out_n     NUMBER   :=  0;

   CURSOR cur_dd_customer (    in_sales_center    IN  VARCHAR2
                              ,in_seq_n           IN  NUMBER)
   IS
   SELECT  *
   FROM    swgcnv_dd_customer_interface   cust
   WHERE   sales_center   =  in_sales_center
   AND     cust.seq       =  in_seq_n;
   --    AND ROWNUM <=10;

   l_customer_rec             swgcnv_customer_rec_type;
   l_empty_customer_rec       swgcnv_customer_rec_type;

   CURSOR cur_org_collect(in_sales_center IN VARCHAR2)
   IS
   SELECT collector_id
   FROM   ar_collectors
   WHERE  status   =   'A'
   AND    name     =  in_sales_center;

   l_limit_rows_n             NUMBER  := 50;

   TYPE CustList IS TABLE OF swgcnv_dd_customer_interface%ROWTYPE INDEX BY BINARY_INTEGER;

   l_dd_cust_rec2             CustList;

   l_collector_id_n           NUMBER;
   l_division_id_n            NUMBER;

   l_status_c                 VARCHAR2(1);
   l_user_name_s              VARCHAR2(20) := 'SWGCNV';
   l_message_s                VARCHAR2(2000);

   l_profile_class_s          swgcnv_dd_customer_billto.customer_profile_class_name%TYPE;

   -- used to initialize g_cust_account_rec
   l_cust_account_rec         Hz_Cust_Account_V2pub.cust_account_rec_type;

   --used to initialize g_customer_profile_rec
   l_customer_profile_rec     Hz_Customer_Profile_V2pub.customer_profile_rec_type;

   --used to initialize g_cust_profile_amt_rec
   l_cust_profile_amt_rec     Hz_Customer_Profile_V2pub.cust_profile_amt_rec_type;

   INIT_ERROR                 EXCEPTION;

BEGIN

   ou_errbuf_s       :=     NULL;
   ou_errcode_n      :=     0;

   l_start_time_d    :=     SYSDATE;
   l_system_name_s   :=     in_system_name_s;

   g_ship_recs_read_n  := 0;
   g_bill_recs_read_n  := 0;

   BEGIN
      SELECT  user_id
      INTO    g_conv_userid_n
      FROM    fnd_user
      WHERE   user_name = 'SWGCNV';
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         dbms_output.put_line('Failed to initialize - User Name SWGCNV not present');
         Fnd_File.Put_Line(Fnd_File.LOG,'Failed to initialize - User Name SWGCNV not present');
         RAISE INIT_ERROR;
   END;

   -- Initialize the API

   BEGIN

      Fnd_Global.APPS_INITIALIZE
      (USER_ID        => g_conv_userid_n
      ,RESP_ID        => NULL
      ,RESP_APPL_ID   => NULL);

   EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('error in APPS_INITIALIZE ');
         Fnd_File.Put_Line(Fnd_File.LOG,'error in APPS_INITIALIZE ');
         RAISE INIT_ERROR;

   END;

   -- Retrieve the collector id for the given sales center

   OPEN cur_org_collect(in_sales_center_s);

   FETCH cur_org_collect
   INTO l_collector_id_n;

  IF cur_org_collect%NOTFOUND THEN
      l_collector_id_n  :=  NULL;
   END IF;

  CLOSE   cur_org_collect;

  IF l_collector_id_n IS NULL THEN

    l_error_message_s := 'Collector not defined for new sales center: ' || in_sales_center_s;
      RAISE INIT_ERROR;

  END IF;

   -- Get the Organization Id for the New Sales center
  BEGIN

      SELECT organization_id
      INTO   l_organization_id_n
      FROM   mtl_parameters
      WHERE  organization_code   =  in_sales_center_s;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         l_error_message_s   := 'Error: No data found for organization::'  || in_sales_center_s;
         RAISE INIT_ERROR;

      WHEN OTHERS THEN
         l_error_message_s  :=  'Unexpected Error retrieving organization data for '
                                    || in_sales_center_s || '...'
                                    || SQLERRM;
         RAISE INIT_ERROR;
   END;

   -- Get the warehouse and price list for new sales center
   BEGIN
      SELECT TO_NUMBER(hro.attribute1)--TO_NUMBER(NVL(hro.attribute1,'39559'))
            ,hro.organization_id
      INTO  g_price_list_id_n 
           ,g_warehouse_id_n
      FROM hr_organization_units    hro
      WHERE hro.organization_id =  l_organization_id_n;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         l_error_message_s   := 'Error: No data found retrieving organization data for::'
                                    || in_sales_center_s;
         RAISE INIT_ERROR;
      WHEN OTHERS THEN
         l_error_message_s  :=  'Unexpected Error retrieving organization data for '
                                    || in_sales_center_s || '...'
                                    || SQLERRM;
         RAISE INIT_ERROR;
   END;

   l_division_id_n  :=  Swg_Hierarchy_Pkg.get_parent 
                                        (in_child_type_s        =>   'LOCATION'
                                        ,in_child_value_s       =>   NULL
                                        ,in_child_id_n          =>   l_organization_id_n
                                        ,in_level_rqrd_s        =>   'DIVISION'
                                        ,in_effective_date_d    =>   TRUNC(SYSDATE)
                                        ,in_output_type_s       =>   'ID'
                                        ,in_output_style_s      =>   'HTL');
   IF l_division_id_n IS NULL THEN

      swg_cust_debug(in_debug_c,'No value for division for  '||l_organization_id_n);

      l_error_message_s :=  'Error getting division: hierarchy not defined for location: '
                                    || in_sales_center_s;
      RAISE INIT_ERROR;

      --  l_division_id_n :=  197;

   END IF; -- l_division_id_n

   swg_cust_debug('Y', 'before initialize');

   Initialize
            (in_system_name_s       =>  in_system_name_s
            ,in_sales_center_s      =>  in_sales_center_s
            ,in_debug_c             =>  in_debug_c
            ,ou_status_c            =>  l_status_c
            ,ou_message_s           =>  l_message_s);

   IF l_status_c != G_SUCCESS_C THEN

      l_error_message_s   := l_message_s;
      RAISE INIT_ERROR;

   END IF;

   swg_cust_debug('Y', 'after initialize');
        
   --
   -- Adding bulk collect to improve performance - 06/14/04 Kimberly Piper
   --

   OPEN cur_dd_customer ( in_sales_center_s, in_seq_num_n);--,in_route_num_s );
   LOOP

      FETCH cur_dd_customer BULK COLLECT INTO l_dd_cust_rec2 LIMIT l_limit_rows_n;

     FOR i IN 1..l_dd_cust_rec2.COUNT
     LOOP

        BEGIN

            l_cust_recs_read_n       :=    l_cust_recs_read_n + 1;

            swg_cust_debug(in_debug_c, 'Customers Read: '|| l_cust_recs_read_n);

            l_error_message_s         :=     NULL;
          l_err_customer_number_s   :=     LTRIM(RTRIM(l_dd_cust_rec2(i).customer_number));
--          l_err_address_code_s       :=    NULL;


            -- Check if the customer has already been converted in the SWGCNV_DD_TEMP_CUSTOMERS
          IF Is_Cust_Converted 
                            (  in_customer_number_s   => LTRIM(RTRIM(l_dd_cust_rec2(i).customer_number))
                              ,in_sales_center_s      => LTRIM(RTRIM(l_dd_cust_rec2(i).sales_center))
                              ,in_system_name_s       => in_system_name_s)
            THEN
             swg_cust_debug(in_debug_c,'Customer already converted '||l_dd_cust_rec2(i).customer_number);
             GOTO end_loop;
          END IF;

          swg_cust_debug(in_debug_c,'After Is_Cust_Converted... for Customer: '||l_dd_cust_rec2(i).customer_number);

          l_customer_ref_s  :=  l_dd_value_c        || '-' ||
                           l_system_name_s    || '-' ||
                           l_dd_cust_rec2(i).sales_center   || '-' ||
                           LTRIM(RTRIM(l_dd_cust_rec2(i).customer_number));
      
          -- Initialize the variables
      
          g_cust_account_rec     := l_cust_account_rec;
          g_customer_profile_rec  :=  l_customer_profile_rec;
          g_cust_profile_amt_rec  :=  l_cust_profile_amt_rec;
          l_customer_rec          :=  l_empty_customer_rec;

            -- Call procedure to populate the customer account rec

            swg_cust_debug(in_debug_c,'Before Populate_Cust_Acct_Rec...');
                          
            Populate_Cust_Acct_Rec
                            (in_system_name_s       => in_system_name_s
                            ,in_cust_rec            => l_dd_cust_rec2(i)
                            ,in_debug_c             => in_debug_c
                            ,in_cust_ref_s          => l_customer_ref_s
                            ,ou_status_c            => l_status_c
                            ,ou_message_s           => l_message_s);

            IF l_status_c != G_SUCCESS_C THEN

               l_error_message_s   := l_message_s;
               RAISE ERROR_ENCOUNTERED;

            END IF;

            -- Call procedure to populate the customer profile rec

            Populate_Cust_Profile_Rec
                            (in_system_name_s       => in_system_name_s
                            ,in_collector_id_n      => l_collector_id_n
                            ,in_cust_rec            => l_dd_cust_rec2(i)
                            ,in_debug_c             => in_debug_c
                            ,ou_status_c            => l_status_c
                            ,ou_message_s           => l_message_s
                            ,ou_profile_class_s     => l_profile_class_s);

            IF l_status_c != G_SUCCESS_C THEN

               l_error_message_s   := l_message_s;
               RAISE ERROR_ENCOUNTERED;

            END IF;

            IF g_customer_profile_rec.profile_class_id IN (1060, 1080, 1081, 1084) THEN
               g_cust_account_rec.attribute11 := 'C';
            END IF;

            -- Call the customer API to create the customer

            swg_cust_debug(in_debug_c,'Before calling create_cust_account API ');

            IF  LTRIM(RTRIM(l_dd_cust_rec2(i).person_flag)) = 'Y' THEN

               Hz_Cust_Account_V2pub.create_cust_account
                  (  p_init_msg_list         => Fnd_Api.G_TRUE
               ,p_cust_account_rec      => g_cust_account_rec
               ,p_person_rec            => g_person_rec
               ,p_customer_profile_rec  => g_customer_profile_rec
               ,p_create_profile_amt     => Fnd_Api.G_TRUE
               ,x_cust_account_id       => l_customer_rec.cust_account_id
               ,x_account_number        => l_customer_rec.account_number
               ,x_party_id              => l_customer_rec.party_id
               ,x_party_number          => l_customer_rec.party_number
               ,x_profile_id            => l_customer_rec.profile_id
               ,x_return_status         => l_customer_rec.return_status
               ,x_msg_count             => l_customer_rec.msg_count
               ,x_msg_data              => l_customer_rec.msg_data);

               swg_format_string
                  (io_msg_count_n => l_customer_rec.msg_count
                  ,io_msg_data_s  => l_customer_rec.msg_data);

            ELSIF(LTRIM(RTRIM(l_dd_cust_rec2(i).person_flag)) = 'N') THEN
            
           Hz_Cust_Account_V2pub.create_cust_account
                 (   p_init_msg_list         => Fnd_Api.G_TRUE
               ,p_cust_account_rec      => g_cust_account_rec
                    ,p_organization_rec      => g_organization_rec
               ,p_customer_profile_rec  => g_customer_profile_rec
               ,p_create_profile_amt     => Fnd_Api.G_TRUE
               ,x_cust_account_id       => l_customer_rec.cust_account_id
               ,x_account_number        => l_customer_rec.account_number
                    ,x_party_id              => l_customer_rec.party_id
               ,x_party_number          => l_customer_rec.party_number
               ,x_profile_id            => l_customer_rec.profile_id
               ,x_return_status         => l_customer_rec.return_status
               ,x_msg_count             => l_customer_rec.msg_count
               ,x_msg_data              => l_customer_rec.msg_data);

               swg_format_string
                 (io_msg_count_n => l_customer_rec.msg_count
                 ,io_msg_data_s  => l_customer_rec.msg_data);
                 
            END IF;

            swg_cust_debug(in_debug_c,'create_cust_account return status  '||l_customer_rec.return_status);
          swg_cust_debug(in_debug_c,'create_cust_account customer number'||l_customer_rec.account_number);

            -- Check the Error message

          IF l_customer_rec.return_status != G_SUCCESS_C  THEN

            l_error_message_s :=  'create_cust_account API Error '||l_customer_rec.msg_data;

            swg_cust_debug(in_debug_c,'create_cust_account returm status '||l_customer_rec.return_status);

            RAISE ERROR_ENCOUNTERED;

          END IF;

            l_route_s := NULL;
            
            Process_Addresses
               (  in_system_name_s           => in_system_name_s
                 ,in_lgcy_cust_rec           => l_dd_cust_rec2(i)
                 ,in_cust_rec                => l_customer_rec
                 ,in_cust_sales_center_s     => in_sales_center_s
                 ,in_cust_sales_center_id_n  => l_organization_id_n
                 ,in_cust_collector_id_n     => l_collector_id_n
                 ,in_cust_division_id_n      => l_division_id_n 
                 ,in_profile_class_s         => l_profile_class_s
                 ,in_debug_c                 => in_debug_c
                 ,ou_address_code_s          => l_err_address_code_s
                 ,ou_status_c                => l_status_c
                 ,ou_message_s               => l_message_s
                 ,ou_route_s                 => l_route_s);

            IF l_status_c != G_SUCCESS_C THEN
               l_error_message_s    := 'Process Addresses returned in error: '||CHR(10)
                                        || l_message_s;
            RAISE ERROR_ENCOUNTERED;
            END IF;

            IF l_route_s IS NULL THEN
               l_error_message_s := 'Error: Unable to determine the customer route.';
               RAISE  ERROR_ENCOUNTERED;
            END IF;

         -- Temp Table Information

         l_orcl_conv_rec.system_code            :=  in_system_name_s;
            l_orcl_conv_rec.division            :=  l_division_id_n;
            l_orcl_conv_rec.legacy_customer_number  :=  l_dd_cust_rec2(i).customer_number;
            l_orcl_conv_rec.new_sales_center      :=  l_dd_cust_rec2(i).sales_center;

            -- Insert into Temp Tables

            BEGIN
               swg_cust_debug(in_debug_c,'Inside temp customers loop' );
               
               INSERT INTO  swgcnv_dd_temp_customers
                  ( system_code
                    ,new_sales_center
                    ,division
                    ,legacy_customer_number
                    ,legacy_route_number
                    ,legacy_default_route
                    ,contracts_proc_flag
                    ,special_price_proc_flag
                    ,proj_pchase_proc_flag
                    ,proj_pchase_item_proc_flag
                    ,stmnt_proc_flag
                    ,ar_proc_flag
                    ,cust_import_flag
                    ,customer_balance
                    ,oracle_customer_id
                    ,oracle_customer_number
                    ,commitment_proc_flag)
                     VALUES
                  ( l_orcl_conv_rec.system_code
                    ,l_orcl_conv_rec.new_sales_center
                    ,l_orcl_conv_rec.division
                    ,l_orcl_conv_rec.legacy_customer_number
                    ,l_route_s
                    ,l_route_s
                    ,'N'
                    ,'N'
                    ,'N'
                    ,'N'
                    ,'N'
                    ,'N'
                    ,'Y'
                    ,NULL
                    ,l_customer_rec.cust_account_id
                    ,TO_NUMBER(l_customer_rec.account_number)
                    ,'N');

               l_orcl_conv_recs_out_n := l_orcl_conv_recs_out_n + 1;

               swg_cust_debug(in_debug_c,'Inserted into temp Customer  '||l_orcl_conv_rec.legacy_customer_number);

            EXCEPTION
               WHEN OTHERS THEN
                  l_error_message_s :=  'Error inserting temp_customers' || CHR(10) || SQLERRM;
                  RAISE ERROR_ENCOUNTERED;
            END;

            IF in_validate_only_c != 'Y' THEN
            COMMIT;
          ELSE
               ROLLBACK;
          END IF;

         <<end_loop>>

         IF in_validate_only_c != 'Y' THEN
            COMMIT;
       ELSE
         ROLLBACK;
       END IF;
      EXCEPTION
        WHEN ERROR_ENCOUNTERED THEN
            ROLLBACK;
            IF ou_errcode_n != 2 THEN
               ou_errbuf_s      :=  'Error encountered in customer loop see Exceptions for details.'
                                     ||l_error_message_s;
               ou_errcode_n   :=  1;

            END IF;

            Insert_Exceptions
               (  in_customer_number_s   => l_err_customer_number_s
              ,in_address_code_s      => l_err_address_code_s
              ,in_error_message_s     => l_error_message_s
              ,in_sales_center        => l_dd_cust_rec2(i).sales_center
               );
           COMMIT;

           swg_cust_debug
               (  in_debug_c     => G_SWG_DEBUG
                 ,in_debug_s     => 'Exception  '||l_error_message_s
               );

        WHEN OTHERS THEN
            l_error_message_s :=  SQLERRM;
            ou_errbuf_s     :=  'Unexpected Error encountered in customer loop see Exceptions for details.'
                                    ||l_error_message_s;
            ou_errcode_n    :=  2;
                  
            ROLLBACK;
            insert_exceptions 
              (   in_customer_number_s   => l_err_customer_number_s
              ,in_address_code_s      => l_err_address_code_s
              ,in_error_message_s     => 'Unexpected Error in Swgcnv_Dd_Customer_Convert::'||l_error_message_s
              ,in_sales_center        => l_dd_cust_rec2(i).sales_center
              );
          COMMIT;

           swg_cust_debug
               (  in_debug_c     => G_SWG_DEBUG
                 ,in_debug_s     => 'Exception  '||l_error_message_s
               );

         END;

      END LOOP;
   
      EXIT WHEN cur_dd_customer%NOTFOUND;

   END LOOP;

   CLOSE cur_dd_customer;

   l_end_time_d :=  SYSDATE;
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'*************************  RUN STATISTICS *******************************');
   Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Customer Records Read           : ' || l_cust_recs_read_n);
   Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Ship Address  Records Read      : ' || g_ship_recs_read_n);
   Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Bill Address  Records Read      : ' || g_bill_recs_read_n);
   Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Temp Customer Records Written   : ' || l_orcl_conv_recs_out_n);
   Fnd_File.Put_Line(Fnd_File.OUTPUT,' ------------------------------------------------------------------------');
   Fnd_File.Put_Line(Fnd_File.OUTPUT,' Start Time : ' || TO_CHAR(l_start_time_d, 'MM/DD/RRRR HH24:MI:SS'));
   Fnd_File.Put_Line(Fnd_File.OUTPUT,' End Time   : ' || TO_CHAR(l_end_time_d, 'MM/DD/RRRR HH24:MI:SS'));
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'*************************************************************************');

EXCEPTION
   WHEN INIT_ERROR THEN
      ou_errbuf_s       :=  'Initialization Error encountered.' || l_error_message_s;
      ou_errcode_n    :=  2;
      RETURN;
   WHEN OTHERS THEN
      l_error_message_s   :=  SQLERRM;
      ou_errbuf_s         :=  'Unexpected Error: Child_Program::'||l_error_message_s;
      ou_errcode_n      :=  2;
      Fnd_File.Put_Line(Fnd_File.LOG,'Unexpected Error: Child_Program::'||l_error_message_s);
      RETURN;

END   Child_Program;--swgcnv_dd_Customer_Convert;

---------------------------------------------------------------------

PROCEDURE SWGCNV_CONTACT_API(io_contact_rec     IN OUT SWGCNV_CONTACT_REC_TYPE)
IS

BEGIN

--sgb
      io_contact_rec.status     :=  'A';
--    io_contact_rec.contact_person_first_name  :=  'DUNABLE'; --l_first_name_s;
--    io_contact_rec.contact_person_last_name :=  'BIEBER'; --l_last_name_s;
    io_contact_rec.account_party_type   :=  'PERSON'; --in_cust_rec.party_type;--PERSON ORGANIZATINO
    io_contact_rec.account_party_type   :=  'ORGANIZATION';

--    io_contact_rec.cust_account_id    :=  113125;  --in_cust_rec.cust_account_id;
--    io_contact_rec.cust_acct_site_id    :=  7936252; --in_cust_rec.address_id;
--    io_contact_rec.account_party_id   :=  764611;  --in_cust_rec.party_id;
Fnd_File.Put_Line ( Fnd_File.LOG,   'XXXXXX: '|| io_contact_rec.contact_person_first_name);
Fnd_File.Put_Line ( Fnd_File.LOG,   '1Time: '|| io_contact_rec.contact_person_last_name);
Fnd_File.Put_Line ( Fnd_File.LOG,   '2Time: '||  io_contact_rec.cust_account_id);
Fnd_File.Put_Line ( Fnd_File.LOG,   '3Time: '|| io_contact_rec.cust_acct_site_id);
Fnd_File.Put_Line ( Fnd_File.LOG,   '4Time: '||  io_contact_rec.account_party_id );

  g_person_rec.created_by_module            :=    g_created_by_module;
  g_org_contact_rec.created_by_module       :=    g_created_by_module;
  g_cust_acc_role_rec.created_by_module     :=    g_created_by_module;

  g_person_rec.person_first_name            :=    io_contact_rec.contact_person_first_name;
  g_person_rec.person_last_name             :=    io_contact_rec.contact_person_last_name;

  g_org_contact_rec.party_rel_rec.subject_type            :=    'PERSON';
  g_org_contact_rec.party_rel_rec.subject_table_name      :=    'HZ_PARTIES';
  g_org_contact_rec.party_rel_rec.object_id               :=    io_contact_rec.account_party_id;
  g_org_contact_rec.party_rel_rec.object_type             :=    io_contact_rec.account_party_type;
  g_org_contact_rec.party_rel_rec.object_table_name       :=    'HZ_PARTIES';
  g_org_contact_rec.party_rel_rec.relationship_code       :=    'CONTACT_OF';
  g_org_contact_rec.party_rel_rec.relationship_type       :=    'CONTACT';
  g_org_contact_rec.party_rel_rec.start_date              :=    SYSDATE;
  g_org_contact_rec.orig_system_reference                 :=    io_contact_rec.orig_system_reference;

  g_cust_acc_role_rec.cust_account_id                     :=    io_contact_rec.cust_account_id;
  g_cust_acc_role_rec.cust_acct_site_id                   :=    io_contact_rec.cust_acct_site_id;
  g_cust_acc_role_rec.role_type                           :=    'CONTACT';
  g_cust_acc_role_rec.orig_system_reference               :=    io_contact_rec.orig_system_reference;


  -- Call the create person API

  Hz_Party_V2pub.create_person (
     p_init_msg_list  => Fnd_Api.G_TRUE
    ,p_person_rec     => g_person_rec
    ,x_party_id       => io_contact_rec.contact_party_id
    ,x_party_number   => io_contact_rec.contact_party_number
    ,x_profile_id     => io_contact_rec.contact_party_profile_id
    ,x_return_status  => io_contact_rec.return_status
    ,x_msg_count      => io_contact_rec.msg_count
    ,x_msg_data      => io_contact_rec.msg_data);

  swg_format_string (io_contact_rec.msg_count,io_contact_rec.msg_data);

  IF (io_contact_rec.return_status = Fnd_Api.G_RET_STS_SUCCESS)
  THEN

    g_org_contact_rec.party_rel_rec.subject_id := io_contact_rec.contact_party_id;

    Hz_Party_Contact_V2pub.create_org_contact (
       p_init_msg_list   => Fnd_Api.G_TRUE
      ,p_org_contact_rec => g_org_contact_rec
      ,x_org_contact_id  => io_contact_rec.org_contact_id
      ,x_party_rel_id    => io_contact_rec.relationship_id
      ,x_party_id        => io_contact_rec.related_party_id
      ,x_party_number    => io_contact_rec.related_party_number
      ,x_return_status   => io_contact_rec.return_status
      ,x_msg_count       => io_contact_rec.msg_count
      ,x_msg_data        => io_contact_rec.msg_data);

    io_contact_rec.contact_number := g_org_contact_rec.contact_number;

    swg_format_string (io_contact_rec.msg_count,io_contact_rec.msg_data);

    IF (io_contact_rec.return_status = Fnd_Api.G_RET_STS_SUCCESS)
    THEN
      g_cust_acc_role_rec.party_id := io_contact_rec.related_party_id;

      Hz_Cust_Account_Role_V2pub.create_cust_account_role(
         p_init_msg_list         => Fnd_Api.G_TRUE
        ,p_cust_account_role_rec => g_cust_acc_role_rec
        ,x_cust_account_role_id  => io_contact_rec.contact_id
        ,x_return_status         => io_contact_rec.return_status
        ,x_msg_count             => io_contact_rec.msg_count
        ,x_msg_data              => io_contact_rec.msg_data);

      swg_format_string (io_contact_rec.msg_count,io_contact_rec.msg_data);
    END IF;
  END IF;

END SWGCNV_CONTACT_API;

-------------------------------------------------------------------

PROCEDURE Swgcnv_Contact_Point_Api(io_contact_point_rec IN OUT swgcnv_contact_point_rec_type)
IS

BEGIN

   g_contact_point_rec.created_by_module     :=    g_created_by_module;

  g_contact_point_rec.owner_table_name       :=    'HZ_PARTIES';
  g_contact_point_rec.owner_table_id         :=    io_contact_point_rec.related_party_id;
  g_contact_point_rec.contact_point_type     :=    io_contact_point_rec.contact_point_type;

  g_phone_rec.phone_area_code                :=    io_contact_point_rec.phone_area_code;
  g_phone_rec.phone_number                   :=    io_contact_point_rec.phone_number;
  g_phone_rec.phone_extension                :=    io_contact_point_rec.phone_extension;
  g_phone_rec.phone_line_type                :=    'GEN';

  g_email_rec.email_format                   :=    io_contact_point_rec.email_format;
  g_email_rec.email_address                  :=    io_contact_point_rec.email_address;
  g_contact_point_rec.orig_system_reference  :=    io_contact_point_rec.orig_system_reference;
   
   -- SAGE
   Hz_Contact_Point_V2pub.create_contact_point
      (
       p_init_msg_list     => Fnd_Api.G_TRUE
      ,p_contact_point_rec => g_contact_point_rec
      ,p_phone_rec         => g_phone_rec
      ,p_email_rec         => g_email_rec
      ,x_contact_point_id  => io_contact_point_rec.contact_point_id
      ,x_return_status     => io_contact_point_rec.return_status
      ,x_msg_count         => io_contact_point_rec.msg_count
      ,x_msg_data          => io_contact_point_rec.msg_data
      );  

   swg_format_string (io_contact_point_rec.msg_count,io_contact_point_rec.msg_data);   
   -- SAGE   
      
   /*

  IF    (io_contact_point_rec.contact_point_type IN ('PHONE','PAGER','GEN','FAX'))
  THEN
      Hz_Contact_Point_V2pub.create_phone_contact_point(
         p_init_msg_list     => Fnd_Api.G_TRUE
        ,p_contact_point_rec => g_contact_point_rec
        ,p_phone_rec         => g_phone_rec
        ,x_contact_point_id  => io_contact_point_rec.contact_point_id
        ,x_return_status     => io_contact_point_rec.return_status
        ,x_msg_count         => io_contact_point_rec.msg_count
        ,x_msg_data          => io_contact_point_rec.msg_data);

      swg_format_string (io_contact_point_rec.msg_count,io_contact_point_rec.msg_data);
         
      -- Added To Create Email Contact Point. SAGE Acquisition Modification 
      IF ( io_contact_point_rec.email_address IS NOT NULL ) THEN
      
         g_contact_point_rec.contact_point_id   :=    io_contact_point_rec.contact_point_id;
         g_contact_point_rec.contact_point_type :=    'EMAIL';

      Hz_Contact_Point_V2pub.create_email_contact_point(
        p_init_msg_list      => Fnd_Api.G_TRUE
        ,p_contact_point_rec => g_contact_point_rec
        ,p_email_rec         => g_email_rec
        ,x_contact_point_id  => io_contact_point_rec.contact_point_id
        ,x_return_status     => io_contact_point_rec.return_status
        ,x_msg_count         => io_contact_point_rec.msg_count
        ,x_msg_data          => io_contact_point_rec.msg_data);

         swg_format_string (io_contact_point_rec.msg_count,io_contact_point_rec.msg_data);

      END IF;      
      -- Added To Create Email Contact Point. SAGE Acquisition Modification      

  ELSIF (io_contact_point_rec.contact_point_type = 'EMAIL')
  THEN
      Hz_Contact_Point_V2pub.create_email_contact_point(
        p_init_msg_list      => Fnd_Api.G_TRUE
        ,p_contact_point_rec => g_contact_point_rec
        ,p_email_rec         => g_email_rec
        ,x_contact_point_id  => io_contact_point_rec.contact_point_id
        ,x_return_status     => io_contact_point_rec.return_status
        ,x_msg_count         => io_contact_point_rec.msg_count
        ,x_msg_data          => io_contact_point_rec.msg_data);

         swg_format_string (io_contact_point_rec.msg_count,io_contact_point_rec.msg_data);

  END IF;
   */

END SWGCNV_CONTACT_POINT_API;

----------------------------------------------------------------------------------------
PROCEDURE   Master_Program
            (  ou_errbuf_s         OUT  VARCHAR2
              ,ou_errcode_n     OUT NUMBER
              ,in_sales_center_s    IN    VARCHAR2
              ,in_system_name_s   IN     VARCHAR2
              ,in_split_proc_cnt_n  IN    NUMBER 
              ,in_mode_c           IN    VARCHAR2    DEFAULT    G_SWG_CONCURRENT
              ,in_debug_flag_c    IN     VARCHAR2    DEFAULT    G_SWG_NODEBUG
              ,in_validate_only_c   IN    VARCHAR2    DEFAULT     'Y'
            )
IS


   l_request_tbl          request_tbl_type;
   l_request_empty_tbl      request_tbl_type;

   l_no_of_child_n          NUMBER;

   l_request_id_n         NUMBER;
   l_idx_bi           BINARY_INTEGER;

   l_check_req_b          BOOLEAN;

   l_call_status_b          BOOLEAN;
   l_rphase_s           VARCHAR2(80);
   l_rstatus_s            VARCHAR2(80);
   l_dphase_s           VARCHAR2(30);
   l_dstatus_s            VARCHAR2(30);
   l_message_s            VARCHAR2(2000);
   l_status_c           VARCHAR2(1);
   l_error_message_s      VARCHAR2(2000);

   ERROR_ENCOUNTERED      EXCEPTION;
    
BEGIN

   ou_errbuf_s    :=     NULL;
   ou_errcode_n   :=     0;
   l_no_of_child_n  :=     in_split_proc_cnt_n;

   assign_sequences
        (in_split_proc_cnt_n     =>     in_split_proc_cnt_n
        ,in_sales_center_s       =>     in_sales_center_s
        ,ou_child_proc_cnt_n     =>     l_no_of_child_n
        ,ou_status_c             =>     l_status_c
        ,ou_message_s            =>     l_error_message_s);

   IF l_status_c !=  G_SUCCESS_C THEN
      RAISE       ERROR_ENCOUNTERED;
   ELSE
      SWG_Cust_Debug(G_SWG_DEBUG, 'Assigning Sequences Success');
   END IF;

   Fnd_Stats.GATHER_TABLE_STATS('SWGCNV', 'SWGCNV_DD_TEMP_CUSTOMERS', 70);
   Fnd_Stats.GATHER_TABLE_STATS('SWGCNV', 'SWGCNV_DD_CUSTOMER_INTERFACE', 70);
   Fnd_Stats.GATHER_TABLE_STATS('SWGCNV', 'SWGCNV_DD_CUSTOMER_SHIPTO', 70);
   Fnd_Stats.GATHER_TABLE_STATS('SWGCNV', 'SWGCNV_DD_CUSTOMER_BILLTO', 70);
   Fnd_Stats.GATHER_TABLE_STATS('SWGCNV', 'SWGCNV_DD_CUSTOMER_CONTACT', 70);

   ---------------------------------------------------
   -- Submit the Child Process ( Process by Sequence )
   ----------------------------------------------------
   l_idx_bi   :=  0;
   l_request_tbl  :=  l_request_empty_tbl;

   FOR  l_proc_seq_n    IN  1..l_no_of_child_n
   LOOP

      l_request_id_n  :=  Fnd_Request.Submit_Request 
                                ( application =>     'SWGCNV'
                                 ,program      =>    'SWGCNV_CUST_CHILD_PROG'
                                 ,description =>     NULL
                                 ,start_time     =>    NULL
                                 ,sub_request =>     FALSE
                                 ,argument1   =>     in_sales_center_s    --  Sales Center
                                 ,argument2     =>    in_system_name_s
                                 ,argument3   =>     l_proc_seq_n     --  Process Sequence
                                 ,argument4   =>     in_debug_flag_c
                                 ,argument5     =>    in_validate_only_c
                                );

      IF l_request_id_n = 0 THEN

        ou_errbuf_s     :=  'ERROR: Unable to Submit Child Concurrent Request, Process Seq: '|| l_proc_seq_n;
         ou_errcode_n    :=   2;
         RAISE  ERROR_ENCOUNTERED;

      ELSE

         l_idx_bi                             := l_idx_bi  + 1;
         l_request_tbl(l_idx_bi).request_id   := l_request_id_n;
         l_request_tbl(l_idx_bi).proc_seq     :=  l_proc_seq_n;

     END IF;

   END LOOP;

   COMMIT;    -- Concurrent Request Commit

   ---------------------------------------------------
   -- Check all the child process has been completed
   ----------------------------------------------------
   l_check_req_b  :=  TRUE;

   WHILE l_check_req_b
   LOOP

      --Fnd_File.Put_Line ( Fnd_File.LOG,   'Time: '|| TO_CHAR(sysdate, 'DD-MON-RR HH24:MI:SS'));

      FOR l_req_idx_bi  IN  1..l_request_tbl.COUNT
      LOOP

         l_call_status_b  :=  Fnd_Concurrent.Get_Request_Status 
                                    (   request_id     =>    l_request_tbl(l_req_idx_bi).request_id
                                       ,phase          =>     l_rphase_s
                                       ,status         =>     l_rstatus_s
                                       ,dev_phase      =>    l_dphase_s
                                       ,dev_status     =>    l_dstatus_s
                                       ,message        =>     l_message_s
                                    );

         /*
         Fnd_File.Put_Line ( Fnd_File.LOG,    'Request Id: '|| l_request_tbl(l_req_idx_bi).request_id  || ' ' ||
                                             'Proc Seq: '  || l_request_tbl(l_req_idx_bi).proc_seq  || ' ' ||
                                             'Dev Phase: ' || l_dphase_s);
         */

         IF NVL(l_dphase_s, '~') != 'COMPLETE' THEN
            EXIT;
         END IF;

      END LOOP;

      IF NVL(l_dphase_s, '~') != 'COMPLETE' THEN

         DBMS_LOCK.SLEEP (90);

      ELSE

         l_check_req_b  :=  FALSE;

      END IF;

   END LOOP;    -- While Loop

EXCEPTION
   WHEN ERROR_ENCOUNTERED THEN
      RETURN;
   WHEN OTHERS THEN
      ou_errbuf_s     :=  'UNEXPECTED ERROR: '||SQLERRM;
      ou_errcode_n    := 2;        
      RETURN;

END   Master_Program;

/*Overloaded  --no its not SGB!!!*/

PROCEDURE   Master_Program_Post
            (  ou_errbuf_s          OUT   VARCHAR2
              ,ou_errcode_n         OUT   NUMBER
              ,in_sales_center_s    IN    VARCHAR2
              ,in_system_name_s     IN    VARCHAR2
              ,in_split_proc_cnt_n  IN    NUMBER 
              ,in_mode_c            IN    VARCHAR2    DEFAULT    G_SWG_CONCURRENT
              ,in_debug_flag_c      IN    VARCHAR2    DEFAULT    G_SWG_NODEBUG
              ,in_validate_only_c   IN    VARCHAR2    DEFAULT    'Y'
            )
IS


   l_request_tbl            request_tbl_type;
   l_request_empty_tbl      request_tbl_type;

   l_no_of_child_n          NUMBER;

   l_request_id_n           NUMBER;
   l_idx_bi                 BINARY_INTEGER;

   l_check_req_b            BOOLEAN;

   l_call_status_b          BOOLEAN;
   l_rphase_s               VARCHAR2(80);
   l_rstatus_s              VARCHAR2(80);
   l_dphase_s               VARCHAR2(30);
   l_dstatus_s              VARCHAR2(30);
   l_message_s              VARCHAR2(2000);
   l_status_c               VARCHAR2(1);
   l_error_message_s        VARCHAR2(2000);

   ERROR_ENCOUNTERED        EXCEPTION;
   
   CURSOR  get_location ( in_sc_center  VARCHAR2 )
   IS
   SELECT  unique a.sales_center
   FROM    swgcnv_dd_customer_interface a
   WHERE   a.sales_center =  NVL( in_sc_center, a.sales_center ) ;
   
   TYPE   sc_tbl_type
   IS     TABLE  OF  get_location%ROWTYPE;
   
   l_loc_tbl                 sc_tbl_type;
   l_loc_empty_tbl           sc_tbl_type;
   l_idx_bis                 BINARY_INTEGER;
   l_sc_center_s             VARCHAR2(100);
   
BEGIN
 
   l_loc_tbl    :=  l_loc_empty_tbl;

   Fnd_Stats.GATHER_TABLE_STATS('SWGCNV', 'SWGCNV_DD_TEMP_CUSTOMERS', 70);
   Fnd_Stats.GATHER_TABLE_STATS('SWGCNV', 'SWGCNV_DD_CUSTOMER_INTERFACE', 70);
   Fnd_Stats.GATHER_TABLE_STATS('SWGCNV', 'SWGCNV_DD_CUSTOMER_SHIPTO', 70);
   Fnd_Stats.GATHER_TABLE_STATS('SWGCNV', 'SWGCNV_DD_CUSTOMER_BILLTO', 70);
   Fnd_Stats.GATHER_TABLE_STATS('SWGCNV', 'SWGCNV_DD_CUSTOMER_CONTACT', 70);

   IF in_sales_center_s = 'ALL' THEN
      l_sc_center_s :=  NULL;
   ELSE
      l_sc_center_s :=  in_sales_center_s;
   END IF;

   OPEN     get_location  ( l_sc_center_s ) ;
	 FETCH    get_location
	 BULK     COLLECT  INTO     l_loc_tbl;
	 CLOSE    get_location;

	 IF l_loc_tbl.COUNT <> 0 THEN

	  	l_idx_bis := l_loc_tbl.FIRST;

	 LOOP

	   ou_errbuf_s    :=     NULL;
	   ou_errcode_n   :=     0;
	   l_no_of_child_n  :=     in_split_proc_cnt_n;

	   assign_sequences
		(in_split_proc_cnt_n     =>    in_split_proc_cnt_n
		,in_sales_center_s       =>    l_loc_tbl(l_idx_bis).sales_center
		,ou_child_proc_cnt_n     =>    l_no_of_child_n
		,ou_status_c             =>    l_status_c
		,ou_message_s            =>    l_error_message_s);

	   IF l_status_c !=  G_SUCCESS_C THEN
	      ou_errbuf_s     :=  'ERROR with assigning sequences';
	      ou_errcode_n    :=   2;
	      RAISE     ERROR_ENCOUNTERED;
	   ELSE
	      SWG_Cust_Debug(G_SWG_DEBUG, 'Assigning Sequences Success');
	   END IF;

	   ---------------------------------------------------
	   -- Submit the Child Process ( Process by Sequence )
	   ----------------------------------------------------
	   l_idx_bi   :=  0;
	   l_request_tbl  :=  l_request_empty_tbl;

	   FOR  l_proc_seq_n    IN  1..l_no_of_child_n
	   LOOP

	      l_request_id_n  :=  Fnd_Request.Submit_Request 
					( application =>     'SWGCNV'
					 ,program     =>     'SWGCNV_CUST_CHILD_PROG'
					 ,description =>     NULL
					 ,start_time  =>     NULL
					 ,sub_request =>     FALSE
					 ,argument1   =>     l_loc_tbl(l_idx_bis).sales_center    --  Sales Center
					 ,argument2   =>     in_system_name_s
					 ,argument3   =>     l_proc_seq_n     --  Process Sequence
					 ,argument4   =>     in_debug_flag_c
					 ,argument5   =>     in_validate_only_c
					);

	      IF l_request_id_n = 0 THEN

		      ou_errbuf_s      :=  'ERROR: Unable to Submit Child Concurrent Request, Process Seq: '|| l_proc_seq_n;
		      ou_errcode_n    :=   2;
		      RAISE  ERROR_ENCOUNTERED;

	      ELSE

		      l_idx_bi        := l_idx_bi  + 1;
		      l_request_tbl(l_idx_bi).request_id  := l_request_id_n;
		      l_request_tbl(l_idx_bi).proc_seq  := l_proc_seq_n;

	      END IF;

	   END LOOP;

	   COMMIT;  -- Concurrent Request Commit

	  EXIT WHEN (l_idx_bis = l_loc_tbl.LAST);

	       l_idx_bis := l_loc_tbl.NEXT( l_idx_bis );

	  END LOOP;

	  ELSE

	     ou_errbuf_s   :=  'No Sales Centers Are Loaded for Processing';
		   ou_errcode_n    :=   2;
	     RAISE  ERROR_ENCOUNTERED;

	  END IF;   

EXCEPTION
   WHEN ERROR_ENCOUNTERED THEN
      RETURN;
   WHEN OTHERS THEN
      ou_errbuf_s     :=  'UNEXPECTED ERROR: '||SQLERRM;
      ou_errcode_n    := 2;        
      RETURN;

END   Master_Program_Post;

-----------------------------------------------------------------------------------------------------------------------------

FUNCTION  Get_List_Price
    ( in_price_list_id_n    IN    NUMBER
     ,in_item_id_n      IN    NUMBER
     ,in_pricing_date_d     IN    DATE    DEFAULT   TRUNC(SYSDATE)
    )
RETURN  NUMBER
IS

    l_list_prc_n    NUMBER;
    l_status_c      VARCHAR2(1);
    l_message_s     VARCHAR2(2000);

BEGIN
    
    SWG_PRICING_PKG.swg_get_list_price
    ( in_price_list_id_n    =>    in_price_list_id_n
     ,in_item_id_n      =>    in_item_id_n
     ,in_pricing_date_d     =>    in_pricing_date_d
     ,io_list_price_n     =>    l_list_prc_n
     ,io_status_c     =>    l_status_c
     ,io_message_s      =>    l_message_s
     ,in_debug_c      =>    'N'
    );

    IF l_status_c  !=  'S'  THEN
        l_list_prc_n  :=  NULL;
        RETURN l_list_prc_n;
    END IF;

    RETURN l_list_prc_n;

EXCEPTION
    WHEN OTHERS THEN
    l_list_prc_n  :=  NULL;
    RETURN l_list_prc_n;
END get_list_price;

-----------------------------------------------------------------------------------------------------------------------------

FUNCTION  Get_Price
    ( in_customer_id_n      IN    NUMBER
     ,in_ship_to_id_n       IN    NUMBER
     ,in_item_id_n          IN    NUMBER
     ,in_quantity_n         IN    NUMBER    DEFAULT   0
     ,in_price_list_id_n    IN    NUMBER    DEFAULT   NULL
     ,in_pricing_date_d     IN    DATE      DEFAULT   TRUNC(SYSDATE)
    )
RETURN  NUMBER
IS

    l_adj_prc_n         NUMBER;
    l_status_c          VARCHAR2(1);
    l_message_s         VARCHAR2(2000);
    l_list_price_n      NUMBER;
    l_pricing_method_s  VARCHAR2(100);

BEGIN


    SWG_PRICING_PKG.swg_get_price
    ( in_customer_id_n      =>    in_customer_id_n
     ,in_ship_to_id_n       =>    in_ship_to_id_n
     ,in_item_id_n          =>    in_item_id_n
     ,in_quantity_n         =>    0
     ,in_price_list_id_n    =>    in_price_list_id_n  
     ,in_pricing_date_d     =>    in_pricing_date_d 
     ,io_list_price_n       =>    l_list_price_n
     ,io_adjusted_price_n   =>    l_adj_prc_n
     ,io_pricing_method_s   =>    l_status_c
     ,io_status_c           =>    l_pricing_method_s
     ,io_message_s          =>    l_message_s
     ,in_debug_c            =>    'N'
    );

    IF l_status_c  !=  'S'  THEN
        l_adj_prc_n  :=  NULL;
        RETURN l_adj_prc_n;
    END IF;

    RETURN l_adj_prc_n;


EXCEPTION
    WHEN OTHERS THEN
    l_adj_prc_n  :=  NULL;
    RETURN l_adj_prc_n;
END get_price;

-----------------------------------------------------------------------------------------------------------------------------

PROCEDURE       Create_RT_Phone
(in_lgcy_cust_rec           IN  swgcnv_dd_customer_interface%ROWTYPE
,in_lgcy_address_id_n       IN  NUMBER
,in_cust_rec                IN  swgcnv_customer_rec_type
,in_cust_acct_site_id_n     IN  NUMBER
,in_debug_c                 IN  VARCHAR2
,ou_status_c                OUT VARCHAR2
,ou_message_s               OUT VARCHAR2)
IS

    CURSOR  cur_phone
                        (in_customer_id IN NUMBER
                        ,in_address_id  IN NUMBER)
    IS
    SELECT  DISTINCT
    c.customer_id
    ,c.address_id
    ,c.contact_first_name
    ,c.contact_last_name
    ,c.telephone_area_code
    ,c.telephone
    ,c.telephone_extension
    ,c.telephone_type
    ,c.email_address
    FROM  swgcnv_dd_customer_contact  c
    WHERE --c.customer_id   = in_customer_id
       c.address_id    = in_address_id;

    l_contact_rec             swgcnv_contact_rec_type;
    l_contact_point_rec       swgcnv_contact_point_rec_type;
    l_error_message_s       VARCHAR2(2000);

BEGIN

    ou_status_c := G_SUCCESS_C;
    
    swg_cust_debug
                        (in_debug_c     => in_debug_c
                        ,in_debug_s     => 'mts Customer_id '
                                            ||in_lgcy_cust_rec.customer_id||' - '||in_lgcy_address_id_n);
                                            
                    

    FOR l_phone IN  cur_phone (in_lgcy_cust_rec.customer_id,in_lgcy_address_id_n)
    LOOP
        IF ((l_phone.contact_first_name IS NOT NULL)
      OR (l_phone.contact_last_name IS NOT NULL)) THEN

            swg_cust_debug
                        (in_debug_c     => in_debug_c
                        ,in_debug_s     => 'Entered into Cur Phone');

            g_phone_seq_n   :=  g_phone_seq_n + 1;


            l_contact_rec.insert_update_flag        :=  'I';
            l_contact_rec.contact_person_first_name :=  l_phone.contact_first_name;
            l_contact_rec.contact_person_last_name  :=  l_phone.contact_last_name;
            l_contact_rec.account_party_id          :=  in_cust_rec.party_id;

            IF in_lgcy_cust_rec.person_flag = 'Y' THEN

                l_contact_rec.account_party_type  :=  'PERSON';

            ELSIF in_lgcy_cust_rec.person_flag  = 'N' THEN

                l_contact_rec.account_party_type  :=  'ORGANIZATION';

            END IF;

            l_contact_rec.orig_system_reference :=  g_location_rec.orig_system_reference  || '-' ||
                                  l_phone.contact_first_name  || '-' ||
                                l_phone.contact_last_name || '-' ||
                                                    g_phone_seq_n;

            l_contact_rec.cust_account_id   :=  in_cust_rec.cust_account_id;
            l_contact_rec.cust_acct_site_id   :=  in_cust_acct_site_id_n;


            -- Call the contact phone API

            SWGCNV_CONTACT_API(l_contact_rec);

            swg_cust_debug
                        (in_debug_c     => in_debug_c
                        ,in_debug_s     => 'swgcnv_contact_api return status  '
                                            ||l_contact_rec.return_status);


            IF (l_contact_rec.return_status != Fnd_Api.G_RET_STS_SUCCESS) THEN

                l_error_message_s :=  'SWGCNV_CONTACT_API API Error '||l_contact_rec.msg_data;

                ou_status_c     := G_ERROR_C;
                ou_message_s    := l_error_message_s;
                RETURN;

                --RAISE ERROR_ENCOUNTERED;
            END IF;


            IF (l_contact_rec.return_status = Fnd_Api.G_RET_STS_SUCCESS)  THEN

                -- Call the contact point API

                l_contact_point_rec.contact_point_type  := l_phone.telephone_type;
                l_contact_point_rec.phone_area_code     := l_phone.telephone_area_code;
                l_contact_point_rec.phone_number      := l_phone.telephone;
                l_contact_point_rec.phone_extension     := l_phone.telephone_extension;
                l_contact_point_rec.email_address     := l_phone.email_address;
                l_contact_point_rec.email_format      := 'MAILHTML';
                l_contact_point_rec.related_party_id  := l_contact_rec.related_party_id;

  -- Satyaki says add an original system reference for phone numbers!!!!!!!!!!!!!!!!!!!
    l_contact_point_rec.orig_system_reference :=   l_contact_rec.orig_system_reference||'-'|| l_phone.telephone_area_code||'-'|| l_phone.telephone;

                SWGCNV_CONTACT_POINT_API(l_contact_point_rec);

                swg_cust_debug
                            (in_debug_c     => in_debug_c
                            ,in_debug_s     => 'swgcnv_contact_point_api return status  '
                                                ||l_contact_point_rec.return_status);

                IF (l_contact_point_rec.return_status != Fnd_Api.G_RET_STS_SUCCESS) THEN

                    l_error_message_s :=  'SWGCNV_CONTACT_POINT_API API Error '||l_contact_point_rec.msg_data;

                    ou_status_c     := G_ERROR_C;
                    ou_message_s    := l_error_message_s;

                    RETURN;

          --RAISE ERROR_ENCOUNTERED;
                END IF;

            END IF;

        END IF;

    END LOOP;  -- l_billto_phone
EXCEPTION
  WHEN OTHERS THEN
       swg_cust_debug
                            (in_debug_c     => in_debug_c
                            ,in_debug_s     => 'Exception in create_phone');
       RAISE;
END         Create_RT_Phone;

-----------------------------------------------------------------------------------------------------------------------------

PROCEDURE       Process_Only_Ship_Tos
(in_system_name_s           IN  VARCHAR2
,in_cust_rec                IN  swgcnv_customer_rec_type
,in_cust_acct_site_id_n     IN  NUMBER
,in_billto_location_id_n    IN  NUMBER
,in_billto_site_use_id_n    IN  NUMBER
,in_debug_c                 IN  VARCHAR2
,ou_address_code_s          OUT VARCHAR2
,ou_status_c                OUT VARCHAR2
,ou_message_s               OUT VARCHAR2
,ou_route_s                 OUT VARCHAR2)
IS


    CURSOR  cur_shipto
                        (in_customer_no IN  NUMBER
                        ,in_billto_id IN  NUMBER)
    IS
    SELECT  shipto.*
    ,addr.Address1
    ,addr.Address2
    ,addr.Address3
    ,addr.Address4
    ,addr.City
    ,addr.State
    ,addr.Province
    ,addr.County
    ,addr.Postal_Code
    ,addr.Country
    ,addr.Latitude
    ,addr.Longitude
    ,addr.Complex_Type
    ,addr.Variable_Unload_Time
    ,addr.Fixed_Unload_Time
    ,addr.Dock_Type
    FROM  swgcnv_dd_addresses       addr,
          swgcnv_dd_customer_shipto shipto
    WHERE shipto.customer_id        =       in_customer_no
    AND   shipto.billing_site_id        =       in_billto_id
    AND    addr.addr_clean_up_flag       <>     'E'
    AND   shipto.ship_to_address_id     =       addr.address_id
    AND   shipto.PROCESSED_FLAG         =       'N'
--    AND   shipto_site_id  = 128632
    AND   shipto.customer_id = addr.customer_id 
    ORDER BY shipto.delivery_location_number;

    l_ship_to_count_n           NUMBER;
    l_ship_organization_id_n    NUMBER;
    l_orcl_route_id             NUMBER;
    l_new_org_id                NUMBER;

    l_status_c                  VARCHAR2(1);
    l_dd_value_c                VARCHAR2(2) := 'DD';
    l_new_org_s                 VARCHAR2(3);
    l_ship_new_sales_center     VARCHAR2(10);
    l_err_shipto_code_s         VARCHAR2(10);
    l_err_address_code_s        VARCHAR2(30);
    l_new_code_s                VARCHAR2(100);
    l_new_sub_code_s            VARCHAR2(100);
    l_error_message_s           VARCHAR2(2000);
    l_message_s                 VARCHAR2(2000);

    l_address_rec               swgcnv_address_rec_type;
    l_site_use_rec              swgcnv_site_use_rec_type;

    l_billto_orig_sys_ref_s     g_cust_site_use_rec.orig_system_reference%TYPE;

    l_default_route_s           VARCHAR2(10)    := 'D23';
    l_primo_list_s              VARCHAR2(500);
    l_lgcy_cust_rec             swgcnv_dd_customer_interface%ROWTYPE;

BEGIN
    ou_status_c     := G_SUCCESS_C;
    ou_route_s      := NULL;

    swg_cust_debug(in_debug_c, 'in_cust_rec.account_number::        '||in_cust_rec.account_number);
    swg_cust_debug(in_debug_c, 'in_cust_rec.cust_account_id::       '||in_cust_rec.cust_account_id);
    swg_cust_debug(in_debug_c, 'in_cust_acct_site_id_n::            '||in_cust_acct_site_id_n    );
    swg_cust_debug(in_debug_c, 'in_billto_location_id_n::           '||in_billto_location_id_n   );
    swg_cust_debug(in_debug_c, 'in_billto_site_use_id_n::           '||in_billto_site_use_id_n   );

    -- Create the Shipto Records for the customer
    swg_cust_debug
            (in_debug_c     => in_debug_c
            ,in_debug_s     => 'Entered procedure::Process_Only_Ship_Tos');

    l_ship_to_count_n :=  0;

    FOR l_shipto_rec IN cur_shipto
                            (in_cust_rec.cust_account_id
                            ,in_billto_site_use_id_n)
    LOOP

        swg_cust_debug
                    (in_debug_c     => in_debug_c
                    ,in_debug_s     => 'Entered Shipto loop for '||in_cust_rec.account_number 
                                        ||' shipto_site_id '||l_shipto_rec.SHIPTO_SITE_ID);

        ou_address_code_s     :=  LTRIM(RTRIM(l_shipto_rec.delivery_location_number));

        g_ship_recs_read_n      :=  g_ship_recs_read_n  + 1;
        l_ship_to_count_n     :=  l_ship_to_count_n + 1;

        -- Initialize the variables

        g_location_rec    :=  NULL;
        g_party_site_rec  :=  NULL;
        g_cust_acct_site_rec  :=  NULL;
        g_cust_site_use_rec :=  NULL;

            BEGIN
                  SELECT organization_id
                        ,organization_code
                  INTO   l_ship_organization_id_n
                        ,l_ship_new_sales_center
                  FROM   mtl_parameters
                  WHERE  organization_code = l_shipto_rec.sales_center;

            EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                      l_error_message_s := 'Organization Not found in Oracle for '
                                           || l_shipto_rec.sales_center;

                      ou_status_c         := G_ERROR_C;
                      ou_message_s        := l_error_message_s;

                      RETURN;
                 WHEN OTHERS THEN
                      l_error_message_s := 'Unexpected Error: finding the organization for::'
                                           || l_shipto_rec.sales_center
                                           || '...'||SQLERRM;

                      ou_status_c         := G_ERROR_C;
                      ou_message_s        := l_error_message_s;

                      RETURN;
                    --RAISE ERROR_ENCOUNTERED;
            END;
            
         IF ( l_shipto_rec.price_list_name IS NOT NULL ) THEN  -- Stephen Bowen as per EB-367/21850

              g_cust_site_use_rec.price_list_id  :=  l_shipto_rec.price_list_name;

         END IF;

            -- Assign the address API values

               g_location_rec.created_by_module        := g_created_by_module;
               g_party_site_rec.created_by_module      := g_created_by_module;
               g_cust_acct_site_rec.created_by_module  := g_created_by_module;

               g_location_rec.country           := UPPER(LTRIM(RTRIM(l_shipto_rec.country)));
               g_location_rec.address1          := UPPER(LTRIM(RTRIM(l_shipto_rec.address1)));
               g_location_rec.address2          := UPPER(LTRIM(RTRIM(l_shipto_rec.address2)));
               g_location_rec.address3          := UPPER(LTRIM(RTRIM(l_shipto_rec.address3)));
               g_location_rec.address4          := UPPER(LTRIM(RTRIM(l_shipto_rec.address4)));
               g_location_rec.city              := UPPER(LTRIM(RTRIM(l_shipto_rec.city)));
               g_location_rec.postal_code       := UPPER(LTRIM(RTRIM(l_shipto_rec.postal_code)));
               g_location_rec.state             := UPPER(LTRIM(RTRIM(l_shipto_rec.state)));
               g_location_rec.province          := UPPER(LTRIM(RTRIM(l_shipto_rec.province)));
               g_location_rec.county            := UPPER(LTRIM(RTRIM(l_shipto_rec.county)));

               g_location_rec.orig_system_reference := l_dd_value_c     || '-' ||
                                                       in_system_name_s || '-' ||
                                                       l_shipto_rec.sales_center || '-' ||
                                                       LTRIM(RTRIM(in_cust_rec.account_number))|| '-' ||  --mts
                                                    --   LTRIM(RTRIM(in_cust_rec.customer_number))|| '-' || --mts
                                                       LTRIM(RTRIM(l_shipto_rec.delivery_location_number));

               -- Get the Sagent Data

               g_location_rec.attribute_category:=  'SAGENT DATA';
               g_location_rec.attribute1        :=  l_shipto_rec.latitude;
               g_location_rec.attribute2        :=  l_shipto_rec.longitude;
               g_location_rec.attribute3        :=  l_shipto_rec.complex_type;
               g_location_rec.attribute4        :=  l_shipto_rec.variable_unload_time;
               g_location_rec.attribute5        :=  l_shipto_rec.fixed_unload_time;
               g_location_rec.attribute6        :=  l_shipto_rec.dock_type;

               -- Call the location API

               Hz_Location_V2pub.create_location
                                 (p_init_msg_list => Fnd_Api.G_TRUE
                                 ,p_location_rec  => g_location_rec
                                 ,x_location_id   => l_address_rec.location_id
                                 ,x_return_status => l_address_rec.return_status
                                 ,x_msg_count     => l_address_rec.msg_count
                                 ,x_msg_data      => l_address_rec.msg_data);

               swg_format_string
                    (io_msg_count_n => l_address_rec.msg_count
                    ,io_msg_data_s  => l_address_rec.msg_data);

               swg_cust_debug
                    (in_debug_c     => in_debug_c
                    ,in_debug_s     => 'shipto create_location return status  '
                                        ||l_address_rec.return_status);


               IF (l_address_rec.return_status != Fnd_Api.G_RET_STS_SUCCESS) THEN

                   l_error_message_s := 'create_location API Error '||l_address_rec.msg_data;

                   ou_status_c         := G_ERROR_C;
                   ou_message_s        := l_error_message_s;

                   UPDATE  swgcnv_dd_customer_shipto  shipto
                   SET     shipto.PROCESSED_FLAG  = 'Y'
                          ,shipto.PROCESSED_STATUS= 'E'
                   WHERE   shipto.customer_id     = in_cust_rec.account_number
                   AND     shipto.billing_site_id = in_billto_site_use_id_n
                   AND     shipto.shipto_site_id  = l_shipto_rec.shipto_site_id;

                   RETURN;
                   --   RAISE ERROR_ENCOUNTERED;
               END IF;

               IF (l_address_rec.return_status = Fnd_Api.G_RET_STS_SUCCESS) THEN

                   g_party_site_rec.location_id           := l_address_rec.location_id;
                   g_party_site_rec.party_id              := in_cust_rec.party_id;
                   g_party_site_rec.orig_system_reference := g_location_rec.orig_system_reference;
                   g_party_site_rec.addressee             := l_shipto_rec.addressee;

                   -- Call the party site API

                   Hz_Party_Site_V2pub.create_party_site
                   (p_init_msg_list     => Fnd_Api.G_TRUE
                   ,p_party_site_rec    => g_party_site_rec
                   ,x_party_site_id     => l_address_rec.party_site_id
                   ,x_party_site_number => l_address_rec.party_site_number
                   ,x_return_status     => l_address_rec.return_status
                   ,x_msg_count         => l_address_rec.msg_count
                   ,x_msg_data          => l_address_rec.msg_data);

                   swg_format_string
                        (io_msg_count_n => l_address_rec.msg_count
                        ,io_msg_data_s  => l_address_rec.msg_data);

                   swg_cust_debug
                        (in_debug_c     => in_debug_c
                        ,in_debug_s     => 'shipto create_party_site return status '
                                            ||l_address_rec.return_status);
               END IF;

               IF (l_address_rec.return_status != Fnd_Api.G_RET_STS_SUCCESS) THEN

                   l_error_message_s  :=  'create_party_site API Error '||l_address_rec.msg_data;

                   ou_status_c         := G_ERROR_C;
                   ou_message_s        := l_error_message_s;

                   UPDATE  swgcnv_dd_customer_shipto  shipto
                   SET     shipto.processed_flag  = 'Y'
                          ,shipto.processed_status= 'E'
                   WHERE   shipto.customer_id     = in_cust_rec.account_number
                   AND     shipto.billing_site_id = in_billto_site_use_id_n
                   AND     shipto.shipto_site_id  = l_shipto_rec.shipto_site_id;

                   RETURN;
                   -- RAISE ERROR_ENCOUNTERED;
               END IF;

               IF (l_address_rec.return_status = Fnd_Api.G_RET_STS_SUCCESS) THEN

                   g_cust_acct_site_rec.status                := 'A';
                   g_cust_acct_site_rec.party_site_id         := l_address_rec.party_site_id;
                   g_cust_acct_site_rec.cust_account_id       := in_cust_rec.cust_account_id;
                   g_cust_acct_site_rec.orig_system_reference := g_location_rec.orig_system_reference;

                   -- Get the Sagent Data

                   g_cust_acct_site_rec.attribute_category  :=  'SAGENT DATA';
                   g_cust_acct_site_rec.attribute1    :=  l_shipto_rec.latitude;
                   g_cust_acct_site_rec.attribute2    :=  l_shipto_rec.longitude;
                   g_cust_acct_site_rec.attribute3    :=  l_shipto_rec.complex_type;
                   g_cust_acct_site_rec.attribute4    :=  l_shipto_rec.variable_unload_time;
                   g_cust_acct_site_rec.attribute5    :=  l_shipto_rec.fixed_unload_time;
                   g_cust_acct_site_rec.attribute6    :=  l_shipto_rec.dock_type;
                   g_cust_acct_site_rec.attribute9    :=  l_shipto_rec.primo_type||'-'||l_shipto_rec.primo_ar_price_list||'-'||l_shipto_rec.primo_acct_no||'-'||l_shipto_rec.primo_empty_credit;
                   g_cust_acct_site_rec.translated_customer_name := l_shipto_rec.sub_cust_number; -- Added by Ashok on 07/16/07 to store sub-cust reference (ARS02)


                   -- Call the Address API

                   Hz_Cust_Account_Site_V2pub.create_cust_acct_site
                   (p_init_msg_list      => Fnd_Api.G_TRUE
                   ,p_cust_acct_site_rec => g_cust_acct_site_rec
                   ,x_cust_acct_site_id  => l_address_rec.cust_acct_site_id
                   ,x_return_status      => l_address_rec.return_status
                   ,x_msg_count          => l_address_rec.msg_count
                   ,x_msg_data           => l_address_rec.msg_data);

                   swg_format_string
                        (io_msg_count_n => l_address_rec.msg_count
                        ,io_msg_data_s  => l_address_rec.msg_data);

                   swg_cust_debug
                        (in_debug_c     => in_debug_c
                        ,in_debug_s     => 'Shipto create_cust_acct_site return status  '
                                            ||l_address_rec.return_status);

                   swg_cust_debug
                        (in_debug_c     => in_debug_c
                        ,in_debug_s     => 'Shipto create_cust_acct_site new  '
                                            ||l_address_rec.cust_acct_site_id);
                                            
                   swg_cust_debug
                        (in_debug_c     => in_debug_c
                        ,in_debug_s     => 'g_cust_acct_site_rec.orig_system_reference  '
                                            ||g_cust_acct_site_rec.orig_system_reference);
                           
                   g_cust_site_use_rec.cust_acct_site_id     := l_address_rec.cust_acct_site_id;
                   g_cust_site_use_rec.orig_system_reference :=   g_cust_acct_site_rec.orig_system_reference;
                   
                   
               END IF;

               IF (l_address_rec.return_status != Fnd_Api.G_RET_STS_SUCCESS) THEN

                   l_error_message_s   :=  'Ship create_cust_acct_site API Error '
                                           ||l_address_rec.msg_data;
                   ou_status_c         := G_ERROR_C;
                   ou_message_s        := l_error_message_s;

                   UPDATE  swgcnv_dd_customer_shipto  shipto
                   SET     shipto.processed_flag  = 'Y'
                          ,shipto.processed_status= 'E'
                   WHERE   shipto.customer_id     = in_cust_rec.account_number
                   AND     shipto.billing_site_id = in_billto_site_use_id_n
                   AND     shipto.shipto_site_id  = l_shipto_rec.shipto_site_id;
        
                   RETURN;
                   --RAISE  ERROR_ENCOUNTERED;
               END IF;

   

        -- Check if shipto addresss and billto addresses are same, if they are same then
        -- use the billto address reference

          swg_cust_debug(in_debug_c, 'l_address_rec.return_status::'||l_address_rec.return_status);

          g_cust_site_use_rec.created_by_module   := g_created_by_module;
          g_cust_site_use_rec.site_use_code       := 'SHIP_TO';
          g_cust_site_use_rec.status              := 'A';
          g_cust_site_use_rec.bill_to_site_use_id := in_billto_site_use_id_n;

          -- Tax code

           g_cust_site_use_rec.tax_code  :=  'LOCATION';

           BEGIN
     
                g_cust_site_use_rec.warehouse_id := l_ship_organization_id_n;

                IF g_cust_site_use_rec.price_list_id IS NULL THEN
                
                  SELECT LIST_HEADER_ID
                  INTO   g_cust_site_use_rec.price_list_id
                  FROM   QP_LIST_HEADERS_TL
                  WHERE  name = UPPER(l_shipto_rec.price_list_name);
                  
                END IF;
                
                swg_cust_debug(in_debug_c,'sales center warehouse_id  : '||g_cust_site_use_rec.warehouse_id);
                swg_cust_debug(in_debug_c,'sales center price_list_id : '||g_cust_site_use_rec.price_list_id);

           EXCEPTION
                WHEN OTHERS THEN

                    g_cust_site_use_rec.price_list_id :=  NULL;

           END;

          IF g_cust_site_use_rec.price_list_id IS NULL OR
             g_cust_site_use_rec.warehouse_id  IS NULL THEN

                swg_cust_debug(in_debug_c,'One of the below required field is NULL');
                swg_cust_debug(in_debug_c,'sales center warehouse_id  : '||g_cust_site_use_rec.warehouse_id);
                swg_cust_debug(in_debug_c,'sales center price_list_id : '||g_cust_site_use_rec.price_list_id);

             BEGIN

                    l_new_org_s  :=  l_ship_new_sales_center;

                    swg_cust_debug(in_debug_c,'Get the shipto sales center price list '||l_new_org_s);

                    -- Get the the price list and warehouse

                    SELECT hro.attribute1
                          ,hro.organization_id
                    INTO   g_cust_site_use_rec.price_list_id
                          ,g_cust_site_use_rec.warehouse_id
                    FROM   hr_organization_units   hro
                    WHERE  hro.organization_id     = (SELECT org.organization_id
                                                      FROM   mtl_parameters org
                                                      WHERE  org.organization_code = l_new_org_s);

                    IF l_shipto_rec.rate_schedule = '2000' THEN
                       g_cust_site_use_rec.price_list_id := g_assoc_price_list_id;
                    END IF;

             EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                       l_error_message_s   := 'No data found getting price list for new sales center: '
                                              || l_new_org_s
                                              ||CHR(10)||SQLERRM;
                       ou_status_c         := G_ERROR_C;
                       ou_message_s        := l_error_message_s;
                       RETURN;

                  WHEN OTHERS THEN
                       l_error_message_s   :=  'Error getting price list for new sales center: ' ||
                                               l_new_org_s||CHR(10)||SQLERRM;

                       ou_status_c         := G_UNEXP_ERROR_C;
                       ou_message_s        := l_error_message_s;

                       RETURN;
                       --RAISE  ERROR_ENCOUNTERED;
             END;

          END IF; --warehouse or pricelist are null

          -- Check the price list

          Fnd_File.Put_Line(Fnd_File.LOG,'MEGAN g_cust_site_use_rec.price_list_id '||g_cust_site_use_rec.price_list_id);

          IF g_cust_site_use_rec.price_list_id IS NULL THEN
                   
             l_error_message_s   := 'Error getting price list for new sales center: '
                                    ||l_new_org_s;
             ou_status_c         := G_UNEXP_ERROR_C;
             ou_message_s        := l_error_message_s;
             RETURN;
          END IF;

          swg_cust_debug
            (   in_debug_c     =>  in_debug_c
               ,in_debug_s     => 'l_shipto_rec.sales_rep: '||l_shipto_rec.sales_rep);

          IF ( l_shipto_rec.sales_rep IS NOT NULL ) THEN

            BEGIN
            
               SELECT  salesrep_id
               INTO    g_cust_site_use_rec.primary_salesrep_id
               FROM    jtf_rs_salesreps
               WHERE   TRUNC(SYSDATE)   BETWEEN  start_date_active AND NVL(end_date_active,TRUNC(SYSDATE))
               AND     org_id           =  Fnd_Profile.Value('ORG_ID')
               AND     salesrep_number  =  l_shipto_rec.sales_rep;
               
            EXCEPTION
               WHEN OTHERS THEN
                 l_error_message_s   :=  'Error getting sales Rep: ' ||
                                               l_shipto_rec.sales_rep||CHR(10)||SQLERRM;
                 ou_status_c         := G_UNEXP_ERROR_C;
                 ou_message_s        := l_error_message_s;
                 RETURN;
            END;

          ELSE
         
             g_cust_site_use_rec.primary_salesrep_id   :=  NULL;
            
          END IF; 
         
          swg_cust_debug
            (   in_debug_c     =>  in_debug_c
               ,in_debug_s     => 'Sales Rep Id: '||g_cust_site_use_rec.primary_salesrep_id
            );
            
          swg_cust_debug
            (   in_debug_c     =>  in_debug_c
               ,in_debug_s     => 'Effective From Date: '||l_shipto_rec.po_effective_from_date
            );           

        -- Shipto Descriptive flexfield

            g_cust_site_use_rec.attribute_category  := 'Ship To';
            g_cust_site_use_rec.attribute1          := l_shipto_rec.customer_tax_class;
            g_cust_site_use_rec.attribute2          := l_shipto_rec.po_number;
            --g_cust_site_use_rec.attribute3          := TO_CHAR(TO_DATE(l_shipto_rec.po_effective_from_date,'DD-MON-RR'),'YYYY/MM/DD HH24:MI:SS');
            --g_cust_site_use_rec.attribute4          := TO_CHAR(TO_DATE(l_shipto_rec.po_effective_to_date,'DD-MON-RR'),'YYYY/MM/DD HH24:MI:SS');
            g_cust_site_use_rec.attribute5          := l_shipto_rec.customer_reference_number;
            g_cust_site_use_rec.attribute6          := l_shipto_rec.po_total_dollars;
            g_cust_site_use_rec.attribute7          := l_shipto_rec.po_total_units;

            IF l_new_code_s = 'OTHER NOT FOR PROFIT' THEN
                 g_cust_site_use_rec.attribute8     := l_shipto_rec.tax_exempt_number;  --'NO TAX # IN RIM';--
                 g_cust_site_use_rec.attribute9     := TO_CHAR(TO_DATE(l_shipto_rec.tax_exempt_exp_date,'DD-MON-RR'),'YYYY/MM/DD HH24:MI:SS');--TO_CHAR(TO_DATE(ADD_MONTHS(TRUNC(SYSDATE),4*12),'DD-MON-RR'),'YYYY/MM/DD HH24:MI:SS');--
            ELSE
                 g_cust_site_use_rec.attribute8     := l_shipto_rec.tax_exempt_number;
                 g_cust_site_use_rec.attribute9     := TO_CHAR(TO_DATE(l_shipto_rec.tax_exempt_exp_date,'DD-MON-RR'),'YYYY/MM/DD HH24:MI:SS');
            END IF;

                 g_cust_site_use_rec.attribute10    := l_shipto_rec.tax_exempt_certificate_rcvd;
                 g_cust_site_use_rec.attribute11    := TO_CHAR(TO_DATE(l_shipto_rec.ship_to_start_date,'DD-MON-RR'),'YYYY/MM/DD HH24:MI:SS');--TO_CHAR(TO_DATE(l_shipto_rec.customer_start_date,'DD-MON-RR'),'YYYY/MM/DD HH24:MI:SS');

                 g_cust_site_use_rec.attribute12    :=  l_shipto_rec.suppress_price_hh_ticket ; --'Y'    ; -- 'Suppress Price on HH Ticket?'
                 g_cust_site_use_rec.attribute13    :=  l_shipto_rec.rsr_overide_suppress_price; --'N'  ;  -- 'RSR Override Suppress Price?'

                 --SGB some more stuff
                 g_cust_site_use_rec.attribute14    :=  l_shipto_rec.bottle_initial_inv;
                 g_cust_site_use_rec.attribute15    :=  l_shipto_rec.crv_suppress;
                 g_cust_site_use_rec.attribute16    :=  l_shipto_rec.allow_multiple_tix;
                 g_cust_site_use_rec.attribute19    :=  l_shipto_rec.ticket_copies||'|'||l_shipto_rec.store_stamp||'|'||l_shipto_rec.split_trxn||'|'||l_shipto_rec.ticket_scan;


            -- Call the customer site use API

            Hz_Cust_Account_Site_V2pub.create_cust_site_use
                            (p_init_msg_list         => Fnd_Api.G_TRUE
                            ,p_cust_site_use_rec     => g_cust_site_use_rec
                            ,p_customer_profile_rec  => NULL --g_customer_profile_rec
                            ,p_create_profile        => Fnd_Api.G_FALSE     --- Modified not to create
                            ,p_create_profile_amt    => Fnd_Api.G_FALSE     --- profiles for shiptos
                            ,x_site_use_id           => l_site_use_rec.site_use_id
                            ,x_return_status         => l_site_use_rec.return_status
                            ,x_msg_count             => l_site_use_rec.msg_count
                            ,x_msg_data              => l_site_use_rec.msg_data);

            swg_format_string
                        (io_msg_count_n => l_site_use_rec.msg_count
                        ,io_msg_data_s  => l_site_use_rec.msg_data);


        swg_cust_debug
                (in_debug_c     => in_debug_c
                ,in_debug_s     =>'create_cust_site_use return status  '||l_site_use_rec.return_status);

        IF (l_site_use_rec.return_status != Fnd_Api.G_RET_STS_SUCCESS) THEN

            l_error_message_s :=  'create_cust_site_use API Error '||l_site_use_rec.msg_data;

            ou_status_c         := G_UNEXP_ERROR_C;
            ou_message_s        := l_error_message_s;
      
            UPDATE  swgcnv_dd_customer_shipto shipto
            SET     shipto.PROCESSED_FLAG  = 'Y'
                   ,shipto.PROCESSED_STATUS= 'E'
            WHERE   shipto.customer_id     = in_cust_rec.account_number
            AND     shipto.billing_site_id = in_billto_site_use_id_n
            AND     shipto.shipto_site_id  = l_shipto_rec.shipto_site_id;
      
            RETURN;
            --RAISE ERROR_ENCOUNTERED;
        END IF;

        UPDATE  swgcnv_dd_customer_shipto shipto
        SET     shipto.processed_flag    = 'Y'
               ,shipto.processed_status  = 'S'
               ,oracle_party_site_number = l_address_rec.party_site_number
               ,oracle_party_site_id     = l_address_rec.party_site_id
               ,oracle_ship_site_use_id  = l_site_use_rec.site_use_id
        WHERE   shipto.customer_id       = in_cust_rec.account_number
        AND     shipto.billing_site_id   = in_billto_site_use_id_n
        AND     shipto.shipto_site_id    = l_shipto_rec.shipto_site_id;
    
        ou_route_s  := l_shipto_rec.route_number;

        l_lgcy_cust_rec                 := NULL;
        l_lgcy_cust_rec.customer_number := l_shipto_rec.customer_id;

        l_lgcy_cust_rec.person_flag     := in_cust_rec.person_flag; --EB-659
        
        --Create_rt_Phone  EB-659
        Create_Phone
            (in_lgcy_cust_rec           => l_lgcy_cust_rec
            ,in_lgcy_address_id_n       => l_shipto_rec.ship_to_address_id
            ,in_cust_rec                => in_cust_rec
            ,in_cust_acct_site_id_n     => l_address_rec.cust_acct_site_id
            ,in_debug_c                 => in_debug_c
            ,ou_status_c                => l_status_c
            ,ou_message_s               => l_message_s);

        IF l_status_c != G_SUCCESS_C THEN

            ou_status_c     := l_status_c;
            ou_message_s    := l_message_s;
            swg_cust_debug  (in_debug_c     => in_debug_c
                            ,in_debug_s     => 'Exception in Create_Phone for address_id: '||l_shipto_rec.ship_to_address_id);
      RETURN;

        END IF;

    END LOOP; -- l_shipto_rec

EXCEPTION
  WHEN OTHERS THEN
       swg_cust_debug
                            (in_debug_c     => in_debug_c
                            ,in_debug_s     => 'Exception in Process_Ship_Tos');
       RAISE;
END Process_Only_Ship_Tos;

-----------------------------------------------------------------------------------------------------------------------------

  PROCEDURE   SWGCNV_DD_SHIPTO_CONVERT  --sgb
      (   ou_errbuf_s         OUT   VARCHAR2
         ,ou_errcode_n        OUT   NUMBER
         ,in_sales_center_s   IN    VARCHAR2
         ,in_system_name_s    IN    VARCHAR2
         ,in_debug_c          IN    VARCHAR2 DEFAULT 'N'
         ,in_validate_only_c  IN    VARCHAR2 DEFAULT 'Y' -- if set to Y then the program will only commit the exceptions
      )
   AS

      l_orcl_conv_rec            swgcnv_dd_temp_customers%ROWTYPE;

      l_system_name_s            VARCHAR2(10);
      l_dd_value_c               VARCHAR2(2)    := 'DD';
      l_route_s                  VARCHAR2(10);
      l_err_customer_number_s    VARCHAR2(30);
      l_err_address_code_s       VARCHAR2(30);
      l_error_message_s          VARCHAR2(2000);
      l_customer_ref_s           VARCHAR2(1000);

      l_start_time_d             DATE;
      l_end_time_d               DATE;

      ERROR_ENCOUNTERED          EXCEPTION;

      l_already_converted_c      VARCHAR2(1);

      l_cust_recs_read_n         NUMBER   := 0;
      l_shipto_recs_read_n       NUMBER   := 0;
      l_organization_id_n        NUMBER   := 0;

      l_orcl_conv_recs_out_n     NUMBER   := 0;

      l_customer_rec             swgcnv_customer_rec_type;
      l_empty_customer_rec       swgcnv_customer_rec_type;
      --l_legacy_customer_number_s     VARCHAR2(50);
      --l_sav_legacy_customer_number_s VARCHAR2(50)  := ' '; 
      -- Modified For PN 1131 to process multiple national accounts
      CURSOR cur_rt_customer
      IS 
      SELECT  DISTINCT hca.party_id
             ,hp.party_number
             ,hca.cust_account_id
             ,hca.account_number
             ,hcp.profile_class_id
             ,sdcs.billing_site_id
             ,DECODE ( hp.party_type, 'PERSON','Y','N') person_flag
      FROM    hz_cust_accounts      hca
             ,hz_parties            hp
             ,hz_customer_profiles  hcp
             ,swgcnv_dd_customer_shipto  sdcs
      WHERE  hca.CUST_ACCOUNT_ID    =  hcp.CUST_ACCOUNT_ID
      AND    hca.PARTY_ID           =  hp.PARTY_ID
      AND    hcp.SITE_USE_ID        IS NULL
      AND    hca.account_number     =  sdcs.customer_number
      AND    sdcs.sales_center = in_sales_center_s
      AND    nvl(sdcs.processed_flag,'N')  =  'N';

      l_location_id_n        NUMBER;
      l_cust_acct_site_id_n  NUMBER;
      l_bill_site_use_id_n   NUMBER;

      CURSOR   cur_org_collect(in_sales_center IN VARCHAR2)
      IS
      SELECT   collector_id
      FROM     ar_collectors
      WHERE    status   =  'A'
      AND      name     =  in_sales_center;

      l_limit_rows_n    NUMBER   :=    50;

      TYPE CustList IS TABLE OF swgcnv_dd_customer_interface%ROWTYPE INDEX BY BINARY_INTEGER;

      l_dd_cust_rec2    CustList;

      --  TYPE RtCustList IS TABLE OF swgcnv_dd_customer_interface%ROWTYPE;
      l_rt_lgcy_cust_rec      swgcnv_dd_customer_interface%ROWTYPE;

      l_collector_id_n        NUMBER;
      l_division_id_n         NUMBER;

      l_status_c              VARCHAR2(1);
      l_user_name_s           VARCHAR2(20)   := 'SWGCNV';
      l_message_s             VARCHAR2(2000);

      l_profile_class_s       swgcnv.swgcnv_dd_customer_billto.customer_profile_class_name%TYPE;

      -- used to initialize g_cust_account_rec
      l_cust_account_rec      Hz_Cust_Account_V2pub.cust_account_rec_type;

      --used to initialize g_customer_profile_rec
      l_customer_profile_rec  Hz_Customer_Profile_V2pub.customer_profile_rec_type;

      --used to initialize g_cust_profile_amt_rec
      l_cust_profile_amt_rec  Hz_Customer_Profile_V2pub.cust_profile_amt_rec_type;

      INIT_ERROR                  EXCEPTION;

      l_new_org_s                 VARCHAR2(3);
      l_ship_address_code_s       VARCHAR2(30);
      l_new_sales_center          VARCHAR2(100);
      l_billto_site_id_n          NUMBER;

   BEGIN
      DELETE SWGCNV_DD_TEMP_CUSTOMERS;
      ou_errbuf_s       :=    NULL;
      ou_errcode_n      :=    0;

      l_start_time_d    :=    SYSDATE;
      l_system_name_s   :=    in_system_name_s;

      g_ship_recs_read_n  := 0;
      g_bill_recs_read_n  := 0;

      BEGIN
      
        SELECT user_id
        INTO   g_conv_userid_n
        FROM   fnd_user
        WHERE  user_name = 'SWGCNV';
        
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            dbms_output.put_line('Failed to initialize - User Name SWGCNV not present');
            Fnd_File.Put_Line(Fnd_File.LOG,'Failed to initialize - User Name SWGCNV not present');
            RAISE INIT_ERROR;
      END;

      -- Initialize the API
      BEGIN

         Fnd_Global.APPS_INITIALIZE
            (   USER_ID       => g_conv_userid_n
               ,RESP_ID       => NULL
               ,RESP_APPL_ID  => NULL
            );

      EXCEPTION
         WHEN OTHERS THEN
            dbms_output.put_line('error in APPS_INITIALIZE ');
            Fnd_File.Put_Line(Fnd_File.LOG,'error in APPS_INITIALIZE ');
            RAISE INIT_ERROR;
      END;

      -- Retrieve the collector id for the given sales center

      OPEN  cur_org_collect(in_sales_center_s);

      FETCH cur_org_collect
      INTO  l_collector_id_n;

      IF cur_org_collect%NOTFOUND THEN
         l_collector_id_n  := NULL;
      END IF;

      CLOSE    cur_org_collect;

      IF l_collector_id_n IS NULL THEN

         l_error_message_s := 'Collector not defined for new sales center: ' ||in_sales_center_s;
         RAISE INIT_ERROR;

      END IF;

      -- Get the Organization Id for the New Sales center
      BEGIN

        SELECT organization_id
        INTO   l_organization_id_n
        FROM   mtl_parameters
        WHERE  organization_code = in_sales_center_s;

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            l_error_message_s   := 'Error: No data found for organization::'|| in_sales_center_s;
            RAISE INIT_ERROR;

         WHEN OTHERS THEN
            l_error_message_s    := 'Unexpected Error retrieving organization data for '
                                    || in_sales_center_s || '...'
                                    || SQLERRM;

            RAISE INIT_ERROR;
      END;

      -- Get the warehouse and price list for new sales center
      BEGIN
         SELECT TO_NUMBER(hro.attribute1)
               ,hro.organization_id
         INTO   g_price_list_id_n
               ,g_warehouse_id_n
         FROM   hr_organization_units   hro
         WHERE  hro.organization_id    = l_organization_id_n;

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            l_error_message_s   := 'Error: No data found retrieving organization data for::'|| in_sales_center_s;
            RAISE INIT_ERROR;
        WHEN OTHERS THEN
            l_error_message_s := 'Unexpected Error retrieving organization data for '
                                    || in_sales_center_s || '...'|| SQLERRM;
            RAISE INIT_ERROR;
      END;

      l_division_id_n   := Swg_Hierarchy_Pkg.get_parent
                              (   in_child_type_s        => 'LOCATION'
                                 ,in_child_value_s       =>  NULL
                                 ,in_child_id_n          =>  l_organization_id_n
                                 ,in_level_rqrd_s        => 'DIVISION'
                                 ,in_effective_date_d    =>  TRUNC(SYSDATE)
                                 ,in_output_type_s       => 'ID'
                                 ,in_output_style_s      => 'HTL'
                              );
                              
      IF l_division_id_n IS NULL THEN
        swg_cust_debug(in_debug_c,'No value for division for  '||l_organization_id_n);
        l_error_message_s  := 'Error getting division: hierarchy not defined for location: '|| in_sales_center_s;
        RAISE INIT_ERROR;
      END IF; -- l_division_id_n

      OPEN cur_rt_customer; -- ( in_sales_center_s, in_seq_num_n);--,in_route_num_s );
      
      LOOP -- Added For PN 1131, to process multiple national accounts.

         -- Initialize the variables
         g_cust_account_rec      := l_cust_account_rec;
         g_customer_profile_rec  := l_customer_profile_rec;
         g_cust_profile_amt_rec  := l_cust_profile_amt_rec;
         l_customer_rec          := l_empty_customer_rec;
        BEGIN    
         FETCH cur_rt_customer INTO  
        l_customer_rec.party_id
       ,l_customer_rec.party_number
       ,l_customer_rec.cust_account_id
       ,l_customer_rec.account_number
       ,l_customer_rec.profile_id
       ,l_billto_site_id_n
       ,l_customer_rec.person_flag;  --EB-659
       EXCEPTION WHEN OTHERS THEN
         NULL;
       END;
        --l_customer_rec.customer_number := l_legacy_customer_number_s;  --MTS
         -- Added For PN 1131, to process multiple national accounts.
         IF ( cur_rt_customer%NOTFOUND ) THEN
            CLOSE cur_rt_customer;
            EXIT;
         END IF;  

         BEGIN

            l_cust_recs_read_n       :=   l_cust_recs_read_n + 1;
            swg_cust_debug(in_debug_c, 'Customers Read: '|| l_cust_recs_read_n);

            l_error_message_s          := NULL;
            l_err_customer_number_s    := LTRIM(RTRIM(l_customer_rec.account_number));

            l_customer_ref_s  := l_dd_value_c       || '-' ||
                                 l_system_name_s    || '-' ||
                                 in_sales_center_s  || '-' ||
                                 --LTRIM(RTRIM(l_customer_rec.account_number));  --MTS 431 
                                 LTRIM(RTRIM(l_customer_rec.customer_number));
                                     
            swg_cust_debug(in_debug_c,'Customer Reference Is: '||l_customer_ref_s);                

            -- Prepare legacy record. -- as we are directly loading the customer shipto

            l_rt_lgcy_cust_rec.customer_id            :=    l_customer_rec.cust_account_id;
            l_rt_lgcy_cust_rec.customer_number        :=    l_customer_rec.account_number;

            l_route_s                                 :=    NULL;

            --  Fetch the bill_to details 
            BEGIN
               
               SELECT hps.location_id
                     ,hcas.cust_acct_site_id
                     ,hcsu.site_use_id
               INTO   l_location_id_n
                     ,l_cust_acct_site_id_n
                     ,l_bill_site_use_id_n
               FROM   hz_party_sites             hps
                     ,hz_cust_acct_sites_all     hcas
                     ,hz_cust_site_uses_all      hcsu
               WHERE  hcas.party_site_id        = hps.party_site_id 
               AND    hcsu.cust_acct_site_id    = hcas.cust_acct_site_id
               AND    hcsu.site_use_code        = 'BILL_TO'
               AND    hcsu.site_use_id          = l_billto_site_id_n;
               
               -- Commented for pn 1131, to process multiple shipto accounts
               --IN ( select distinct billing_site_id from SWGCNV_DD_CUSTOMER_SHIPTO s);

               swg_cust_debug
                  (   in_debug_c => G_SWG_DEBUG
                     ,in_debug_s => 'l_bill_site_use_id_n  : '||l_bill_site_use_id_n ||CHR(10)||
                                    'l_cust_acct_site_id_n : '||l_cust_acct_site_id_n||CHR(10)||
                                    'l_location_id_n       : '||l_location_id_n
                  );

            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  l_error_message_s  := 'Bill To Not found in Oracle for '|| l_customer_rec.account_number;
                  ou_errcode_n       := 2;
                  ou_errbuf_s        := l_error_message_s;

                  RETURN;
               WHEN OTHERS THEN
                  l_error_message_s := 'Unexpected Error: Unable to find bill_to details for the given billing_site_id ::'
                                       || l_customer_rec.account_number
                                       || '...'||SQLERRM;

                  ou_errcode_n      := 2;
                  ou_errbuf_s       := l_error_message_s;

                  RETURN;
                  --RAISE  ERROR_ENCOUNTERED;
            END;

            Process_only_Ship_Tos
               (   in_system_name_s           =>   in_system_name_s
                  ,in_cust_rec                =>   l_customer_rec        --in_cust_rec
                  ,in_cust_acct_site_id_n     =>   l_cust_acct_site_id_n --3813767 --l_address_rec.cust_acct_site_id
                  ,in_billto_location_id_n    =>   l_location_id_n       --3877796 --loc_id --l_address_rec.location_id
                  ,in_billto_site_use_id_n    =>   l_bill_site_use_id_n  --6820701 --6308866 --l_site_use_rec.site_use_id
                  ,in_debug_c                 =>   in_debug_c
                  ,ou_address_code_s          =>   l_ship_address_code_s
                  ,ou_status_c                =>   l_status_c
                  ,ou_message_s               =>   l_message_s
                  ,ou_route_s                 =>   l_route_s
               );

            IF l_status_c != G_SUCCESS_C THEN
               l_error_message_s   := l_message_s;
               RAISE ERROR_ENCOUNTERED;
               RETURN;
            END IF;
          --  IF l_sav_legacy_customer_number_s <> l_legacy_customer_number_s THEN
            	 --l_sav_legacy_customer_number_s :=  l_legacy_customer_number_s;
            	 BEGIN
               INSERT INTO SWGCNV_DD_TEMP_CUSTOMERS
               (
                SYSTEM_CODE,
                NEW_SALES_CENTER,
                DIVISION,
                LEGACY_CUSTOMER_NUMBER,
                LEGACY_ROUTE_NUMBER,
                LEGACY_DEFAULT_ROUTE,
                CONTRACTS_PROC_FLAG,
                SPECIAL_PRICE_PROC_FLAG,
                PROJ_PCHASE_PROC_FLAG,
                PROJ_PCHASE_ITEM_PROC_FLAG,
                STMNT_PROC_FLAG,
                AR_PROC_FLAG,
                CUST_IMPORT_FLAG,
                CUSTOMER_BALANCE,
                ORACLE_CUSTOMER_ID,
                ORACLE_CUSTOMER_NUMBER,
                CPP_PROC_FLAG,
                CREDIT_CHECK_PROC_FLAG,
                DEPOSIT_PROC_FLAG,
                COMMITMENT_PROC_FLAG,
                BOT_DEPOSIT_PROC_FLAG,
                TIER_PRICE_PROC_FLAG,
                CYCLE_BILLING_PROC_FLAG,
                RECEIPT_PROC_FLAG
              )
              VALUES
              (
                in_system_name_s,
                in_sales_center_s,
                l_division_id_n,
                --l_legacy_customer_number_s,
                l_customer_rec.account_number,  --CORRECT??? MTS
                NULL, --needed ??
                NULL, --needed ??
                'N',
                'N',
                'N',
                'N',
                'N',
                'N',
                'Y',
                NULL,
                l_customer_rec.cust_account_id,
                l_customer_rec.account_number,
                'N',
                'N',
                'N',
                'N',
                'N',
                'N',
                'N',
                'N'
              );
              EXCEPTION  WHEN OTHERS THEN
                ou_errbuf_s     :=  'UNEXPECTED ERROR: INSERTING ROW IN SWGCNV_DD_TEMP_CUSTOMERS'||SQLERRM;
                ou_errcode_n    := 2;        
                RETURN;
            END;
--            END IF;
            IF in_validate_only_c != 'Y' THEN
               COMMIT;
            ELSE
               ROLLBACK;
            END IF;

            <<end_loop>>
            IF in_validate_only_c != 'Y' THEN
               COMMIT;
            ELSE
               ROLLBACK;
            END IF;

         EXCEPTION
            WHEN ERROR_ENCOUNTERED THEN
               ROLLBACK;

               IF ou_errcode_n != 2 THEN

                  ou_errbuf_s  := 'Error encountered in customer loop see Exceptions for details.'
                                  ||l_error_message_s;
                  ou_errcode_n := 1;
               END IF;

               Insert_Exceptions
                  (   in_customer_number_s   => l_err_customer_number_s
                     ,in_address_code_s      => l_err_address_code_s
                     ,in_error_message_s     => l_error_message_s
                     ,in_sales_center        => in_sales_center_s
                  );
                  
               COMMIT;

               swg_cust_debug
                  (   in_debug_c => G_SWG_DEBUG
                     ,in_debug_s => 'Exception  '||l_error_message_s
                  );

            WHEN OTHERS THEN
               l_error_message_s   :=  SQLERRM;
               ou_errbuf_s         := 'Unexpected Error encountered in customer loop see Exceptions for details.'
                                          ||l_error_message_s;
               ou_errcode_n        :=  2;
               ROLLBACK;
               insert_exceptions
                  (   in_customer_number_s   => l_err_customer_number_s
                     ,in_address_code_s      => l_err_address_code_s
                     ,in_error_message_s     => 'Unexpected Error in Swgcnv_Dd_Customer_Convert::'||l_error_message_s
                     ,in_sales_center        => in_sales_center_s
                  );
               COMMIT;

               swg_cust_debug
                  (   in_debug_c => G_SWG_DEBUG
                     ,in_debug_s => 'Exception  '||l_error_message_s);

         END;

      END LOOP;
      --EXIT WHEN cur_dd_customer%NOTFOUND;
      --END LOOP;
      --CLOSE cur_dd_customer;

      l_end_time_d   := SYSDATE;
      
      Fnd_File.Put_Line(Fnd_File.OUTPUT,'*************************  RUN STATISTICS *******************************');
      Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Customer Records Read           : ' || l_cust_recs_read_n);
      Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Ship Address  Records Read      : ' || g_ship_recs_read_n);
      Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Bill Address  Records Read      : ' || g_bill_recs_read_n);
      Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Temp Customer Records Written   : ' || l_orcl_conv_recs_out_n);
      Fnd_File.Put_Line(Fnd_File.OUTPUT,' ------------------------------------------------------------------------');
      Fnd_File.Put_Line(Fnd_File.OUTPUT,' Start Time : ' || TO_CHAR(l_start_time_d, 'MM/DD/RRRR HH24:MI:SS'));
      Fnd_File.Put_Line(Fnd_File.OUTPUT,' End Time   : ' || TO_CHAR(l_end_time_d, 'MM/DD/RRRR HH24:MI:SS'));
      Fnd_File.Put_Line(Fnd_File.OUTPUT,'*************************************************************************');

   EXCEPTION
      WHEN INIT_ERROR THEN
         ou_errbuf_s    := 'Initialization Error encountered.' || l_error_message_s;
         ou_errcode_n   := 2;
         RETURN;
      WHEN OTHERS THEN
         l_error_message_s   :=  SQLERRM;
         ou_errbuf_s         :=  'Unexpected Error: Child_Program::'||l_error_message_s;
         ou_errcode_n        :=  2;

         Fnd_File.Put_Line(Fnd_File.LOG,'Unexpected Error: Child_Program::'||l_error_message_s);

         RETURN;
   END   SWGCNV_DD_SHIPTO_CONVERT;

/************************************************************************/

END Swgcnv_Dd_Customer_Pub_Pkg;
/
SHOW ERRORS
EXIT;