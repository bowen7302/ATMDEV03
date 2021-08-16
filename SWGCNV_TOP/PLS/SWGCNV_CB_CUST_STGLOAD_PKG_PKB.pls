create or replace PACKAGE BODY Swgcnv_CB_Cust_stgload_Pkg
AS

/* $Header: SWGCNV_CB_CUST_STGLOAD_PKB.pls 1.1 2010/02/17 09:33:33 SBEGAR $ */
/*=====================================================================================+
| Copyright (c) 2005 DS Waters, Atlanta, GA 30328 USA All rights reserved.             |
+======================================================================================+
| Name:           SWGCNV_CB_CUST_STGLOAD_PKG                                           |
| File:           SWGCNV_CB_CUST_STGLOAD_PKB.pls                                       |
| Description:    Package Body For Loading Data From Pre Staging To Staging Tables     |
|                                                                                      |
| Company:        DS Waters                                                            |
| Author:         Unknown                                                              |
| Date:           Unknown                                                              |
|                                                                                      |
| Modification History:                                                                |
| Date            Author            Description                                        |
| ----            ------            -----------                                        |
| Unknown         Unknown           Production Release                                 |
| 04/24/2008      Pankaj Umate      Modified For PURPLM Conversion. Daptiv No:  368    |
| 05/28/2008      Pankaj Umate      Modified For RENO Conversion. Daptiv No:    429    |
| 07/29/2008      Pankaj Umate      Modified For WTRFLX1 Conversion. Daptiv No: 555    |
| 11/26/2008      Pankaj Umate      Modified For ARS03 Conversion. Daptiv No: 753      |
| 01/09/2009      Pankaj Umate      Modified For ARS04 Conversion. Daptiv No:768       |
| 11/28/2009      Pankaj Umate      Modified For SAGE Conversion. Datptiv No: 1299     |
| 02/17/2010      Shashi Begar      Modified for Yosimite Conversion. Daptiv No: 1359  |
| 04/09/2010      Pankaj Umate      Daptiv # 1471. Conversion Mapping Table Migration  |
| 08/25/2010      Mike Schenk       Project #1641 ARS07                                |
| 04/11/2012      Stephen Bowen     WO #20129                                          |
| 06/19/2013      Bala Palani       WO #19982 Added will_call_flag col to cust shipto  |
| 08/05/2013      Bala Palani       WO #21652                                          |
| 05/14/2014      Bala Palani		    JIRA EB670 Added first and Last name changes       |
| 08/06/2014      Suganthi Uthaman  Modified for HDPRIMO Conversion. EB-829            |
| 11/03/2014      Bala Palani       EB-1156, Fix to handle null phone numbers          |
| 02/03/2015      Toseef Akram      EB-1289, Add The ADRESSEE field                    |
| 05/18/2016      Sateesh Kumar     EB-1877 Conversion Code Upgrade changes.           |
| 09/08/2016      Sateesh Kumar     EB-2023 Conversion - DSW Customer Module Changes   |
| 10/20/2016      Sateesh Kumar     EB-2058 Modify acquisition customer conversion     |
|                                   process to no longer default the tax certificate   |
|                                   received field based on tax status                 |
| 06/01/2018      Stephen Bowen     EB-2793 Set Signature Flag                         |
+=====================================================================================*/

   --1.  Customer staging table  :       SWGCNV_DD_CUSTOMER_INTERFACE
   --2.  Addresses table         :       SWGCNV_DD_ADDRESSES
   --3.  Billing Locations       :       SWGCNV_DD_CUSTOMER_BILLTO
   --4.  Shipping Locations      :       SWGCNV_DD_CUSTOMER_SHIPTO
   --5.  Contacts                :       SWGCNV_DD_CUSTOMER_CONTACT
   --6.  Shipping Cycle Day      :       SWGCNV_DD_CYCLEDAYS
   --7.  Contracts/Equipment     :       SWGCNV_DD_EQPMNT_INTERFACE

   g_error_flag_c     VARCHAR2(1)   :=    'N';
   
       TYPE  request_rec_type  IS  RECORD
  ( request_id      NUMBER
   ,sales_center    varchar2(100));
   
       TYPE  request_tbl_type  IS  TABLE OF  request_rec_type
    INDEX BY  BINARY_INTEGER;

   -----------------------------------------------------------------

   PROCEDURE swg_cust_debug( in_debug_c VARCHAR2,in_debug_s VARCHAR2)
   IS
   BEGIN
      IF NVL(in_debug_c,'N') = 'Y' THEN

         Fnd_File.Put_Line(Fnd_File.LOG, in_debug_s);

      END IF;

   END;

   ------------------------------------------------------------------

   PROCEDURE insert_row
      (   in_entity_name_s    IN    VARCHAR2
         ,in_cust_rec         IN    cust_rec_type      --1.  Customer staging table :  SWGCNV_DD_CUSTOMER_INTERFACE
         ,in_addr_rec         IN    addr_rec_type      --2.  Addresses table       : SWGCNV_DD_ADDRESSES
         ,in_billto_rec       IN    billto_rec_type    --3.  Billing Locations      : SWGCNV_DD_CUSTOMER_BILLTO
         ,in_shipto_rec       IN    shipto_rec_type    --4.  Shipping Locations     : SWGCNV_DD_CUSTOMER_SHIPTO
         ,in_contact_rec      IN    contact_rec_type   --5.  Contacts           : SWGCNV_DD_CUSTOMER_CONTACT
         ,in_cycleday_rec     IN    cycleday_rec_type  --6.  Shipping Cycle Day     : SWGCNV_DD_CYCLEDAYS
         ,in_eqp_rec          IN    eqp_rec_type       --7.  Contracts/Equipment    : SWGCNV_DD_EQPMNT_INTERFACE
      )
   IS

   BEGIN

      IF in_entity_name_s = 'CUST' THEN

         NULL;

      ELSIF in_entity_name_s = 'ADDR' THEN

         NULL;

      ELSIF in_entity_name_s = 'BILLTO' THEN

         NULL;

      ELSIF in_entity_name_s = 'SHIPTO' THEN

         NULL;

      ELSIF in_entity_name_s = 'CONTACT' THEN

         NULL;

      ELSIF in_entity_name_s = 'CYCLEDAY' THEN

         NULL;

      ELSIF in_entity_name_s = 'EQP' THEN

         NULL;

      END IF;

   END insert_row;

   ------------------------------------------------------------------

   FUNCTION check_cust_exists
      (   in_cust_num_s    IN    VARCHAR2
         ,in_cust_type_s IN    VARCHAR2
         ,in_cust_name_s IN    VARCHAR2
         ,in_sales_ctr_s IN    VARCHAR2
         ,in_division_s    IN    VARCHAR2
      )
   RETURN NUMBER
   IS

      l_customer_id  NUMBER;

   BEGIN

      SELECT customer_id
      INTO   l_customer_id
      FROM   swgcnv_dd_customer_interface
      WHERE  customer_number     =  in_cust_num_s
      AND    customer_name       =  in_cust_name_s
      AND    person_flag         =  in_cust_type_s
      AND    sales_center        =  in_sales_ctr_s
--      AND    division            =  in_division_s  --MTS 20129 Process bill to master for all divisions
      AND    rownum              =  1;

      RETURN l_customer_id;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         l_customer_id := -9;
         RETURN l_customer_id;
      WHEN OTHERS THEN
         swg_cust_debug('Y', 'Unexpected Error in Swgcnv_CB_Cust_stgload_Pkg.'||'check_cust_exists:  ' ||SQLERRM);
         g_error_flag_c := 'Y';
         RETURN 1;
   END check_cust_exists;

   ------------------------------------------------------------------

   FUNCTION check_mast_cust_exists
      (   in_cust_num_s     IN       VARCHAR2
         ,in_sales_ctr_s  IN       VARCHAR2
         ,in_division_s     IN       VARCHAR2
         ,io_mast_cust_name_s IN OUT VARCHAR2
      )
   RETURN NUMBER
   IS

      l_customer_id          NUMBER;
      l_mast_cust_name       VARCHAR2(50);
      l_mast_cust_bill_to    NUMBER;

   BEGIN

      SELECT customer_id
            ,customer_name
      INTO   l_customer_id
            ,l_mast_cust_name
      FROM   swgcnv_dd_customer_interface
      WHERE  customer_number     =    in_cust_num_s
      --AND    sales_center      =    in_sales_ctr_s
--      AND    division            =    in_division_s --MTS 20129 Process bill to master for all divisions
      AND    rownum              =    1;

      io_mast_cust_name_s := nvl(l_mast_cust_name,' ');

      RETURN l_customer_id;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         l_customer_id := -9;
         RETURN l_customer_id;
      WHEN OTHERS THEN
         swg_cust_debug('Y', 'Unexpected Error in Swgcnv_CB_Cust_stgload_Pkg.'||'check_mast_cust_exists:  ' ||SQLERRM);
         g_error_flag_c := 'Y';
         RETURN 1;
   END check_mast_cust_exists;

   ------------------------------------------------------------------

   FUNCTION  get_master_cust_billto
      (   in_cust_id_n  IN    NUMBER
         ,in_sales_ctr_s IN    VARCHAR2
         ,in_division_s  IN    VARCHAR2
      )
   RETURN NUMBER
   IS

      l_mast_cust_bill_to NUMBER;

   BEGIN

      SELECT sda.address_id
      INTO   l_mast_cust_bill_to
      FROM   swgcnv_dd_addresses          sda
            ,swgcnv_dd_customer_billto    sdcb
      WHERE  sda.customer_id           =      in_cust_id_n
--      AND    sda.sales_center          =      in_sales_ctr_s   --MTS 20129 Process bill to master for all divisions
--      AND    sda.division              =      in_division_s  --MTS 20129 Process bill to master for all divisions
      AND    sda.customer_id           =      sdcb.customer_id
      AND    sda.address_id            =      sdcb.BILL_TO_ADDRESS_ID
--      AND    sda.sales_center          =      sda.sales_center --MTS 20129
--      AND    sda.division              =      sda.division     --MTS 20129
      AND    rownum                    =      1;

      RETURN l_mast_cust_bill_to;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         l_mast_cust_bill_to := -9;
         RETURN l_mast_cust_bill_to;
      WHEN OTHERS THEN
         swg_cust_debug('Y', 'Unexpected Error in Swgcnv_CB_Cust_stgload_Pkg.'||'get_master_cust_billto:  ' ||SQLERRM);
         g_error_flag_c := 'Y';
         RETURN 1;
   END get_master_cust_billto;

   ------------------------------------------------------------------

   FUNCTION check_bill_addr_exists
      (   in_cust_num_s    IN    VARCHAR2
         ,in_bill_addr1_s IN    VARCHAR2
         ,in_bill_addr2_s IN    VARCHAR2
         ,in_bill_city_s IN    VARCHAR2
         ,in_bill_state_s IN    VARCHAR2
         ,in_bill_zip  IN    VARCHAR2
         ,in_sales_ctr_s IN    VARCHAR2
         ,in_division_s    IN    VARCHAR2
      )
   RETURN NUMBER
   IS

      l_addr_id NUMBER;

   BEGIN

      SELECT address_id
      INTO   l_addr_id
      FROM   swgcnv_dd_addresses
      WHERE  customer_number       =    in_cust_num_s
      AND    address1              =    in_bill_addr1_s
      AND    nvl(address2,'X')     =    nvl(in_bill_addr2_s,'X')
      AND    city                  =    in_bill_city_s
      AND    state                 =    in_bill_state_s
      AND    postal_code           =    in_bill_zip
      AND    sales_center          =    in_sales_ctr_s
--      AND    division              =    in_division_s --MTS 20129 Process bill to master for all divisions
      AND    rownum                =    1;

      RETURN l_addr_id;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         l_addr_id := -9;
         RETURN (l_addr_id);
      WHEN OTHERS THEN
         swg_cust_debug('Y', 'Unexpected Error in Swgcnv_CB_Cust_stgload_Pkg.'||'check_cust_exists:  ' ||SQLERRM);
         g_error_flag_c := 'Y';
         RETURN 1;
   END check_bill_addr_exists;

   ----------------------------------------------------------------

   FUNCTION check_ship_addr_exists
      (   in_cust_num_s    IN  VARCHAR2
         ,in_ship_addr1_s IN    VARCHAR2
         ,in_ship_addr2_s IN    VARCHAR2
         ,in_ship_addr3_s  IN    VARCHAR2   --  Added For SAGE Conversion
         ,in_ship_city_s IN    VARCHAR2
         ,in_ship_state_s IN    VARCHAR2
         ,in_ship_zip  IN    VARCHAR2
         ,in_sales_ctr_s IN    VARCHAR2
         ,in_division_s    IN    VARCHAR2
      )
   RETURN NUMBER
   IS

      l_addr_id NUMBER;

   BEGIN

      SELECT address_id
      INTO   l_addr_id
      FROM   swgcnv_dd_addresses
      WHERE  customer_number        =      in_cust_num_s
      AND    address1               =      in_ship_addr1_s
      AND    NVL(address2,'X')      =      NVL(in_ship_addr2_s,'X')
      AND    NVL(address2,'X')      =      NVL(in_ship_addr3_s,'X')  -- Added For SAGE Conversion
      AND    city                   =      in_ship_city_s
      AND    state                  =      in_ship_state_s
      AND    postal_code            =      in_ship_zip
      AND    sales_center           =      in_sales_ctr_s
--      AND    division               =      in_division_s --MTS 20129 Process bill to master for all divisions
      AND    rownum                 =      1;

      RETURN l_addr_id;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         l_addr_id := -9;
         RETURN (l_addr_id);
      WHEN OTHERS THEN
         swg_cust_debug('Y', 'Unexpected Error in Swgcnv_CB_Cust_stgload_Pkg.'||'check_cust_exists:  ' ||SQLERRM);
         g_error_flag_c := 'Y';
         RETURN 1;
   END check_ship_addr_exists;

   -----------------------------------------------------------------

   FUNCTION  get_bill_site_id
      (   in_cust_id_n             NUMBER
         ,in_bill_addr_id_n       NUMBER
         ,in_cust_num_s             VARCHAR2
         ,in_sales_ctr_s    IN    VARCHAR2
         ,in_division_s       IN    VARCHAR2
      )
   RETURN NUMBER
   IS

      l_billing_site_id  NUMBER;

   BEGIN

      SELECT  billto_site_id
      INTO    l_billing_site_id
      FROM    swgcnv_dd_customer_billto
      WHERE   customer_id          =     in_cust_id_n
      AND   bill_to_address_id   =     in_bill_addr_id_n
      AND   customer_number      =     in_cust_num_s
      --AND BILLING_SITE_ID =     in_bill_site_id_n
--      AND     sales_center         =     in_sales_ctr_s  --MTS 20129 Process bill to master for all divisions
--      AND     division             =     in_division_s  --MTS 20129 Process bill to master for all divisions
      AND     rownum               =     1;

      RETURN (l_billing_site_id);

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         --g_error_flag_c := 'Y';
         swg_cust_debug('Y', 'No data found for Swgcnv_CB_Cust_stgload_Pkg.'||'get_bill_site_id :  ' ||SQLERRM);
         RETURN (-99);
      WHEN OTHERS THEN
         swg_cust_debug('Y', 'Unexpected Error in Swgcnv_CB_Cust_stgload_Pkg.'||'get_bill_site_id :  ' ||SQLERRM);
         g_error_flag_c := 'Y';
         RETURN (-99);
   END get_bill_site_id;

   -----------------------------------------------------------------

   FUNCTION get_ship_to_site_id
      (   in_cust_id_n         NUMBER
         ,in_ship_addr_id_n NUMBER
         ,in_bill_site_id_n NUMBER
         ,in_cust_num_s         VARCHAR2
         ,in_sales_ctr_s    IN VARCHAR2
         ,in_division_s    IN VARCHAR2
      )
   RETURN NUMBER
   IS

      l_ship_site_id  NUMBER;

   BEGIN

      SELECT SHIPTO_SITE_ID
      INTO   l_ship_site_id
      FROM   swgcnv_dd_customer_shipto
      WHERE  customer_id          =    in_cust_id_n
      AND  ship_to_address_id   =    in_ship_addr_id_n
      AND  customer_number     =    in_cust_num_s
      AND  billing_site_id      =    in_bill_site_id_n
      AND    sales_center         =    in_sales_ctr_s
--      AND    division             =    in_division_s  --MTS 20129 Process bill to master for all divisions
      AND    rownum               =    1;

      RETURN (l_ship_site_id);

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         --g_error_flag_c := 'Y';
         swg_cust_debug('Y', 'No data found for Swgcnv_CB_Cust_stgload_Pkg.'||'get_ship_to_site_id :  ' ||SQLERRM);
         RETURN (-99);
      WHEN OTHERS THEN
         swg_cust_debug('Y', 'Unexpected Error in Swgcnv_CB_Cust_stgload_Pkg.'||'get_ship_to_site_id :  ' ||SQLERRM);
         g_error_flag_c := 'Y';
         RETURN (-99);
   END get_ship_to_site_id;

  /* -----------------------------------------------------------------

   --
   --  added by bala palani for WTRFLX2 conversion, to fetch new code value for the cycle day table
   --


   FUNCTION swgcnv_rtsrvday_code (  p_legacy_system VARCHAR2
                                   ,p_old_code     VARCHAR2
                                )
   RETURN VARCHAR2
   IS

      l_new_code_s      VARCHAR2(20);

   BEGIN
      SELECT new_code
      INTO   l_new_code_s
      FROM   swgcnv_map
      WHERE  system_code   =  p_legacy_system
      AND    type_code     = 'RTSRVDAY'
      AND    old_code      =  p_old_code;

      RETURN NVL(l_new_code_s,'NOT MAPPED');

   EXCEPTION

      WHEN OTHERS THEN

         RETURN 'NOT MAPPED';

   END swgcnv_rtsrvday_code;


    ----------------------------------------------------------------- */

   FUNCTION check_cust_contact_exists
      (   in_customer_id_n IN NUMBER
         ,in_address_id_n IN NUMBER
         ,in_area_code_s IN VARCHAR2
         ,in_number_s IN VARCHAR2
         ,in_email_address_s  IN VARCHAR2 -- Added For Mayberry
      )
   RETURN BOOLEAN
   IS

      l_phone_exists_s VARCHAR2(1);

   BEGIN

      IF ( in_email_address_s IS NULL ) THEN -- Added For SAGE Acquisition

         SELECT 'Y'
         INTO   l_phone_exists_s
         FROM   swgcnv_dd_customer_contact
         WHERE  customer_id          =  in_customer_id_n
         AND    address_id           =  in_address_id_n
         AND    telephone_area_code  =  in_area_code_s
         AND  telephone            =  in_number_s
         AND    telephone_type       =  'PHONE'
         AND    rownum               =  1;

         swg_cust_debug('Y', 'Check_cust_contact_exists: Phone Contact already exists for customer id/address_id./item/serialnum/sc: ' ||in_customer_id_n
                         ||'/'||in_address_id_n||'/'||in_area_code_s||'/'||in_number_s);
         RETURN (TRUE);

      ELSE

         SELECT 'Y'
         INTO   l_phone_exists_s
         FROM   swgcnv_dd_customer_contact
         WHERE  customer_id          =  in_customer_id_n
         AND    address_id           =  in_address_id_n
         AND    email_address        =  in_email_address_s
         AND    telephone_type       =  'EMAIL'
         AND    rownum               =  1;

         swg_cust_debug('Y', 'Check_cust_contact_exists: Email Contact already exists for customer id/address_id./item/serialnum/sc: ' ||in_customer_id_n
                         ||'/'||in_address_id_n||'/'||in_area_code_s||'/'||in_number_s);
         RETURN (TRUE);

      END IF;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN (FALSE);
      WHEN OTHERS THEN
         swg_cust_debug('Y', 'Unexpected Error in Swgcnv_CB_Cust_stgload_Pkg.'||'check_cust_contact_exists:  ' ||SQLERRM);
         g_error_flag_c := 'Y';
         RETURN (TRUE);
   END check_cust_contact_exists;

   -----------------------------------------------------------------

   FUNCTION check_contract_exists
      (   in_cust_num_s      IN    VARCHAR2
         ,in_ship_site_id_s  IN    VARCHAR2
         ,in_item_code_s     IN    VARCHAR2
         ,in_serial_num_s    IN     VARCHAR2
         ,in_sales_ctr_s     IN    VARCHAR2
         ,in_division_s      IN    VARCHAR2
      )
   RETURN BOOLEAN
   IS
      l_exists_c VARCHAR2(1);
   BEGIN

      SELECT 'Y'
      INTO   l_exists_c
      FROM   swgcnv_dd_eqpmnt_interface
      WHERE  customer_number           =   in_cust_num_s
      AND    DELIVERY_LOCATION_NUMBER  =   in_ship_site_id_s
      AND    item_code                 =   in_item_code_s
      AND    serial_number             =   in_serial_num_s
      AND    sales_center              =   in_sales_ctr_s
--      AND    division                  =   in_division_s   --MTS 20129 Process bill to master for all divisions
      AND    rownum                    =   1;

      swg_cust_debug('Y', 'Check_contract_exists: Contract already exists for cust num/del.loc./item/serialnum/sc: ' ||in_cust_num_s
                         ||'/'||in_ship_site_id_s||'/'||in_item_code_s||'/'||in_serial_num_s||'/'||in_sales_ctr_s);
      RETURN (TRUE);

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN(FALSE);
      WHEN OTHERS THEN
         swg_cust_debug('Y', 'Unexpected Error in Swgcnv_CB_Cust_stgload_Pkg.'||'check_contract_exists:  ' ||SQLERRM);
         g_error_flag_c := 'Y';
         RETURN (TRUE);

   END check_contract_exists;

   -----------------------------------------------------------------
   -- The following function can be commented out if the check_contract_exists, SIGNED_DELVIERY_RECEIPT (Customers)) col do not need to use it
   -- acutally needed for billing_interval
   -- Also, if used, need to IN OUT the new/old subcode?

   FUNCTION get_mapped_value
      (   in_system_name_s     IN    VARCHAR2
         ,in_entity_s        IN    VARCHAR2
         ,in_old_entity_value_s IN    VARCHAR2
      )
   RETURN VARCHAR2
   IS

      l_new_code_s  VARCHAR2(110);
      l_new_sub_code_s VARCHAR2(110);

   BEGIN

      swgcnv_conversion_pkg.swg_map_lookup
         (   in_system_name_s
            ,in_entity_s
            ,UPPER(in_old_entity_value_s)
            ,NULL
            ,l_new_code_s
            ,l_new_sub_code_s
            ,NULL
         );

      RETURN  l_new_code_s;

   EXCEPTION
      WHEN OTHERS THEN
         RETURN(NULL);
   END;

   -------------------------------------------------------------------

   FUNCTION get_mapped_value
      (   in_system_name_s     IN    VARCHAR2
         ,in_entity_s        IN    VARCHAR2
         ,in_old_entity_value_s IN    VARCHAR2
         ,in_sales_center_s      IN    VARCHAR2
      )
   RETURN VARCHAR2
   IS

      l_new_code_s  VARCHAR2(110);
      l_new_sub_code_s VARCHAR2(110);

   BEGIN

      swgcnv_conversion_pkg.swg_map_lookup
         (   in_system_name_s
            ,in_entity_s
            ,UPPER(in_old_entity_value_s)
            ,UPPER(in_sales_center_s)
            ,l_new_code_s
            ,l_new_sub_code_s
            ,NULL
         );

      RETURN  l_new_code_s;

   EXCEPTION
      WHEN OTHERS THEN
         RETURN(NULL);
   END;
   
   -----------------------------------------------------------------
   --
   -- Function added by Bala Palani as per WO : 19982
   -- 
   
   FUNCTION swgcnv_get_restrctd_prclst
                                   ( p_legacy_system  VARCHAR2
                                   , p_leg_cust_nbr   VARCHAR2  )
   RETURN VARCHAR2
   IS
   
      l_res_prclst_id_s      VARCHAR2(200);
    
   BEGIN
       SELECT   mp.new_code
         INTO   l_res_prclst_id_s
         FROM   swgcnv_map                      mp,
                 swgcnv_dd_cb_prestaging_cust    cust
        WHERE   mp.old_code   =   cust.price_list
          AND   system_code =  p_legacy_system     -- 'IBM01'
          AND   type_code   = 'PRCLIST'
          AND   new_code <> 'NOT MAPPED'
          AND   cust.customer_number = p_leg_cust_nbr   --'07225652Z'
            ;
    
      RETURN l_res_prclst_id_s;
   
   EXCEPTION
          WHEN NO_DATA_FOUND THEN
          RETURN NULL;
   END   swgcnv_get_restrctd_prclst; 

   -----------------------------------------------------------------

   PROCEDURE   insert_sub_cust
      (   ou_errbuf2_s         OUT     VARCHAR2
         ,ou_errcode2_n        OUT     NUMBER
         ,in_sales_center_s    IN      VARCHAR2    DEFAULT     'SAC'
         ,in_system_name_s     IN      VARCHAR2    DEFAULT     'ARS01'
         ,in_mode_c            IN      VARCHAR2    DEFAULT      G_SWG_CONCURRENT
         ,in_debug_flag_c      IN      VARCHAR2    DEFAULT      G_SWG_NODEBUG
      )
   IS

      CURSOR  cur_sub_cust_data(in_sales_center IN VARCHAR2)
      IS
      SELECT  *
      FROM    swgcnv_dd_cb_prestaging_cust
      WHERE   processed_flag     =  'N'
      AND     bill_to_master     IS NOT NULL
      --AND     record_num between 1 and 100
      AND     sales_center       =  NVL(in_sales_center,sales_center)
      ORDER BY record_num;

      l_sub_cust_rec          cur_sub_cust_data%ROWTYPE;

      l_system_name_s         VARCHAR2(20);
      l_sales_center_s        VARCHAR2(3);
      l_debug_c               VARCHAR2(1);
      l_mode_c                VARCHAR2(1);
      l_error_message_s       VARCHAR2(2000);
      l_msg_data_s            VARCHAR2(2000);
      l_mast_cust_name_s      VARCHAR2(50);
      l_division_s            VARCHAR2(20);
      
      l_state_s               VARCHAR2(20);   -- added by Bala Palani
      l_new_code_s            VARCHAR2(20);   -- added by Bala Palani
      l_new_sub_code_s        VARCHAR2(50);   -- added by Bala Palani
      l_error_mesg_s          VARCHAR2(50);   -- added by Bala Palani

      l_cust_recs_read_n      NUMBER;
      l_cust_id               NUMBER;
      l_cust_id_seq           NUMBER;
      l_addr_id               NUMBER;
      l_addr_id_seq           NUMBER;
      l_bill_site_id          NUMBER;
      l_bill_site_id_seq      NUMBER;
      l_ship_addr_id          NUMBER;
      l_ship_addr_id_seq      NUMBER;
      l_ship_site_id          NUMBER;
      l_ship_site_id_seq      NUMBER;

      l_return_status_s       VARCHAR2(10);

      l_message_s             VARCHAR2(2000);

      l_start_time_d          DATE;
      l_end_time_d            DATE;

      ERROR_ENCOUNTERED       EXCEPTION;
      INIT_ERROR              EXCEPTION;

      l_cust_acct_id_n        NUMBER;
      l_obj_version_num_n     NUMBER;
      l_msg_count_n           NUMBER;
      l_legacy_cust_num_n     NUMBER   :=    0;

      l_rtsrvdy_s     VARCHAR2(10);
	  
	   l_first_name_s     VARCHAR2(150);   -- Added by Bala Palani EB-670
	   l_last_name_s      VARCHAR2(150);    -- Added by Bala Palani EB-670

      CURSOR  cur_upd_col_1
         (   in_sales_center_s IN VARCHAR2
            ,in_division_s     IN VARCHAR2
         )
      IS
      SELECT customer_id
      FROM   swgcnv_dd_customer_interface
      WHERE  sales_center    =     in_sales_center_s
--      AND    division        =     in_division_s       --MTS 20129 Process bill to master for all divisions
      ORDER BY customer_id;

      l_no_of_shiptos     NUMBER;
      l_sc_s              VARCHAR2(3);
      l_def_route_day_s   VARCHAR2(10);
      l_delivery_freq_s   VARCHAR2(10);
      l_person_flag_c     VARCHAR2(1);

   BEGIN

      -- CALL insert_sub_cust;
      -- Open cursor, check if parent customer exists in interface table;
      -- If yes then
      --     check if address exists,else create
      --       create ship to for this record as an additional ship to for the parent customer,
      --       with customer name in addressee field, if different from that of the parent customer

      --       create contacts if needed
      --       create contracts
      -- Else
      --  Raise error
      -- End IF;

      ou_errbuf2_s        :=      NULL;
      ou_errcode2_n       :=      0;

      l_start_time_d      :=      SYSDATE;
      l_system_name_s     :=      in_system_name_s;
      l_sales_center_s    :=      in_sales_center_s;
      l_debug_c           :=      in_debug_flag_c;
      l_mode_c            :=      in_mode_c;

      l_division_s   := Swg_Hierarchy_Pkg.Get_Parent
                           (   'LOCATION'
                              , l_sales_center_s
                              , NULL
                              ,'DIVISION'
                              , SYSDATE
                              ,'ID'
                              ,'HTL'
                           );

      IF l_division_s IS NULL THEN

         l_error_message_s := 'Division is NULL in sub-cust';
         swg_cust_debug( l_debug_c,l_error_message_s);
         RAISE INIT_ERROR;

      END IF;

      l_cust_recs_read_n  := 0;

   OPEN  cur_sub_cust_data(l_sales_center_s);
   LOOP
      --SAVEPOINT at_subcust_first;
      --g_error_flag_c := 'N';
      BEGIN

         FETCH cur_sub_cust_data INTO l_sub_cust_rec;
         EXIT WHEN cur_sub_cust_data%NOTFOUND;

         SAVEPOINT at_subcust_first;
         g_error_flag_c := 'N';

         l_cust_recs_read_n   := l_cust_recs_read_n + 1;

         swg_cust_debug(l_debug_c,'Processing record number: '||to_char(l_sub_cust_rec.record_num));

         -- check if master customer already exists in staging table else raise error

         l_mast_cust_name_s := NULL;

         BEGIN

            SELECT DISTINCT sales_center
            INTO   l_sc_s
            FROM   swgcnv_dd_cb_prestaging_cust
            WHERE  customer_number  =  l_sub_cust_rec.bill_to_master;

         EXCEPTION
            WHEN OTHERS THEN
               l_sc_s := NULL;
         END;

         l_cust_id   := check_mast_cust_exists
                           (   l_sub_cust_rec.bill_to_master
                              ,nvl(l_sc_s,l_sales_center_s)
                              ,l_division_s
                              ,l_mast_cust_name_s
                           ) ;

         IF (l_cust_id = -9) THEN

            l_msg_data_s := 'Rec/Master Cust num does not exist in staging table,cannot create sub-customer record: '||to_char(l_sub_cust_rec.record_num)||'/'||l_sub_cust_rec.bill_to_master;
            swg_cust_debug(l_debug_c,l_msg_data_s);

            RAISE ERROR_ENCOUNTERED;

         ELSIF (l_cust_id = 1) THEN

            l_msg_data_s := 'Unexpected Error in Swgcnv_CB_Cust_stgload_Pkg.check_mast_cust_exists for Rec/Master Customer num: '||to_char(l_sub_cust_rec.record_num)||'/'||l_sub_cust_rec.bill_to_master||': '||SQLERRM;
            swg_cust_debug('Y',l_msg_data_s);

            RAISE ERROR_ENCOUNTERED;

         ELSE

            l_msg_data_s := 'Rec/Master Customer num exists in staging table: '||to_char(l_sub_cust_rec.record_num)||'/'||l_sub_cust_rec.bill_to_master;
            swg_cust_debug(l_debug_c,l_msg_data_s);

            l_addr_id   := get_master_cust_billto
                              (   l_cust_id
                                 ,nvl(l_sc_s,l_sales_center_s)
                                 ,l_division_s --'BV10'
                              );

            IF (l_addr_id = -9 OR l_addr_id = 1) THEN

               l_msg_data_s := 'No data found / Unexpected Error in Swgcnv_CB_Cust_stgload_Pkg.get_master_cust_billto for Rec/Master Customer num: '||to_char(l_sub_cust_rec.record_num)||'/'||l_sub_cust_rec.bill_to_master||': '||SQLERRM;
               swg_cust_debug('Y',l_msg_data_s);

               RAISE ERROR_ENCOUNTERED;

            END IF;


                        SELECT
                           CASE WHEN new_code like 'DD RESI%' OR new_code like 'DD EMPLOYEE%' THEN
                                'Y'
                           ELSE 'N'
                           END CASE
                        INTO
                           l_person_flag_c
                        FROM
                           swgcnv_map
                        WHERE
                           system_code = in_system_name_s
                        AND type_code = 'CUSTPROFL'
                        AND old_code = l_sub_cust_rec.customer_type
                        AND ROWNUM = 1;

            l_bill_site_id := get_bill_site_id
                              (   l_cust_id
                                 ,l_addr_id
                                 ,l_sub_cust_rec.bill_to_master
                                 ,nvl(l_sc_s,l_sales_center_s)
                                 ,l_division_s
                              );

            IF (l_bill_site_id= -99 OR  g_error_flag_c = 'Y') THEN
               l_msg_data_s := 'No data found / Unexpected Error in Swgcnv_CB_Cust_stgload_Pkg.get_bill_site_id for Rec/Master Customer num: '||to_char(l_sub_cust_rec.record_num)||'/'||l_sub_cust_rec.bill_to_master||': '||SQLERRM;
               swg_cust_debug('Y',l_msg_data_s);

               RAISE ERROR_ENCOUNTERED;

            END IF;
			
			

            l_ship_addr_id := check_ship_addr_exists
                                 (   l_sub_cust_rec.bill_to_master
                                    ,l_sub_cust_rec.ship_to_address1
                                    ,l_sub_cust_rec.ship_to_address2
                                    ,l_sub_cust_rec.customer_name    -- Added For SAGE Conversion
                                    ,l_sub_cust_rec.ship_to_city
                                    ,l_sub_cust_rec.ship_to_state
                                    ,l_sub_cust_rec.ship_to_zip_code
                                    ,l_sales_center_s
                                    ,l_division_s
                                 ) ;

            swg_cust_debug('Y','Ship addr ID = '||to_char(l_ship_addr_id));

            IF l_ship_addr_id = -9 THEN

               SELECT SWGCNV.SWGCNV_CB_ADDR_ID_S.nextval
               INTO   l_ship_addr_id_seq
               FROM   dual;

               INSERT INTO SWGCNV_DD_ADDRESSES
                  (   ADDRESS_ID            --NUMBER(15)              NOT NULL,
                     ,CUSTOMER_ID           --NUMBER(15)              NOT NULL,
                     ,CUSTOMER_NUMBER       --VARCHAR2(10 BYTE)       NOT NULL,
                     ,ADDRESS1              --VARCHAR2(240 BYTE),
                     ,ADDRESS2              --VARCHAR2(240 BYTE),
                     ,ADDRESS3              --VARCHAR2(240 BYTE),
                     ,ADDRESS4              --VARCHAR2(240 BYTE),
                     ,CITY                  --VARCHAR2(60 BYTE),
                     ,STATE                 --VARCHAR2(60 BYTE),
                     ,PROVINCE              --VARCHAR2(60 BYTE),
                     ,COUNTY                --VARCHAR2(60 BYTE),
                     ,POSTAL_CODE           --VARCHAR2(60 BYTE),
                     ,COUNTRY               --VARCHAR2(60 BYTE)       NOT NULL,
                     ,LATITUDE              --VARCHAR2(150 BYTE),
                     ,LONGITUDE             --VARCHAR2(150 BYTE),
                     ,COMPLEX_TYPE          --VARCHAR2(150 BYTE),
                     ,VARIABLE_UNLOAD_TIME  --VARCHAR2(150 BYTE),
                     ,FIXED_UNLOAD_TIME     --VARCHAR2(150 BYTE),
                     ,DOCK_TYPE             --VARCHAR2(150 BYTE),
                     ,SALES_CENTER          --VARCHAR2(3 BYTE)        NOT NULL,
                     ,ADDR_CLEAN_UP_FLAG    --VARCHAR2(1 BYTE)        DEFAULT 'N',
                     ,DIVISION              --VARCHAR2(10 BYTE)       NOT NULL,
                     ,SEQ                   --NUMBER
                  )
               VALUES
                  (   l_ship_addr_id_seq
                     ,l_cust_id
                     ,l_sub_cust_rec.bill_to_master
                     ,l_sub_cust_rec.ship_to_address1
                     ,l_sub_cust_rec.ship_to_address2
                     ,l_sub_cust_rec.customer_name    -- Added For SAGE Acquisition
                     ,NULL
                     ,l_sub_cust_rec.ship_to_city
                     ,l_sub_cust_rec.ship_to_state
                     ,NULL
                     ,NULL
                     ,l_sub_cust_rec.ship_to_zip_code
                     ,'US'
                     ,NULL       -- lat. will be provided in a separate file
                     ,NULL       -- long. will be provided in a separate file
                     ,NULL
                     ,NULL
                     ,NULL
                     ,'ALL'
                     ,l_sales_center_s
                     ,'N'
                     ,l_division_s
                     ,NULL
                  );

                  --insert l_addr_id_seq for address_id column, l_cust_id for customer_id column

                  l_ship_addr_id := l_ship_addr_id_seq;

                  SELECT SWGCNV.SWGCNV_CB_SITE_ID_S.nextval
                  INTO   l_ship_site_id_seq
                  FROM   DUAL;

                  INSERT INTO SWGCNV_DD_CUSTOMER_SHIPTO
                     (   SHIPTO_SITE_ID               --NUMBER(15)       NOT NULL,
                        ,CUSTOMER_ID                  --NUMBER(15)       NOT NULL,
                        ,SHIP_TO_ADDRESS_ID           --NUMBER(15)       NOT NULL,
                        ,BILLING_SITE_ID              --NUMBER(15)       NOT NULL,
                        ,CUSTOMER_NUMBER              --VARCHAR2(10 BYTE) NOT NULL,
                        ,DELIVERY_LOCATION_NUMBER     --VARCHAR2(10 BYTE) NOT NULL,
                        ,CUSTOMER_TAX_CLASS           --VARCHAR2(150 BYTE),
                        ,PO_NUMBER                    --VARCHAR2(150 BYTE),
                        ,PO_EFFECTIVE_FROM_DATE       --VARCHAR2(150 BYTE),
                        ,PO_EFFECTIVE_TO_DATE         --VARCHAR2(150 BYTE),
                        ,PO_TOTAL_DOLLARS             --VARCHAR2(150 BYTE),
                        ,PO_TOTAL_UNITS               --VARCHAR2(150 BYTE),
                        ,CUSTOMER_REFERENCE_NUMBER    --VARCHAR2(150 BYTE),
                        ,TAX_EXEMPT_NUMBER            --VARCHAR2(150 BYTE),
                        ,TAX_EXEMPT_EXP_DATE          --VARCHAR2(150 BYTE),
                        ,TAX_EXEMPT_CERTIFICATE_RCVD  --VARCHAR2(150 BYTE),
                        ,SALES_CENTER                 --VARCHAR2(3 BYTE) NOT NULL,
                        ,DIVISION                     --VARCHAR2(50 BYTE) NOT NULL,
                        ,ROUTE_NUMBER                 --VARCHAR2(10 BYTE),
                        ,ROUTE_DELIVERY_FREQUENCY     --VARCHAR2(10 BYTE),
                        ,NEXT_REGULAR_DELIVER_DATE    --DATE,
                        ,DELIVERY_INSTRUCTIONS        --VARCHAR2(1000 BYTE),
                        ,ROUTE_MESSAGE                --VARCHAR2(240 BYTE),
                        ,COLLECTION_MESSAGE           --VARCHAR2(240 BYTE),
                        ,ADDRESSEE                    --VARCHAR2(100 BYTE),
                        ,FREQUENCY                    --VARCHAR2(10 BYTE),
                        ,CUSTOMER_START_DATE          --DATE,
                        ,SHIP_TO_START_DATE           --DATE,
                        ,SUPPRESS_PRICE_HH_TICKET     --VARCHAR2(1 BYTE),
                        ,RSR_OVERIDE_SUPPRESS_PRICE   --VARCHAR2(1 BYTE),
                        ,BOTTLE_INITIAL_INVENTORY     --VARCHAR2(3 BYTE),
                        ,RATE_SCHEDULE                --VARCHAR2(4 BYTE),
                        ,CHARGE_DEPOSIT               --VARCHAR2(1 BYTE),
                        ,PREFERRED_CUSTOMER_FLAG      --VARCHAR2(1 BYTE),
                        ,PENDING                      --VARCHAR2(1 BYTE),
                        ,BSC_FLAG                     --VARCHAR2(1 BYTE),
                        ,CREDIT_SCORE                 --VARCHAR2(4 BYTE),
                        ,TERM_FEE_AMOUNT              --NUMBER,
                        ,AGREEMENT_TERM               --VARCHAR2(30 BYTE),
                        ,BOTTLE_DEPOSIT_AMT           --NUMBER,
                        ,DELIVERY_TICKET_PRINT_FLAG   --VARCHAR2(1 BYTE),
                        ,TIER_PRICE_PROC_FLAG         --VARCHAR2(1 BYTE) DEFAULT 'N',
                        ,BOT_DEPOSIT_PROC_FLAG        --VARCHAR2(1 BYTE) DEFAULT 'N'
                        --,HOLD_REASON                --VARCHAR2(10),
                        ,WILL_CALL_FLAG             --VARCHAR2(1)      
                        ,SUB_CUST_NUMBER              --VARCHAR2(40)
                        ,PRICE_LIST_NAME                               -- Added by Bala Palani as per WO : 19982
                     )
                  VALUES
                     (   l_ship_site_id_seq
                        ,l_cust_id
                        ,l_ship_addr_id
                        ,l_bill_site_id
                        ,l_sub_cust_rec.bill_to_master
                        ,to_char(l_ship_site_id_seq)
                        --,DECODE(l_sub_cust_rec.sales_tax,'EX','EXEMPT','TAXABLE')  Removed  Decode Condition as per  EB-2058
                        ,l_sub_cust_rec.sales_tax
                        ,l_sub_cust_rec.SHIP_TO_PO_NUM
                        ,NULL
                        ,NULL
                        ,NULL
                        ,NULL
                        ,l_sub_cust_rec.ship_to_reference_num  --EB-1877
                        --,DECODE(l_sub_cust_rec.sales_tax,'EXEMPT','ON FILE',NULL)  --SGB  Removed  Decode Condition as per  EB-2058  AND Added new field as per EB-2058
                        ,l_sub_cust_rec.TAX_EXEMPT_NUM
                        ,NULL
                       -- ,DECODE(l_sub_cust_rec.sales_tax,'EXEMPT','Y','N')    --SGB       Removed  Decode Condition as per  EB-2058  AND Added new field as per EB-2058
                        ,l_sub_cust_rec.TAX_CERT_RECVD
                        ,l_sales_center_s
                        ,l_division_s                   --'BV10'
                        ,get_mapped_value(l_system_name_s,'ROUTES',l_sub_cust_rec.route_number,l_sales_center_s)
                        ,l_sub_cust_rec.delivery_frequency -- Added PU 4/24/2008
                        ,NULL       -- NEXT_REGULAR_DELIVER_DATE   
                        ,NULL       -- DELIVERY_INSTRUCTIONS       
                        ,NULL
                        ,l_sub_cust_rec.ADDRESSEE    --,NULL  Addedd by MAKRAM for EB-1289
                        ,decode(l_sub_cust_rec.customer_name,l_mast_cust_name_s,NULL,l_sub_cust_rec.customer_name)
                        ,l_sub_cust_rec.delivery_frequency -- Added PU 4/24/2008
                        ,l_sub_cust_rec.CUST_START_DATE
                        ,l_sub_cust_rec.CUST_START_DATE
                        ,'Y'            -- SUPPRESS_PRICE_HH_TICKET
                        ,'Y'            --  RSR_OVERIDE_SUPPRESS_PRICE
                        ,NULL           --  BOTTLE_INITIAL_INVENTORY
                        ,NULL           --  RATE_SCHEDULE
                        ,'Y'            -- Default to Y for all Ship Tos  -- CHARGE_DEPOSIT
                        ,'N'            -- PREFERRED_CUSTOMER_FLAG
                        ,NULL           -- PENDING
                        ,l_sub_cust_rec.esc_fee            -- ESC_FLAG  --EB-1877
                        ,NULL           -- CREDIT_SCORE -- 01/24/07:  Val will map it
                        ,0              -- TERM_FEE_AMOUNT -- $100 by default (Agreement - Term Fee column) -- update later?
                        ,'GFAGR'        -- AGREEMENT_TERM -- Default from the Agreement code (Agreement - Term Code column) -- update later?
                        ,NULL           -- BOTTLE_DEPOSIT_AMT -- If the amount in this field is different that what is on the price list then
                                                           -- create a special price record to ensure the customer is charged correctly -- ?
                        ,l_sub_cust_rec.print_delivery_tickets            -- DELIVERY_TICKET_PRINT_FLAG  --EB-1877
                        ,'N'            -- TIER_PRICE_PROC_FLAG
                        ,'N'            -- BOT_DEPOSIT_PROC_FLAG
                        ,l_sub_cust_rec.ON_REQUEST_FLAG       -- re-activated this columns to fetch will call flag data from the prestaging cust tab by Bala Palani as per WO 19982
                        ,l_sub_cust_rec.customer_number
                        ,swgcnv_get_restrctd_prclst(l_system_name_s, l_sub_cust_rec.customer_number)  -- Added by Bala Palani as per WO : 19982
                     );

                  l_ship_site_id      :=      l_ship_site_id_seq;
				  
				  
				IF l_person_flag_c != 'Y' THEN
					 
						  l_first_name_s   :=   TRIM(NVL(l_sub_cust_rec.primary_contact_first_name, 'ACCOUNTS'));   -- Added by Bala Palani EB-670        
						  l_last_name_s    :=   TRIM(NVL(l_sub_cust_rec.primary_contact_last_name, 'PAYABLE'));
					 
				ELSE
				    
					 l_first_name_s   :=   TRIM(NVL(l_sub_cust_rec.primary_contact_first_name, TRIM(SUBSTR(l_sub_cust_rec.customer_name,INSTR(l_sub_cust_rec.customer_name,';')+1))));      -- Added by Bala Palani EB-670        
					 l_last_name_s    :=   TRIM(NVL(l_sub_cust_rec.primary_contact_last_name, TRIM(SUBSTR(l_sub_cust_rec.customer_name,1,INSTR(l_sub_cust_rec.customer_name,';')-1))));	 
					 
				END IF;


                  -- Contact Info

                  INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                     (   CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                        ,ADDRESS_ID           --NUMBER(15),
                        ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                        ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                        ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                        ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                        ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                        ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                        ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                     )
                  VALUES
                     (   l_cust_id
                        ,l_ship_addr_id
                        ,l_first_name_s
                        ,l_last_name_s
                        ,NVL(substr(l_sub_cust_rec.primary_phone,1,3), '111')        -- Added by Bala Palani EB-1156
                        ,NVL(substr(l_sub_cust_rec.primary_phone,4,10),'1111111')    -- Added by Bala Palani EB-1156
                        ,substr(l_sub_cust_rec.primary_phone,11)
                        ,'PHONE'
                        ,NULL
                     );

                      ---EB-1877
              IF ( l_sub_cust_rec.primary_bus_phone IS NOT NULL )  THEN
              
              INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_first_name_s 
                                 ,l_last_name_s  
                                 ,NVL(substr(l_sub_cust_rec.primary_bus_phone,1,3), '111')                 
                                 ,NVL(substr(l_sub_cust_rec.primary_bus_phone,4,10),'1111111')              
                                 ,substr(l_sub_cust_rec.primary_bus_phone,11)
                                 ,'PHONE'
                                 ,NULL
                                );
              
              END IF;
              
             IF ( l_sub_cust_rec.primary_cell_phone IS NOT NULL )  THEN
              
              INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_first_name_s 
                                 ,l_last_name_s 
                                 ,NVL(substr(l_sub_cust_rec.primary_cell_phone,1,3), '111')                
                                 ,NVL(substr(l_sub_cust_rec.primary_cell_phone,4,10),'1111111')              
                                 ,substr(l_sub_cust_rec.primary_cell_phone,11)
                                 ,'PHONE'
                                 ,NULL
                                );
              
              END IF;
              --EB-1877

                  -- Added For SAGE Conversion
                  IF ( l_sub_cust_rec.primary_email_address IS NOT NULL ) THEN

                     INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                        (   CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                           ,ADDRESS_ID           --NUMBER(15),
                           ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                           ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                           ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                           ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                           ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                           ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                           ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                           ,PRIMARY_EMAIL_FLAG
                        )
                     VALUES
                        (   l_cust_id
                           ,l_ship_addr_id
                           ,l_first_name_s
                           ,l_last_name_s
                           ,NVL(SUBSTR(l_sub_cust_rec.primary_phone,1,3), '111')       -- Added by Bala Palani EB-1156
                           ,NVL(SUBSTR(l_sub_cust_rec.primary_phone,4,10),'1111111')   -- Added by Bala Palani EB-1156
                           ,substr(l_sub_cust_rec.primary_phone,11)
                           ,'EMAIL'
                           ,l_sub_cust_rec.primary_email_address
                           ,'Y'
                        );

                  END IF;
                  -- Added For SAGE Conversion
                  
                                              
               --EB-1877 Contact2 and Contact3----
               
               IF (l_sub_cust_rec.CONTACT2_LAST_NAME) IS NOT NULL THEN
               
                 IF  (l_sub_cust_rec.Phone2)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_sub_cust_rec.contact2_first_name  
                                 ,l_sub_cust_rec.contact2_last_name  
                                 ,NVL(substr(l_sub_cust_rec.Phone2,1,3), '111')                  
                                 ,NVL(substr(l_sub_cust_rec.Phone2,4,10),'1111111')              
                                 ,substr(l_sub_cust_rec.Phone2,11)
                                 ,'PHONE'
                                 ,NULL
                                );
                 
                  END IF;
                 
                 IF  (l_sub_cust_rec.bus_phone2)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_sub_cust_rec.contact2_first_name  
                                 ,l_sub_cust_rec.contact2_last_name  
                                 ,NVL(substr(l_sub_cust_rec.bus_phone2,1,3), '111')                  
                                 ,NVL(substr(l_sub_cust_rec.bus_phone2,4,10),'1111111')              
                                 ,substr(l_sub_cust_rec.bus_phone2,11)
                                 ,'PHONE'
                                 ,NULL
                                );
               
                 
                 END IF; 
                 
                 IF  (l_sub_cust_rec.cell_phone2)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_sub_cust_rec.contact2_first_name  
                                 ,l_sub_cust_rec.contact2_last_name 
                                 ,NVL(substr(l_sub_cust_rec.cell_phone2,1,3), '111')                  
                                 ,NVL(substr(l_sub_cust_rec.cell_phone2,4,10),'1111111')              
                                 ,substr(l_sub_cust_rec.cell_phone2,11)
                                 ,'PHONE'
                                 ,NULL
                                );
                 
                 END IF;
                 
                 IF  (l_sub_cust_rec.email_address2)  IS NOT NULL THEN
                 
                  INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                     (   CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                        ,ADDRESS_ID           --NUMBER(15),
                        ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                        ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                        ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                        ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                        ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                        ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                        ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                     )
                  VALUES
                     (   l_cust_id
                        ,l_ship_addr_id
                        ,l_sub_cust_rec.contact2_first_name  
                        ,l_sub_cust_rec.contact2_last_name  
                        ,NVL(SUBSTR(l_sub_cust_rec.phone2,1,3), '111')          
                        ,NVL(SUBSTR(l_sub_cust_rec.phone2,4,10),'1111111')     
                        ,substr(l_sub_cust_rec.phone2,11)
                        ,'EMAIL'
                        ,l_sub_cust_rec.email_address2
                     );
                 
                 END IF;
               
               
               END IF;
               
               
               IF (l_sub_cust_rec.CONTACT3_LAST_NAME) IS NOT NULL THEN
               
                 IF  (l_sub_cust_rec.Phone3)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_sub_cust_rec.contact3_first_name  
                                 ,l_sub_cust_rec.contact3_last_name  
                                 ,NVL(substr(l_sub_cust_rec.Phone3,1,3), '111')                  
                                 ,NVL(substr(l_sub_cust_rec.Phone3,4,10),'1111111')              
                                 ,substr(l_sub_cust_rec.Phone3,11)
                                 ,'PHONE'
                                 ,NULL
                                );
                 
                  END IF;
                 
                 IF  (l_sub_cust_rec.bus_phone3)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_sub_cust_rec.contact3_first_name  
                                 ,l_sub_cust_rec.contact3_last_name  
                                 ,NVL(substr(l_sub_cust_rec.bus_phone3,1,3), '111')                  
                                 ,NVL(substr(l_sub_cust_rec.bus_phone3,4,10),'1111111')              
                                 ,substr(l_sub_cust_rec.bus_phone3,11)
                                 ,'PHONE'
                                 ,NULL
                                );
               
                 
                 END IF; 
                 
                 IF  (l_sub_cust_rec.cell_phone3)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_sub_cust_rec.contact3_first_name  
                                 ,l_sub_cust_rec.contact3_last_name 
                                 ,NVL(substr(l_sub_cust_rec.cell_phone3,1,3), '111')                  
                                 ,NVL(substr(l_sub_cust_rec.cell_phone3,4,10),'1111111')              
                                 ,substr(l_sub_cust_rec.cell_phone3,11)
                                 ,'PHONE'
                                 ,NULL
                                );
                 
                 END IF;
                 
                 IF  (l_sub_cust_rec.email_address3)  IS NOT NULL THEN
                 
                  INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                     (   CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                        ,ADDRESS_ID           --NUMBER(15),
                        ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                        ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                        ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                        ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                        ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                        ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                        ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                     )
                  VALUES
                     (   l_cust_id
                        ,l_ship_addr_id
                        ,l_sub_cust_rec.contact3_first_name  
                        ,l_sub_cust_rec.contact3_last_name  
                        ,NVL(SUBSTR(l_sub_cust_rec.phone3,1,3), '111')          
                        ,NVL(SUBSTR(l_sub_cust_rec.phone3,4,10),'1111111')     
                        ,substr(l_sub_cust_rec.phone3,11)
                        ,'EMAIL'
                        ,l_sub_cust_rec.email_address3
                     );
                 
                 END IF;
               
               END IF;
               
               --EB-1877 Contact2 and Contact3----

                  -- also enter shipcycle days
                  l_delivery_freq_s   :=  l_sub_cust_rec.delivery_frequency;

                  swgcnv_conversion_pkg.swg_map_lookup
                                          (p_swg_system_code      => l_system_name_s   -- main_rec.system_code
                                          ,p_swg_type_code        => 'RTSRVDAY'
                                          ,p_swg_old_code         => LTRIM(RTRIM(l_sub_cust_rec.route_day))
                                          ,p_swg_old_sub_code     => l_state_s
                                          ,r_swg_new_code         => l_new_code_s
                                          ,r_swg_new_sub_code     => l_new_sub_code_s
                                          ,p_txn_date             => NULL);

                 IF l_new_code_s IS NULL
                 THEN
                    l_error_message_s    :=    'Cycle day not found in Map table: '||LTRIM(RTRIM(l_sub_cust_rec.route_day));
                    RAISE ERROR_ENCOUNTERED;
                 END IF;
             
             
               INSERT INTO SWGCNV_DD_CYCLEDAYS
                    (    CUSTOMER_ID           --NUMBER(15),
                        ,SHIPPING_SITE_ID      --NUMBER(15),
                        ,ROUTE_SERVICE_DAY     --VARCHAR2(2 BYTE),
                        ,ROUTE_SEQUENCE        --NUMBER(15),
                        ,CYCLE_DAY             --VARCHAR2(2 BYTE),
                        ,DRIVING_INSTRUCTIONS  --VARCHAR2(2000 BYTE)
                    )
               VALUES
                    (    l_cust_id
                        ,l_ship_site_id
                        ,l_new_code_s
                        ,to_number(l_sub_cust_rec.route_seq)
                        ,l_new_code_s
                        ,NULL
                    );


           
           if nvl(l_delivery_freq_s,'2') = '0' then

              INSERT INTO SWGCNV_DD_CYCLEDAYS
                    (   CUSTOMER_ID           --NUMBER(15),
                       ,SHIPPING_SITE_ID      --NUMBER(15),
                       ,ROUTE_SERVICE_DAY     --VARCHAR2(2 BYTE),
                       ,ROUTE_SEQUENCE        --NUMBER(15),
                       ,CYCLE_DAY             --VARCHAR2(2 BYTE),
                       ,DRIVING_INSTRUCTIONS  --VARCHAR2(2000 BYTE)
                    )
              VALUES
                    (   l_cust_id
                       ,l_ship_site_id
                       ,l_new_code_s
                       ,to_number(l_sub_cust_rec.route_seq)
                       ,l_new_code_s
                       ,NULL
                    );

             END IF;

           ELSE
             IF g_error_flag_c != 'Y' THEN
                 l_msg_data_s := 'Rec/Customer/Cust num/ship addr,shipto_loc,shp_cycle_days,contacts already exists in staging table: '||to_char(l_sub_cust_rec.record_num)||'/'||l_mast_cust_name_s||'/'|| l_sub_cust_rec.bill_to_master;
                 dbms_output.put_line(l_msg_data_s);
                --Fnd_File.Put_Line(Fnd_File.LOG,l_msg_data_s);
                 swg_cust_debug(l_debug_c,l_msg_data_s);
                swg_cust_debug(l_debug_c,'Cust_id= '||to_char(l_cust_id)||'/ Ship Addr Id = '||to_char(l_ship_addr_id)||'/ Bill site id= '||to_char(l_bill_site_id)||'/ Customer number= '||l_sub_cust_rec.bill_to_master||'Sales/center/division ='||l_sales_center_s||'/'||l_division_s);

            -- VG 8/7/2007 SAVKC INSERT IF CUSTOMER_CONTACT NOT EXISTS
            -- check if cust contact exists.

            IF l_sub_cust_rec.primary_phone is not null then

               IF NOT check_cust_contact_exists( l_cust_id
                                                ,l_ship_addr_id
                                                ,substr(l_sub_cust_rec.primary_phone,1,3)
                                                ,nvl(substr(l_sub_cust_rec.primary_phone,4),'NONE')
                                                ,NULL
                                                )  THEN
                    dbms_output.put_line('Before Phone contract insert');

                    INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                           ( CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                            ,ADDRESS_ID           --NUMBER(15),
                            ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                            ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                            ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                            ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                            ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                            ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                            ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                           )
                    VALUES
                           ( l_cust_id
                            ,l_addr_id
                            ,l_first_name_s      -- Added by Bala Palani EB-670
                            ,l_last_name_s
                            ,NVL(substr(l_sub_cust_rec.primary_phone,1,3), '111')        -- Added by Bala Palani EB-1156
                            ,NVL(substr(l_sub_cust_rec.primary_phone,4,10),'1111111')    -- Added by Bala Palani EB-1156
                            ,substr(l_sub_cust_rec.primary_phone,11)
                            ,'PHONE'
                            ,NULL
                           );

                        dbms_output.put_line('After ADDITIONAL cust contact insert');
                        swg_cust_debug('Y','After ADDITIONAL cust contact insert');
                        
               END IF; -- end if check_cust_contact_exists

            END IF; -- end if l_sub_cust_rec.phone is null

            -- Added For SAGE Acquisition
            IF l_sub_cust_rec.primary_email_address is not null then

               IF NOT check_cust_contact_exists( l_cust_id
                                                ,l_ship_addr_id
                                                ,NULL
                                                ,NULL
                                                ,l_sub_cust_rec.primary_email_address
                                                )  THEN
                    dbms_output.put_line('Before Email contract insert');

                    INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                           ( CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                            ,ADDRESS_ID           --NUMBER(15),
                            ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                            ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                            ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                            ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                            ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                            ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                            ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                            ,PRIMARY_EMAIL_FLAG
                           )
                    VALUES
                           ( l_cust_id
                            ,l_addr_id
                            ,l_first_name_s  -- Added by Bala Palani EB-670
                            ,l_last_name_s
                            ,NVL(SUBSTR(l_sub_cust_rec.primary_phone,1,3), '111')        -- Added by Bala Palani EB-1156
                            ,NVL(SUBSTR(l_sub_cust_rec.primary_phone,4,10),'1111111')    -- Added by Bala Palani EB-1156
                            ,substr(l_sub_cust_rec.primary_phone,11)
                            ,'EMAIL'
                            ,l_sub_cust_rec.primary_email_address
                            ,'Y'
                           );
                        dbms_output.put_line('After ADDITIONAL cust contact insert');
                        swg_cust_debug('Y','After ADDITIONAL cust contact insert');
               END IF; -- end if check_cust_contact_exists

            END IF; -- end if l_sub_cust_rec.email_address is null
            -- Added For SAGE Acquisition

            -- VG 8/7/2007 SAVKC END INSERT IF CUSTOMER_CONTACT NOT EXISTS

            -- Actually, if ship_addr exists, ship_site_id may not exist so need to call insert_proc_ship_site if needed, may not apply here, but will apply to sub-cust ship to
            l_ship_site_id      :=      get_ship_to_site_id( l_cust_id
                                                            ,l_ship_addr_id
                                                            ,l_bill_site_id
                                                            ,l_sub_cust_rec.bill_to_master
                                                            --,nvl(l_sc_s,l_sales_center_s) --'SAC'
                                                            ,l_sales_center_s
                                                            ,l_division_s --'BV10'
                                                           );

            IF (g_error_flag_c = 'N' AND l_ship_site_id != -99) THEN

                UPDATE SWGCNV_DD_CUSTOMER_SHIPTO
                SET    SUB_CUST_NUMBER       =  decode(sub_cust_number,NULL,l_sub_cust_rec.customer_number,sub_cust_number||'-'||l_sub_cust_rec.customer_number)
                WHERE  SHIPTO_SITE_ID        =  l_ship_site_id
                AND    CUSTOMER_ID           =  l_cust_id
                AND    SHIP_TO_ADDRESS_ID    =  l_ship_addr_id
                AND    BILLING_SITE_ID       =  l_bill_site_id
                AND    CUSTOMER_NUMBER       =  l_sub_cust_rec.bill_to_master
                AND    SALES_CENTER          =  l_sales_center_s
                AND    DIVISION              =  l_division_s
                     -- Added by Ashok Krishnamurthy on 08/03/07 BEGIN
                AND    NOT EXISTS (SELECT 1
                                   FROM    SWGCNV_DD_CUSTOMER_SHIPTO
                                   WHERE   SUB_CUST_NUMBER      LIKE '%'||l_sub_cust_rec.customer_number||'%'
                                   AND     SHIPTO_SITE_ID        =   l_ship_site_id
                                   AND     CUSTOMER_ID           =   l_cust_id
                                   AND     SHIP_TO_ADDRESS_ID    =   l_ship_addr_id
                                   AND     BILLING_SITE_ID       =   l_bill_site_id
                                   AND     CUSTOMER_NUMBER       =   l_sub_cust_rec.bill_to_master
                                   AND     SALES_CENTER          =   l_sales_center_s
                                   AND     DIVISION              =   l_division_s
                                  )
                     -- Added by Ashok Krishnamurthy on 08/03/07 END
                     ;

            END IF;

            IF (g_error_flag_c = 'N' AND l_ship_site_id = -99) THEN

                SELECT SWGCNV.SWGCNV_CB_SITE_ID_S.nextval
                INTO   l_ship_site_id_seq
                FROM dual;

                INSERT INTO SWGCNV_DD_CUSTOMER_SHIPTO
                         (   SHIPTO_SITE_ID               --NUMBER(15)       NOT NULL,
                            ,CUSTOMER_ID                  --NUMBER(15)       NOT NULL,
                            ,SHIP_TO_ADDRESS_ID           --NUMBER(15)       NOT NULL,
                            ,BILLING_SITE_ID              --NUMBER(15)       NOT NULL,
                            ,CUSTOMER_NUMBER              --VARCHAR2(10 BYTE) NOT NULL,
                            ,DELIVERY_LOCATION_NUMBER     --VARCHAR2(10 BYTE) NOT NULL,
                            ,CUSTOMER_TAX_CLASS           --VARCHAR2(150 BYTE),
                            ,PO_NUMBER                    --VARCHAR2(150 BYTE),
                            ,PO_EFFECTIVE_FROM_DATE       --VARCHAR2(150 BYTE),
                            ,PO_EFFECTIVE_TO_DATE         --VARCHAR2(150 BYTE),
                            ,PO_TOTAL_DOLLARS             --VARCHAR2(150 BYTE),
                            ,PO_TOTAL_UNITS               --VARCHAR2(150 BYTE),
                            ,CUSTOMER_REFERENCE_NUMBER    --VARCHAR2(150 BYTE),
                            ,TAX_EXEMPT_NUMBER            --VARCHAR2(150 BYTE),
                            ,TAX_EXEMPT_EXP_DATE          --VARCHAR2(150 BYTE),
                            ,TAX_EXEMPT_CERTIFICATE_RCVD  --VARCHAR2(150 BYTE),
                            ,SALES_CENTER                 --VARCHAR2(3 BYTE) NOT NULL,
                            ,DIVISION                     --VARCHAR2(50 BYTE) NOT NULL,
                            ,ROUTE_NUMBER                 --VARCHAR2(10 BYTE),
                            ,ROUTE_DELIVERY_FREQUENCY     --VARCHAR2(10 BYTE),
                            ,NEXT_REGULAR_DELIVER_DATE    --DATE,
                            ,DELIVERY_INSTRUCTIONS        --VARCHAR2(1000 BYTE),
                            ,ROUTE_MESSAGE                --VARCHAR2(240 BYTE),
                            ,COLLECTION_MESSAGE           --VARCHAR2(240 BYTE),
                            ,ADDRESSEE                    --VARCHAR2(100 BYTE),
                            ,FREQUENCY                    --VARCHAR2(10 BYTE),
                            ,CUSTOMER_START_DATE          --DATE,
                            ,SHIP_TO_START_DATE           --DATE,
                            ,SUPPRESS_PRICE_HH_TICKET     --VARCHAR2(1 BYTE),
                            ,RSR_OVERIDE_SUPPRESS_PRICE   --VARCHAR2(1 BYTE),
                            ,BOTTLE_INITIAL_INVENTORY     --VARCHAR2(3 BYTE),
                            ,RATE_SCHEDULE                --VARCHAR2(4 BYTE),
                            ,CHARGE_DEPOSIT               --VARCHAR2(1 BYTE),
                            ,PREFERRED_CUSTOMER_FLAG      --VARCHAR2(1 BYTE),
                            ,PENDING                      --VARCHAR2(1 BYTE),
                            ,BSC_FLAG                     --VARCHAR2(1 BYTE),
                            ,CREDIT_SCORE                 --VARCHAR2(4 BYTE),
                            ,TERM_FEE_AMOUNT              --NUMBER,
                            ,AGREEMENT_TERM               --VARCHAR2(30 BYTE),
                            ,BOTTLE_DEPOSIT_AMT           --NUMBER,
                            ,DELIVERY_TICKET_PRINT_FLAG   --VARCHAR2(1 BYTE),
                            ,TIER_PRICE_PROC_FLAG         --VARCHAR2(1 BYTE) DEFAULT 'N',
                            ,BOT_DEPOSIT_PROC_FLAG        --VARCHAR2(1 BYTE) DEFAULT 'N'
                            --,HOLD_REASON                --VARCHAR2(10),
                            ,WILL_CALL_FLAG             --VARCHAR2(1)     -- re-activated this columns to fetch will call flag data from the prestaging cust tab by Bala Palani as per WO 19982
                            ,SUB_CUST_NUMBER              --VARCHAR2(40)
                            ,PRICE_LIST_NAME                                -- Added by Bala Palani as per WO : 19982
                         )
                VALUES
                         (   l_ship_site_id_seq
                            ,l_cust_id
                            ,l_ship_addr_id
                            ,l_bill_site_id
                            ,l_sub_cust_rec.bill_to_master
                            ,decode(l_addr_id,l_ship_addr_id,to_char(l_ship_addr_id),to_char(l_ship_site_id_seq)) -- where bill to = ship to address for master customer since reference field is the same for both
                           -- ,DECODE(l_sub_cust_rec.sales_tax,'EX','EXEMPT','TAXABLE')   Removed  Decode Condition as per  EB-2058
                           ,l_sub_cust_rec.sales_tax
                            ,l_sub_cust_rec.SHIP_TO_PO_NUM
                            ,NULL
                            ,NULL
                            ,NULL
                            ,NULL
                            ,l_sub_cust_rec.ship_to_reference_num  --EB-1877
                         --   ,DECODE(l_sub_cust_rec.sales_tax,'EX','ON FILE',NULL)   Removed  Decode Condition as per  EB-2058  AND Added new field as per EB-2058
                            ,l_sub_cust_rec.TAX_EXEMPT_NUM
                            ,NULL
                           -- ,DECODE(l_sub_cust_rec.sales_tax,'EX','Y','N')          Removed  Decode Condition as per  EB-2058  AND Added new field as per EB-2058
                            ,l_sub_cust_rec.TAX_CERT_RECVD
                            ,l_sales_center_s
                            ,l_division_s --'BV10'
                            ,get_mapped_value(l_system_name_s,'ROUTES',l_sub_cust_rec.route_number,l_sales_center_s)
                            ,l_sub_cust_rec.delivery_frequency   -- Added PU 4/24/2008
                            ,NULL       -- NEXT_REGULAR_DELIVER_DATE -- Not used in Oracle, it is calculated when you query the PPF
                            ,NULL       -- DELIVERY_INSTRUCTIONS -- INSERTED AS A NOTE ON THE PPF.SWGRTM_NOTES.NOTE_TEXT; 01/24/07:  Alert file will have this data
                            ,NULL
                            ,NULL
                            ,decode(l_sub_cust_rec.customer_name,l_mast_cust_name_s,NULL,l_sub_cust_rec.customer_name)
                            ,l_sub_cust_rec.delivery_frequency   -- Added PU 4/24/2008
                            ,l_sub_cust_rec.CUST_START_DATE
                            ,l_sub_cust_rec.CUST_START_DATE
                            ,'Y'            -- SUPPRESS_PRICE_HH_TICKET
                            ,'Y'            --  RSR_OVERIDE_SUPPRESS_PRICE
                            ,NULL           --  BOTTLE_INITIAL_INVENTORY
                            ,NULL           --  RATE_SCHEDULE
                            ,'Y'            -- Default to Y for all Ship Tos  -- CHARGE_DEPOSIT
                            ,'N'            -- PREFERRED_CUSTOMER_FLAG
                            ,NULL           -- PENDING
                            ,l_sub_cust_rec.esc_fee            -- ESC_FLAG --EB-1877
                            ,NULL           -- CREDIT_SCORE -- 01/24/07:  Val will map it
                            ,0              -- TERM_FEE_AMOUNT -- $100 by default (Agreement - Term Fee column) -- update later?
                            ,'GFAGR'        -- AGREEMENT_TERM -- Default from the Agreement code (Agreement - Term Code column) -- update later?
                            ,NULL           -- BOTTLE_DEPOSIT_AMT -- If the amount in this field is different that what is on the price list then
                                                           -- create a special price record to ensure the customer is charged correctly -- ?
                            ,l_sub_cust_rec.print_delivery_tickets            -- DELIVERY_TICKET_PRINT_FLAG  --EB-1877
                            ,'N'            -- TIER_PRICE_PROC_FLAG
                            ,'N'            -- BOT_DEPOSIT_PROC_FLAG
                            ,l_sub_cust_rec.ON_REQUEST_FLAG       -- re-activated this columns to fetch will call flag data from the prestaging cust tab by Bala Palani as per WO 19982
                            ,l_sub_cust_rec.customer_number
                            ,swgcnv_get_restrctd_prclst(l_system_name_s, l_sub_cust_rec.customer_number)        -- Added by Bala Palani as per WO : 19982
                         );


                SELECT decode(l_addr_id,l_ship_addr_id,l_ship_addr_id,l_ship_site_id_seq)
                INTO   l_ship_site_id
                FROM   dual;

                swg_cust_debug('Y','Ship site ID (sub-cust): '||to_char(l_ship_site_id));
                dbms_output.put_line('Ship site ID (sub-cust): '||to_char(l_ship_site_id));

                -- Contact Info

                INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                    (    CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                        ,ADDRESS_ID           --NUMBER(15),
                        ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                        ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                        ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                        ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                        ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                        ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                        ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                    )
                VALUES
                    (    l_cust_id
                        ,l_ship_addr_id
                        ,l_first_name_s    -- Added by Bala Palani EB-670
                        ,l_last_name_s
                        ,NVL(substr(l_sub_cust_rec.primary_phone,1,3), '111')                  -- Added by Bala Palani EB-1156
                        ,NVL(substr(l_sub_cust_rec.primary_phone,4,10),'1111111')  -- Added by Bala Palani EB-1156
                        ,substr(l_sub_cust_rec.primary_phone,11)
                        ,'PHONE'
                        ,NULL
                    );

          ---EB-1877
              IF ( l_sub_cust_rec.primary_bus_phone IS NOT NULL )  THEN
              
              INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_first_name_s 
                                 ,l_last_name_s  
                                 ,NVL(substr(l_sub_cust_rec.primary_bus_phone,1,3), '111')                  
                                 ,NVL(substr(l_sub_cust_rec.primary_bus_phone,4,10),'1111111')             
                                 ,substr(l_sub_cust_rec.primary_bus_phone,11)
                                 ,'PHONE'
                                 ,NULL
                                );
              
              END IF;
              
             IF ( l_sub_cust_rec.primary_cell_phone IS NOT NULL )  THEN
              
              INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_first_name_s  
                                 ,l_last_name_s  
                                 ,NVL(substr(l_sub_cust_rec.primary_cell_phone,1,3), '111')                 
                                 ,NVL(substr(l_sub_cust_rec.primary_cell_phone,4,10),'1111111')             
                                 ,substr(l_sub_cust_rec.primary_cell_phone,11)
                                 ,'PHONE'
                                 ,NULL
                                );
              
              END IF;
              --EB-1877

               -- Added For SAGE Conversion
               IF ( l_sub_cust_rec.primary_email_address IS NOT NULL ) THEN

                  INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                     (   CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                        ,ADDRESS_ID           --NUMBER(15),
                        ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                        ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                        ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                        ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                        ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                        ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                        ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                        ,PRIMARY_EMAIL_FLAG
                     )
                  VALUES
                     (   l_cust_id
                        ,l_ship_addr_id
                        ,l_first_name_s  -- Added by Bala Palani EB-670
                        ,l_last_name_s
                        ,NVL(SUBSTR(l_sub_cust_rec.primary_phone,1,3), '111')              -- Added by Bala Palani EB-1156
                        ,NVL(SUBSTR(l_sub_cust_rec.primary_phone,4,10),'1111111')          -- Added by Bala Palani EB-1156
                        ,substr(l_sub_cust_rec.primary_phone,11)
                        ,'EMAIL'
                        ,l_sub_cust_rec.primary_email_address
                        ,'Y'
                     );

               END IF;
               -- Added For SAGE Conversion
               
                    --EB-1877 Contact2 and Contact3----
               
               IF (l_sub_cust_rec.CONTACT2_LAST_NAME) IS NOT NULL THEN
               
                 IF  (l_sub_cust_rec.Phone2)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_sub_cust_rec.contact2_first_name  
                                 ,l_sub_cust_rec.contact2_last_name  
                                 ,NVL(substr(l_sub_cust_rec.Phone2,1,3), '111')                  
                                 ,NVL(substr(l_sub_cust_rec.Phone2,4,10),'1111111')              
                                 ,substr(l_sub_cust_rec.Phone2,11)
                                 ,'PHONE'
                                 ,NULL
                                );
                 
                  END IF;
                 
                 IF  (l_sub_cust_rec.bus_phone2)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_sub_cust_rec.contact2_first_name  
                                 ,l_sub_cust_rec.contact2_last_name  
                                 ,NVL(substr(l_sub_cust_rec.bus_phone2,1,3), '111')                  
                                 ,NVL(substr(l_sub_cust_rec.bus_phone2,4,10),'1111111')              
                                 ,substr(l_sub_cust_rec.bus_phone2,11)
                                 ,'PHONE'
                                 ,NULL
                                );
               
                 
                 END IF; 
                 
                 IF  (l_sub_cust_rec.cell_phone2)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_sub_cust_rec.contact2_first_name  
                                 ,l_sub_cust_rec.contact2_last_name 
                                 ,NVL(substr(l_sub_cust_rec.cell_phone2,1,3), '111')                  
                                 ,NVL(substr(l_sub_cust_rec.cell_phone2,4,10),'1111111')              
                                 ,substr(l_sub_cust_rec.cell_phone2,11)
                                 ,'PHONE'
                                 ,NULL
                                );
                 
                 END IF;
                 
                 IF  (l_sub_cust_rec.email_address2)  IS NOT NULL THEN
                 
                  INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                     (   CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                        ,ADDRESS_ID           --NUMBER(15),
                        ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                        ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                        ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                        ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                        ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                        ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                        ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                     )
                  VALUES
                     (   l_cust_id
                        ,l_ship_addr_id
                        ,l_sub_cust_rec.contact2_first_name  
                        ,l_sub_cust_rec.contact2_last_name  
                        ,NVL(SUBSTR(l_sub_cust_rec.phone2,1,3), '111')          
                        ,NVL(SUBSTR(l_sub_cust_rec.phone2,4,10),'1111111')     
                        ,substr(l_sub_cust_rec.phone2,11)
                        ,'EMAIL'
                        ,l_sub_cust_rec.email_address2
                     );
                 
                 END IF;
               
               
               END IF;
               
               
               IF (l_sub_cust_rec.CONTACT3_LAST_NAME) IS NOT NULL THEN
               
                 IF  (l_sub_cust_rec.Phone3)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_sub_cust_rec.contact3_first_name  
                                 ,l_sub_cust_rec.contact3_last_name  
                                 ,NVL(substr(l_sub_cust_rec.Phone3,1,3), '111')                  
                                 ,NVL(substr(l_sub_cust_rec.Phone3,4,10),'1111111')              
                                 ,substr(l_sub_cust_rec.Phone3,11)
                                 ,'PHONE'
                                 ,NULL
                                );
                 
                  END IF;
                 
                 IF  (l_sub_cust_rec.bus_phone3)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_sub_cust_rec.contact3_first_name  
                                 ,l_sub_cust_rec.contact3_last_name  
                                 ,NVL(substr(l_sub_cust_rec.bus_phone3,1,3), '111')                  
                                 ,NVL(substr(l_sub_cust_rec.bus_phone3,4,10),'1111111')              
                                 ,substr(l_sub_cust_rec.bus_phone3,11)
                                 ,'PHONE'
                                 ,NULL
                                );
               
                 
                 END IF; 
                 
                 IF  (l_sub_cust_rec.cell_phone3)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_sub_cust_rec.contact3_first_name  
                                 ,l_sub_cust_rec.contact3_last_name 
                                 ,NVL(substr(l_sub_cust_rec.cell_phone3,1,3), '111')                  
                                 ,NVL(substr(l_sub_cust_rec.cell_phone3,4,10),'1111111')              
                                 ,substr(l_sub_cust_rec.cell_phone3,11)
                                 ,'PHONE'
                                 ,NULL
                                );
                 
                 END IF;
                 
                 IF  (l_sub_cust_rec.email_address3)  IS NOT NULL THEN
                 
                  INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                     (   CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                        ,ADDRESS_ID           --NUMBER(15),
                        ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                        ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                        ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                        ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                        ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                        ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                        ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                     )
                  VALUES
                     (   l_cust_id
                        ,l_ship_addr_id
                        ,l_sub_cust_rec.contact3_first_name  
                        ,l_sub_cust_rec.contact3_last_name  
                        ,NVL(SUBSTR(l_sub_cust_rec.phone3,1,3), '111')          
                        ,NVL(SUBSTR(l_sub_cust_rec.phone3,4,10),'1111111')     
                        ,substr(l_sub_cust_rec.phone3,11)
                        ,'EMAIL'
                        ,l_sub_cust_rec.email_address3
                     );
                 
                 END IF;
               
               END IF;
               
               --EB-1877 Contact2 and Contact3----
          

                -- also enter shipcycle days
                l_delivery_freq_s := l_sub_cust_rec.delivery_frequency;

                INSERT INTO SWGCNV_DD_CYCLEDAYS
                    (    CUSTOMER_ID           --NUMBER(15),
                        ,SHIPPING_SITE_ID      --NUMBER(15),
                        ,ROUTE_SERVICE_DAY     --VARCHAR2(2 BYTE),
                        ,ROUTE_SEQUENCE        --NUMBER(15),
                        ,CYCLE_DAY             --VARCHAR2(2 BYTE),
                        ,DRIVING_INSTRUCTIONS  --VARCHAR2(2000 BYTE)
                    )
                VALUES
                    (    l_cust_id
                        ,l_ship_site_id_seq --l_ship_site_id -- Prj_purch code equates ship_to_site_id with shipping_site_id, not delivery_loc_number
                        ,l_new_code_s
                        ,to_number(l_sub_cust_rec.route_seq)
                        ,l_new_code_s
                        ,NULL
                    );

            if nvl(l_delivery_freq_s,'2') = '0' then

              INSERT INTO SWGCNV_DD_CYCLEDAYS
                    (    CUSTOMER_ID           --NUMBER(15),
                        ,SHIPPING_SITE_ID      --NUMBER(15),
                        ,ROUTE_SERVICE_DAY     --VARCHAR2(2 BYTE),
                        ,ROUTE_SEQUENCE        --NUMBER(15),
                        ,CYCLE_DAY             --VARCHAR2(2 BYTE),
                        ,DRIVING_INSTRUCTIONS  --VARCHAR2(2000 BYTE)
                    )
              VALUES
                    (    l_cust_id
                        ,l_ship_site_id_seq --l_ship_site_id -- Prj_purch code equates ship_to_site_id with shipping_site_id, not delivery_loc_number
                        ,l_new_code_s
                        ,to_number(l_sub_cust_rec.route_seq)
                        ,l_new_code_s
                        -- VG 8/7/2007 END
                        ,NULL
                    );

            END IF;

              ELSIF (g_error_flag_c != 'N' AND l_ship_site_id = -99) THEN

                    l_msg_data_s := 'Unexpected Error/no data found in Swgcnv_CB_Cust_stgload_Pkg.get_ship_to_site_id for Rec/Customer/Cust num: '||to_char(l_sub_cust_rec.record_num)||'/'||l_mast_cust_name_s||'/'|| l_sub_cust_rec.bill_to_master||': '||SQLERRM;
                    swg_cust_debug('Y',l_msg_data_s);
                    dbms_output.put_line(l_msg_data_s);
                    --Fnd_File.Put_Line(Fnd_File.LOG,l_msg_data_s);

                    -- GOTO end_loop;
                    RAISE ERROR_ENCOUNTERED;

                 END IF;

             ELSE
               l_msg_data_s := 'Unexpected Error in Swgcnv_CB_Cust_stgload_Pkg.check_ship_addr_exists for Rec/Customer/Cust num: '||to_char(l_sub_cust_rec.record_num)||'/'||l_mast_cust_name_s||'/'|| l_sub_cust_rec.bill_to_master||': '||SQLERRM;
               swg_cust_debug('Y',l_msg_data_s);
               dbms_output.put_line(l_msg_data_s);
               --Fnd_File.Put_Line(Fnd_File.LOG,l_msg_data_s);

               -- GOTO end_loop;
               RAISE ERROR_ENCOUNTERED;
             END IF; --g_error_flag_c <> 'Y'

           END IF;-- l_ship_addr_id = -9 / check_ship_addr_exists

       -- Contracts requires function check

       -- contract info in shipping site area

        IF l_addr_id=l_ship_addr_id THEN
            l_ship_site_id := l_ship_addr_id;
        END IF;

 /*   IF  l_sub_cust_rec.equipment_id is not null AND l_sub_cust_rec.equipment_type IS NOT NULL THEN
     
        IF NOT check_contract_exists (   l_sub_cust_rec.bill_to_master
                                        ,l_ship_site_id
                                        ,UPPER(l_sub_cust_rec.equipment_type) -- VG 8/8/2007
                                        --,get_mapped_value(l_system_name_s,'CONT_ITEM',l_sub_cust_rec.equipment_type) --l_sub_cust_rec.equipment_type -- -- mapping needed -- ITEM_CODE is not there ??
                                        ,l_sub_cust_rec.equipment_id
                                        --,nvl(l_sc_s,l_sales_center_s) --'SAC'
                                        ,l_sales_center_s
                                        ,l_division_s --'BV10'
                                     )  THEN

            INSERT INTO SWGCNV_DD_EQPMNT_INTERFACE
                    (    CUSTOMER_NUMBER           --VARCHAR2(20 BYTE)   NOT NULL,
                        ,DELIVERY_LOCATION_NUMBER  --VARCHAR2(10 BYTE)   NOT NULL,
                        ,ITEM_CODE                 --VARCHAR2(20 BYTE)   NOT NULL,
                        ,PLACEMENT_CODE            --VARCHAR2(20 BYTE)   NOT NULL,
                        ,SERIAL_NUMBER             --VARCHAR2(30 BYTE)   NOT NULL,
                        ,RENTAL_AMOUNT             --NUMBER              NOT NULL,
                        ,INSTALLATION_DATE         --DATE                NOT NULL,
                        ,LAST_BILLING_DATE         --DATE                NOT NULL,
                        ,PAYMENT_TERMS             --VARCHAR2(30 BYTE),
                        ,ACCOUNTING_RULE           --VARCHAR2(20 BYTE)   NOT NULL,
                        ,INVOICING_RULE            --VARCHAR2(20 BYTE)   NOT NULL,
                        ,BILLING_METHOD            --VARCHAR2(30 BYTE)   NOT NULL,
                        ,BILLING_INTERVAL          --VARCHAR2(20 BYTE)   NOT NULL,
                        ,SALES_CENTER              --VARCHAR2(3 BYTE)    NOT NULL,
                        ,DIVISION                  --VARCHAR2(10 BYTE)   NOT NULL,
                        ,MODEL                     --VARCHAR2(50 BYTE),
                        ,ESCROW_AMOUNT             --NUMBER,
                        ,CONTRACT_START_DATE       --DATE,
                        ,NEXT_BILL_DATE            --DATE,
                        ,VALID_FLAG                --VARCHAR2(1 BYTE)    DEFAULT 'N',
                        ,LAST_SRV_DATE             --DATE,
                        ,RENTAL_EXCEPTION_CODE     --VARCHAR2(10 BYTE),
                        ,SRVC_DUE_DATE             --DATE,
                        ,QUANTITY                  --NUMBER,
                        ,ITEM_SUB_CODE             --VARCHAR2(50 BYTE),
                        ,GRATIS_COUNT              --VARCHAR2(10 BYTE),
                        ,CUST_EQPMNT_OWNED_STATUS  --VARCHAR2(1 BYTE),
                        ,CUST_REMAINING_PMT        --NUMBER
                    )
            VALUES
                    (    l_sub_cust_rec.bill_to_master
                        ,to_char(l_ship_site_id)
                        ,UPPER(l_sub_cust_rec.equipment_type)
                        ,'RENTED'
                        ,l_sub_cust_rec.equipment_id
                        ,decode(l_sub_cust_rec.rent_period,'1',(nvl(l_sub_cust_rec.rent,0)/nvl(l_sub_cust_rec.equipment_count,1)),nvl(l_sub_cust_rec.rent,0))
                        ,l_sub_cust_rec.cust_start_date -- INSTALLATION_DATE -- Same as Customer Start Date?
                        ,decode(l_sub_cust_rec.customer_type,'RESIDENTIAL',to_date('01-AUG-2007'),
                                decode(l_sales_center_s,'SAV',to_date('22-JUL-2007'),to_date('15-JUL-2007')))
                        ,NULL       -- PAYMENT_TERMS -- Default from Customer profile class
                        ,'MONTHLY'
                        ,'ADVANCE INVOICE'
                        ,'RECURRING'
                        , nvl(get_mapped_value(l_system_name_s,'BILLINTVL',l_sub_cust_rec.rent_period),'1040')
                        ,l_sales_center_s --'SAC'
                        ,l_division_s --'BV10'
                        ,UPPER(l_sub_cust_rec.equipment_type)
                        ,0
                        ,l_sub_cust_rec.cust_start_date -- CONTRACT_START_DATE -- Same as Customer Start Date?
                        ,decode(l_sub_cust_rec.customer_type,'RESIDENTIAL',to_date('01-SEP-2007'),decode(l_sales_center_s,'SAV',to_date('22-AUG-2007'),to_date('15-AUG-2007')))
                        ,'N' -- VALID_FLAG --NULL
                        ,NULL
                        ,NULL
                        ,NULL
                        ,1
                        ,NULL
                        ,NULL
                        ,NULL
                        ,NULL
                    );
            -- insert l_ship_site_id  for delivery location number

      ELSE

        IF g_error_flag_c != 'Y' THEN
          l_msg_data_s := 'Rec/Customer/Cust num/Contract already exists in staging table: '||to_char(l_sub_cust_rec.record_num)||'/'||l_mast_cust_name_s||'/'|| l_sub_cust_rec.bill_to_master;
          dbms_output.put_line(l_msg_data_s);
          --Fnd_File.Put_Line(Fnd_File.LOG,l_msg_data_s);
          swg_cust_debug(l_debug_c,l_msg_data_s);

        ELSE
          l_msg_data_s := 'Unexpected Error in Swgcnv_CB_Cust_stgload_Pkg.check_contract_exists for Rec/Customer/Cust num: '||to_char(l_sub_cust_rec.record_num)||'/'||l_mast_cust_name_s||'/'|| l_sub_cust_rec.bill_to_master||': '||SQLERRM;
          swg_cust_debug('Y',l_msg_data_s);
          dbms_output.put_line(l_msg_data_s);
          --Fnd_File.Put_Line(Fnd_File.LOG,l_msg_data_s);

          -- GOTO end_loop;
          RAISE ERROR_ENCOUNTERED;
        END IF;
      END IF;-- check_contract_exists
      -- VG GBC01 8/8/2007 -- END IF; -- l_sub_cust_rec.rent_period != '3,4,Z' -- ARS02 change
      END IF; -- equipment_id is not null*/

   END IF; -- check_mast_cust_exists

     IF g_error_flag_c != 'Y' THEN
         UPDATE SWGCNV_DD_CB_PRESTAGING_CUST
         SET    processed_flag='Y'
               ,processed_status='S'
               ,error_message=NULL
         WHERE  record_num = l_sub_cust_rec.record_num
--         AND SALES_CENTER = in_sales_center_s;  -- SSB added to process multiple sales center.      --MTS 20129 process bill_to_master for all sales centers
         ;
         COMMIT;
     END IF;

     EXCEPTION
     WHEN ERROR_ENCOUNTERED THEN
         ROLLBACK TO SAVEPOINT at_subcust_first;
         UPDATE SWGCNV_DD_CB_PRESTAGING_CUST
         SET    processed_flag='Y'
               ,processed_status='E'
               ,error_message=l_msg_data_s
         WHERE  record_num = l_sub_cust_rec.record_num
--         AND  SALES_CENTER = in_sales_center_s;  -- SSB added to process multiple sales center.   --MTS 20129 process bill_to_master for all sales centers
         ;
         COMMIT;

     WHEN OTHERS THEN
            l_msg_data_s    :=  'Unexpected error during processing of record num: '||to_char(l_sub_cust_rec.record_num)||': '||SQLERRM;
            ROLLBACK TO SAVEPOINT at_subcust_first;

             swg_cust_debug('Y',l_msg_data_s);
          dbms_output.put_line(l_msg_data_s);
        --Fnd_File.Put_Line(Fnd_File.LOG,l_msg_data_s);

          UPDATE SWGCNV_DD_CB_PRESTAGING_CUST
          SET   processed_flag='Y'
               ,processed_status='E'
               ,error_message=l_msg_data_s
         WHERE  record_num = l_sub_cust_rec.record_num
--         AND  SALES_CENTER = in_sales_center_s;  -- SSB added to process multiple sales center.    --MTS 20129 process bill_to_master for all sales centers
         ;
         COMMIT;

     END;
    END LOOP;
  CLOSE cur_sub_cust_data;

    l_end_time_d    :=      SYSDATE;
    Fnd_File.Put_Line(Fnd_File.OUTPUT,'*************************  RUN STATISTICS *******************************');
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Sub-Customer Records Read           : ' || l_cust_recs_read_n);
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' ------------------------------------------------------------------------');
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' Start Time : ' || TO_CHAR(l_start_time_d, 'MM/DD/RRRR HH24:MI:SS'));
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' End Time   : ' || TO_CHAR(l_end_time_d, 'MM/DD/RRRR HH24:MI:SS'));
    Fnd_File.Put_Line(Fnd_File.OUTPUT,'*************************************************************************');


 -- Interface/Staging table updates

 -- Monthly_invoice_format

 OPEN cur_upd_col_1( in_sales_center_s,l_division_s);
    LOOP
      BEGIN
         FETCH cur_upd_col_1 INTO l_cust_id;
         EXIT WHEN cur_upd_col_1%NOTFOUND;
         SAVEPOINT upd_intf_fields;
         g_error_flag_c := 'N';

         select nvl(count(SHIPTO_SITE_ID),0)
         into   l_no_of_shiptos
         from   SWGCNV_DD_CUSTOMER_SHIPTO
         where  customer_id=l_cust_id
         ;

         UPDATE SWGCNV_DD_CUSTOMER_INTERFACE
         SET    MONTHLY_INVOICE_FORMAT=decode(l_no_of_shiptos,1,'SINGLE SHIP-TO/BILL-TO',0,'N/A','MULTIPLE SHIP-TO')
         WHERE  customer_id=l_cust_id
         ;

         COMMIT;

      EXCEPTION WHEN OTHERS THEN
          ROLLBACK TO upd_intf_fields;
          l_error_message_s   := 'Error during update of monthly_invoice_format for customer ID: '||to_char(l_cust_id)||': '||SQLERRM;
          swg_cust_debug('Y',l_error_message_s);
          dbms_output.put_line(l_error_message_s);
      END;
    END LOOP;
 CLOSE cur_upd_col_1;


EXCEPTION

    WHEN INIT_ERROR THEN
        ou_errbuf2_s     :=  'Initialization / Bulk Collect Error encountered.' || l_error_message_s;
        ou_errcode2_n    :=  2;
        RETURN;

    WHEN OTHERS THEN

        l_error_message_s   := SQLERRM;

        swg_cust_debug('Y',l_error_message_s);
        dbms_output.put_line(l_error_message_s);
        --Fnd_File.Put_Line(Fnd_File.LOG,l_error_message_s);

        ou_errbuf2_s         :=     'Unexpected Error in procedure insert_sub_cust: '||l_error_message_s;
        ou_errcode2_n        :=     2;

        --Fnd_File.Put_Line(Fnd_File.LOG,'Unexpected Error: '||l_error_message_s);

       RETURN;

END insert_sub_cust;


 ----------------------------------------------------------------
 
    -- Added As per EB-2023 Strats INSERT_MULTI_SALES  Procedure
 
 PROCEDURE    INSERT_MULTI_SALES (out_errbuf_s			    OUT	VARCHAR2
                                 ,out_errnum_n			  OUT	NUMBER
                                 ,in_system_name_s              IN      VARCHAR2
                                 ,in_sales_center_s             IN      VARCHAR2
                                 ,in_proc_mstr_only_c           IN      VARCHAR2
                                 ,in_debug_flag_c               IN      VARCHAR2 DEFAULT G_SWG_NODEBUG
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
SELECT   unique a.sales_center
FROM     SWGCNV_DD_CB_PRESTAGING_CUST      a
where a.sales_center =  NVL( in_sales_center_s, a.sales_center ) ;

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
                                 ,program     =>   'SWGCNV_CB_PRESTAGING_CUST'
                                 ,description =>    NULL
                                 ,start_time  =>    NULL
                                 ,sub_request =>    FALSE
                                 ,argument1   =>    rec_special.sales_center
                                 ,argument2   =>    in_system_name_s
                                 ,argument3   =>    in_proc_mstr_only_c
                                 ,argument4   =>    'C'
                                 ,argument5   =>    in_debug_flag_c
                                  );

      IF l_request_id_n = 0 THEN

         out_errbuf_s     :=  'ERROR: Unable to Submit Child DSW Customer Pre-Staging Load, Process Sales center: '||rec_special.sales_center;
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

END INSERT_MULTI_SALES;

    -- Added As per EB-2023 Ends INSERT_MULTI_SALES  Procedure
 -----------------------------------------------------------------
 
    -- Added As per EB-2023 starts MULTI_SALES_AGREE  Procedure
 
 PROCEDURE    MULTI_SALES_AGREE  (out_errbuf_s            OUT      VARCHAR2
      ,out_errnum_n           OUT      NUMBER
      ,in_system_name_s       IN      VARCHAR2
      ,in_sales_center_s      IN       VARCHAR2
      ,in_debug_c             IN       VARCHAR2    DEFAULT  'N'
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
SELECT   unique a.sales_center
FROM     SWGCNV_DD_CB_PRESTAGING_CUST      a
where a.sales_center =  NVL( in_sales_center_s, a.sales_center ) ;

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
                                 ,program     =>   'SWGCNV_CUST_AGREE_CONV'
                                 ,description =>    NULL
                                 ,start_time  =>    NULL
                                 ,sub_request =>    FALSE
                                 ,argument1   =>    rec_special.sales_center
                                 ,argument2   =>    in_debug_c
                                 ,argument3   =>    in_validate_only_c
                                 );

      IF l_request_id_n = 0 THEN

         out_errbuf_s     :=  'ERROR: Unable to Submit Child DSW Customer Agreement, Process Sales center: '||rec_special.sales_center;
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

END MULTI_SALES_AGREE;

 -- Added As per EB-2023 Ends MULTI_SALES_AGREE  Procedure
------------------------------------------------------------------
  PROCEDURE   Insert_Main ( ou_errbuf_s             OUT    VARCHAR2
                           ,ou_errcode_n            OUT    NUMBER
                           ,in_sales_center_s       IN     VARCHAR2
                           ,in_system_name_s        IN     VARCHAR2
                           ,in_proc_mstr_only_c     IN     VARCHAR2    --MTS 20129
                           ,in_mode_c               IN     VARCHAR2    DEFAULT    G_SWG_CONCURRENT
                           ,in_debug_flag_c         IN     VARCHAR2    DEFAULT    G_SWG_NODEBUG
                          )
  IS

    --Table inserts into:

    --1.  Customer staging table    :    SWGCNV_DD_CUSTOMER_INTERFACE
    --2.  Addresses table           :   SWGCNV_DD_ADDRESSES
    --3.  Billing Locations         :   SWGCNV_DD_CUSTOMER_BILLTO
    --4.  Shipping Locations        :   SWGCNV_DD_CUSTOMER_SHIPTO
    --5.  Contacts                  :   SWGCNV_DD_CUSTOMER_CONTACT
    --6.  Shipping Cycle Day        :   SWGCNV_DD_CYCLEDAYS
    --7.  Contracts/Equipment       :   SWGCNV_DD_EQPMNT_INTERFACE

    -- Create 3 custom sequences, one for customer_id, one for address_id, one for site_id
    -- If time permits, modularize further - ALL inserts to be addressed in one procedure with different entity names
    -- also replace sales center, division with variable names

    CURSOR  cur_cust_data( in_sales_center IN VARCHAR2 )
    IS
    SELECT  *
    FROM    SWGCNV_DD_CB_PRESTAGING_CUST
    WHERE   PROCESSED_FLAG    =   'N'
    AND     bill_to_master    IS   NULL
    --AND     record_num between 1 and 100 --=129 --156 --2
    AND     sales_center      =   nvl(in_sales_center,sales_center)
    AND     in_proc_mstr_only_c = 'N'
    UNION                      --MTS 20129 added to process bill_to_masters for all salescenters before processing the rest of the customer rows
    SELECT  *
    FROM    SWGCNV_DD_CB_PRESTAGING_CUST cust
    WHERE   PROCESSED_FLAG    =   'N'
    AND     bill_to_master    IS   NULL
    --AND     record_num between 1 and 100 --=129 --156 --2
    AND     in_proc_mstr_only_c = 'Y'
    AND     EXISTS  (SELECT 1
                     FROM swgcnv_dd_cb_prestaging_cust cust1
                     WHERE cust1.bill_to_master = cust.customer_number
                     AND ROWNUM = 1)
    ORDER   BY 1;

    CURSOR  cur_upd_col_1( in_sales_center_s IN VARCHAR2
                          ,in_division_s     IN VARCHAR2
                         )
    IS
    SELECT customer_id
    FROM   SWGCNV_DD_CUSTOMER_INTERFACE
    WHERE  sales_center     =    in_sales_center_s
--    AND    division         =    in_division_s   --MTS 20129 Process bill to master for all divisions
    ORDER BY customer_id;

    l_cust_rec                cur_cust_data%ROWTYPE;

    l_system_name_s           VARCHAR2(20);
    l_sales_center_s          VARCHAR2(3);
    l_debug_c                 VARCHAR2(1);
    l_mode_c                  VARCHAR2(1);
    l_user_name_s             VARCHAR2(20)  := 'SWGCNV';
    l_error_message_s         VARCHAR2(2000);
    l_msg_data_s              VARCHAR2(2000);
    l_new_code_s              VARCHAR2(110);
    l_new_sub_code_s          VARCHAR2(110);
    l_person_flag_c           VARCHAR2(1);
    ou_errbuf2_s              VARCHAR2(2000);
    l_division_s              VARCHAR2(20);
    
      l_state_s               VARCHAR2(20);   -- added by Bala Palani to get the new code for the old code for cycle days table as per W.O : 21652
      --l_new_code_s            VARCHAR2(20);    -- added by Bala Palani to get the new code for the old code for cycle days table as per W.O : 21652
      --l_new_sub_code_s        VARCHAR2(50);     -- added by Bala Palani to get the new code for the old code for cycle days table as per W.O : 21652
      l_error_mesg_s          VARCHAR2(50);      -- added by Bala Palani to get the new code for the old code for cycle days table as per W.O : 21652

    l_cust_recs_read_n        NUMBER;
    l_conv_userid_n           NUMBER;
    l_cust_id                 NUMBER;
    l_cust_id_seq             NUMBER;
    l_addr_id                 NUMBER;
    l_addr_id_seq             NUMBER;
    l_bill_site_id            NUMBER;
    l_bill_site_id_seq        NUMBER;
    l_ship_addr_id            NUMBER;
    l_ship_addr_id_seq        NUMBER;
    l_ship_site_id            NUMBER;
    l_ship_site_id_seq        NUMBER;
    l_no_of_shiptos           NUMBER;
    ou_errcode2_n             NUMBER;

    l_dd_value_c              VARCHAR2(2)       :=      'DD';
    l_legacy_cust_num_s       VARCHAR2(15);


    l_return_status_s         VARCHAR2(10);

    l_message_s               VARCHAR2(2000);

    l_start_time_d            DATE;
    l_end_time_d              DATE;

    ERROR_ENCOUNTERED         EXCEPTION;
    INIT_ERROR                EXCEPTION;

    l_cust_acct_id_n          NUMBER;
    l_obj_version_num_n       NUMBER;
    l_msg_count_n             NUMBER;
    l_legacy_cust_num_n       NUMBER := 0;

    l_empty_cust_rec          cust_rec_type;
    l_empty_addr_rec          addr_rec_type;
    l_empty_billto_rec        billto_rec_type;
    l_empty_shipto_rec        shipto_rec_type;
    l_empty_contact_rec       contact_rec_type;
    l_empty_cycleday_rec      cycleday_rec_type;
    l_empty_eqp_rec           eqp_rec_type;

    l_def_route_day_s         VARCHAR2(10);
    l_delivery_freq_s         VARCHAR2(10);

 l_first_name_s     VARCHAR2(150);  -- Proj 1359 SSB RAM02 and ARS05
 l_last_name_s     VARCHAR2(150);  -- Proj 1359 SSB RAM02 and ARS05

  BEGIN

    ou_errbuf_s         :=      NULL;
    ou_errcode_n        :=      0;

    l_start_time_d      :=      SYSDATE;
    l_system_name_s     :=      in_system_name_s;
    l_sales_center_s    :=      in_sales_center_s;


    l_division_s  := Swg_Hierarchy_Pkg.Get_Parent
                                ( 'LOCATION'
                                  ,l_sales_center_s     --'SAC' --NULL
                                  ,NULL --150
                                  ,'DIVISION'
                                  ,sysdate              -- NULL --TRUNC(in_from_date_d)
                                  ,'ID'
                                  ,'HTL'
                                );

    IF l_division_s IS NULL THEN

      dbms_output.put_line('Division is NULL');
      l_error_message_s := 'Division is NULL';
      --Fnd_File.Put_Line(Fnd_File.LOG,'Division is NULL');
      swg_cust_debug( l_debug_c,l_error_message_s);
      RAISE INIT_ERROR;

    END IF;

    l_debug_c      :=    in_debug_flag_c;
    l_mode_c       :=    in_mode_c;

    l_cust_recs_read_n  :=    0;

    BEGIN

      SELECT  user_id
      INTO    l_conv_userid_n
      FROM    fnd_user
      WHERE   user_name   =   'SWGCNV';

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('Failed to initialize - User Name SWGCNV not present');
        l_error_message_s := 'Failed to initialize - User Name SWGCNV not present';
        --Fnd_File.Put_Line(Fnd_File.LOG,'Failed to initialize - User Name SWGCNV not present');
        swg_cust_debug( l_debug_c,l_error_message_s);
        RAISE INIT_ERROR;
    END;

    -- Initialize the API

    BEGIN

      Fnd_Global.APPS_INITIALIZE (   USER_ID        =>  l_conv_userid_n
                                    ,RESP_ID        =>  NULL
                                    ,RESP_APPL_ID   =>  NULL
                                 );
    EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('error in APPS_INITIALIZE ');
        l_error_message_s := 'error in APPS_INITIALIZE ';
        --Fnd_File.Put_Line(Fnd_File.LOG,'error in APPS_INITIALIZE ');
        swg_cust_debug( l_debug_c,l_error_message_s);
        RAISE INIT_ERROR;
    END;

    g_cust_rec      :=   l_empty_cust_rec;
    g_addr_rec      :=   l_empty_addr_rec;
    g_billto_rec    :=   l_empty_billto_rec;
    g_shipto_rec    :=   l_empty_shipto_rec;
    g_contact_rec   :=   l_empty_contact_rec;
    g_cycleday_rec  :=   l_empty_cycleday_rec;
    g_eqp_rec       :=   l_empty_eqp_rec;


    OPEN  cur_cust_data(l_sales_center_s);
    LOOP

      BEGIN
        FETCH cur_cust_data INTO l_cust_rec;
        EXIT WHEN cur_cust_data%NOTFOUND;

        SAVEPOINT at_first;
        g_error_flag_c := 'N';

        l_cust_recs_read_n   := l_cust_recs_read_n + 1;

        --SGB determine location at this point WO #20129

        l_sales_center_s  := l_cust_rec.sales_center;

        l_division_s      := Swg_Hierarchy_Pkg.Get_Parent
                                ( 'LOCATION'
                                  ,l_sales_center_s     --'SAC' --NULL
                                  ,NULL --150
                                  ,'DIVISION'
                                  ,sysdate              -- NULL --TRUNC(in_from_date_d)
                                  ,'ID'
                                  ,'HTL'
                                );

        IF l_division_s IS NULL THEN

            dbms_output.put_line('Division is NULL');
            l_error_message_s := 'Division is NULL';
            --Fnd_File.Put_Line(Fnd_File.LOG,'Division is NULL');
            swg_cust_debug( l_debug_c,l_error_message_s);
            RAISE ERROR_ENCOUNTERED;

        END IF;
        --SGB determine location at this point WO #20129

        swg_cust_debug(l_debug_c,'Processing record number: '||to_char(l_cust_rec.record_num));
        dbms_output.put_line('Processing record number: '||to_char(l_cust_rec.record_num));

        --MTS 1641
        SELECT
            CASE WHEN new_code like 'DD RESI%' OR new_code like 'DD EMPLOYEE%' THEN
                      'Y'
                 ELSE 'N'
            END CASE
         INTO
            l_person_flag_c
         FROM
            swgcnv_map
         WHERE
            system_code = in_system_name_s
         AND type_code = 'CUSTPROFL'
         AND old_code = l_cust_rec.customer_type
         AND ROWNUM = 1;
                  

                  -- added by Bala Palani to get the new code for the old code for cycle days table as per W.O : 21652
                  
                     swgcnv_conversion_pkg.swg_map_lookup
                                                   (p_swg_system_code      => l_system_name_s   -- main_rec.system_code
                                                   ,p_swg_type_code        => 'RTSRVDAY'
                                                   ,p_swg_old_code         => LTRIM(RTRIM(l_cust_rec.route_day))
                                                   ,p_swg_old_sub_code     => l_state_s
                                                   ,r_swg_new_code         => l_new_code_s
                                                   ,r_swg_new_sub_code     => l_new_sub_code_s
                                                   ,p_txn_date             => NULL);

                     IF l_new_code_s IS NULL
                     THEN
                        l_error_message_s    :=    'Cycle day not found in Map table: '||LTRIM(RTRIM(l_cust_rec.route_day));
                        swg_cust_debug( l_debug_c,l_error_message_s); --Added by SU 08/06/14  EB-829   
                        RAISE ERROR_ENCOUNTERED;
                     END IF;
                     

        l_cust_id :=   check_cust_exists( l_cust_rec.customer_number
                                         ,l_person_flag_c
                                         ,l_cust_rec.customer_name
                                         ,l_sales_center_s --'SAC'
                                         ,l_division_s --'BV10'
                                        );

        IF l_cust_id = -9 THEN
   -- Proj 1359 SSB added below lines for handling differently for ARS05 - firstname;lastname (rather than lastname;firstname).
   
   IF l_person_flag_c != 'Y' THEN	 
	 l_first_name_s   :=   TRIM(NVL(l_cust_rec.primary_contact_first_name, 'ACCOUNTS'));   -- Added by Bala Palani EB-670        
     l_last_name_s    :=   TRIM(NVL(l_cust_rec.primary_contact_last_name, 'PAYABLE')); 
   ELSE
     l_first_name_s   :=   TRIM(NVL(l_cust_rec.primary_contact_first_name, TRIM(SUBSTR(l_cust_rec.customer_name,INSTR(l_cust_rec.customer_name,';')+1))));      -- Added by Bala Palani EB-670        
     l_last_name_s    :=   TRIM(NVL(l_cust_rec.primary_contact_last_name, TRIM(SUBSTR(l_cust_rec.customer_name,1,INSTR(l_cust_rec.customer_name,';')-1))));	 
   END IF;
   
     
   -- Proj 1359 SSB added above lines for ARS05 and RAM02 conversion.

          SELECT SWGCNV.SWGCNV_CB_CUST_ID_S.nextval
          INTO   l_cust_id_seq
          FROM   dual;

           INSERT INTO SWGCNV_DD_CUSTOMER_INTERFACE
             ( CUSTOMER_ID                 --NUMBER(15)        NOT NULL,
              ,CUSTOMER_NUMBER             --VARCHAR2(10 BYTE) NOT NULL,
              ,CUSTOMER_NAME               --VARCHAR2(50 BYTE) NOT NULL,
              ,PERSON_FLAG                 --VARCHAR2(1 BYTE)  NOT NULL,
              ,PERSON_FIRST_NAME           --VARCHAR2(150 BYTE),
              ,PERSON_LAST_NAME            --VARCHAR2(150 BYTE),
              ,SERVICE_INTERESTED_IN       --VARCHAR2(150 BYTE) NOT NULL,
              ,HOW_DID_YOU_HEAR_ABOUT_US   --VARCHAR2(150 BYTE) NOT NULL,
              ,SERVICE_LOCATION            --VARCHAR2(150 BYTE) NOT NULL,
              ,NO_OF_PEOPLE_USING_SERVICE  --VARCHAR2(150 BYTE) NOT NULL,
              ,WHAT_PROMPTED_INTEREST      --VARCHAR2(150 BYTE) NOT NULL,
              ,CURRENT_PRODUCT_OR_SERVICE  --VARCHAR2(150 BYTE) NOT NULL,
              ,MONTHLY_INVOICE_FORMAT      --VARCHAR2(150 BYTE) NOT NULL,
              ,SIGNED_DELVIERY_RECEIPT     --VARCHAR2(150 BYTE) NOT NULL,
              ,BILLING_COMMUNICATIONS      --VARCHAR2(150 BYTE) NOT NULL,
              ,SALES_CENTER                --VARCHAR2(3 BYTE)  NOT NULL,
              ,DIVISION                    --VARCHAR2(20 BYTE) NOT NULL,
              ,ATTRIBUTE1                  --VARCHAR2(50 BYTE),
              ,CUSTOMER_START_DATE         --DATE,
              ,MARKET_CODE                 --VARCHAR2(20 BYTE),
              ,ACCOUNT_DEPOSIT             --NUMBER,
              ,SEQ                         --NUMBER,
              ,PREFERRED_CUSTOMER_FLAG     --VARCHAR2(1 BYTE)  DEFAULT 'N'
              ,EMAIL_DELIVERY_TICKETS
              ,ESC_FEE
              ,CUSTOMER_STOP
             )
            VALUES
             ( l_cust_id_seq
              ,l_cust_rec.customer_number
              ,l_cust_rec.customer_name
              ,l_person_flag_c
              ,l_first_name_s  -- Proj 1359 SSB added to handle ARS05 data and other data
              ,l_last_name_s  -- Proj 1359 SSB added to handle ARS05 data differently.
              ,'ALL'
              ,nvl(l_cust_rec.CUST_START_REASON,'ACQ') --nvl(get_mapped_value(l_system_name_s,'CUSTMARKET',l_cust_rec.CUST_START_REASON),'NOT MAPPED')
              ,DECODE(l_person_flag_c,'Y','HOME','OFFICE')
              ,'1'
              ,'ALL OF ABOVE'
              ,'ALL OF ABOVE'
              ,'SINGLE SHIP-TO/BILL-TO'
              , 'N'  --EB=2793 DECODE(l_person_flag_c,'Y','N','C')
              ,'MAIL'   -- NVL(l_cust_rec.stmt_type,'MAIL')
              ,l_sales_center_s    --'SAC'
              ,l_division_s        --'BV10'
              ,NULL
              ,l_cust_rec.cust_start_date
              ,NULL
              ,0                   -- cannot be NULL if Agreements are to be created
              ,NULL
              ,'N'
              ,l_cust_rec.EMAIL_DELIVERY_TICKETS --EB-1877
              ,l_cust_rec.ESC_FEE  --EB-1877
              ,l_cust_rec.customer_stop  --EB-1877
             );

             -- insert from custom sequence for customer_id column, and store in l_cust_id

             l_cust_id := l_cust_id_seq;

             dbms_output.put_line('After cust insert');

        ELSE

          IF g_error_flag_c != 'Y' THEN

            l_msg_data_s := 'Rec/Customer/Cust num already exists in taging table:'
                             ||to_char(l_cust_rec.record_num)||'/'||l_cust_rec.customer_name||'/'||l_cust_rec.customer_number;

            dbms_output.put_line(l_msg_data_s);
            --Fnd_File.Put_Line(Fnd_File.LOG,l_msg_data_s);
            swg_cust_debug(l_debug_c,l_msg_data_s);

          ELSE
            l_msg_data_s := 'Unexpected Error in Swgcnv_CB_Cust_stgload_Pkg.check_cust_exists for Rec/Customer/Cust num: '
                            ||to_char(l_cust_rec.record_num)||'/'||l_cust_rec.customer_name||'/'|| l_cust_rec.customer_number||': '||SQLERRM;

            swg_cust_debug('Y',l_msg_data_s);
            dbms_output.put_line(l_msg_data_s);
            --Fnd_File.Put_Line(Fnd_File.LOG,l_msg_data_s);

            -- GOTO end_loop;
            RAISE ERROR_ENCOUNTERED;
          END IF;

        END IF; -- check_cust_exists

        Swg_cust_debug('Y','Before call to check bill addr');

        Swg_cust_debug('Y','Customer Number ='||l_cust_rec.customer_number||'/ Bill to address1= '||l_cust_rec.BILL_TO_ADDRESS1||'/ Bill to address 2=                                              '||l_cust_rec.BILL_TO_ADDRESS2||'/ Bill to city= '||l_cust_rec.BILL_TO_CITY||'/ Bill to State= '||l_cust_rec.BILL_TO_STATE
                                              ||'/BILL_TO_ZIP_CODE= '||l_cust_rec.BILL_TO_ZIP_CODE||'/ sales center= '||l_sales_center_s
                                              ||' /division = '||l_division_s);
--EB-1877 Replaced Bill_to_Postal_code with Bill_to_Zip_code 
        l_addr_id := check_bill_addr_exists( l_cust_rec.customer_number
                                            ,l_cust_rec.BILL_TO_ADDRESS1
                                            ,l_cust_rec.BILL_TO_ADDRESS2
                                            ,l_cust_rec.BILL_TO_CITY
                                            ,l_cust_rec.BILL_TO_STATE
                                            ,l_cust_rec.BILL_TO_ZIP_CODE
                                            ,l_sales_center_s                --'SAC'
                                            ,l_division_s                    --'BV10'
                                           );
        IF l_addr_id = -9 THEN

          SELECT SWGCNV.SWGCNV_CB_ADDR_ID_S.nextval
          INTO   l_addr_id_seq
          FROM   dual;

          INSERT INTO SWGCNV_DD_ADDRESSES (
                                                     ADDRESS_ID            --NUMBER(15)              NOT NULL,
                                                    ,CUSTOMER_ID           --NUMBER(15)              NOT NULL,
                                                    ,CUSTOMER_NUMBER       --VARCHAR2(10 BYTE)       NOT NULL,
                                                    ,ADDRESS1              --VARCHAR2(240 BYTE),
                                                    ,ADDRESS2              --VARCHAR2(240 BYTE),
                                                    ,ADDRESS3              --VARCHAR2(240 BYTE),
                                                    ,ADDRESS4              --VARCHAR2(240 BYTE),
                                                    ,CITY                  --VARCHAR2(60 BYTE),
                                                    ,STATE                 --VARCHAR2(60 BYTE),
                                                    ,PROVINCE              --VARCHAR2(60 BYTE),
                                                    ,COUNTY                --VARCHAR2(60 BYTE),
                                                    ,POSTAL_CODE           --VARCHAR2(60 BYTE),
                                                    ,COUNTRY               --VARCHAR2(60 BYTE)       NOT NULL,
                                                    ,LATITUDE              --VARCHAR2(150 BYTE),
                                                    ,LONGITUDE             --VARCHAR2(150 BYTE),
                                                    ,COMPLEX_TYPE          --VARCHAR2(150 BYTE),
                                                    ,VARIABLE_UNLOAD_TIME  --VARCHAR2(150 BYTE),
                                                    ,FIXED_UNLOAD_TIME     --VARCHAR2(150 BYTE),
                                                    ,DOCK_TYPE             --VARCHAR2(150 BYTE),
                                                    ,SALES_CENTER          --VARCHAR2(3 BYTE)        NOT NULL,
                                                    ,ADDR_CLEAN_UP_FLAG    --VARCHAR2(1 BYTE)        DEFAULT 'N',
                                                    ,DIVISION              --VARCHAR2(10 BYTE)       NOT NULL,
                                                    ,SEQ                   --NUMBER
                                                  )
           VALUES
                                                 (   l_addr_id_seq
                                                    ,l_cust_id
                                                    ,l_cust_rec.customer_number
                                                    ,l_cust_rec.BILL_TO_ADDRESS1
                                                    ,l_cust_rec.BILL_TO_ADDRESS2
                                                    ,NULL
                                                    ,NULL
                                                    ,l_cust_rec.BILL_TO_CITY
                                                    ,l_cust_rec.BILL_TO_STATE
                                                    ,NULL
                                                    ,NULL
                                                    ,l_cust_rec.BILL_TO_ZIP_CODE
                                                    ,'US'
                                                    ,NULL             -- lat. will be provided in a separate file
                                                    ,NULL             -- long. will be provided in a separate file
                                                    ,NULL
                                                    ,NULL
                                                    ,NULL
                                                    ,'ALL'
                                                    ,l_sales_center_s    --'SAC'
                                                    ,'N'
                                                    ,l_division_s        --'BV10'
                                                    ,NULL
                                                 );

           dbms_output.put_line('After addr insert');
           swg_cust_debug('Y','After addr insert');

           --insert l_addr_id_seq for address_id column, l_cust_id for customer_id column

           l_addr_id  := l_addr_id_seq;

           SELECT  SWGCNV.SWGCNV_CB_SITE_ID_S.nextval
           INTO    l_bill_site_id_seq
           FROM    dual;

          
           INSERT INTO SWGCNV_DD_CUSTOMER_BILLTO  (
                                 BILLTO_SITE_ID               --NUMBER(15)           NOT NULL,
                                ,CUSTOMER_ID                  --NUMBER(15)           NOT NULL,
                                ,BILL_TO_ADDRESS_ID           --NUMBER(15)           NOT NULL,
                                ,CUSTOMER_NUMBER              --VARCHAR2(10 BYTE)    NOT NULL,
                                ,BILLING_LOCATION_NUMBER      --VARCHAR2(10 BYTE)    NOT NULL,
                                ,PO_NUMBER                    --VARCHAR2(150 BYTE),
                                ,PO_EFFECTIVE_FROM_DATE       --VARCHAR2(150 BYTE),
                                ,PO_EFFECTIVE_TO_DATE         --VARCHAR2(150 BYTE),
                                ,PO_TOTAL_DOLLARS             --VARCHAR2(150 BYTE),
                                ,PO_TOTAL_UNITS               --VARCHAR2(150 BYTE),
                                ,CUSTOMER_REFERENCE_NUMBER    --VARCHAR2(150 BYTE),
                                ,REMIT_TO_ADDRESS             --VARCHAR2(150 BYTE)   NOT NULL,
                                ,CUSTOMER_PROFILE_CLASS_NAME  --VARCHAR2(30 BYTE)    NOT NULL,
                                ,PAYMENT_METHOD_NAME          --VARCHAR2(30 BYTE),
                                ,ACCOUNT_STATUS               --VARCHAR2(40 BYTE)    NOT NULL,
                                ,SALES_CENTER                 --VARCHAR2(3 BYTE)     NOT NULL,
                                ,DIVISION                     --VARCHAR2(50 BYTE)    NOT NULL,
                                ,STATEMENT_MAILED             --VARCHAR2(1 BYTE),
                                ,BILLING_CYCLE_DAY            --VARCHAR2(2 BYTE),
                                ,CYCLE_TYPE                   --NUMBER,
                                ,CREDIT_SCORE                 --VARCHAR2(4 BYTE),
                                ,PROTECT_FLAG                 --VARCHAR2(1 BYTE),
                                ,LATE_FEE_FLAG                --VARCHAR2(1 BYTE),
                                ,NEXT_DAY_INVOICE_FLAG        --VARCHAR2(1 BYTE),
                                ,BSC_FLAG                     --VARCHAR2(1 BYTE),
                                ,TERM_FEE_AMOUNT              --NUMBER,
                                ,AGREEMENT_TERM               --VARCHAR2(30 BYTE)
                                ,APPLY_TO_OLDEST
                                ,PAYMENT_TERMS
                               )
           VALUES
                               (
                                 l_bill_site_id_seq
                                ,l_cust_id
                                ,l_addr_id
                                ,l_cust_rec.customer_number
                                ,to_char(l_bill_site_id_seq)
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,NULL
                                ,'FUL'
                                ,l_cust_rec.customer_type
                                ,NULL           -- PAYMENT_METHOD_NAME
                                ,l_cust_rec.credit_class
                                ,l_sales_center_s           --'SAC'
                                ,l_division_s               --'BV10'
                                ,l_cust_rec.stmt_type       -- STATEMENT_MAILED
                                ,NULL                       -- BILLING_CYCLE_DAY
                                ,1          -- all SAGE customers MONTHLY only   -- IF 0 then 'PERIOD' ELSE IF 1 then 'MONTHLY'
                                ,DECODE( l_cust_rec.customer_type,'R','660','NOSC')
                                ,NULL       -- PROTECT_FLAG             -- Default from profile class
                                ,l_cust_rec.late_fee       -- LATE_FEE_FLAG
                                ,NULL
                                ,l_cust_rec.esc_fee       -- BSC_FLAG   --EB-1877              -- Default from Profile class (DFF: Fuel Surcharge Allowed ?)
                                ,0          -- TERM_FEE_AMOUNT          -- $100 by default (Agreement - Term Fee column) -- update later?
                                ,NULL       --'1 YEAR AGREEMENT'        -- AGREEMENT_TERM -- Default from the Agreement code (Agreement - Term Code column) -- update later?
                                ,l_cust_rec.APPLY_TO_OLDEST
                                ,NVL(l_cust_rec.PAYMENT_TERMS,'IMMEDIATE.')
                               );

           dbms_output.put_line('After bill-to-site-insert insert');
           swg_cust_debug('Y','After bill-to-site-insert insert');

           l_bill_site_id := l_bill_site_id_seq;

           -- Contact Info

           INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                   )
                            VALUES
                                ( l_cust_id
                                 ,l_addr_id
                                 ,l_first_name_s  -- Added by Bala Palani EB-670
                                 ,l_last_name_s  -- Proj 1359 SSB changed to handle ARS05 data differently.
                                 ,NVL(substr(l_cust_rec.primary_phone,1,3), '111')                  -- Added by Bala Palani EB-1156
                                 ,NVL(substr(l_cust_rec.primary_phone,4,10),'1111111')              -- Added by Bala Palani EB-1156
                                 ,substr(l_cust_rec.primary_phone,11)
                                 ,'PHONE'
                                 ,NULL
                               );
             
             ---EB-1877
              IF ( l_cust_rec.primary_bus_phone IS NOT NULL )  THEN
              
              INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_addr_id
                                 ,l_first_name_s  
                                 ,l_last_name_s  
                                 ,NVL(substr(l_cust_rec.primary_bus_phone,1,3), '111')                 
                                 ,NVL(substr(l_cust_rec.primary_bus_phone,4,10),'1111111')             
                                 ,substr(l_cust_rec.primary_bus_phone,11)
                                 ,'PHONE'
                                 ,NULL
                                );
              
              END IF;
              
             IF ( l_cust_rec.primary_cell_phone IS NOT NULL )  THEN
              
              INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_addr_id
                                 ,l_first_name_s  
                                 ,l_last_name_s  
                                 ,NVL(substr(l_cust_rec.primary_cell_phone,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.primary_cell_phone,4,10),'1111111')              
                                 ,substr(l_cust_rec.primary_cell_phone,11)
                                 ,'PHONE'
                                 ,NULL
                                );
              
              END IF;
              --EB-1877
               IF ( l_cust_rec.primary_email_address IS NOT NULL ) THEN

                  INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                     (   CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                        ,ADDRESS_ID           --NUMBER(15),
                        ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                        ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                        ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                        ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                        ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                        ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                        ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                        ,PRIMARY_EMAIL_FLAG
                     )
                  VALUES
                     (   l_cust_id
                        ,l_addr_id
                        ,l_first_name_s  --  Added by Bala Palani EB-670
                        ,l_last_name_s   -- Proj 1359 SSB changed to l_last_name_s
                        ,NVL(SUBSTR(l_cust_rec.primary_phone,1,3), '111')          -- Added by Bala Palani EB-1156
                        ,NVL(SUBSTR(l_cust_rec.primary_phone,4,10),'1111111')      -- Added by Bala Palani EB-1156
                        ,substr(l_cust_rec.primary_phone,11)
                        ,'EMAIL'
                        ,l_cust_rec.primary_email_address
                        ,'Y'
                     );

               END IF;
               
               --EB-1877 Contact2 and Contact3----
               
               IF (l_cust_rec.CONTACT2_LAST_NAME) IS NOT NULL THEN
               
                 IF  (l_cust_rec.Phone2)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_addr_id
                                 ,l_cust_rec.contact2_first_name  
                                 ,l_cust_rec.contact2_last_name  
                                 ,NVL(substr(l_cust_rec.Phone2,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.Phone2,4,10),'1111111')              
                                 ,substr(l_cust_rec.Phone2,11)
                                 ,'PHONE'
                                 ,NULL
                                );
                 
                  END IF;
                 
                 IF  (l_cust_rec.bus_phone2)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_addr_id
                                 ,l_cust_rec.contact2_first_name  
                                 ,l_cust_rec.contact2_last_name  
                                 ,NVL(substr(l_cust_rec.bus_phone2,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.bus_phone2,4,10),'1111111')              
                                 ,substr(l_cust_rec.bus_phone2,11)
                                 ,'PHONE'
                                 ,NULL
                                );
               
                 
                 END IF; 
                 
                 IF  (l_cust_rec.cell_phone2)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_addr_id
                                 ,l_cust_rec.contact2_first_name  
                                 ,l_cust_rec.contact2_last_name 
                                 ,NVL(substr(l_cust_rec.cell_phone2,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.cell_phone2,4,10),'1111111')              
                                 ,substr(l_cust_rec.cell_phone2,11)
                                 ,'PHONE'
                                 ,NULL
                                );
                 
                 END IF;
                 
                 IF  (l_cust_rec.email_address2)  IS NOT NULL THEN
                 
                  INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                     (   CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                        ,ADDRESS_ID           --NUMBER(15),
                        ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                        ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                        ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                        ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                        ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                        ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                        ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                     )
                  VALUES
                     (   l_cust_id
                        ,l_addr_id
                        ,l_cust_rec.contact2_first_name  
                        ,l_cust_rec.contact2_last_name  
                        ,NVL(SUBSTR(l_cust_rec.phone2,1,3), '111')          
                        ,NVL(SUBSTR(l_cust_rec.phone2,4,10),'1111111')     
                        ,substr(l_cust_rec.phone2,11)
                        ,'EMAIL'
                        ,l_cust_rec.email_address2
                     );
                 
                 END IF;
               
               
               END IF;
               
               
               IF (l_cust_rec.CONTACT3_LAST_NAME) IS NOT NULL THEN
               
                 IF  (l_cust_rec.Phone3)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_addr_id
                                 ,l_cust_rec.contact3_first_name  
                                 ,l_cust_rec.contact3_last_name  
                                 ,NVL(substr(l_cust_rec.Phone3,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.Phone3,4,10),'1111111')              
                                 ,substr(l_cust_rec.Phone3,11)
                                 ,'PHONE'
                                 ,NULL
                                );
                 
                  END IF;
                 
                 IF  (l_cust_rec.bus_phone3)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_addr_id
                                 ,l_cust_rec.contact3_first_name  
                                 ,l_cust_rec.contact3_last_name  
                                 ,NVL(substr(l_cust_rec.bus_phone3,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.bus_phone3,4,10),'1111111')              
                                 ,substr(l_cust_rec.bus_phone3,11)
                                 ,'PHONE'
                                 ,NULL
                                );
               
                 
                 END IF; 
                 
                 IF  (l_cust_rec.cell_phone3)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_addr_id
                                 ,l_cust_rec.contact3_first_name  
                                 ,l_cust_rec.contact3_last_name 
                                 ,NVL(substr(l_cust_rec.cell_phone3,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.cell_phone3,4,10),'1111111')              
                                 ,substr(l_cust_rec.cell_phone3,11)
                                 ,'PHONE'
                                 ,NULL
                                );
                 
                 END IF;
                 
                 IF  (l_cust_rec.email_address3)  IS NOT NULL THEN
                 
                  INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                     (   CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                        ,ADDRESS_ID           --NUMBER(15),
                        ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                        ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                        ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                        ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                        ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                        ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                        ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                     )
                  VALUES
                     (   l_cust_id
                        ,l_addr_id
                        ,l_cust_rec.contact3_first_name  
                        ,l_cust_rec.contact3_last_name  
                        ,NVL(SUBSTR(l_cust_rec.phone3,1,3), '111')          
                        ,NVL(SUBSTR(l_cust_rec.phone3,4,10),'1111111')     
                        ,substr(l_cust_rec.phone3,11)
                        ,'EMAIL'
                        ,l_cust_rec.email_address3
                     );
                 
                 END IF;
               
               END IF;
               
               --EB-1877 Contact2 and Contact3----

          dbms_output.put_line('After bill-to-phone insert');
          swg_cust_debug('Y','After bill-to-site-insert insert');

        ELSE

          IF g_error_flag_c != 'Y' THEN

            l_msg_data_s := 'Rec/Customer/Cust num/bill addr already exists in staging table: '
                             ||to_char(l_cust_rec.record_num)||'/'||l_cust_rec.customer_name||'/'|| l_cust_rec.customer_number;

            dbms_output.put_line(l_msg_data_s);
            --Fnd_File.Put_Line(Fnd_File.LOG,l_msg_data_s);
            swg_cust_debug(l_debug_c,l_msg_data_s);

            -- VG 8/7/2007 SAVKC INSERT IF CUSTOMER_CONTACT NOT EXISTS
            -- check if cust contact exists.

            IF l_cust_rec.primary_phone IS NOT NULL THEN

              IF NOT check_cust_contact_exists( l_cust_id
                                               ,l_addr_id
                                               ,substr(l_cust_rec.primary_phone,1,3)
                                               ,nvl(substr(l_cust_rec.primary_phone,4),'NONE')
                                               ,NULL
                                              ) THEN

                dbms_output.put_line('Before Phone contract insert');

                INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                                                ,ADDRESS_ID           --NUMBER(15),
                                                                ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                                                ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                                                ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                                                ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                                                ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                                                ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                                                ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                                              )
                VALUES
                       (  l_cust_id
                         ,l_addr_id
                         ,l_first_name_s   -- Added by Bala Palani EB-670
                         ,l_last_name_s     -- Proj 1359 SSB changed to handle ARS05 differently
                         ,substr(l_cust_rec.primary_phone,1,3)
                         ,nvl(substr(l_cust_rec.primary_phone,4,10),'NONE')
                         ,substr(l_cust_rec.primary_phone,11)
                         ,'PHONE'
                         ,NULL
                       );
                       
            dbms_output.put_line('After cust contact insert');
                swg_cust_debug('Y','After cust contact insert');

              END IF; -- end if check_cust_contact_exists

            END IF; -- end if l_cust_rec.phone is null

            IF l_cust_rec.primary_email_address IS NOT NULL THEN

              IF NOT check_cust_contact_exists( l_cust_id
                                               ,l_addr_id
                                               ,NULL
                                               ,NULL
                                               ,l_cust_rec.primary_email_address
                                              ) THEN

                dbms_output.put_line('Before Email contract insert');

                INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                                                ,ADDRESS_ID           --NUMBER(15),
                                                                ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                                                ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                                                ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                                                ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                                                ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                                                ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                                                ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                                                ,PRIMARY_EMAIL_FLAG
                                                              )
                VALUES
                       (  l_cust_id
                         ,l_addr_id
                         ,l_first_name_s       -- Added by Bala Palani EB-670
                         ,l_last_name_s        -- Proj 1359 SSB changed to handle ARS05 differently per Val
                         ,NVL(SUBSTR(l_cust_rec.primary_phone,1,3), '111')         -- Added by Bala Palani EB-1156
                         ,NVL(SUBSTR(l_cust_rec.primary_phone,4,10),'1111111')     -- Added by Bala Palani EB-1156
                         ,substr(l_cust_rec.primary_phone,11)
                         ,'EMAIL'
                         ,l_cust_rec.primary_email_address
                         ,'Y'
                       );

                dbms_output.put_line('After email cust contact insert');
                swg_cust_debug('Y','After email cust contact insert');

              END IF; -- end if check_cust_contact_exists

            END IF; -- end if l_cust_rec.email_address is null

            l_bill_site_id      := get_bill_site_id( l_cust_id
                                                    ,l_addr_id
                                                    ,l_cust_rec.CUSTOMER_NUMBER
                                                    ,l_sales_center_s         --'SAC'
                                                    ,l_division_s             --'BV10'
                                                   );

            IF (g_error_flag_c != 'N' OR l_bill_site_id = -99) THEN

              l_msg_data_s := 'Unexpected Error/no data found in Swgcnv_CB_Cust_stgload_Pkg.get_bill_site_id for Rec/Customer/Cust num: '
                               ||to_char(l_cust_rec.record_num)||'/'||l_cust_rec.customer_name||'/'|| l_cust_rec.customer_number||': '||SQLERRM;

              swg_cust_debug('Y',l_msg_data_s);
              dbms_output.put_line(l_msg_data_s);
              --Fnd_File.Put_Line(Fnd_File.LOG,l_msg_data_s);
              -- GOTO end_loop;

              RAISE ERROR_ENCOUNTERED;

            END IF;

          ELSE

            l_msg_data_s := 'Unexpected Error in Swgcnv_CB_Cust_stgload_Pkg.check_bill_addr_exists for Rec/Customer/Cust num: '
                            ||to_char(l_cust_rec.record_num)||'/'||l_cust_rec.customer_name||'/'|| l_cust_rec.customer_number||': '||SQLERRM;

            swg_cust_debug('Y',l_msg_data_s);
            dbms_output.put_line(l_msg_data_s);
            --Fnd_File.Put_Line(Fnd_File.LOG,l_msg_data_s);

            -- GOTO end_loop;
            RAISE ERROR_ENCOUNTERED;

          END IF;

        END IF; -- check_bill_addr_exists

        swg_cust_debug(l_debug_c,'Bill site ID = '||to_char(l_bill_site_id));
        -- Handle case for bill to = ship to

        IF (     l_cust_rec.BILL_TO_ADDRESS1             =      l_cust_rec.SHIP_TO_ADDRESS1
            AND  nvl(l_cust_rec.BILL_TO_ADDRESS2,'X')    =      nvl(l_cust_rec.SHIP_TO_ADDRESS2,'X')
            AND  l_cust_rec.BILL_TO_CITY                 =      l_cust_rec.SHIP_TO_CITY
            AND  l_cust_rec.BILL_TO_STATE                =      l_cust_rec.SHIP_TO_STATE
            AND  l_cust_rec.BILL_TO_ZIP_CODE          =      l_cust_rec.SHIP_TO_ZIP_CODE
           ) THEN
--EB-1877 Replaced Bill_to_Postal_code with Bill_to_Zip_code 
          swg_cust_debug(l_debug_c,'Before call to ship-to-site-id');

          swg_cust_debug(l_debug_c,'Cust_id= '||to_char(l_cust_id)||'/ Addr Id = '||to_char(l_addr_id)||'/ Bill site id= '||to_char(l_bill_site_id)
                                              ||'/ Customer number= '||l_cust_rec.CUSTOMER_NUMBER||'Sales/center/division ='||l_sales_center_s
                                              ||'/'||l_division_s);

          l_ship_site_id := get_ship_to_site_id( l_cust_id
                                                ,l_addr_id
                                                ,l_bill_site_id
                                                ,l_cust_rec.CUSTOMER_NUMBER
                                                ,l_sales_center_s             --'SAC'
                                                ,l_division_s                 --'BV10'
                                               );
          IF l_ship_site_id = -99 THEN

            l_ship_addr_id := l_addr_id;

            SELECT SWGCNV.SWGCNV_CB_SITE_ID_S.nextval
            INTO   l_ship_site_id_seq
            FROM   dual;

            dbms_output.put_line('Before 1st ship-to-site insert');
            swg_cust_debug('Y','Before 1st ship-to-site insert');

            INSERT INTO SWGCNV_DD_CUSTOMER_SHIPTO  (
                                 SHIPTO_SITE_ID               --NUMBER(15)        NOT NULL,
                                ,CUSTOMER_ID                  --NUMBER(15)        NOT NULL,
                                ,SHIP_TO_ADDRESS_ID           --NUMBER(15)        NOT NULL,
                                ,BILLING_SITE_ID              --NUMBER(15)        NOT NULL,
                                ,CUSTOMER_NUMBER              --VARCHAR2(10 BYTE) NOT NULL,
                                ,DELIVERY_LOCATION_NUMBER     --VARCHAR2(10 BYTE) NOT NULL,
                                ,CUSTOMER_TAX_CLASS           --VARCHAR2(150 BYTE),
                                ,PO_NUMBER                    --VARCHAR2(150 BYTE),
                                ,PO_EFFECTIVE_FROM_DATE       --VARCHAR2(150 BYTE),
                                ,PO_EFFECTIVE_TO_DATE         --VARCHAR2(150 BYTE),
                                ,PO_TOTAL_DOLLARS             --VARCHAR2(150 BYTE),
                                ,PO_TOTAL_UNITS               --VARCHAR2(150 BYTE),
                                ,CUSTOMER_REFERENCE_NUMBER    --VARCHAR2(150 BYTE),
                                ,TAX_EXEMPT_NUMBER            --VARCHAR2(150 BYTE),
                                ,TAX_EXEMPT_EXP_DATE          --VARCHAR2(150 BYTE),
                                ,TAX_EXEMPT_CERTIFICATE_RCVD  --VARCHAR2(150 BYTE),
                                ,SALES_CENTER                 --VARCHAR2(3 BYTE)    NOT NULL,
                                ,DIVISION                     --VARCHAR2(50 BYTE)   NOT NULL,
                                ,ROUTE_NUMBER                 --VARCHAR2(10 BYTE),
                                ,ROUTE_DELIVERY_FREQUENCY     --VARCHAR2(10 BYTE),
                                ,NEXT_REGULAR_DELIVER_DATE    --DATE,
                                ,DELIVERY_INSTRUCTIONS        --VARCHAR2(1000 BYTE),
                                ,ROUTE_MESSAGE                --VARCHAR2(240 BYTE),
                                ,COLLECTION_MESSAGE           --VARCHAR2(240 BYTE),
                                ,ADDRESSEE                    --VARCHAR2(100 BYTE),
                                ,FREQUENCY                    --VARCHAR2(10 BYTE),
                                ,CUSTOMER_START_DATE          --DATE,
                                ,SHIP_TO_START_DATE           --DATE,
                                ,SUPPRESS_PRICE_HH_TICKET     --VARCHAR2(1 BYTE),
                                ,RSR_OVERIDE_SUPPRESS_PRICE   --VARCHAR2(1 BYTE),
                                ,BOTTLE_INITIAL_INVENTORY     --VARCHAR2(3 BYTE),
                                ,RATE_SCHEDULE                --VARCHAR2(4 BYTE),
                                ,CHARGE_DEPOSIT               --VARCHAR2(1 BYTE),
                                ,PREFERRED_CUSTOMER_FLAG      --VARCHAR2(1 BYTE),
                                ,PENDING                      --VARCHAR2(1 BYTE),
                                ,BSC_FLAG                     --VARCHAR2(1 BYTE),
                                ,CREDIT_SCORE                 --VARCHAR2(4 BYTE),
                                ,TERM_FEE_AMOUNT              --NUMBER,
                                ,AGREEMENT_TERM               --VARCHAR2(30 BYTE),
                                ,BOTTLE_DEPOSIT_AMT           --NUMBER,
                                ,DELIVERY_TICKET_PRINT_FLAG   --VARCHAR2(1 BYTE),
                                ,TIER_PRICE_PROC_FLAG         --VARCHAR2(1 BYTE)   DEFAULT 'N',
                                ,BOT_DEPOSIT_PROC_FLAG        --VARCHAR2(1 BYTE)   DEFAULT 'N'
                                --,HOLD_REASON                --VARCHAR2(10),
                                ,WILL_CALL_FLAG             --VARCHAR2(1)    -- re-activated this columns to fetch will call flag data from the prestaging cust tab by Bala Palani as per WO 19982
                                ,PRICE_LIST_NAME                              -- Added by Bala Palani as per WO : 19982
                                )
                        VALUES
                         ( l_ship_site_id_seq
                          ,l_cust_id
                          ,l_ship_addr_id
                          ,l_bill_site_id
                          ,l_cust_rec.customer_number
                          ,to_char(l_ship_addr_id) --to_char(l_ship_site_id_seq) -- where bill to = ship to, the customer code is populating reference field same for both
                         -- ,decode(l_cust_rec.sales_tax,'EX','EXEMPT','TAXABLE')   Removed  Decode Condition as per  EB-2058
                          ,l_cust_rec.sales_tax
                          ,l_cust_rec.SHIP_TO_PO_NUM
                          ,NULL
                          ,NULL
                          ,NULL
                          ,NULL
                          ,l_cust_rec.ship_to_reference_num  --EB-1877
                         -- ,DECODE(l_cust_rec.sales_tax,'EX','ON FILE',NULL)     Removed  Decode Condition as per  EB-2058  AND Added new field as per EB-2058
                          ,l_cust_rec.TAX_EXEMPT_NUM
                          ,NULL
                         -- ,decode(l_cust_rec.sales_tax,'EX','Y','N')            Removed  Decode Condition as per  EB-2058  AND Added new field as per EB-2058
                          ,l_cust_rec.TAX_CERT_RECVD
                          ,l_sales_center_s                 --  'SAC'
                          ,l_division_s                     --  'BV10'
                          ,get_mapped_value(l_system_name_s,'ROUTES',l_cust_rec.route_number,l_sales_center_s)
                          ,l_cust_rec.delivery_frequency   -- Added PU 4/24/2008
                        ,NULL       -- NEXT_REGULAR_DELIVER_DATE -- Not used in Oracle, it is calculated when you query the PPF
                        ,NULL       -- DELIVERY_INSTRUCTIONS -- INSERTED AS A NOTE ON THE PPF.SWGRTM_NOTES.NOTE_TEXT; 01/24/07:  Alert file will have this data
                        ,NULL
                        ,NULL
                        ,l_cust_rec.addressee   -- ADDRESSEE     -- Populate from BILL to Master on Customer file: will be updated later on in code
                        ,l_cust_rec.delivery_frequency -- Added PU 4/24/2008
                        ,l_cust_rec.CUST_START_DATE
                        ,l_cust_rec.CUST_START_DATE
                        ,'Y'            -- SUPPRESS_PRICE_HH_TICKET
                        ,'Y'            --  RSR_OVERIDE_SUPPRESS_PRICE
                        ,NULL           --  BOTTLE_INITIAL_INVENTORY
                        ,NULL           --  RATE_SCHEDULE
                        ,'Y'            -- Default to Y for all Ship Tos  -- CHARGE_DEPOSIT
                        ,'N'            -- PREFERRED_CUSTOMER_FLAG
                        ,NULL           -- PENDING
                        ,l_cust_rec.esc_fee            -- ESC_FLAG --EB-1877
                        ,NULL           -- CREDIT_SCORE -- 01/24/07:  Val will map it
                        ,0              -- TERM_FEE_AMOUNT -- $100 by default (Agreement - Term Fee column) -- update later?
                        ,'GFAGR'        -- AGREEMENT_TERM -- Default from the Agreement code (Agreement - Term Code column) -- update later?
                        ,NULL           -- BOTTLE_DEPOSIT_AMT -- If the amount in this field is different that what is on the price list then
                        ,l_cust_rec.print_delivery_tickets            -- DELIVERY_TICKET_PRINT_FLAG  --EB-1877
                        ,'N'            -- TIER_PRICE_PROC_FLAG
                        ,'N'            -- BOT_DEPOSIT_PROC_FLAG
                        , l_cust_rec.ON_REQUEST_FLAG               -- re-activated this columns to fetch will call flag data from the prestaging cust tab by Bala Palani as per WO 19982
                        ,swgcnv_get_restrctd_prclst(l_system_name_s, l_cust_rec.customer_number)       -- Added by Bala Palani as per WO : 19982
                );
            -- VGOLI 8/4/2007 END

            dbms_output.put_line('After 1st ship-to-site insert');
            swg_cust_debug('Y','After 1st ship-to-site insert');

            l_ship_site_id      :=      l_ship_addr_id; --l_ship_site_id_seq -- reference field is same for bill to = ship to address

            -- Contact Info

            INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                    (    CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                        ,ADDRESS_ID           --NUMBER(15),
                        ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                        ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                        ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                        ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                        ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                        ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                        ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                          )
            VALUES
                    (    l_cust_id
                        ,l_addr_id
                        ,l_first_name_s     -- Added by Bala Palani EB-670
                        ,l_last_name_s      -- Proj 1359 SSB changed per Val for ARS05
                        ,NVL(substr(l_cust_rec.primary_phone,1,3), '111')                 -- Added by Bala Palani EB-1156
                        ,NVL(substr(l_cust_rec.primary_phone,4,10),'1111111')             -- Added by Bala Palani EB-1156
                        ,substr(l_cust_rec.primary_phone,11)
                        ,'PHONE'
                        ,NULL
                    );

                  ---EB-1877
              IF ( l_cust_rec.primary_bus_phone IS NOT NULL )  THEN
              
              INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_addr_id
                                 ,l_first_name_s  
                                 ,l_last_name_s  
                                 ,NVL(substr(l_cust_rec.primary_bus_phone,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.primary_bus_phone,4,10),'1111111')             
                                 ,substr(l_cust_rec.primary_bus_phone,11)
                                 ,'PHONE'
                                 ,NULL
                                );
              
              END IF;
              
             IF ( l_cust_rec.primary_cell_phone IS NOT NULL )  THEN
              
              INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_addr_id
                                 ,l_first_name_s  
                                 ,l_last_name_s  
                                 ,NVL(substr(l_cust_rec.primary_cell_phone,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.primary_cell_phone,4,10),'1111111')              
                                 ,substr(l_cust_rec.primary_cell_phone,11)
                                 ,'PHONE'
                                 ,NULL
                                );
              
              END IF;
              --EB-1877

               -- Added For SAGE Conversion
               IF ( l_cust_rec.primary_email_address IS NOT NULL ) THEN

                  INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                     (   CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                        ,ADDRESS_ID           --NUMBER(15),
                        ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                        ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                        ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                        ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                        ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                        ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                        ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                        ,PRIMARY_EMAIL_FLAG
                     )
                  VALUES
                     (   l_cust_id
                        ,l_addr_id
                        ,l_first_name_s                       -- Added by Bala Palani EB-670
                        ,l_last_name_s                        -- Proj 1359 SSB to make it more generic
                        ,NVL(SUBSTR(l_cust_rec.primary_phone,1,3), '111')                    -- Added by Bala Palani EB-1156
                        ,NVL(SUBSTR(l_cust_rec.primary_phone,4,10),'1111111')     -- Added by Bala Palani EB-1156
                        ,substr(l_cust_rec.primary_phone,11)
                        ,'EMAIL'
                        ,l_cust_rec.primary_email_address
                        ,'Y'
                     );

               END IF;
               -- Added For SAGE Conversion
               
                         
               --EB-1877 Contact2 and Contact3----
               
               IF (l_cust_rec.CONTACT2_LAST_NAME) IS NOT NULL THEN
               
                 IF  (l_cust_rec.Phone2)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_addr_id
                                 ,l_cust_rec.contact2_first_name  
                                 ,l_cust_rec.contact2_last_name  
                                 ,NVL(substr(l_cust_rec.Phone2,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.Phone2,4,10),'1111111')              
                                 ,substr(l_cust_rec.Phone2,11)
                                 ,'PHONE'
                                 ,NULL
                                );
                 
                  END IF;
                 
                 IF  (l_cust_rec.bus_phone2)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_addr_id
                                 ,l_cust_rec.contact2_first_name  
                                 ,l_cust_rec.contact2_last_name  
                                 ,NVL(substr(l_cust_rec.bus_phone2,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.bus_phone2,4,10),'1111111')              
                                 ,substr(l_cust_rec.bus_phone2,11)
                                 ,'PHONE'
                                 ,NULL
                                );
               
                 
                 END IF; 
                 
                 IF  (l_cust_rec.cell_phone2)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_addr_id
                                 ,l_cust_rec.contact2_first_name  
                                 ,l_cust_rec.contact2_last_name 
                                 ,NVL(substr(l_cust_rec.cell_phone2,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.cell_phone2,4,10),'1111111')              
                                 ,substr(l_cust_rec.cell_phone2,11)
                                 ,'PHONE'
                                 ,NULL
                                );
                 
                 END IF;
                 
                 IF  (l_cust_rec.email_address2)  IS NOT NULL THEN
                 
                  INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                     (   CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                        ,ADDRESS_ID           --NUMBER(15),
                        ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                        ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                        ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                        ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                        ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                        ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                        ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                     )
                  VALUES
                     (   l_cust_id
                        ,l_addr_id
                        ,l_cust_rec.contact2_first_name  
                        ,l_cust_rec.contact2_last_name  
                        ,NVL(SUBSTR(l_cust_rec.phone2,1,3), '111')          
                        ,NVL(SUBSTR(l_cust_rec.phone2,4,10),'1111111')     
                        ,substr(l_cust_rec.phone2,11)
                        ,'EMAIL'
                        ,l_cust_rec.email_address2
                     );
                 
                 END IF;
               
               
               END IF;
               
               
               IF (l_cust_rec.CONTACT3_LAST_NAME) IS NOT NULL THEN
               
                 IF  (l_cust_rec.Phone3)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_addr_id
                                 ,l_cust_rec.contact3_first_name  
                                 ,l_cust_rec.contact3_last_name  
                                 ,NVL(substr(l_cust_rec.Phone3,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.Phone3,4,10),'1111111')              
                                 ,substr(l_cust_rec.Phone3,11)
                                 ,'PHONE'
                                 ,NULL
                                );
                 
                  END IF;
                 
                 IF  (l_cust_rec.bus_phone3)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_addr_id
                                 ,l_cust_rec.contact3_first_name  
                                 ,l_cust_rec.contact3_last_name  
                                 ,NVL(substr(l_cust_rec.bus_phone3,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.bus_phone3,4,10),'1111111')              
                                 ,substr(l_cust_rec.bus_phone3,11)
                                 ,'PHONE'
                                 ,NULL
                                );
               
                 
                 END IF; 
                 
                 IF  (l_cust_rec.cell_phone3)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_addr_id
                                 ,l_cust_rec.contact3_first_name  
                                 ,l_cust_rec.contact3_last_name 
                                 ,NVL(substr(l_cust_rec.cell_phone3,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.cell_phone3,4,10),'1111111')              
                                 ,substr(l_cust_rec.cell_phone3,11)
                                 ,'PHONE'
                                 ,NULL
                                );
                 
                 END IF;
                 
                 IF  (l_cust_rec.email_address3)  IS NOT NULL THEN
                 
                  INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                     (   CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                        ,ADDRESS_ID           --NUMBER(15),
                        ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                        ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                        ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                        ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                        ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                        ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                        ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                     )
                  VALUES
                     (   l_cust_id
                        ,l_addr_id
                        ,l_cust_rec.contact3_first_name  
                        ,l_cust_rec.contact3_last_name  
                        ,NVL(SUBSTR(l_cust_rec.phone3,1,3), '111')          
                        ,NVL(SUBSTR(l_cust_rec.phone3,4,10),'1111111')     
                        ,substr(l_cust_rec.phone3,11)
                        ,'EMAIL'
                        ,l_cust_rec.email_address3
                     );
                 
                 END IF;
               
               END IF;
               
               --EB-1877 Contact2 and Contact3----   

            -- also enter shipcycle days
            l_delivery_freq_s := l_cust_rec.delivery_frequency;
            

            INSERT INTO SWGCNV_DD_CYCLEDAYS
                    (    CUSTOMER_ID           --NUMBER(15),
                        ,SHIPPING_SITE_ID      --NUMBER(15),
                        ,ROUTE_SERVICE_DAY     --VARCHAR2(2 BYTE),
                        ,ROUTE_SEQUENCE        --NUMBER(15),
                        ,CYCLE_DAY             --VARCHAR2(2 BYTE),
                        ,DRIVING_INSTRUCTIONS  --VARCHAR2(2000 BYTE)
                    )
            VALUES
                    (    l_cust_id
                        ,l_ship_site_id_seq    --l_ship_site_id -- the Prj_Purch code is looking at shipto_site_id=shipping_site_id
                        ,l_new_code_s
                        ,to_number(l_cust_rec.route_seq)
                        ,l_new_code_s
                        ,NULL
                    );

            if nvl(l_delivery_freq_s,'2') = '0' then

              INSERT INTO SWGCNV_DD_CYCLEDAYS
                     (   CUSTOMER_ID           --NUMBER(15),
                        ,SHIPPING_SITE_ID      --NUMBER(15),
                        ,ROUTE_SERVICE_DAY     --VARCHAR2(2 BYTE),
                        ,ROUTE_SEQUENCE        --NUMBER(15),
                        ,CYCLE_DAY             --VARCHAR2(2 BYTE),
                        ,DRIVING_INSTRUCTIONS  --VARCHAR2(2000 BYTE)
                     )
              VALUES
                    (    l_cust_id
                        ,l_ship_site_id_seq        --l_ship_site_id -- the Prj_Purch code is looking at shipto_site_id=shipping_site_id
                        ,l_new_code_s
                        ,to_number(l_cust_rec.route_seq)
                        ,l_new_code_s
                        ,NULL
                    );

            END IF;

            --insert l_cust_id for customer_id column, l_ship_site_id for shipping_site_id column

          ELSE

            l_msg_data_s := 'Rec/Customer/Cust num/ship addr,shipto_loc,shp_cycle_days,contacts already exists in staging table (bill to same as ship to): '
                             ||to_char(l_cust_rec.record_num)||'/'||l_cust_rec.customer_name||'/'|| l_cust_rec.customer_number;

            dbms_output.put_line(l_msg_data_s);
            --Fnd_File.Put_Line(Fnd_File.LOG,l_msg_data_s);
            swg_cust_debug(l_debug_c,l_msg_data_s);

            l_ship_site_id  :=   l_addr_id;

            -- VG 8/7/2007 SAVKC INSERT IF CUSTOMER_CONTACT NOT EXISTS
            -- check if cust contact exists.

            IF l_cust_rec.primary_phone IS NOT NULL THEN

              IF NOT check_cust_contact_exists(  l_cust_id
                                                ,l_addr_id
                                                ,substr(l_cust_rec.primary_phone,1,3)
                                                ,nvl(substr(l_cust_rec.primary_phone,4),'NONE')
                                                ,NULL
                                              ) THEN

                 dbms_output.put_line('Before phone contract insert');

                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                        (    CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                            ,ADDRESS_ID           --NUMBER(15),
                            ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                            ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                            ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                            ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                            ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                            ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                            ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                        )
                 VALUES
                        (   l_cust_id
                           ,l_addr_id
                           ,l_first_name_s   -- Added by Bala Palani EB-670
                           ,l_last_name_s    -- Proj 1359 SSB per Val
                           ,NVL(substr(l_cust_rec.primary_phone,1,3),'111')         -- Added by Bala Palani EB-1156
                           ,NVL(substr(l_cust_rec.primary_phone,4,10),'1111111')    -- Added by Bala Palani EB-1156
                           ,substr(l_cust_rec.primary_phone,11)
                           ,'PHONE'
                           ,NULL
                        );
                        
                dbms_output.put_line('After ADDITIONAL cust contact insert');
                swg_cust_debug('Y','After ADDITIONAL cust contact insert');

              END IF; -- end if check_cust_contact_exists

            END IF; -- end if l_cust_rec.phone is null

            -- Added For Mayberry Project

            IF l_cust_rec.primary_email_address IS NOT NULL THEN

              IF NOT check_cust_contact_exists(  l_cust_id
                                                ,l_addr_id
                                                ,NULL
                                                ,NULL
                                                ,l_cust_rec.primary_email_address
                                              ) THEN

                 dbms_output.put_line('Before email contract insert');

                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                        (    CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                            ,ADDRESS_ID           --NUMBER(15),
                            ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                            ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                            ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                            ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                            ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                            ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                            ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                            ,PRIMARY_EMAIL_FLAG
                        )
                 VALUES
                        (   l_cust_id
                           ,l_addr_id
                           ,l_first_name_s   -- Added by Bala Palani EB-670                                                                -- Added by Bala Palani EB-670
                           ,l_last_name_s  -- Proj 1359 SSB changed per Val
                           ,NVL(SUBSTR(l_cust_rec.primary_phone,1,3), '111')                       -- Added by Bala Palani EB-1156
                           ,NVL(SUBSTR(l_cust_rec.primary_phone,4,10),'1111111')                   -- Added by Bala Palani EB-1156
                           ,substr(l_cust_rec.primary_phone,11)
                           ,'EMAIL'
                           ,l_cust_rec.primary_email_address
                           ,'Y'
                        );

                dbms_output.put_line('After email cust contact insert');
                swg_cust_debug('Y','After email cust contact insert');

              END IF; -- end if check_cust_contact_exists

            END IF; -- end if l_cust_rec.email_address is null

            -- Added For Mayberry Project

          -- VG 8/7/2007 SAVKC END INSERT IF CUSTOMER_CONTACT NOT EXISTS

          END IF;

        ELSE  -- bill address fields <> ship address fields

          dbms_output.put_line('In ELSE for bill-to <> ship-to');
          swg_cust_debug('Y','In ELSE for bill-to <> ship-to');

          l_ship_addr_id   :=  check_ship_addr_exists( l_cust_rec.customer_number
                                                       ,l_cust_rec.SHIP_TO_ADDRESS1
                                                       ,l_cust_rec.SHIP_TO_ADDRESS2
                                                       ,l_cust_rec.customer_name     -- Added For SAGE Conversion
                                                       ,l_cust_rec.SHIP_TO_CITY
                                                       ,l_cust_rec.SHIP_TO_STATE
                                                       ,l_cust_rec.SHIP_TO_ZIP_CODE
                                                       ,l_sales_center_s                 --'SAC'
                                                       ,l_division_s                     --'BV10'
                                                      );

           IF l_ship_addr_id = -9 THEN

            SELECT SWGCNV.SWGCNV_CB_ADDR_ID_S.nextval
            INTO   l_ship_addr_id_seq
            FROM   dual;

            INSERT INTO SWGCNV_DD_ADDRESSES
                (    ADDRESS_ID            --NUMBER(15)              NOT NULL,
                    ,CUSTOMER_ID           --NUMBER(15)              NOT NULL,
                    ,CUSTOMER_NUMBER       --VARCHAR2(10 BYTE)       NOT NULL,
                    ,ADDRESS1              --VARCHAR2(240 BYTE),
                    ,ADDRESS2              --VARCHAR2(240 BYTE),
                    ,ADDRESS3              --VARCHAR2(240 BYTE),
                    ,ADDRESS4              --VARCHAR2(240 BYTE),
                    ,CITY                  --VARCHAR2(60 BYTE),
                    ,STATE                 --VARCHAR2(60 BYTE),
                    ,PROVINCE              --VARCHAR2(60 BYTE),
                    ,COUNTY                --VARCHAR2(60 BYTE),
                    ,POSTAL_CODE           --VARCHAR2(60 BYTE),
                    ,COUNTRY               --VARCHAR2(60 BYTE)       NOT NULL,
                    ,LATITUDE              --VARCHAR2(150 BYTE),
                    ,LONGITUDE             --VARCHAR2(150 BYTE),
                    ,COMPLEX_TYPE          --VARCHAR2(150 BYTE),
                    ,VARIABLE_UNLOAD_TIME  --VARCHAR2(150 BYTE),
                    ,FIXED_UNLOAD_TIME     --VARCHAR2(150 BYTE),
                    ,DOCK_TYPE             --VARCHAR2(150 BYTE),
                    ,SALES_CENTER          --VARCHAR2(3 BYTE)        NOT NULL,
                    ,ADDR_CLEAN_UP_FLAG    --VARCHAR2(1 BYTE)        DEFAULT 'N',
                    ,DIVISION              --VARCHAR2(10 BYTE)       NOT NULL,
                    ,SEQ                   --NUMBER
                )
            VALUES
                (    l_ship_addr_id_seq
                    ,l_cust_id
                    ,l_cust_rec.customer_number
                    ,l_cust_rec.ship_to_address1
                    ,l_cust_rec.ship_to_address2
                    ,l_cust_rec.customer_name      -- Added For SAGE Conversion
                    ,NULL
                    ,l_cust_rec.SHIP_TO_CITY
                    ,l_cust_rec.SHIP_TO_STATE
                    ,NULL
                    ,NULL
                    ,l_cust_rec.SHIP_TO_ZIP_CODE
                    ,'US'
                    ,NULL           -- lat. will be provided in a separate file
                    ,NULL           -- long. will be provided in a separate file
                    ,NULL
                    ,NULL
                    ,NULL
                    ,'ALL'
                    ,l_sales_center_s       --'SAC'
                    ,'N'
                    ,l_division_s           --'BV10'
                    ,NULL
                );

             --insert l_addr_id_seq for address_id column, l_cust_id for customer_id column
             dbms_output.put_line('AFter address insert in bill-to<> ship-to');
             swg_cust_debug('Y','AFter address insert in bill-to<> ship-to');

             l_ship_addr_id   :=   l_ship_addr_id_seq;

             SELECT SWGCNV.SWGCNV_CB_SITE_ID_S.nextval
             INTO   l_ship_site_id_seq
             FROM   dual;

             INSERT INTO SWGCNV_DD_CUSTOMER_SHIPTO
                (    SHIPTO_SITE_ID               --NUMBER(15)       NOT NULL,
                    ,CUSTOMER_ID                  --NUMBER(15)       NOT NULL,
                    ,SHIP_TO_ADDRESS_ID           --NUMBER(15)       NOT NULL,
                    ,BILLING_SITE_ID              --NUMBER(15)       NOT NULL,
                    ,CUSTOMER_NUMBER              --VARCHAR2(10 BYTE) NOT NULL,
                    ,DELIVERY_LOCATION_NUMBER     --VARCHAR2(10 BYTE) NOT NULL,
                    ,CUSTOMER_TAX_CLASS           --VARCHAR2(150 BYTE),
                    ,PO_NUMBER                    --VARCHAR2(150 BYTE),
                    ,PO_EFFECTIVE_FROM_DATE       --VARCHAR2(150 BYTE),
                    ,PO_EFFECTIVE_TO_DATE         --VARCHAR2(150 BYTE),
                    ,PO_TOTAL_DOLLARS             --VARCHAR2(150 BYTE),
                    ,PO_TOTAL_UNITS               --VARCHAR2(150 BYTE),
                    ,CUSTOMER_REFERENCE_NUMBER    --VARCHAR2(150 BYTE),
                    ,TAX_EXEMPT_NUMBER            --VARCHAR2(150 BYTE),
                    ,TAX_EXEMPT_EXP_DATE          --VARCHAR2(150 BYTE),
                    ,TAX_EXEMPT_CERTIFICATE_RCVD  --VARCHAR2(150 BYTE),
                    ,SALES_CENTER                 --VARCHAR2(3 BYTE) NOT NULL,
                    ,DIVISION                     --VARCHAR2(50 BYTE) NOT NULL,
                    ,ROUTE_NUMBER                 --VARCHAR2(10 BYTE),
                    ,ROUTE_DELIVERY_FREQUENCY     --VARCHAR2(10 BYTE),
                    ,NEXT_REGULAR_DELIVER_DATE    --DATE,
                    ,DELIVERY_INSTRUCTIONS        --VARCHAR2(1000 BYTE),
                    ,ROUTE_MESSAGE                --VARCHAR2(240 BYTE),
                    ,COLLECTION_MESSAGE           --VARCHAR2(240 BYTE),
                    ,ADDRESSEE                    --VARCHAR2(100 BYTE),
                    ,FREQUENCY                    --VARCHAR2(10 BYTE),
                    ,CUSTOMER_START_DATE          --DATE,
                    ,SHIP_TO_START_DATE           --DATE,
                    ,SUPPRESS_PRICE_HH_TICKET     --VARCHAR2(1 BYTE),
                    ,RSR_OVERIDE_SUPPRESS_PRICE   --VARCHAR2(1 BYTE),
                    ,BOTTLE_INITIAL_INVENTORY     --VARCHAR2(3 BYTE),
                    ,RATE_SCHEDULE                --VARCHAR2(4 BYTE),
                    ,CHARGE_DEPOSIT               --VARCHAR2(1 BYTE),
                    ,PREFERRED_CUSTOMER_FLAG      --VARCHAR2(1 BYTE),
                    ,PENDING                      --VARCHAR2(1 BYTE),
                    ,BSC_FLAG                     --VARCHAR2(1 BYTE),
                    ,CREDIT_SCORE                 --VARCHAR2(4 BYTE),
                    ,TERM_FEE_AMOUNT              --NUMBER,
                    ,AGREEMENT_TERM               --VARCHAR2(30 BYTE),
                    ,BOTTLE_DEPOSIT_AMT           --NUMBER,
                    ,DELIVERY_TICKET_PRINT_FLAG   --VARCHAR2(1 BYTE),
                    ,TIER_PRICE_PROC_FLAG         --VARCHAR2(1 BYTE) DEFAULT 'N',
                    ,BOT_DEPOSIT_PROC_FLAG        --VARCHAR2(1 BYTE) DEFAULT 'N'
                    --,HOLD_REASON                --VARCHAR2(10),
                    ,WILL_CALL_FLAG             --VARCHAR2(1)        -- re-activated this columns to fetch will call flag data from the prestaging cust tab by Bala Palani as per WO 19982
                    ,PRICE_LIST_NAME                                 -- Added by Bala Palani as per WO : 19982
                ) 
             VALUES
                (    l_ship_site_id_seq
                    ,l_cust_id
                    ,l_ship_addr_id
                    ,l_bill_site_id
                    ,l_cust_rec.customer_number
                    ,to_char(l_ship_site_id_seq)
                    --,DECODE(l_cust_rec.sales_tax,'EX','EXEMPT','TAXABLE')  Removed  Decode Condition as per  EB-2058
                    ,l_cust_rec.sales_tax 
                    ,l_cust_rec.SHIP_TO_PO_NUM
                    ,NULL
                    ,NULL
                    ,NULL
                    ,NULL
                    ,l_cust_rec.ship_to_reference_num  --EB-1877
                    --,DECODE(l_cust_rec.sales_tax,'EX','ON FILE',NULL)   Removed  Decode Condition as per  EB-2058  AND Added new field as per EB-2058
                    ,l_cust_rec.TAX_EXEMPT_NUM
                    ,NULL
                   -- ,DECODE(l_cust_rec.sales_tax,'EX','Y','N')               -- added by Steven WO: 20129   Removed  Decode Condition as per  EB-2058  AND Added new field as per EB-2058
                    ,l_cust_rec.TAX_CERT_RECVD
                    ,l_sales_center_s --'SAC'
                    ,l_division_s --'BV10'
                    ,get_mapped_value(l_system_name_s,'ROUTES',l_cust_rec.route_number,l_sales_center_s)
                    ,l_cust_rec.delivery_frequency -- Added PU 4/24/2008
                    ,NULL   -- NEXT_REGULAR_DELIVER_DATE -- Not used in Oracle, it is calculated when you query the PPF
                    ,NULL   -- DELIVERY_INSTRUCTIONS -- INSERTED AS A NOTE ON THE PPF.SWGRTM_NOTES.NOTE_TEXT; 01/24/07:  Alert file will have this data
                    ,NULL
                    ,NULL
                    ,l_cust_rec.ADDRESSEE-- ADDRESSEE
                    ,l_cust_rec.delivery_frequency -- Added PU 4/24/2008
                    ,l_cust_rec.CUST_START_DATE
                    ,l_cust_rec.CUST_START_DATE
                    ,'Y'            -- SUPPRESS_PRICE_HH_TICKET
                    ,'Y'            --  RSR_OVERIDE_SUPPRESS_PRICE
                    ,NULL           --  BOTTLE_INITIAL_INVENTORY
                    ,NULL           --  RATE_SCHEDULE
                    ,'Y'            -- Default to Y for all Ship Tos  -- CHARGE_DEPOSIT
                    ,'N'            -- PREFERRED_CUSTOMER_FLAG
                    ,NULL           -- PENDING
                    ,l_cust_rec.esc_fee            -- ESC_FLAG  --EB-1877
                    ,NULL           -- CREDIT_SCORE -- 01/24/07:  Val will map it
                    ,0              -- TERM_FEE_AMOUNT -- $100 by default (Agreement - Term Fee column) -- update later?
                    ,'GFAGR'        -- AGREEMENT_TERM -- Default from the Agreement code (Agreement - Term Code column) -- update later?
                    ,NULL           -- BOTTLE_DEPOSIT_AMT -- If the amount in this field is different that what is on the price list then
                                                           -- create a special price record to ensure the customer is charged correctly -- ?
                    ,l_cust_rec.print_delivery_tickets            -- DELIVERY_TICKET_PRINT_FLAG  --EB-1877
                    ,'N'            -- TIER_PRICE_PROC_FLAG
                    ,'N'            -- BOT_DEPOSIT_PROC_FLAG
                    ,l_cust_rec.ON_REQUEST_FLAG       -- re-activated this columns to fetch will call flag data from the prestaging cust tab by Bala Palani as per WO 19982
                    ,swgcnv_get_restrctd_prclst(l_system_name_s, l_cust_rec.customer_number)      -- Added by Bala Palani as per WO : 19982
                    
                );

            dbms_output.put_line('AFter ship-to insert in bill-to<> ship-to');
            swg_cust_debug('Y','AFter ship-to insert in bill-to<> ship-to');

            l_ship_site_id   :=    l_ship_site_id_seq;

            -- Contact Info

            INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                    (    CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                        ,ADDRESS_ID           --NUMBER(15),
                        ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                        ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                        ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                        ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                        ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                        ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                        ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                    )
            VALUES
                    (    l_cust_id
                        ,l_ship_addr_id
                        ,l_first_name_s   -- Added by Bala Palani EB-670
                        ,l_last_name_s    -- Proj 1359 SSB
                        ,NVL(substr(l_cust_rec.primary_phone,1,3), '111')             -- Added by Bala Palani EB-1156
                        ,NVL(substr(l_cust_rec.primary_phone,4,10),'1111111')         -- Added by Bala Palani EB-1156
                        ,substr(l_cust_rec.primary_phone,11)
                        ,'PHONE'
                        ,NULL
                    );


             ---EB-1877
              IF ( l_cust_rec.primary_bus_phone IS NOT NULL )  THEN
              
              INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_first_name_s  
                                 ,l_last_name_s  
                                 ,NVL(substr(l_cust_rec.primary_bus_phone,1,3), '111')                
                                 ,NVL(substr(l_cust_rec.primary_bus_phone,4,10),'1111111')              
                                 ,substr(l_cust_rec.primary_bus_phone,11)
                                 ,'PHONE'
                                 ,NULL
                                );
              
              END IF;
              
             IF ( l_cust_rec.primary_cell_phone IS NOT NULL )  THEN
              
              INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_first_name_s  
                                 ,l_last_name_s  
                                 ,NVL(substr(l_cust_rec.primary_cell_phone,1,3), '111')                
                                 ,NVL(substr(l_cust_rec.primary_cell_phone,4,10),'1111111')             
                                 ,substr(l_cust_rec.primary_cell_phone,11)
                                 ,'PHONE'
                                 ,NULL
                                );
              
              END IF;
              --EB-1877
               -- Added For SAGE Conversion
               IF ( l_cust_rec.primary_email_address IS NOT NULL ) THEN

                  INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                     (   CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                        ,ADDRESS_ID           --NUMBER(15),
                        ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                        ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                        ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                        ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                        ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                        ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                        ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                        ,PRIMARY_EMAIL_FLAG
                     )
                  VALUES
                     (   l_cust_id
                        ,l_ship_addr_id
                        ,l_first_name_s    -- Added by Bala Palani EB-670
                        ,l_last_name_s     -- Proj 1359 SSB per Val
                        ,NVL(SUBSTR(l_cust_rec.primary_phone,1,3), '111')                          -- Added by Bala Palani EB-1156
                        ,NVL(SUBSTR(l_cust_rec.primary_phone,4,10),'1111111')            -- Added by Bala Palani EB-1156
                        ,substr(l_cust_rec.primary_phone,11)
                        ,'EMAIL'
                        ,l_cust_rec.primary_email_address
                        ,'Y'
                     );

               END IF;
               -- Added For SAGE Conversion
               
                            
               --EB-1877 Contact2 and Contact3----
               
               IF (l_cust_rec.CONTACT2_LAST_NAME) IS NOT NULL THEN
               
                 IF  (l_cust_rec.Phone2)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_cust_rec.contact2_first_name  
                                 ,l_cust_rec.contact2_last_name  
                                 ,NVL(substr(l_cust_rec.Phone2,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.Phone2,4,10),'1111111')              
                                 ,substr(l_cust_rec.Phone2,11)
                                 ,'PHONE'
                                 ,NULL
                                );
                 
                  END IF;
                 
                 IF  (l_cust_rec.bus_phone2)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_cust_rec.contact2_first_name  
                                 ,l_cust_rec.contact2_last_name  
                                 ,NVL(substr(l_cust_rec.bus_phone2,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.bus_phone2,4,10),'1111111')              
                                 ,substr(l_cust_rec.bus_phone2,11)
                                 ,'PHONE'
                                 ,NULL
                                );
               
                 
                 END IF; 
                 
                 IF  (l_cust_rec.cell_phone2)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_cust_rec.contact2_first_name  
                                 ,l_cust_rec.contact2_last_name 
                                 ,NVL(substr(l_cust_rec.cell_phone2,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.cell_phone2,4,10),'1111111')              
                                 ,substr(l_cust_rec.cell_phone2,11)
                                 ,'PHONE'
                                 ,NULL
                                );
                 
                 END IF;
                 
                 IF  (l_cust_rec.email_address2)  IS NOT NULL THEN
                 
                  INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                     (   CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                        ,ADDRESS_ID           --NUMBER(15),
                        ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                        ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                        ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                        ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                        ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                        ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                        ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                     )
                  VALUES
                     (   l_cust_id
                        ,l_ship_addr_id
                        ,l_cust_rec.contact2_first_name  
                        ,l_cust_rec.contact2_last_name  
                        ,NVL(SUBSTR(l_cust_rec.phone2,1,3), '111')          
                        ,NVL(SUBSTR(l_cust_rec.phone2,4,10),'1111111')     
                        ,substr(l_cust_rec.phone2,11)
                        ,'EMAIL'
                        ,l_cust_rec.email_address2
                     );
                 
                 END IF;
               
               
               END IF;
               
               
               IF (l_cust_rec.CONTACT3_LAST_NAME) IS NOT NULL THEN
               
                 IF  (l_cust_rec.Phone3)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_cust_rec.contact3_first_name  
                                 ,l_cust_rec.contact3_last_name  
                                 ,NVL(substr(l_cust_rec.Phone3,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.Phone3,4,10),'1111111')              
                                 ,substr(l_cust_rec.Phone3,11)
                                 ,'PHONE'
                                 ,NULL
                                );
                 
                  END IF;
                 
                 IF  (l_cust_rec.bus_phone3)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_cust_rec.contact3_first_name  
                                 ,l_cust_rec.contact3_last_name  
                                 ,NVL(substr(l_cust_rec.bus_phone3,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.bus_phone3,4,10),'1111111')              
                                 ,substr(l_cust_rec.bus_phone3,11)
                                 ,'PHONE'
                                 ,NULL
                                );
               
                 
                 END IF; 
                 
                 IF  (l_cust_rec.cell_phone3)  IS NOT NULL THEN
                 
                 INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                                (  CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                                  ,ADDRESS_ID           --NUMBER(15),
                                  ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                                  ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                                  ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                                  ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                                  ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                                  ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                                  ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                                )
                            VALUES
                                ( l_cust_id
                                 ,l_ship_addr_id
                                 ,l_cust_rec.contact3_first_name  
                                 ,l_cust_rec.contact3_last_name 
                                 ,NVL(substr(l_cust_rec.cell_phone3,1,3), '111')                  
                                 ,NVL(substr(l_cust_rec.cell_phone3,4,10),'1111111')              
                                 ,substr(l_cust_rec.cell_phone3,11)
                                 ,'PHONE'
                                 ,NULL
                                );
                 
                 END IF;
                 
                 IF  (l_cust_rec.email_address3)  IS NOT NULL THEN
                 
                  INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                     (   CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                        ,ADDRESS_ID           --NUMBER(15),
                        ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                        ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                        ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                        ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                        ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                        ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                        ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                     )
                  VALUES
                     (   l_cust_id
                        ,l_ship_addr_id
                        ,l_cust_rec.contact3_first_name  
                        ,l_cust_rec.contact3_last_name  
                        ,NVL(SUBSTR(l_cust_rec.phone3,1,3), '111')          
                        ,NVL(SUBSTR(l_cust_rec.phone3,4,10),'1111111')     
                        ,substr(l_cust_rec.phone3,11)
                        ,'EMAIL'
                        ,l_cust_rec.email_address3
                     );
                 
                 END IF;
               
               END IF;
               
               --EB-1877 Contact2 and Contact3----

           dbms_output.put_line('AFter contact insert in bill-to<> ship-to');
           swg_cust_debug('Y','AFter contact insert in bill-to<> ship-to');

           -- also enter shipcycle days

           l_delivery_freq_s := l_cust_rec.delivery_frequency;

           INSERT INTO SWGCNV_DD_CYCLEDAYS
                (    CUSTOMER_ID           --NUMBER(15),
                    ,SHIPPING_SITE_ID      --NUMBER(15),
                    ,ROUTE_SERVICE_DAY     --VARCHAR2(2 BYTE),
                    ,ROUTE_SEQUENCE        --NUMBER(15),
                    ,CYCLE_DAY             --VARCHAR2(2 BYTE),
                    ,DRIVING_INSTRUCTIONS  --VARCHAR2(2000 BYTE)
                )
           VALUES
                (    l_cust_id
                    ,l_ship_site_id
                    ,l_new_code_s
                    ,to_number(l_cust_rec.route_seq)
                    ,l_new_code_s
                    ,NULL
                );

           if nvl(l_delivery_freq_s,'2') = '0' then

             INSERT INTO SWGCNV_DD_CYCLEDAYS
                (    CUSTOMER_ID           --NUMBER(15),
                    ,SHIPPING_SITE_ID      --NUMBER(15),
                    ,ROUTE_SERVICE_DAY     --VARCHAR2(2 BYTE),
                    ,ROUTE_SEQUENCE        --NUMBER(15),
                    ,CYCLE_DAY             --VARCHAR2(2 BYTE),
                    ,DRIVING_INSTRUCTIONS  --VARCHAR2(2000 BYTE)
                )
             VALUES
                (    l_cust_id
                    ,l_ship_site_id
                    ,l_new_code_s
                    ,to_number(l_cust_rec.route_seq)
                    ,l_new_code_s
                    ,NULL
                    );

           END IF;

           --insert l_cust_id for customer_id column, l_ship_site_id for shipping_site_id column

           dbms_output.put_line('AFter cycle days insert in bill-to<> ship-to');
           swg_cust_debug('Y','AFter cycle days insert in bill-to<> ship-to');

         ELSE

           IF g_error_flag_c != 'Y' THEN

             l_msg_data_s := 'Rec/Customer/Cust num/ship addr,shipto_loc,shp_cycle_days,contacts already exists in staging table: '
                              ||to_char(l_cust_rec.record_num)||'/'||l_cust_rec.customer_name||'/'|| l_cust_rec.customer_number;

              dbms_output.put_line(l_msg_data_s);
              --Fnd_File.Put_Line(Fnd_File.LOG,l_msg_data_s);
              swg_cust_debug(l_debug_c,l_msg_data_s);

              -- VG 8/7/2007 SAVKC INSERT IF CUSTOMER_CONTACT NOT EXISTS
              -- check if cust contact exists.

              IF l_cust_rec.primary_phone IS NOT NULL THEN

                IF NOT check_cust_contact_exists( l_cust_id
                                                 ,l_ship_addr_id
                                                 ,substr(l_cust_rec.primary_phone,1,3)
                                                 ,nvl(substr(l_cust_rec.primary_phone,4),'NONE')
                                                 ,NULL
                                                )  THEN

                  dbms_output.put_line('Before phone contract insert');

                  INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                        (    CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                            ,ADDRESS_ID           --NUMBER(15),
                            ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                            ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                            ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                            ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                            ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                            ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                            ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                        )
                  VALUES
                        (    l_cust_id
                            ,l_ship_addr_id
                            ,l_first_name_s    -- Added by Bala Palani EB-670
                            ,l_last_name_s     -- Proj 1359 SSB per Val
                            ,NVL(substr(l_cust_rec.primary_phone,1,3), '111')           -- Added by Bala Palani EB-1156
                            ,NVL(substr(l_cust_rec.primary_phone,4,10),'1111111')       -- Added by Bala Palani EB-1156
                            ,substr(l_cust_rec.primary_phone,11)
                            ,'PHONE'
                            ,NULL
                        );

                 dbms_output.put_line('After ADDITIONAL cust contact insert');
                  swg_cust_debug('Y','After ADDITIONAL cust contact insert');

                END IF; -- end if check_cust_contact_exists

              END IF; -- end if l_cust_rec.phone is null

              -- Added For Mayberry
              IF l_cust_rec.primary_email_address IS NOT NULL THEN

                IF NOT check_cust_contact_exists( l_cust_id
                                                 ,l_ship_addr_id
                                                 ,NULL
                                                 ,NULL
                                                 ,l_cust_rec.primary_email_address
                                                )  THEN

                  dbms_output.put_line('Before email contract insert');

                  INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                        (    CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                            ,ADDRESS_ID           --NUMBER(15),
                            ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                            ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                            ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                            ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                            ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                            ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                            ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                            ,PRIMARY_EMAIL_FLAG
                        )
                  VALUES
                        (    l_cust_id
                            ,l_ship_addr_id
                            ,l_first_name_s   -- Added by Bala Palani EB-670
                            ,l_last_name_s    -- Proj 1359 SSB per Val
                            ,NVL(substr(l_cust_rec.primary_phone,1,3), '111')               -- Added by Bala Palani EB-1156
                            ,NVL(substr(l_cust_rec.primary_phone,4,10),'1111111')          -- Added by Bala Palani EB-1156
                            ,substr(l_cust_rec.primary_phone,11)
                            ,'EMAIL'
                            ,l_cust_rec.primary_email_address
                            ,'Y'
                        );

                  dbms_output.put_line('After email cust contact insert');
                  swg_cust_debug('Y','After email cust contact insert');

                END IF; -- end if check_cust_contact_exists

              END IF; -- end if l_cust_rec.phone is null
              -- Added For Mayberry


            -- VG 8/7/2007 SAVKC END INSERT IF CUSTOMER_CONTACT NOT EXISTS

              swg_cust_debug(l_debug_c,'Before call to ship-to-site-id, bill-to<> ship-to');

              swg_cust_debug(l_debug_c,'Cust_id= '||to_char(l_cust_id)||'/ Ship Addr Id = '||to_char(l_ship_addr_id)||'/ Bill site id= '||to_char(l_bill_site_id)
                                                  ||'/ Customer number= '||l_cust_rec.CUSTOMER_NUMBER||'Sales/center/division ='||l_sales_center_s||'/'||l_division_s);

              -- Actually, if ship_addr exists, ship_site_id may not exist to need to call insert_proc_ship_site if needed, may not apply here,
              -- but will apply to sub-cust ship to

              l_ship_site_id := get_ship_to_site_id( l_cust_id
                                                    ,l_ship_addr_id
                                                    ,l_bill_site_id
                                                    ,l_cust_rec.CUSTOMER_NUMBER
                                                    ,l_sales_center_s          --'SAC'
                                                    ,l_division_s              --'BV10'
                                                   );

              IF (g_error_flag_c != 'N' OR l_ship_site_id = -99) THEN

                l_msg_data_s := 'Unexpected Error/no data found in Swgcnv_CB_Cust_stgload_Pkg.get_ship_to_site_id for Rec/Customer/Cust num: '
                                    ||to_char(l_cust_rec.record_num)||'/'||l_cust_rec.customer_name||'/'|| l_cust_rec.customer_number||': '||SQLERRM;

                swg_cust_debug('Y',l_msg_data_s);
                dbms_output.put_line(l_msg_data_s);
                --Fnd_File.Put_Line(Fnd_File.LOG,l_msg_data_s);

                -- GOTO end_loop;
                RAISE ERROR_ENCOUNTERED;

              END IF;

            ELSE

              l_msg_data_s := 'Unexpected Error in Swgcnv_CB_Cust_stgload_Pkg.check_ship_addr_exists for Rec/Customer/Cust num: '
                               ||to_char(l_cust_rec.record_num)||'/'||l_cust_rec.customer_name||'/'|| l_cust_rec.customer_number||': '||SQLERRM;

              swg_cust_debug('Y',l_msg_data_s);
              dbms_output.put_line(l_msg_data_s);
              --Fnd_File.Put_Line(Fnd_File.LOG,l_msg_data_s);

              -- GOTO end_loop;
              RAISE ERROR_ENCOUNTERED;
            END IF; --g_error_flag_c <> 'Y'

          END IF;-- l_ship_addr_id = -9 / check_ship_addr_exists

        END IF; -- Handle bill to=ship to

        -- Contracts requires function check

        -- contract info in shipping site area

     /*   IF l_cust_rec.equipment_id is not null AND l_cust_rec.equipment_type IS NOT NULL THEN

          -- VG GBC01 8/8/2007 -- IF (l_cust_rec.rent_period != '3' AND l_cust_rec.rent_period != '4' AND l_cust_rec.rent_period != 'Z') THEN -- ARS02 change

          IF NOT check_contract_exists( l_cust_rec.CUSTOMER_NUMBER
                                        ,l_ship_site_id
                                        ,UPPER(l_cust_rec.equipment_type) -- VG 8/8/2007
                                        ,l_cust_rec.equipment_id
                                        ,l_sales_center_s               --'SAC'
                                        ,l_division_s                   --'BV10'
                                      )   THEN

            dbms_output.put_line('Before contract insert');

            INSERT INTO SWGCNV_DD_EQPMNT_INTERFACE
                (    CUSTOMER_NUMBER           --VARCHAR2(20 BYTE)   NOT NULL,
                    ,DELIVERY_LOCATION_NUMBER  --VARCHAR2(10 BYTE)   NOT NULL,
                    ,ITEM_CODE                 --VARCHAR2(20 BYTE)   NOT NULL,
                    ,PLACEMENT_CODE            --VARCHAR2(20 BYTE)   NOT NULL,
                    ,SERIAL_NUMBER             --VARCHAR2(30 BYTE)   NOT NULL,
                    ,RENTAL_AMOUNT             --NUMBER              NOT NULL,
                    ,INSTALLATION_DATE         --DATE                NOT NULL,
                    ,LAST_BILLING_DATE         --DATE                NOT NULL,
                    ,PAYMENT_TERMS             --VARCHAR2(30 BYTE),
                    ,ACCOUNTING_RULE           --VARCHAR2(20 BYTE)   NOT NULL,
                    ,INVOICING_RULE            --VARCHAR2(20 BYTE)   NOT NULL,
                    ,BILLING_METHOD            --VARCHAR2(30 BYTE)   NOT NULL,
                    ,BILLING_INTERVAL          --VARCHAR2(20 BYTE)   NOT NULL,
                    ,SALES_CENTER              --VARCHAR2(3 BYTE)    NOT NULL,
                    ,DIVISION                  --VARCHAR2(10 BYTE)   NOT NULL,
                    ,MODEL                     --VARCHAR2(50 BYTE),
                    ,ESCROW_AMOUNT             --NUMBER,
                    ,CONTRACT_START_DATE       --DATE,
                    ,NEXT_BILL_DATE            --DATE,
                    ,VALID_FLAG                --VARCHAR2(1 BYTE)    DEFAULT 'N',
                    ,LAST_SRV_DATE             --DATE,
                    ,RENTAL_EXCEPTION_CODE     --VARCHAR2(10 BYTE),
                    ,SRVC_DUE_DATE             --DATE,
                    ,QUANTITY                  --NUMBER,
                    ,ITEM_SUB_CODE             --VARCHAR2(50 BYTE),
                    ,GRATIS_COUNT              --VARCHAR2(10 BYTE),
                    ,CUST_EQPMNT_OWNED_STATUS  --VARCHAR2(1 BYTE),
                    ,CUST_REMAINING_PMT        --NUMBER
                )
            VALUES
                (    l_cust_rec.customer_number
                    ,to_char(l_ship_site_id)
                    ,UPPER(l_cust_rec.equipment_type) -- VG 8/8/2007
                    ,'RENTED'
                    ,l_cust_rec.equipment_id
                    ,decode(l_cust_rec.rent_period,'1',(nvl(l_cust_rec.rent,0)/nvl(l_cust_rec.equipment_count,1)),nvl(l_cust_rec.rent,0))
                    ,l_cust_rec.cust_start_date -- INSTALLATION_DATE    -- Same as Customer Start Date?
                    ,decode(l_cust_rec.customer_type,'RESIDENTIAL',to_date('01-AUG-2007'),decode(l_sales_center_s,'SAV',to_date('22-JUL-2007'),to_date('15-JUL-2007')))
                    ,NULL           -- PAYMENT_TERMS -- Default from Customer profile class
                    ,'MONTHLY'
                    ,'ADVANCE INVOICE'
                    ,'RECURRING'
                    , nvl(get_mapped_value(l_system_name_s,'BILLINTVL',l_cust_rec.rent_period),'1040')
                    ,l_sales_center_s --'SAC'
                    ,l_division_s --'BV10'
                    ,UPPER(l_cust_rec.equipment_type) -- VG 8/8/2007
                    ,0
                    ,l_cust_rec.cust_start_date -- CONTRACT_START_DATE -- Same as Customer Start Date?
                    ,decode(l_cust_rec.customer_type,'RESIDENTIAL',to_date('01-SEP-2007'),decode(l_sales_center_s,'SAV',to_date('22-AUG-2007'),to_date('15-AUG-2007')))
                    ,'N' -- VALID_FLAG --NULL
                    ,NULL
                    ,NULL
                    ,NULL
                    ,1
                    ,NULL
                    ,NULL
                    ,NULL
                    ,NULL
                );
                
            -- insert l_ship_site_id  for delivery location number
            dbms_output.put_line('After contract insert');
            swg_cust_debug('Y','After contract insert');

          ELSE

            IF g_error_flag_c != 'Y' THEN

              l_msg_data_s := 'Rec/Customer/Cust num/Contract already exists in staging table: '||to_char(l_cust_rec.record_num)
                               ||'/'||l_cust_rec.customer_name||'/'|| l_cust_rec.customer_number;

              dbms_output.put_line(l_msg_data_s);
            --Fnd_File.Put_Line(Fnd_File.LOG,l_msg_data_s);
              swg_cust_debug(l_debug_c,l_msg_data_s);

            ELSE

              l_msg_data_s := 'Unexpected Error in Swgcnv_CB_Cust_stgload_Pkg.check_contract_exists for Rec/Customer/Cust num: '
                               ||to_char(l_cust_rec.record_num)||'/'||l_cust_rec.customer_name||'/'|| l_cust_rec.customer_number||': '||SQLERRM;

              swg_cust_debug('Y',l_msg_data_s);
              dbms_output.put_line(l_msg_data_s);
            --Fnd_File.Put_Line(Fnd_File.LOG,l_msg_data_s);

              -- GOTO end_loop;
              RAISE ERROR_ENCOUNTERED;

            END IF;

          END IF;-- check_contract_exists

        -- VG GBC01 8/8/2007 -- END IF; --l_cust_rec.RENT_PERIOD != '3,4,Z' -- ARS02 change

        END IF; -- equip_id is not null  */

        -- <<end_loop>>
        IF g_error_flag_c != 'Y' THEN

          UPDATE SWGCNV_DD_CB_PRESTAGING_CUST
          SET    processed_flag          =      'Y'
                ,processed_status        =      'S'
                ,error_message           =       NULL
          WHERE  record_num              =       l_cust_rec.record_num
--    AND  SALES_CENTER = in_sales_center_s;  -- SSB added to process multiple sales center.  --MTS 20129 process bill_to_master for all sales centers
      ;

          COMMIT;

        END IF;

      EXCEPTION
        WHEN ERROR_ENCOUNTERED THEN

          ROLLBACK TO SAVEPOINT at_first;

          UPDATE SWGCNV_DD_CB_PRESTAGING_CUST
          SET    processed_flag          =    'Y'
                ,processed_status        =    'E'
                ,error_message           =     l_msg_data_s
          WHERE  record_num              =     l_cust_rec.record_num
--    AND  SALES_CENTER = in_sales_center_s;  -- SSB added to process multiple sales center.  --MTS 20129 process bill_to_master for all sales centers
     ;

          COMMIT;

        WHEN OTHERS THEN

            l_msg_data_s := 'Unexpected error during processing of record num: '||to_char(l_cust_rec.record_num)||': '||SQLERRM;
            ROLLBACK TO SAVEPOINT at_first;

            swg_cust_debug('Y',l_msg_data_s);
            dbms_output.put_line(l_msg_data_s);
            --Fnd_File.Put_Line(Fnd_File.LOG,l_msg_data_s);

            UPDATE SWGCNV_DD_CB_PRESTAGING_CUST
            SET    processed_flag       =    'Y'
                  ,processed_status     =    'E'
                  ,error_message        =     l_msg_data_s
            WHERE  record_num           =     l_cust_rec.record_num
--   AND  SALES_CENTER = in_sales_center_s;  -- SSB added to process multiple sales center.   --MTS 20129 process bill_to_master for all sales centers
     ;
            COMMIT;
       END;

    END LOOP;

    CLOSE cur_cust_data;

    l_end_time_d    :=      SYSDATE;
    Fnd_File.Put_Line(Fnd_File.OUTPUT,'*************************  RUN STATISTICS *******************************');
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Customer Records Read           : ' || l_cust_recs_read_n);
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' ------------------------------------------------------------------------');
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' Start Time : ' || TO_CHAR(l_start_time_d, 'MM/DD/RRRR HH24:MI:SS'));
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' End Time   : ' || TO_CHAR(l_end_time_d, 'MM/DD/RRRR HH24:MI:SS'));
    Fnd_File.Put_Line(Fnd_File.OUTPUT,'*************************************************************************');

    -- Need to call this in a separate process/concurrent program

    IF ( in_proc_mstr_only_c = 'N' ) THEN   --SGB WO# 20129

        swg_cust_debug(l_debug_c,'Calling procedure insert_sub_cust');

        Insert_Sub_Cust ( ou_errbuf2_s
                         ,ou_errcode2_n
                         ,l_sales_center_s
                         ,l_system_name_s
                         ,l_mode_c
                         ,l_debug_c
                        );

        IF g_error_flag_c != 'Y' THEN

          l_msg_data_s := 'Procedure insert_sub_cust completed successfully';
          dbms_output.put_line(l_msg_data_s);
          --Fnd_File.Put_Line(Fnd_File.LOG,l_msg_data_s);
          swg_cust_debug(l_debug_c,l_msg_data_s);

        ELSE

          l_msg_data_s := 'Unexpected Error in Procedure Swgcnv_CB_Cust_stgload_Pkg.insert_sub_cust: '||SQLERRM;
          swg_cust_debug('Y',l_msg_data_s);
          dbms_output.put_line(l_msg_data_s);
          --Fnd_File.Put_Line(Fnd_File.LOG,l_msg_data_s);

          -- GOTO end_loop;
          RAISE ERROR_ENCOUNTERED;

        END IF;

        -- Interface/Staging table updates

        -- Monthly_invoice_format

        OPEN cur_upd_col_1( in_sales_center_s,l_division_s);
        LOOP

          BEGIN

             FETCH cur_upd_col_1 INTO l_cust_id;
             EXIT WHEN cur_upd_col_1%NOTFOUND;
             SAVEPOINT upd_intf_fields;
             g_error_flag_c := 'N';

             SELECT nvl(count(SHIPTO_SITE_ID),0)
             INTO   l_no_of_shiptos
             FROM   SWGCNV_DD_CUSTOMER_SHIPTO
             WHERE  customer_id   =   l_cust_id;

             UPDATE SWGCNV_DD_CUSTOMER_INTERFACE
             SET    MONTHLY_INVOICE_FORMAT  =   decode(l_no_of_shiptos,1,'SINGLE SHIP-TO/BILL-TO',0,'N/A','MULTIPLE SHIP-TO')
             WHERE  customer_id             =   l_cust_id;

             COMMIT;

          EXCEPTION
            WHEN OTHERS THEN

              ROLLBACK TO upd_intf_fields;
              l_error_message_s   := 'Error during update of monthly_invoice_format for customer ID: '||to_char(l_cust_id)||': '||SQLERRM;
              swg_cust_debug('Y',l_error_message_s);
              dbms_output.put_line(l_error_message_s);

          END;

        END LOOP;

        CLOSE cur_upd_col_1;

    END IF;  --in_proc_mstr_only_c = 'N'

  EXCEPTION
    WHEN INIT_ERROR THEN
      ou_errbuf_s     :=    'Initialization / Bulk Collect Error encountered.' || l_error_message_s;
      ou_errcode_n    :=    2;
      RETURN;

    WHEN ERROR_ENCOUNTERED THEN
      l_error_message_s   := SQLERRM;

      ou_errbuf_s     :=    'Unexpected Error encountered in procedure insert_sub_cust: ' || l_error_message_s;
      ou_errcode_n    :=    2;
      RETURN;

    WHEN OTHERS THEN

      l_error_message_s   := SQLERRM;

      swg_cust_debug('Y',l_error_message_s);
      dbms_output.put_line(l_error_message_s);
      --Fnd_File.Put_Line(Fnd_File.LOG,l_error_message_s);

      ou_errbuf_s   :=    'Unexpected Error: '||l_error_message_s;
      ou_errcode_n  :=     2;

      --Fnd_File.Put_Line(Fnd_File.LOG,'Unexpected Error: '||l_error_message_s);

      RETURN;

  END Insert_Main;

---


PROCEDURE process_first_cycle_day
IS
CURSOR c_svc_days_e1w IS
SELECT
             scd.customer_id,
             scd.shipping_site_id,
             scd.route_service_day,
             nvl(scd.route_sequence,999) route_sequence,
             scd.cycle_day,
             scd.driving_instructions,
             shp.frequency
       FROM
             swgcnv_dd_customer_shipto      shp,
             swgcnv.swgcnv_dd_cycledays     scd
       WHERE shp.SHIPTO_SITE_ID      =   scd.shipping_site_id
         AND shp.frequency           =  'E1W';

CURSOR c_svc_days_e2w IS
       SELECT     scd.customer_id,
             scd.shipping_site_id,
             scd.route_service_day,
             nvl(scd.route_sequence,999) route_sequence,
             scd.cycle_day,
             scd.driving_instructions,
             shp.frequency,
             CASE WHEN  scd.cycle_day < 11 then scd.cycle_day + 10
             ELSE scd.cycle_day - 10
             END              new_cycle_day                                -- Added by Bala Palani for WO : 21391
       FROM
             swgcnv_dd_customer_shipto       shp,
             swgcnv.swgcnv_dd_cycledays      scd
       WHERE shp.SHIPTO_SITE_ID      =   scd.shipping_site_id
         AND shp.frequency = 'E2W';
 

     
CURSOR c_svc_days_etw IS
SELECT
             scd.customer_id,
             scd.shipping_site_id,
             scd.route_service_day,
             nvl(scd.route_sequence,999) route_sequence,
             scd.cycle_day,
             scd.driving_instructions,
             shp.frequency
       FROM
             swgcnv_dd_customer_shipto      shp,
             swgcnv.swgcnv_dd_cycledays     scd
       WHERE shp.SHIPTO_SITE_ID      =   scd.shipping_site_id
         AND shp.frequency = 'ETW';


CURSOR c_svc_days_ethw IS
SELECT
             scd.customer_id,
             scd.shipping_site_id,
             scd.route_service_day,
             nvl(scd.route_sequence,999) route_sequence,
             scd.cycle_day,
             scd.driving_instructions,
             shp.frequency
       FROM
             swgcnv_dd_customer_shipto       shp,
             swgcnv.swgcnv_dd_cycledays      scd
       WHERE shp.SHIPTO_SITE_ID      =   scd.shipping_site_id
    --   AND pc.customer_number =  '00000001'
         and shp.frequency = 'ETHW';     


   TYPE l_cycle_day_table IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
   l_cycle_day_tab l_cycle_day_table;


FUNCTION get_first_cycle_day (in_cycle_day_n NUMBER) RETURN NUMBER IS
    l_cycle_day_n NUMBER;
BEGIN
   l_cycle_day_n := in_cycle_day_n;
   LOOP
      IF l_cycle_day_n <= 5 THEN
         RETURN l_cycle_day_n;
      ELSE
         l_cycle_day_n := l_cycle_day_n - 5;
      END IF;
  END LOOP;
END get_first_cycle_day;

BEGIN

FOR svc_days_rec_e1w IN c_svc_days_e1w LOOP

    l_cycle_day_tab(1) := get_first_cycle_day(svc_days_rec_e1w.cycle_day);       -- Added by Bala Palani for WO : 21391

    -- l_cycle_day_tab(1) := get_first_cycle_day(svc_days_rec_e1w.old_code);          -- Commented by Bala Palani for WO : 21391
    l_cycle_day_tab(2) := l_cycle_day_tab(1) + 5;
    l_cycle_day_tab(3) := l_cycle_day_tab(1) + 10;
    l_cycle_day_tab(4) := l_cycle_day_tab(1) + 15;

    FOR idx IN 1 .. 4 LOOP

        IF l_cycle_day_tab(idx) <> svc_days_rec_e1w.cycle_day THEN                -- Added by Bala Palani for WO : 21391

       -- IF l_cycle_day_tab(idx) <> svc_days_rec_e1w.old_code THEN                  -- Commented by Bala Palani for WO : 21391
           INSERT INTO
                  swgcnv.swgcnv_dd_cycledays
           VALUES
                 (svc_days_rec_e1w.customer_id,
                  svc_days_rec_e1w.SHIPPING_SITE_ID,
                  l_cycle_day_tab(idx),
                  svc_days_rec_e1w.ROUTE_SEQUENCE,
                  l_cycle_day_tab(idx),
                  svc_days_rec_e1w.driving_instructions);
        END IF;
    END LOOP;
END LOOP;


FOR svc_days_rec_e2w IN c_svc_days_e2w LOOP
        INSERT
        INTO swgcnv.swgcnv_dd_cycledays
        VALUES
             (svc_days_rec_e2w.customer_id,
              svc_days_rec_e2w.SHIPPING_SITE_ID,
              svc_days_rec_e2w.new_cycle_day,
              svc_days_rec_e2w.ROUTE_SEQUENCE,
              svc_days_rec_e2w.new_cycle_day,
              svc_days_rec_e2w.driving_instructions);
    END LOOP;
    


FOR svc_days_rec_etw IN c_svc_days_etw LOOP

    l_cycle_day_tab(1) := get_first_cycle_day(svc_days_rec_etw.cycle_day);      

 l_cycle_day_tab(2) := l_cycle_day_tab(1) + 3;
    
 -- DBMS_OUTPUT.PUT_LINE ('2ND CYCLE DAY : '||l_cycle_day_tab(2));
    
    l_cycle_day_tab(3) := l_cycle_day_tab(1) + 5;

 -- DBMS_OUTPUT.PUT_LINE ('3RD CYCLE DAY : '||l_cycle_day_tab(3));    
    
    l_cycle_day_tab(4) := l_cycle_day_tab(1) + 8; 
    
--DBMS_OUTPUT.PUT_LINE ('4TH CYCLE DAY : '||l_cycle_day_tab(4));      

    l_cycle_day_tab(5) := l_cycle_day_tab(1) + 10; 
    
--DBMS_OUTPUT.PUT_LINE ('5TH CYCLE DAY : '||l_cycle_day_tab(5)); 

    l_cycle_day_tab(6) := l_cycle_day_tab(1) + 13; 
    
--DBMS_OUTPUT.PUT_LINE ('6TH CYCLE DAY : '||l_cycle_day_tab(6)); 

    l_cycle_day_tab(7) := l_cycle_day_tab(1) + 15; 
    
--DBMS_OUTPUT.PUT_LINE ('7TH CYCLE DAY : '||l_cycle_day_tab(7)); 

    l_cycle_day_tab(8) := l_cycle_day_tab(1) + 18; 

    FOR idx IN 1 .. 8 LOOP

        IF l_cycle_day_tab(idx) <> svc_days_rec_etw.cycle_day THEN                -- Added by Bala Palani for WO : 21391

       -- IF l_cycle_day_tab(idx) <> svc_days_rec_e1w.old_code THEN                  -- Commented by Bala Palani for WO : 21391
           INSERT INTO
                  swgcnv.swgcnv_dd_cycledays
           VALUES
                 (svc_days_rec_etw.customer_id,
                  svc_days_rec_etw.SHIPPING_SITE_ID,
                  l_cycle_day_tab(idx),
                  svc_days_rec_etw.ROUTE_SEQUENCE,
                  l_cycle_day_tab(idx),
                  svc_days_rec_etw.driving_instructions);
        END IF;
    END LOOP;
END LOOP;


FOR svc_days_rec_ethw IN c_svc_days_ethw LOOP

    l_cycle_day_tab(1) := get_first_cycle_day(svc_days_rec_ethw.cycle_day); 
  
    
   -- DBMS_OUTPUT.PUT_LINE ('1ST CYCLE DAY : '||l_cycle_day_tab(1));

    l_cycle_day_tab(2) := l_cycle_day_tab(1) + 1;
    
 -- DBMS_OUTPUT.PUT_LINE ('2ND CYCLE DAY : '||l_cycle_day_tab(2));
    
    l_cycle_day_tab(3) := l_cycle_day_tab(1) + 3;

 -- DBMS_OUTPUT.PUT_LINE ('3RD CYCLE DAY : '||l_cycle_day_tab(3));    
    
    l_cycle_day_tab(4) := l_cycle_day_tab(1) + 5; 
    
--DBMS_OUTPUT.PUT_LINE ('4TH CYCLE DAY : '||l_cycle_day_tab(4));      


    l_cycle_day_tab(5) := l_cycle_day_tab(1) + 6; 
    
-- DBMS_OUTPUT.PUT_LINE ('5TH CYCLE DAY : '||l_cycle_day_tab(5)); 

    l_cycle_day_tab(6) := l_cycle_day_tab(1) + 8; 
    
-- DBMS_OUTPUT.PUT_LINE ('6TH CYCLE DAY : '||l_cycle_day_tab(6)); 


    l_cycle_day_tab(7) := l_cycle_day_tab(1) + 10; 
    
-- DBMS_OUTPUT.PUT_LINE ('7TH CYCLE DAY : '||l_cycle_day_tab(7)); 

    l_cycle_day_tab(8) := l_cycle_day_tab(1) + 11; 
    
-- DBMS_OUTPUT.PUT_LINE ('8TH CYCLE DAY : '||l_cycle_day_tab(8)); 

    l_cycle_day_tab(9) := l_cycle_day_tab(1) + 13; 
    
-- DBMS_OUTPUT.PUT_LINE ('9TH CYCLE DAY : '||l_cycle_day_tab(9)); 

    l_cycle_day_tab(10) := l_cycle_day_tab(1) + 15; 
    
-- DBMS_OUTPUT.PUT_LINE ('10TH CYCLE DAY : '||l_cycle_day_tab(10)); 

    l_cycle_day_tab(11) := l_cycle_day_tab(1) + 16; 
    
-- DBMS_OUTPUT.PUT_LINE ('11TH CYCLE DAY : '||l_cycle_day_tab(11)); 

    l_cycle_day_tab(12) := l_cycle_day_tab(1) + 18; 
    
-- DBMS_OUTPUT.PUT_LINE ('12TH CYCLE DAY : '||l_cycle_day_tab(12)); 

    FOR idx IN 1 .. 12 LOOP

        IF l_cycle_day_tab(idx) <> svc_days_rec_ethw.cycle_day THEN                  -- Added by Bala Palani for WO : 21391

       -- IF l_cycle_day_tab(idx) <> svc_days_rec_e1w.old_code THEN                  -- Commented by Bala Palani for WO : 21391
           INSERT INTO
                  swgcnv.swgcnv_dd_cycledays
           VALUES
                 (svc_days_rec_ethw.customer_id,
                  svc_days_rec_ethw.SHIPPING_SITE_ID,
                  l_cycle_day_tab(idx),
                  svc_days_rec_ethw.ROUTE_SEQUENCE,
                  l_cycle_day_tab(idx),
                  svc_days_rec_ethw.driving_instructions);
        END IF;
    END LOOP;

END LOOP;

    
    COMMIT;
    --ROLLBACK;
END;

-- SGB

FUNCTION    ret_price_list   (  in_price_list_name  VARCHAR2 )
RETURN      NUMBER
IS
l_header_n  NUMBER;
BEGIN
SELECT  list_header_id
INTO    l_header_n
FROM    qp_list_headers_all
WHERE   UPPER( name ) =  UPPER ( in_price_list_name );
RETURN  l_header_n; 
EXCEPTION
WHEN OTHERS THEN
  RETURN -1;
END;

PROCEDURE   insert_shipto_cust
      (   ou_errbuf2_s         OUT     VARCHAR2
         ,ou_errcode2_n        OUT     NUMBER
         ,in_sales_center_s    IN      VARCHAR2    DEFAULT     'SAC'
         ,in_system_name_s     IN      VARCHAR2    DEFAULT     'ARS01'
         ,in_mode_c            IN      VARCHAR2    DEFAULT      G_SWG_CONCURRENT
         ,in_debug_flag_c      IN      VARCHAR2    DEFAULT      G_SWG_NODEBUG
      )
   IS

      CURSOR  cur_sub_cust_data(in_sales_center IN VARCHAR2)
      IS
      SELECT  shipto.*, a.cust_account_id, decode ( party_type, 'PERSON','Y','N') person_flag, pa.party_name
      FROM    swgcnv_dd_cb_prestaging_shipto shipto, hz_cust_accounts a, hz_parties pa
      WHERE   processed_flag         =  'N'
      AND     shipto.ship_to_master  =  a.account_number
      AND     pa.party_id            =  a.party_id
      AND     shipto.sales_Center    =  in_sales_center
      ORDER BY record_num;
      
      CURSOR cur_bill_to_address (in_billing_site_id_n NUMBER) 
      IS
      SELECT
          loc.address1              
         ,loc.address2              
         ,loc.city                  
         ,loc.state                 
         ,loc.province              
         ,loc.postal_code           
         ,loc.country  
      FROM
          hz_cust_site_uses_all su,
          hz_locations loc,
          hz_party_sites ps,
          hz_cust_acct_sites_all sites
      WHERE
           loc.location_id = ps.location_id
      AND  ps.party_site_id = sites.party_site_id
      AND  sites.cust_acct_site_id = su.cust_acct_site_id
      AND  su.site_use_id = in_billing_site_id_n;
                   

      l_sub_cust_rec          cur_sub_cust_data%ROWTYPE;

      l_system_name_s         VARCHAR2(20);
      l_sales_center_s        VARCHAR2(3);
      l_debug_c               VARCHAR2(1);
      l_mode_c                VARCHAR2(1);
      l_error_message_s       VARCHAR2(2000);
      l_msg_data_s            VARCHAR2(2000);
      l_mast_cust_name_s      VARCHAR2(50);
      l_division_s            VARCHAR2(20);

      l_state_s               VARCHAR2(20);   -- added by Bala Palani
      l_new_code_s            VARCHAR2(20);   -- added by Bala Palani
      l_new_sub_code_s        VARCHAR2(50);   -- added by Bala Palani
      l_error_mesg_s          VARCHAR2(50);   -- added by Bala Palani

      l_cust_recs_read_n      NUMBER;
      l_cust_id               NUMBER;
      l_cust_id_seq           NUMBER;
      l_addr_id               NUMBER;
      l_addr_id_seq           NUMBER;
      l_bill_site_id          NUMBER;
      l_bill_site_id_seq      NUMBER;
      l_ship_addr_id          NUMBER;
      l_ship_addr_id_seq      NUMBER;
      l_ship_site_id          NUMBER;
      l_ship_site_id_seq      NUMBER;
      l_price_list_id         NUMBER;

      l_return_status_s       VARCHAR2(10);

      l_message_s             VARCHAR2(2000);

      l_start_time_d          DATE;
      l_end_time_d            DATE;

      ERROR_ENCOUNTERED       EXCEPTION;
      INIT_ERROR              EXCEPTION;

      l_cust_acct_id_n        NUMBER;
      l_obj_version_num_n     NUMBER;
      l_msg_count_n           NUMBER;
      l_legacy_cust_num_n     NUMBER   :=    0;

      l_rtsrvdy_s     VARCHAR2(10);

      CURSOR  cur_upd_col_1
         (   in_sales_center_s IN VARCHAR2
            ,in_division_s     IN VARCHAR2
         )
      IS
      SELECT customer_id
      FROM   swgcnv_dd_customer_interface
      WHERE  sales_center    =     in_sales_center_s
      ORDER BY customer_id;

      l_no_of_shiptos     NUMBER;
      l_sc_s              VARCHAR2(3);
      l_def_route_day_s   VARCHAR2(10);
      l_delivery_freq_s   VARCHAR2(10);
      l_person_flag_c     VARCHAR2(1);
      l_pr_price_list_id  NUMBER;
      l_sav_customer_number_s VARCHAR2(50) := ' ';
   BEGIN

      ou_errbuf2_s        :=      NULL;
      ou_errcode2_n       :=      0;

      l_start_time_d      :=      SYSDATE;
      l_system_name_s     :=      in_system_name_s;
      l_sales_center_s    :=      in_sales_center_s;
      l_debug_c           :=      in_debug_flag_c;
      l_mode_c            :=      in_mode_c;

      l_division_s   := Swg_Hierarchy_Pkg.Get_Parent
                           (   'LOCATION'
                              , l_sales_center_s
                              , NULL
                              ,'DIVISION'
                              , SYSDATE
                              ,'ID'
                              ,'HTL'
                           );

      IF l_division_s IS NULL THEN

         l_error_message_s := 'Division is NULL in sub-cust';
         swg_cust_debug( l_debug_c,l_error_message_s);
         RAISE INIT_ERROR;

      END IF;

      l_cust_recs_read_n  := 0;

      DELETE FROM SWGCNV_DD_ADDRESSES;
      DELETE FROM SWGCNV_DD_CUSTOMER_CONTACT;
      DELETE FROM SWGCNV_DD_CUSTOMER_SHIPTO;
      DELETE FROM SWGCNV_DD_CYCLEDAYS;     
      DELETE FROM SWGCNV_DD_CUSTOMER_BILLTO;
      DELETE FROM SWGCNV_DD_CUSTOMER_INTERFACE;
	  DELETE FROM SWGCNV_DD_ROUTE_INTERFACE;

   OPEN  cur_sub_cust_data(l_sales_center_s);
   LOOP

         FETCH cur_sub_cust_data INTO l_sub_cust_rec;
         EXIT WHEN cur_sub_cust_data%NOTFOUND;
 
         l_cust_id := l_sub_cust_rec.cust_account_id;

         SELECT  DISTINCT shipto.bill_to_site_id  INTO l_bill_site_id
         FROM    swgcnv_dd_cb_prestaging_shipto shipto, hz_cust_site_uses_all a
         WHERE   processed_flag          =  'N'
         AND     shipto.bill_to_site_id  =  a.site_use_id;

         g_error_flag_c := 'N';

         l_cust_recs_read_n   := l_cust_recs_read_n + 1;

         swg_cust_debug(l_debug_c,'Processing record number: '||to_char(l_sub_cust_rec.record_num));

               SELECT SWGCNV.SWGCNV_CB_ADDR_ID_S.nextval
               INTO   l_ship_addr_id_seq
               FROM   dual;
         
               INSERT INTO SWGCNV_DD_ADDRESSES
                  (   ADDRESS_ID            --NUMBER(15)              NOT NULL,
                     ,CUSTOMER_ID           --NUMBER(15)              NOT NULL,
                     ,CUSTOMER_NUMBER       --VARCHAR2(10 BYTE)       NOT NULL,
                     ,ADDRESS1              --VARCHAR2(240 BYTE),
                     ,ADDRESS2              --VARCHAR2(240 BYTE),
                     ,ADDRESS3              --VARCHAR2(240 BYTE),
                     ,ADDRESS4              --VARCHAR2(240 BYTE),
                     ,CITY                  --VARCHAR2(60 BYTE),
                     ,STATE                 --VARCHAR2(60 BYTE),
                     ,PROVINCE              --VARCHAR2(60 BYTE),
                     ,COUNTY                --VARCHAR2(60 BYTE),
                     ,POSTAL_CODE           --VARCHAR2(60 BYTE),
                     ,COUNTRY               --VARCHAR2(60 BYTE)       NOT NULL,
                     ,LATITUDE              --VARCHAR2(150 BYTE),
                     ,LONGITUDE             --VARCHAR2(150 BYTE),
                     ,COMPLEX_TYPE          --VARCHAR2(150 BYTE),
                     ,VARIABLE_UNLOAD_TIME  --VARCHAR2(150 BYTE),
                     ,FIXED_UNLOAD_TIME     --VARCHAR2(150 BYTE),
                     ,DOCK_TYPE             --VARCHAR2(150 BYTE),
                     ,SALES_CENTER          --VARCHAR2(3 BYTE)        NOT NULL,
                     ,ADDR_CLEAN_UP_FLAG    --VARCHAR2(1 BYTE)        DEFAULT 'N',
                     ,DIVISION              --VARCHAR2(10 BYTE)       NOT NULL,
                     ,SEQ                   --NUMBER
                  )
               VALUES
                  (   l_ship_addr_id_seq
                     ,l_cust_id
                     ,l_sub_cust_rec.customer_number
                     ,l_sub_cust_rec.ship_to_address1
                     ,l_sub_cust_rec.ship_to_address2
                     ,NULL
                     ,NULL
                     ,l_sub_cust_rec.ship_to_city
                     ,l_sub_cust_rec.ship_to_state
                     ,NULL
                     ,NULL
                     ,l_sub_cust_rec.ship_to_postal_code
                     ,'US'
                     ,NULL       -- lat. will be provided in a separate file
                     ,NULL       -- long. will be provided in a separate file
                     ,NULL
                     ,NULL
                     ,NULL
                     ,'ALL'
                     ,l_sales_center_s
                     ,'N'
                     ,l_division_s
                     ,NULL
                  );

                  Fnd_File.Put_Line(Fnd_File.LOG,'Total Rows SWGCNV_DD_ADDRESSES: '||sql%rowcount);
                  
                  --insert l_addr_id_seq for address_id column, l_cust_id for customer_id column

                  l_ship_addr_id := l_ship_addr_id_seq;

                  SELECT SWGCNV.SWGCNV_CB_SITE_ID_S.nextval
                  INTO   l_ship_site_id_seq
                  FROM   DUAL;

                  IF ( l_sub_cust_rec.price_list IS NOT NULL ) THEN

                    l_price_list_id   :=  ret_price_list   (  l_sub_cust_rec.price_list );

                    IF l_price_list_id < 0 THEN
                         l_error_message_s := 'BAD PRICE LIST NAME '||l_sub_cust_rec.price_list;
                         swg_cust_debug( l_debug_c,l_error_message_s);
                         RAISE INIT_ERROR;
                    END IF;

                  END IF;

                  IF ( l_sub_cust_rec.primo_ar_price_list IS NOT NULL ) THEN

                    l_pr_price_list_id   :=  ret_price_list   (  l_sub_cust_rec.primo_ar_price_list);

                    IF l_pr_price_list_id < 0 THEN
                         l_error_message_s := 'BAD PRICE LIST NAME '||l_sub_cust_rec.primo_ar_price_list;
                         swg_cust_debug( l_debug_c,l_error_message_s);
                         RAISE INIT_ERROR;
                    END IF;

                  END IF;

                  INSERT INTO SWGCNV_DD_CUSTOMER_SHIPTO
                     (   SHIPTO_SITE_ID               --NUMBER(15)       NOT NULL,
                        ,CUSTOMER_ID                  --NUMBER(15)       NOT NULL,
                        ,SHIP_TO_ADDRESS_ID           --NUMBER(15)       NOT NULL,
                        ,BILLING_SITE_ID              --NUMBER(15)       NOT NULL,
                        ,CUSTOMER_NUMBER              --VARCHAR2(10 BYTE) NOT NULL,
                        ,DELIVERY_LOCATION_NUMBER     --VARCHAR2(10 BYTE) NOT NULL,
                        ,CUSTOMER_TAX_CLASS           --VARCHAR2(150 BYTE),
                        ,PO_NUMBER                    --VARCHAR2(150 BYTE),
                        ,PO_EFFECTIVE_FROM_DATE       --VARCHAR2(150 BYTE),
                        ,PO_EFFECTIVE_TO_DATE         --VARCHAR2(150 BYTE),
                        ,PO_TOTAL_DOLLARS             --VARCHAR2(150 BYTE),
                        ,PO_TOTAL_UNITS               --VARCHAR2(150 BYTE),
                        ,CUSTOMER_REFERENCE_NUMBER    --VARCHAR2(150 BYTE),
                        ,TAX_EXEMPT_NUMBER            --VARCHAR2(150 BYTE),
                        ,TAX_EXEMPT_EXP_DATE          --VARCHAR2(150 BYTE),
                        ,TAX_EXEMPT_CERTIFICATE_RCVD  --VARCHAR2(150 BYTE),
                        ,SALES_CENTER                 --VARCHAR2(3 BYTE)  NOT NULL,
                        ,DIVISION                     --VARCHAR2(50 BYTE) NOT NULL,
                        ,ROUTE_NUMBER                 --VARCHAR2(10 BYTE),
                        ,ROUTE_DELIVERY_FREQUENCY     --VARCHAR2(10 BYTE),
                        ,NEXT_REGULAR_DELIVER_DATE    --DATE,
                        ,DELIVERY_INSTRUCTIONS        --VARCHAR2(1000 BYTE),
                        ,ROUTE_MESSAGE                --VARCHAR2(240 BYTE),
                        ,COLLECTION_MESSAGE           --VARCHAR2(240 BYTE),
                        ,ADDRESSEE                    --VARCHAR2(100 BYTE),
                        ,FREQUENCY                    --VARCHAR2(10 BYTE),
                        ,CUSTOMER_START_DATE          --DATE,
                        ,SHIP_TO_START_DATE           --DATE,
                        ,SUPPRESS_PRICE_HH_TICKET     --VARCHAR2(1 BYTE),
                        ,RSR_OVERIDE_SUPPRESS_PRICE   --VARCHAR2(1 BYTE),
                        ,BOTTLE_INITIAL_INV    --VARCHAR2(3 BYTE),
                        ,RATE_SCHEDULE                --VARCHAR2(4 BYTE),
                        ,CHARGE_DEPOSIT               --VARCHAR2(1 BYTE),
                        ,PREFERRED_CUSTOMER_FLAG      --VARCHAR2(1 BYTE),
                        ,PENDING                      --VARCHAR2(1 BYTE),
                        ,BSC_FLAG                     --VARCHAR2(1 BYTE),
                        ,CREDIT_SCORE                 --VARCHAR2(4 BYTE),
                        ,TERM_FEE_AMOUNT              --NUMBER,
                        ,AGREEMENT_TERM               --VARCHAR2(30 BYTE),
                        ,BOTTLE_DEPOSIT_AMT           --NUMBER,
                        ,DELIVERY_TICKET_PRINT_FLAG   --VARCHAR2(1 BYTE),
                        ,TIER_PRICE_PROC_FLAG         --VARCHAR2(1 BYTE) DEFAULT 'N',
                        ,BOT_DEPOSIT_PROC_FLAG        --VARCHAR2(1 BYTE) DEFAULT 'N'
                        --,HOLD_REASON                --VARCHAR2(10),
                        ,WILL_CALL_FLAG               --VARCHAR2(1)
                        ,SUB_CUST_NUMBER              --VARCHAR2(40)
                       ,PRICE_LIST_NAME
                        ,CRV_SUPPRESS
                        ,ALLOW_MULTIPLE_TIX
                        ,TICKET_COPIES
                        ,STORE_STAMP
                        ,SPLIT_TRXN
                        ,TICKET_SCAN
                        ,PRIMO_TYPE
                        ,PRIMO_AR_PRICE_LIST
                        ,PRIMO_ACCT_NO
                        ,PRIMO_EMPTY_CREDIT
                        ,PROCESSED_FLAG
                     )
                  VALUES
                     (   l_ship_site_id_seq
                        ,l_cust_id
                        ,l_ship_addr_id
                        ,l_bill_site_id
                        ,l_sub_cust_rec.ship_to_master
                        ,to_char(l_ship_site_id_seq)
                        ,l_sub_cust_rec.customer_tax_class
                        ,l_sub_cust_rec.po_number
                        ,l_sub_cust_rec.po_effective_from_date
                        ,l_sub_cust_rec.po_effective_to_date
                        ,l_sub_cust_rec.po_total_dollars
                        ,l_sub_cust_rec.po_total_units
                        ,l_sub_cust_rec.customer_reference_number
                        ,l_sub_cust_rec.tax_exempt_number
                        ,l_sub_cust_rec.tax_exempt_exp_date
                        ,l_sub_cust_rec.tax_exempt_certificate_rcvd
                        ,l_sales_center_s
                        ,l_division_s
                        ,l_sub_cust_rec.route_number
                        ,l_sub_cust_rec.delivery_frequency
                        ,NULL       -- NEXT_REGULAR_DELIVER_DATE
                        ,NULL       -- DELIVERY_INSTRUCTIONS
                        ,NULL
                        ,NULL
                        ,l_sub_cust_rec.addressee
                        ,l_sub_cust_rec.delivery_frequency
                        ,NULL
                        ,l_sub_cust_rec.ship_to_start_date
                        ,NVL(l_sub_cust_rec.SUPPRESS_PRICE_HH_TICKET,'Y')
                        ,NVL(l_sub_cust_rec.RSR_OVERIDE_SUPPRESS_PRICE,'Y')
                        ,l_sub_cust_rec.BOTTLE_INITIAL_INV
                       ,NULL           --  RATE_SCHEDULE
                        ,'Y'            -- Default to Y for all Ship Tos  -- CHARGE_DEPOSIT
                        ,'N'            -- PREFERRED_CUSTOMER_FLAG
                        ,NULL           -- PENDING
                        ,'Y'            -- ESC_FLAG
                        ,NULL           -- CREDIT_SCORE -- 01/24/07:  Val will map it
                        ,0              -- TERM_FEE_AMOUNT -- $100 by default (Agreement - Term Fee column) -- update later?
                        ,'GFAGR'        -- AGREEMENT_TERM -- Default from the Agreement code (Agreement - Term Code column) -- update later?
                        ,NULL           -- BOTTLE_DEPOSIT_AMT -- If the amount in this field is different that what is on the price list then
                        ,'Y'            -- DELIVERY_TICKET_PRINT_FLAG
                        ,'N'            -- TIER_PRICE_PROC_FLAG
                        ,'N'            -- BOT_DEPOSIT_PROC_FLAG
                        ,l_sub_cust_rec.willcall_flag
                        ,l_sub_cust_rec.customer_number
                        ,l_price_list_id
                        ,l_sub_cust_rec.crv_suppress
                        ,l_sub_cust_rec.allow_multiple_tix
                        ,l_sub_cust_rec.ticket_copies
                        ,l_sub_cust_rec.store_stamp
                        ,l_sub_cust_rec.split_trxn
                        ,l_sub_cust_rec.ticket_scan
                        ,l_sub_cust_rec.primo_type
                        ,l_pr_price_list_id
                        ,l_sub_cust_rec.primo_acct_no
                        ,l_sub_cust_rec.primo_empty_credit
                        ,'N'
                     );

                  l_ship_site_id      :=      l_ship_site_id_seq;

                  Fnd_File.Put_Line(Fnd_File.LOG,'Total Rows SWGCNV_DD_CUSTOMER_SHIPTO: '||sql%rowcount);

                  -- Contact Info

                  INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                     (   CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                        ,ADDRESS_ID           --NUMBER(15),
                        ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                        ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                        ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                        ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                        ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                        ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                        ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                     )
                  VALUES
                     (   l_cust_id
                        ,l_ship_addr_id
                        ,NVL(l_sub_cust_rec.contact_first_name, 'ACCOUNTS')   -- Added by Bala Palani EB-670
                        ,NVL( l_sub_cust_rec.contact_last_name, 'PAYABLE' )
                        ,NVL(substr(l_sub_cust_rec.phone,1,3), '111')         -- Added by Bala Palani EB-1156
                        ,NVL(substr(l_sub_cust_rec.phone,4,10), '1111111')     -- Added by Bala Palani EB-1156
                        ,substr(l_sub_cust_rec.phone,11)
                        ,'PHONE'
                        ,NULL
                     );

                  Fnd_File.Put_Line(Fnd_File.LOG,'Total Rows SWGCNV_DD_CUSTOMER_CONTACT: '||sql%rowcount);

                  -- Added For SAGE Conversion
                  IF ( l_sub_cust_rec.email_address IS NOT NULL ) THEN

                     INSERT INTO SWGCNV_DD_CUSTOMER_CONTACT
                        (   CUSTOMER_ID          --NUMBER(15)               NOT NULL,
                           ,ADDRESS_ID           --NUMBER(15),
                           ,CONTACT_FIRST_NAME   --VARCHAR2(40 BYTE),
                           ,CONTACT_LAST_NAME    --VARCHAR2(50 BYTE),
                           ,TELEPHONE_AREA_CODE  --VARCHAR2(10 BYTE),
                           ,TELEPHONE            --VARCHAR2(25 BYTE)        NOT NULL,
                           ,TELEPHONE_EXTENSION  --VARCHAR2(20 BYTE),
                           ,TELEPHONE_TYPE       --VARCHAR2(30 BYTE)        NOT NULL,
                           ,EMAIL_ADDRESS        --VARCHAR2(240 BYTE)
                        )
                     VALUES
                        (   l_cust_id
                           ,l_ship_addr_id
                           ,NVL(l_sub_cust_rec.contact_first_name, 'ACCOUNTS')   -- Added by Bala Palani EB-670
                           ,NVL( l_sub_cust_rec.contact_last_name, 'PAYABLE' )
                           ,NVL(SUBSTR(l_sub_cust_rec.phone,1,3), '111')               -- Added by Bala Palani EB-1156
                           ,NVL(SUBSTR(l_sub_cust_rec.phone,4,10), '1111111')          -- Added by Bala Palani EB-1156
                           ,substr(l_sub_cust_rec.phone,11)
                           ,'EMAIL'
                           ,l_sub_cust_rec.email_address
                        );
                        
                       Fnd_File.Put_Line(Fnd_File.LOG,'Total Rows SWGCNV_DD_CUSTOMER_CONTACT (EMAIL): '||sql%rowcount);

                  END IF;

                 INSERT INTO SWGCNV_DD_CYCLEDAYS
                    (    CUSTOMER_ID           --NUMBER(15),
                        ,SHIPPING_SITE_ID      --NUMBER(15),
                        ,ROUTE_SERVICE_DAY     --VARCHAR2(2 BYTE),
                        ,ROUTE_SEQUENCE        --NUMBER(15),
                        ,CYCLE_DAY             --VARCHAR2(2 BYTE),
                        ,DRIVING_INSTRUCTIONS  --VARCHAR2(2000 BYTE)
                    )
                 VALUES
                    (    l_cust_id
                        ,l_ship_site_id
                        ,to_number(l_sub_cust_rec.route_day)
                        ,to_number(nvl(l_sub_cust_rec.route_seq,999))
                        ,to_number(l_sub_cust_rec.route_day)
                        ,NULL
                    );
                    
              Fnd_File.Put_Line(Fnd_File.LOG,'Total Rows SWGCNV_DD_CYCLEDAYS: '||sql%rowcount);
              
              IF l_sav_customer_number_s <> l_sub_cust_rec.ship_to_master THEN
              --insert dummy row into swgcnv_dd_customer_interface
                 l_sav_customer_number_s := l_sub_cust_rec.ship_to_master;
                 INSERT INTO swgcnv_dd_customer_interface 
                   (customer_number,
                    customer_id,
                    customer_name,
                    person_flag,
                    person_first_name,
                    person_last_name,
                    service_interested_in,
                    how_did_you_hear_about_us,
                    service_location,
                    no_of_people_using_service,
                    what_prompted_interest,
                    current_product_or_service,
                    monthly_invoice_format,
                    signed_delviery_receipt,
                    billing_communications,
                    sales_center,
                    division
                    )
                 VALUES
                   (l_sub_cust_rec.ship_to_master,
                    l_cust_id,
                    l_sub_cust_rec.party_name,
                    l_sub_cust_rec.person_flag,
                    l_sub_cust_rec.contact_first_name,
                    l_sub_cust_rec.contact_last_name,					
                    'ALL',
                    'Z-ACQUISITION',
                    'OFFICE',
                    1,
                    'ALL OF ABOVE',
                    'ALL OF ABOVE',
                    'MULTIPLE SHIP-TO',
                    'N',  --EB=2793 'C',
                    'MAIL',
                    in_sales_center_s,
                    l_division_s
                   );
                    
                    INSERT INTO SWGCNV_DD_CUSTOMER_BILLTO  (
                       BILLTO_SITE_ID               --NUMBER(15)           NOT NULL,
                      ,CUSTOMER_ID                  --NUMBER(15)           NOT NULL,
                      ,BILL_TO_ADDRESS_ID           --NUMBER(15)           NOT NULL,
                      ,CUSTOMER_NUMBER              --VARCHAR2(10 BYTE)    NOT NULL,
                      ,BILLING_LOCATION_NUMBER      --VARCHAR2(10 BYTE)    NOT NULL,
                      ,REMIT_TO_ADDRESS             --VARCHAR2(150 BYTE)   NOT NULL,
                      ,CUSTOMER_PROFILE_CLASS_NAME  --VARCHAR2(30 BYTE)    NOT NULL,
                      ,ACCOUNT_STATUS               --VARCHAR2(40 BYTE)    NOT NULL,
                      ,SALES_CENTER                 --VARCHAR2(3 BYTE)     NOT NULL,
                      ,DIVISION                     --VARCHAR2(50 BYTE)    NOT NULL,
                               )
                    VALUES
                    (
                       l_bill_site_id
                      ,l_cust_id
                      ,l_bill_site_id  --l_addr_id
                      ,l_sub_cust_rec.ship_to_master
                      ,l_bill_site_id
                      ,'FUL'
                      ,' '
                      ,' '
                      ,l_sales_center_s           
                      ,l_division_s               
                     );
                           
                     FOR bill_to_address_rec IN cur_bill_to_address(l_bill_site_id) LOOP
                         INSERT INTO SWGCNV_DD_ADDRESSES (
                            ADDRESS_ID            --NUMBER(15)              NOT NULL,
                           ,CUSTOMER_ID           --NUMBER(15)              NOT NULL,
                           ,CUSTOMER_NUMBER       --VARCHAR2(10 BYTE)       NOT NULL,
                           ,ADDRESS1              --VARCHAR2(240 BYTE),
                           ,ADDRESS2              --VARCHAR2(240 BYTE),
                           ,CITY                  --VARCHAR2(60 BYTE),
                           ,STATE                 --VARCHAR2(60 BYTE),
                           ,PROVINCE              --VARCHAR2(60 BYTE),
                           ,POSTAL_CODE           --VARCHAR2(60 BYTE),
                           ,COUNTRY               --VARCHAR2(60 BYTE)       NOT NULL,
                           ,DOCK_TYPE             --VARCHAR2(150 BYTE),
                           ,SALES_CENTER          --VARCHAR2(3 BYTE)        NOT NULL,
                           ,ADDR_CLEAN_UP_FLAG    --VARCHAR2(1 BYTE)        DEFAULT 'N',
                           ,DIVISION              --VARCHAR2(10 BYTE)       NOT NULL,
                           )
                       VALUES
                           (
                            l_bill_site_id
                           ,l_cust_id
                           ,l_sub_cust_rec.customer_number
                           ,bill_to_address_rec.ADDRESS1
                           ,bill_to_address_rec.ADDRESS2
                           ,bill_to_address_rec.CITY
                           ,bill_to_address_rec.STATE
                           ,bill_to_address_rec.PROVINCE
                           ,bill_to_address_rec.POSTAL_CODE
                           ,bill_to_address_rec.country
                           ,'ALL'
                           ,l_sales_center_s   
                           ,'N'
                           ,l_division_s       
                           );
                      END LOOP;                      
              END IF;
              


    END LOOP;
    
    CLOSE cur_sub_cust_data;
    
    process_first_cycle_day;
    
    IF g_error_flag_c != 'Y' THEN
         UPDATE SWGCNV_DD_CB_PRESTAGING_SHIPTO
         SET    processed_flag   = 'Y'
               ,processed_status = 'S'
               ,error_message    = NULL
         WHERE sales_center = in_sales_center_s;
    END IF;

    l_end_time_d    :=      SYSDATE;
    Fnd_File.Put_Line(Fnd_File.OUTPUT,'*************************  RUN STATISTICS *******************************');
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Ship-To Records Read           : ' || l_cust_recs_read_n);
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' ------------------------------------------------------------------------');
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' Start Time : ' || TO_CHAR(l_start_time_d, 'MM/DD/RRRR HH24:MI:SS'));
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' End Time   : ' || TO_CHAR(l_end_time_d, 'MM/DD/RRRR HH24:MI:SS'));
    Fnd_File.Put_Line(Fnd_File.OUTPUT,'*************************************************************************');


 -- Interface/Staging table update

EXCEPTION

    WHEN INIT_ERROR THEN
        ou_errbuf2_s     :=  'Initialization / Bulk Collect Error encountered.' || l_error_message_s;
        ou_errcode2_n    :=  2;
        RETURN;

    WHEN OTHERS THEN

        l_error_message_s   := SQLERRM;

        swg_cust_debug('Y',l_error_message_s);
        dbms_output.put_line(l_error_message_s);
        --Fnd_File.Put_Line(Fnd_File.LOG,l_error_message_s);

        ou_errbuf2_s         :=     'Unexpected Error in procedure insert_sub_cust: '||l_error_message_s;
        ou_errcode2_n        :=     2;

        --Fnd_File.Put_Line(Fnd_File.LOG,'Unexpected Error: '||l_error_message_s);

       RETURN;

END insert_shipto_cust;

--SGG

END Swgcnv_CB_Cust_stgload_Pkg;
/
SHOW ERRORS;
EXIT;
