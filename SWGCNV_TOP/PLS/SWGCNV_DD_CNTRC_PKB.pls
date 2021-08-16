CREATE OR REPLACE PACKAGE BODY  Swgcnv_Dd_Cntrc_Pkg AS
/*===========================================================================================+
| Copyright (c) 2005 DS Waters, Atlanta, GA 30328 USA All rights reserved.                   |
+============================================================================================+
|                                                                                            |
| Name:           SWGCNV_DD_CNTRC_PKG                                                        |
| File:           SWGCNV_DD_CNTRC_PKB.pls                                                    |
| Description:    Package For Rental Contract Creation                                       |
|                                                                                            |
| Company:        DS Waters                                                                  |
|                                                                                            |
| Author:         Unknown                                                                    |
| Date:           Unknown                                                                    |
|                                                                                            |
| Modification History:                                                                      |
| Date            Author           Description                                               |
| ----            ------           -----------                                               |
| Unknown         Unknown          Production Release                                        |
| 04/24/2008      Pankaj Umate     Modified For PURPLM Conversion. Daptiv No: 368            |
| 04/28/2008      Pankaj Umate     Modified For RAM01 Conversion. Daptiv No: 429             |
| 08/06/2008      Pankaj Umate     Modified For WTRFLX1 Conversion. Daptiv No: 555           |
| 10/24/2008      Pankaj Umate     Modified For RHDIST  Conversion Maysville. Daptiv No: 721 |
| 12/03/2008      Pankaj Umate     Modified For ARS03 Conversion. Daptiv No: 753             |
| 01/12/2009      Pankaj Umate     Modified For ARS04 Conversion. Daptiv No: 768             |
| 01/12/2009      Vijay            Modified for IBM01 Conversion WO:20129.                   |
| 03/12/2014      Mike Schenk      Jira 431 add ship_to's to existing Oracle customer        |
| 08/06/2014      Suganthi Uthaman Modified for HDPRIMO Conversion. EB-829                   |
| 08/25/2015      Bala Palani      Defaulted SYSDATE for contract start date Jira EB-1555    |
| 09/21/2015      Bala Palani      Fetch contract start date from staging table Jira EB-1596 |  
| 11/02/2015      Stephen Bowen    EB-1667 Remove SalesCenter piece from BOH                 |  
|===========================================================================================*/

-------------------------------------------------------------------------------------------------
PROCEDURE debug_mesg
( in_message_s      IN    VARCHAR2
)
IS

BEGIN

    IF  g_flag_c =  'Y' THEN
  Fnd_File.Put_Line(Fnd_File.LOG,in_message_s);
    END IF;

END   debug_mesg;
-------------------------------------------------------------------------------------------------

PROCEDURE Get_Rental_Code
( in_system_code_s        IN  VARCHAR2
 ,in_sales_center_s         IN  VARCHAR2
 ,in_lgcyitem_sub_code_s    IN  VARCHAR2
 ,in_legacyitemcode_s   IN  VARCHAR2
 ,in_placement_code_s       IN  VARCHAR2
 ,io_rentalitemcode_s   IN OUT  VARCHAR2
 ,io_originvitemId_n    IN OUT  NUMBER
 ,io_quantity_n         IN OUT  NUMBER
 ,io_uomcode_s          IN OUT  VARCHAR2
 ,io_process_flag_c       IN OUT  VARCHAR2
 ,io_related_item_id_n    IN OUT  VARCHAR2
 ,io_msg_data_s         IN OUT  VARCHAR2
 ,io_serial_controlled_c    IN OUT  VARCHAR2
)
IS

    --
    -- Cursor declaration Section
    --

    CURSOR Cur_OrgItemId ( in_segment1_s  IN  VARCHAR2
              ,in_organization_id_n IN  NUMBER
             )
    IS
    SELECT  Inventory_Item_Id   OrigInvItemId,
      1       Quantity,
     'EA'       Uom_Code,
      Serial_Number_Control_Code  SrCntrlCode
    FROM    Mtl_System_Items
    WHERE   segment1    = in_segment1_s
    AND     organization_id = in_Organization_Id_n;


-- Check Item is Exist in INV DIRECT DELIVERY Organization (DDL) Added Naren 07/10/2002

   CURSOR org_check ( in_inventory_item_id IN NUMBER )
   IS
   SELECT inventory_item_id
   FROM   Mtl_System_Items
   WHERE  inventory_item_id   = in_inventory_item_id
   AND    organization_id = 6;

    CURSOR  Cur_RelatedItem ( in_InvItemId_n    IN  NUMBER
           ,in_Organization_Id_n  IN  NUMBER
         )
    IS
    SELECT  Related_Item_Id
    FROM    Mtl_Related_Items
    WHERE   Inventory_Item_Id = in_InvItemId_n
    AND     organization_id = in_Organization_Id_n;

    CURSOR   Cur_RentalCode ( in_RelatedItemId_n  IN  NUMBER
          ,in_Organization_Id_n IN  NUMBER
         )
    IS
    SELECT  Segment1
    FROM    Mtl_System_Items
    WHERE   Inventory_Item_Id = in_RelatedItemId_n
    AND     organization_id = in_Organization_Id_n;


--Variable Declaration section

    l_Rental_Code_s   Mtl_System_Items.Segment1%TYPE;

    l_New_Code_s    VARCHAR2(100);
    l_New_Sub_Code_s    VARCHAR2(100);
    l_legacy_system_s   VARCHAR2(100);
    l_error_mesg_s    VARCHAR2(1000);
    l_UomCode_s     VARCHAR2(30);

    l_status_c              VARCHAR2(1);
    l_error_message_s       VARCHAR2(2000);

    l_Original_Item_Id_n  NUMBER;
    l_Quantity_n    NUMBER;
    l_SrlCntrlCode_n    NUMBER;
    l_Related_Item_Id_n   NUMBER;
    l_org_item_id   NUMBER;

    l_item_rec              Swgcnv_Cntrct_Vldt.item_info_rec_type;
    l_org_rec               Swgcnv_Cntrct_Vldt.org_info_rec_type;

BEGIN

--Initialiation of variables

    l_Rental_Code_s :=  NULL;
    io_RentalItemCode_s :=  NULL;
    io_OrigInvItemId_n  :=  NULL;
    io_Quantity_n :=  NULL;
    io_UomCode_s  :=  NULL;
    io_process_flag_c :=  'Y';
    io_msg_data_s :=  'SUCCESS';
    io_serial_controlled_c  := 'Y';

    debug_mesg('Before calling item map ');
    debug_mesg('Oracle Item code '||l_new_code_s);
    debug_mesg('Legacy model code '||in_legacyItemcode_s);

--Check for the legacy item code for null

    IF in_legacyItemcode_s  IS NULL
    THEN
  io_process_flag_c :=  'N';
  io_msg_data_s   :=  'ERROR: Legacy model Code is NULL ';
  RETURN;
    END IF;

    BEGIN

         Swgcnv_Cntrct_Vldt.Get_Maps_And_Details
         ( in_sacs_org_s         => in_sales_center_s
         ,in_sacs_brand_s   => in_lgcyitem_sub_code_s
         ,in_sacs_item_s        => in_legacyItemcode_s
         ,in_eff_date_d     => TRUNC(SYSDATE)
         ,io_item_rec     => l_item_rec
         ,io_org_rec          => l_org_rec
         ,io_status_c     => l_status_c
         ,io_message_s      => l_error_message_s
         ,in_debug_c          => Swgcnv_Cntrct_Vldt.G_DEBUG
         ,in_system_code_c       => in_system_code_s );



       IF l_status_c != Swgcnv_Cntrct_Vldt.G_STS_SUCCESS THEN

            l_error_message_s :=  in_system_code_s||'-'||LTRIM(RTRIM(in_legacyItemcode_s))
                                    || 'Error returned from Get_Maps_And_Details: '
                                    || l_error_message_s;
         END IF;

         -- l_new_code_s    := l_item_rec.item_code; -- 2006/04/09 RIMLAP
         l_new_code_s    := l_item_rec.item_code; -- reverted

       IF l_status_c != Swgcnv_Cntrct_Vldt.G_STS_SUCCESS
       THEN
          io_process_flag_c :=  'N';
            io_msg_data_s   :=  l_error_message_s;
          RETURN;
     END IF;

       debug_mesg('Oracle Item code  '||l_new_code_s);
       debug_mesg('Legacy model code '||in_legacyItemcode_s);

    EXCEPTION
      WHEN OTHERS THEN
          io_process_flag_c :=  'N';
          io_msg_data_s :=  'ERROR: Unable to find Corresponding Oracle Item. '||in_LegacyItemCode_s;
          RETURN;
    END;
    -------------------------------------------------------------

    -- open the Organisation Item cursor

    OPEN    Cur_OrgItemId ( l_new_code_s
         ,G_SWG_MASTER_ORG
        );
    FETCH   Cur_OrgItemId
    INTO    l_Original_Item_Id_n,
      l_Quantity_n,
      l_UomCode_s,
      l_SrlCntrlCode_n;

        IF   Cur_OrgItemId%NOTFOUND
        THEN
         l_Original_Item_Id_n := NULL;
        END IF;
    CLOSE   Cur_OrgItemId;

    debug_mesg('Item id from table'||l_Original_Item_Id_n);

    IF  l_Original_Item_Id_n IS NULL
    THEN
  io_process_flag_c :=  'N';
      io_msg_data_s   :=  ' ERROR: Invalid Mapping New Code. '||l_new_code_s||
            ' Legacy model Code: '||in_LegacyItemCode_s;
  RETURN;
    END IF;

    IF  l_SrlCntrlCode_n  NOT IN (2,5,6) AND in_legacyItemcode_s NOT IN ('0277','0279','0310', '0312')
    THEN
        io_serial_controlled_c  := 'N';
--  RETURN;
    END IF;

    -------------------------------------------------------------

    -- Check the Oracle Item is assigned to INV DIRECT DELIVERY Organization (DDL) Added by Naren 07/10/02

  OPEN  org_check (l_Original_Item_Id_n);
  FETCH org_check INTO  l_org_item_id;

    IF  org_check%NOTFOUND  THEN

      l_org_item_id :=  NULL;
    END IF;
  CLOSE   org_check;

  IF  l_org_item_id IS NULL
  THEN
    io_process_flag_c :=  'N';
    io_msg_data_s   :=  'ERROR: '||l_new_code_s ||
            ' Not Assigned to INV DIRECT DELIVERY Organization (DDL)';
    RETURN;
  END IF;

   ------------------------------------------------------------

    -- get related item info if the item is not SACS CPP

    IF in_placement_code_s NOT IN ('LOSS','SOLD','WRITEOFF','PULLED') THEN --in_legacyItemcode_s NOT IN ('0277','0279')   THEN
       OPEN   Cur_RelatedItem ( l_Original_Item_Id_n
            ,G_SWG_MASTER_ORG
           );

       FETCH  Cur_RelatedItem
       INTO   l_Related_Item_Id_n;

           IF Cur_RelatedItem%NOTFOUND
           THEN
      l_Related_Item_Id_n := NULL;
           END IF;
       CLOSE  Cur_RelatedItem;

       IF l_Related_Item_Id_n IS NULL
       THEN
    io_process_flag_c :=  'N';
    io_msg_data_s   :=  'ERROR: Related Rental Code Not found. '||
                'Oracle Item Id: '||l_Original_Item_Id_n||
                'Legacy model Code: '||in_LegacyItemCode_s;
          RETURN;
       END IF;
    -------------------------------------------------------------

       OPEN    Cur_RentalCode ( l_Related_Item_Id_n
             ,G_SWG_MASTER_ORG
            );
       FETCH   Cur_RentalCode
       INTO    l_Rental_Code_s;

        IF  Cur_RentalCode%NOTFOUND
        THEN
      l_Rental_Code_s := NULL;
        END IF;
       CLOSE   Cur_RentalCode;

        IF  l_Rental_Code_s IS NULL
        THEN
      io_process_flag_c :=  'N';
      io_msg_data_s   :=  'ERROR: Invalid Related Item Id: '||l_Related_Item_Id_n||
                ' Legacy Part Code: '||in_LegacyItemCode_s;
            RETURN;
        END IF;

    END IF;

    -------------------------------------------------------------

--Values returned back to the main contract program

    io_RentalItemCode_s   :=  l_Rental_Code_s;
    io_OrigInvItemId_n    :=  l_Original_Item_Id_n;
    io_Quantity_n   :=  l_Quantity_n;
    io_UomCode_s    :=  l_UomCode_s;
    io_related_item_id_n    :=  l_Related_Item_Id_n;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
    io_process_flag_c :=  'N';
          io_msg_data_s   :=  l_error_mesg_s;
       WHEN OTHERS THEN
      io_process_flag_c :=  'N';
          io_msg_data_s   :=  'Get_Rental_code Others '||SQLERRM;
    RETURN;

END   Get_Rental_Code;

--------------------------------------------------------------

PROCEDURE Update_InstalledBase
(
  in_write_off_date_d       IN  DATE
 ,in_return_date_d          IN  DATE
 ,in_cp_id_n                IN  NUMBER
 ,in_cp_rec                 IN  Swg_Installedbase_Pub_Pkg.ib_instl_rec_type
 ,x_Return_Status_c       OUT VARCHAR2
 ,x_Msg_Count_n         OUT NUMBER
 ,x_MSG_Data_s          OUT VARCHAR2
 ,x_PlaceofError_s        OUT VARCHAR2
)
IS
    l_cp_rec        Swg_Installedbase_Pub_Pkg.ib_instl_rec_type;
    l_cp_id_n               NUMBER;

BEGIN

    l_cp_rec    := in_cp_rec;

    l_cp_id_n   := in_cp_id_n;


    IF in_write_off_date_d IS NOT NULL THEN

        l_cp_rec.end_date_active    := in_write_off_date_d;

    ELSIF in_return_date_d IS NOT NULL THEN

        l_cp_rec.actual_returned_date   := in_return_date_d;
        l_cp_rec.return_by_date         := in_return_date_d;

    END IF;

    Swg_Installedbase_Pub_Pkg.Update_Product
    (p_api_version          => 1.0
    ,p_init_msg_list        => Fnd_Api.G_TRUE
    ,p_commit             => Fnd_Api.G_FALSE
    ,x_return_status        => x_return_status_c
    ,x_msg_count            => x_msg_count_n
    ,x_msg_data             => x_msg_data_s
    ,p_cp_id                => l_cp_id_n
    ,p_as_of_date           => TRUNC(SYSDATE)
    ,p_cp_rec               => l_cp_rec
    ,p_org_id               => NULL);

  IF X_Return_Status_c != Fnd_Api.G_RET_STS_SUCCESS THEN
    x_PlaceofError_s  :=  'Update Installbase API';
    x_msg_data_s    :=  SUBSTR(x_msg_data_s, 1, 1998);
    RETURN;
  END IF;

END     Update_InstalledBase;

-- New installed base API procedure

PROCEDURE Create_InstalledBase
( in_OrgId_n      IN  NUMBER
 ,in_CustomerId_n   IN  NUMBER
 ,in_InvItemId_n    IN  NUMBER
 ,in_CpStatusId_n   IN  NUMBER
 ,in_Quantity_n     IN  NUMBER
 ,in_UomCode_s      IN  VARCHAR2
 ,in_BillTo_AddressId_n   IN  NUMBER
 ,in_ShipTo_PartySiteId_n IN  NUMBER
 ,in_Installed_Date_d   IN  DATE
 ,in_Shipped_Date_d   IN  DATE
 ,in_Serial_NUmber_s    IN  VARCHAR2
 ,in_escrow_amount_n    IN  NUMBER
 ,X_Customer_ProductId_n  OUT NUMBER
 ,X_Obj_Version_Num_n   OUT NUMBER
 ,X_New_CPId_n      OUT NUMBER
 ,x_Return_Status_c   OUT VARCHAR2
 ,x_Msg_Count_n     OUT NUMBER
 ,x_MSG_Data_s      OUT VARCHAR2
 ,x_PlaceofError_s    OUT VARCHAR2
 ,x_cp_rec              OUT Swg_Installedbase_Pub_Pkg.ib_instl_rec_type
)
IS

    l_cp_rec        Swg_Installedbase_Pub_Pkg.ib_instl_rec_type;

BEGIN

  l_cp_rec.customer_id    :=    in_CustomerId_n;
  l_cp_rec.inv_item_id    :=    in_InvItemId_n;
  l_cp_rec.cp_status_id   :=    in_CpStatusId_n;
  l_cp_rec.quantity   :=    in_Quantity_n;
  l_cp_rec.uom_code   :=    in_UomCode_s;
  l_cp_rec.currency_code    :=    'USD';

  l_cp_rec.installation_date  :=    in_Installed_Date_d;
  l_cp_rec.shipped_date   :=    in_Shipped_Date_d;
  l_cp_rec.install_site_use_id  :=    in_ShipTo_PartySiteId_n;

  IF NVL(in_escrow_amount_n,0) != 0 THEN
        l_cp_rec.attribute4   :=  LTRIM(RTRIM(TO_CHAR(in_escrow_amount_n,'99999990.00')));
    END IF;

  l_cp_rec.serial_number    :=    in_Serial_Number_s;
  l_cp_rec.order_line_id    :=    Fnd_Api.G_MISS_NUM;


  -- Call the new Instalbase API

  Swg_Installedbase_Pub_Pkg.Create_Base_Product
           ( p_api_version        =>  1.0
            ,p_init_msg_list        =>  Fnd_Api.G_TRUE
            ,p_commit             =>  Fnd_Api.G_FALSE
            ,x_return_status        =>  x_return_status_c
            ,x_msg_count            =>  x_msg_count_n
            ,x_msg_data             =>  x_msg_data_s
            ,p_cp_rec         =>  l_cp_rec
            ,p_created_manually_flag  =>  'N'
            ,p_org_id           =>  NULL
            ,x_cp_id                  =>  X_Customer_ProductId_n
            ,x_object_version_number  =>  X_Obj_Version_Num_n
           );

  IF X_Return_Status_c != Fnd_Api.G_RET_STS_SUCCESS THEN
    x_PlaceofError_s  :=  'Instalbase API';
    x_msg_data_s    :=  SUBSTR(x_msg_data_s, 1, 1998);
    RETURN;
  END IF;

    x_cp_rec    := l_cp_rec;

END Create_InstalledBase;

-------------------------------------------------------------------------------------------------

PROCEDURE Insert_Exceptions
          (  in_Type_s             IN  VARCHAR2
            ,in_customer_Number_s  IN  VARCHAR2
            ,in_Address_Code_s     IN  VARCHAR2
            ,in_Error_Message_s    IN  VARCHAR2
            ,in_sales_center_s     IN  VARCHAR2
          )
IS
BEGIN

    INSERT
    INTO  swgcnv_conversion_exceptions
    ( conversion_type
     ,conversion_key_value
     ,conversion_sub_key1
     ,error_message
     ,conversion_sub_key2
    )
    VALUES  ( in_Type_s
     ,in_Customer_Number_s
     ,in_Address_Code_s
     ,in_Error_Message_s
     ,in_sales_center_s
    );

END Insert_Exceptions;
-------------------------------------------------------------------------------------------------

PROCEDURE contract_main
( ou_errbuf_s           OUT VARCHAR2
 ,ou_errcode_n          OUT NUMBER
 ,in_system_code_s      IN  VARCHAR2
 ,in_division_s         IN  VARCHAR2
 ,in_sales_center_s     IN  VARCHAR2
 ,in_debug_c            IN  VARCHAR2    DEFAULT 'N'
 ,in_validate_only_c    IN  VARCHAR2    DEFAULT 'Y'
)
IS

-- Cursor defination

    CURSOR    Cur_Main
                (  in_system_code_s     IN  VARCHAR2
                  ,in_sales_center_s    IN  VARCHAR2)
    IS
    SELECT a.ROWID  row_id
          ,i.customer_start_date
          ,a.*
    FROM  swgcnv_dd_temp_customers       a
         ,swgcnv_dd_customer_interface   i
    WHERE a.new_sales_center      = in_sales_center_s
    AND   a.Cust_Import_Flag      = 'Y'
    AND   a.Contracts_Proc_Flag   = 'N'
    AND   i.sales_center          = a.new_sales_center
    AND   i.customer_number       = a.legacy_customer_number;

-- Get the New Customer Id, Part Id based on Old Customer Number

    CURSOR    Cur_NewCstmr ( in_orig_system_customer_ref_s  IN  VARCHAR2 )
    IS
    SELECT  Party_Id    Party_Id,
    Cust_Account_Id   Customer_Id,
    Account_Number    Customer_Number
    FROM  hz_cust_Accounts
    WHERE Orig_System_Reference   = in_orig_system_customer_ref_s;

-- Get the install base status id

    CURSOR  Cur_CpStatus ( in_CpStatusName_s  IN  VARCHAR2 )
    IS
    SELECT  Customer_Product_Status_Id
    FROM  Cs_Customer_Product_Statuses
    WHERE Name        = in_CpStatusName_s;


-- Check the install base created

    CURSOR  Cur_instalbase_check (  in_cust_id_n  IN  NUMBER
          ,in_item_id_n   IN  NUMBER
          ,in_shipto_id_n IN  NUMBER
          ,in_serial_n  IN  VARCHAR2
          ,in_status_id_n IN  NUMBER)
    IS
    SELECT  customer_product_id
    FROM  cs_customer_products
    WHERE customer_id     = in_cust_id_n
    AND   inventory_item_id   = in_item_id_n
    AND   ship_to_site_use_id   = in_shipto_id_n
    AND   current_serial_number   = in_serial_n
    AND   customer_product_status_id  = in_status_id_n;


-- Get the Rental Information From the Legacy Equipment

    CURSOR  Cur_LegacyRntlEqp (  in_new_sales_center_s IN  VARCHAR2
           ,in_Customer_Number_s  IN  VARCHAR2
           ,in_Address_Code_s     IN  VARCHAR2
          )
    IS
    SELECT  Eqp.*
    FROM   Swgcnv_dd_Eqpmnt_interface    Eqp
        ,  swgcnv_dd_customer_shipto      s
    WHERE (s.customer_number            =   in_customer_number_s OR s.sub_cust_number = in_customer_number_s)
    AND   s.delivery_location_number    =   in_address_code_s
    AND   (Eqp.Customer_Number          =   s.customer_number OR Eqp.customer_number = s.sub_cust_number)
    AND   Eqp.delivery_location_number  =   s.delivery_location_number  --in_Address_Code_s
    AND     eqp.placement_code          != 'POSITIVE' -- ignores depositable items
    AND nvl(eqp.valid_flag,'N')         != 'E';          -- ignores invalid items



-- Get the bill to ship to cursor

    CURSOR  cur_shipto_info ( in_Customer_Id_n    IN  NUMBER
         ,in_orig_system_customer_ref_s IN  VARCHAR2
        )
    IS
    SELECT  ship_site.site_use_id       ship_to_site_use_id,
    ship_site.warehouse_id        salescenter,
    RTRIM(LTRIM(SUBSTR(ship_addr.orig_system_reference,instr(ship_addr.orig_system_reference,'-',1,2)+1,instr(ship_addr.orig_system_reference,'-',1,3)-1-instr(ship_addr.orig_system_reference,'-',1,2)))) lgcy_sales_center, 
    ship_addr.orig_system_reference     orig_system_address_ref,
    CASE WHEN SUBSTR(ship_addr.orig_system_reference,4,6) = 'SHIPTO' THEN    --MTS 431
     SUBSTR(ship_addr.orig_system_reference,instr(ship_addr.orig_system_reference,'-',-1) + 1,20) 
    ELSE 
    RTRIM(LTRIM(SUBSTR(
                SUBSTR(ship_addr.orig_system_reference,LENGTH(in_orig_system_customer_ref_s)+2)
                ,1
                ,DECODE(INSTR(ship_addr.orig_system_reference,'-HEADER')
                    ,0,10
                    ,INSTR(ship_addr.orig_system_reference,'-HEADER')
                        -(LENGTH(in_orig_system_customer_ref_s)+2) )))) END             address_code,
    ship_addr.party_site_id       ship_to_party_site_id,
    ship_addr.cust_acct_site_id     ship_to_address_id,
    bill_site.site_use_id       bill_to_site_use_id,
    bill_site.payment_term_id     payment_term_id,
    bill_addr.party_site_id       bill_to_party_site_id,
    bill_addr.cust_acct_site_id     bill_to_address_id
    FROM  hz_cust_acct_sites      ship_addr,
    hz_cust_acct_sites      bill_addr,
    hz_cust_site_uses     ship_site,
    hz_cust_site_uses     bill_site,
    hz_cust_accounts      cust
    WHERE cust.cust_account_id    = in_customer_id_n
    AND   cust.cust_account_id    = ship_addr.cust_account_id
    AND   ship_addr.cust_acct_site_id = ship_site.cust_acct_site_id
    AND   ship_site.site_use_code   = 'SHIP_TO'
    AND   ship_site.bill_to_site_use_id = bill_site.site_use_id
    AND   bill_site.site_use_code   = 'BILL_TO'
    AND   bill_site.cust_acct_site_id = bill_addr.cust_acct_site_id;

-- Variable declaration section

    TYPE  Temp_Cust_Tbl_Type  IS  TABLE OF  Cur_Main%ROWTYPE
    INDEX   BY  BINARY_INTEGER;

    l_temp_cust_tbl             Temp_Cust_Tbl_Type;
    l_temp_idx_bi             BINARY_INTEGER;
    l_temp_cust_rec             Cur_Main%ROWTYPE;
    l_cust_rec                Cur_Main%ROWTYPE;

    l_process_flag_c          VARCHAR2(1);
    l_serial_ctrl_c                 VARCHAR2(1);
    l_Orig_System_Customer_Ref_s    VARCHAR2(240);
    l_msg_data_s              VARCHAR2(2000);
    l_Errmsg_s                VARCHAR2(2000);
    l_Return_Status_c         VARCHAR2(1);
    l_error_mesg_s              VARCHAR2(2000);
--     l_legacy_addrcode_s      VARCHAR2(3);
    l_legacy_addrcode_s         VARCHAR2(20);
    l_item_code_s             VARCHAR2(100);
    l_uomcode_s               VARCHAR2(100);
    l_CpStatusName_s          VARCHAR2(100);
    l_Serial_Number_s           VARCHAR2(30);
    l_contract_status_s         VARCHAR2(30);
    l_PlaceOfErr_s              VARCHAR2(100);

    l_orgid_n               NUMBER;
    l_msg_count_n             NUMBER;
    l_conversion_userid_n       NUMBER;
    l_party_id_n              NUMBER;
    l_Customer_Id_n             NUMBER;
    l_customer_number_n         NUMBER;
    l_Original_InvItemId_n        NUMBER;
    l_related_item_id_n         NUMBER;
    l_Quantity_n                NUMBER;
    l_CpStatusId_n              NUMBER;
    l_CstmrPrdctId_n            NUMBER;
    l_ObjVrsn_n               NUMBER;
    l_NewCpId_n               NUMBER;
    l_contract_id_n             NUMBER;
    nu_l_CstmrPrdctId_n         NUMBER;
    nu_l_ObjVrsn_n              NUMBER;
    nu_l_NewCpId_n              NUMBER;
    l_create_instal_base        VARCHAR2(1);

    l_totl_recd_errors_n        NUMBER:=0;
    l_recs_read_n             NUMBER:=0;
    l_contract_recs_written_n       NUMBER:=0;
    l_instalbase_recs_written_n     NUMBER:=0;
    l_rec_datafile_n          NUMBER:=0;

    l_start_d               DATE;
    l_end_d                   DATE;
    l_installed_date          DATE;
    l_shipped_date_d          DATE;
    l_Installed_Date_d          DATE;
    l_start_date_d                  DATE;

    l_write_off_date_d              DATE;
    l_return_date_d                 DATE;

    ERROR_INSTALLBASE         EXCEPTION;
    ERROR_CONTRACT              EXCEPTION;

  l_next_billon_start_date      DATE;
        l_init_bill_from_date               DATE;
--  l_customer_start_date       DATE;
  l_rec_count                 NUMBER;
  l_item_id                 NUMBER;
  l_escrow_amount_n           NUMBER;
  l_status_name             VARCHAR2(100);

    l_service_type_s                VARCHAR2(20);

    l_cp_rec        Swg_Installedbase_Pub_Pkg.ib_instl_rec_type;
    nu_cp_rec               Swg_Installedbase_Pub_Pkg.ib_instl_rec_type;

BEGIN

    ou_errbuf_s     :=  NULL;
    ou_errcode_n    :=  0;

    l_start_d   :=  SYSDATE;
    g_flag_c    :=  in_debug_c;
    l_OrgId_n   :=  2;


--    Fnd_Stats.GATHER_TABLE_STATS('SWGCNV', 'SWGCNV_DD_TEMP_CUSTOMERS',90);

   Fnd_Stats.GATHER_TABLE_STATS('SWGCNV', 'SWGCNV_DD_EQPMNT_INTERFACE',90);

   --Set the Context to Direct Delivery Org
   --Fnd_Client_Info.SET_ORG_CONTEXT(2);
   MO_GLOBAL.Set_Policy_Context('S',2);

    BEGIN
  SELECT  user_id
  INTO  l_conversion_userid_n
  FROM  fnd_user
  WHERE user_name = 'SWGCNV';
      EXCEPTION
      WHEN OTHERS THEN
          Fnd_File.Put_Line(Fnd_File.LOG,'SWGCNV not defined as an user' );
            ou_errcode_n    := 2;
          RETURN;
    END;

    -- Populate the Local Plsql Table Records

    FOR l_temp_cust_rec IN Cur_Main ( in_system_code_s,in_sales_center_s )
    LOOP
      l_temp_idx_bi     :=  NVL(l_temp_idx_bi,0)  + 1;
      l_temp_cust_tbl (l_temp_idx_bi) :=  l_temp_cust_rec;
    END LOOP;

    debug_mesg( 'Temp Table customer count '||l_temp_cust_tbl.COUNT);

    Fnd_File.Put_Line(Fnd_File.LOG, 'Temp Table customer count '||l_temp_cust_tbl.COUNT);

    ------------------------------------------- START PROCESS ----------------------------------------

    FOR l_temp_idx_bi IN  1..l_temp_cust_tbl.COUNT
    LOOP
  BEGIN

        l_cust_rec.system_code          :=  l_temp_cust_tbl(l_temp_idx_bi).system_code;
        l_cust_rec.new_sales_center     :=  l_temp_cust_tbl(l_temp_idx_bi).new_sales_center;
        l_cust_rec.division             :=  l_temp_cust_tbl(l_temp_idx_bi).division;
        l_cust_rec.legacy_customer_number :=  l_temp_cust_tbl(l_temp_idx_bi).legacy_customer_number;
        l_cust_rec.legacy_route_number    :=  l_temp_cust_tbl(l_temp_idx_bi).legacy_route_number;
        l_cust_rec.contracts_proc_flag    :=  l_temp_cust_tbl(l_temp_idx_bi).contracts_proc_flag;
        l_cust_rec.cust_import_flag       :=  l_temp_cust_tbl(l_temp_idx_bi).cust_import_flag;
        l_cust_rec.customer_start_date    :=  l_temp_cust_tbl(l_temp_idx_bi).customer_start_date;
        l_cust_rec.oracle_customer_number :=  l_temp_cust_tbl(l_temp_idx_bi).oracle_customer_number;   --MTS 431

        l_msg_data_s        :=  NULL;
        l_Msg_Count_n           :=  0;
        l_Errmsg_s            :=  NULL;
        l_Return_Status_c     :=  'S';
        l_process_flag_c      :=  'Y';
        l_recs_read_n       :=  l_recs_read_n +  1;

        IF l_cust_rec.system_code LIKE  'SHIPTO%' THEN   --MTS 431  add ship to's to existing oracle customer
           BEGIN
            SELECT orig_system_reference
            INTO   l_orig_system_customer_ref_s
            FROM   hz_cust_accounts
            WHERE  account_number = l_cust_rec.oracle_customer_number;
           EXCEPTION WHEN OTHERS THEN
            l_orig_system_customer_ref_s := NULL;
           END;
        ELSE
           l_Orig_System_Customer_Ref_s :=  G_SWG_CNV_DD_PREFIX   ||
           l_cust_rec.system_code   ||'-'||
           l_cust_rec.new_sales_center  ||'-'||
           l_cust_rec.legacy_customer_number;
        END IF;


      debug_mesg( 'customer ref '||l_Orig_System_Customer_Ref_s);

--Get Party Id, Customer Id based on Old Customer Number

      OPEN  Cur_NewCstmr ( l_Orig_System_Customer_Ref_s );
      FETCH Cur_NewCstmr
      INTO  l_Party_Id_n,
          l_Customer_Id_n,
          l_customer_number_n;

        IF  Cur_NewCstmr%NOTFOUND
      THEN
            l_Party_Id_n    :=  NULL;
            l_Customer_Id_n   :=  NULL;
            l_customer_number_n :=  NULL;
            l_process_flag_c  :=  'N';
        END IF;

     CLOSE  Cur_NewCstmr;

     IF l_process_flag_c <> 'Y'
     THEN
            l_error_mesg_s    :=  'ERROR: Customer Not Found in Oracle. '||
                        'Legacy Customer Number: '|| l_Cust_Rec.Legacy_Customer_Number;
            RAISE NO_DATA_FOUND;
     END IF;

     ---------------------------------- SHIP TO --------------------------

    l_rec_count :=  0; -- 02/06/03

     FOR  l_shipto_rec  IN cur_shipto_info  ( l_Customer_Id_n
               ,l_orig_system_customer_ref_s
              )
     LOOP


    l_legacy_addrcode_s :=  LTRIM(RTRIM(l_shipto_rec.address_code));

    debug_mesg( 'address_code:    '||l_legacy_addrcode_s);
    debug_mesg( 'orig system address ref:   '||l_shipto_rec.orig_system_address_ref);


        debug_mesg('Before Cur_legacyRntlEqp...');
        debug_mesg('Division: '|| l_cust_rec.division);
        debug_mesg('Branch: '|| l_shipto_rec.lgcy_sales_center);
        debug_mesg('Legacy Customer: '|| l_Cust_Rec.Legacy_Customer_Number);
        debug_mesg('Delivery Location: '|| l_shipto_rec.address_code);

    debug_mesg('New Delivery Location: '|| l_shipto_rec.address_code);

    FOR l_rntl_rec   IN Cur_legacyRntlEqp (  l_shipto_rec.lgcy_sales_center
                                          ,l_Cust_Rec.Legacy_Customer_Number
                                          ,l_shipto_rec.address_code 
                                          )
    LOOP
        l_rec_datafile_n        :=  NVL(l_rec_datafile_n,0) + 1;
        l_item_Code_s           :=  NULL;
        l_Original_InvItemId_n  :=  NULL;
        l_Quantity_n            :=  NULL;
        l_UomCode_s             :=  NULL;
        l_Related_Item_Id_n     :=  NULL;
        l_CpStatusName_s        :=  NULL;
        l_contract_status_s     :=  NULL;

        l_rec_count             :=  1;

        debug_mesg( 'Model code '||LTRIM(RTRIM(l_Rntl_Rec.MODEL)));

        l_error_mesg_s  :=  NULL;

        Get_Rental_Code (  in_system_code_s          => in_system_code_s --l_cust_rec.system_code Commented by Muthu For SACS7
                        ,  in_sales_center_s         => l_rntl_rec.sales_center
                        ,  in_lgcyitem_sub_code_s    => l_rntl_rec.item_sub_code
                        ,  in_legacyItemCode_s       => LTRIM(RTRIM(l_Rntl_Rec.MODEL))
                        ,  in_placement_code_s       => LTRIM(RTRIM(l_rntl_rec.placement_code))
                        , io_RentalItemCode_s        => l_item_Code_s
                        , io_OrigInvItemId_n         => l_Original_InvItemId_n
                        , io_Quantity_n              => l_Quantity_n
                        , io_UomCode_s               => l_UomCode_s
                        , io_related_item_id_n       => l_Related_Item_Id_n
                        , io_process_flag_c          => l_process_flag_c
                        , io_msg_data_s              => l_error_mesg_s
                        , io_serial_controlled_c     => l_serial_ctrl_c);

        IF l_process_flag_c <> 'Y'
        THEN
          l_error_Mesg_s    :=   'Error at Get_Rental_Code procedure : '||l_error_mesg_s;
          debug_mesg( 'Error at Get_Rental_Code procedure : '||l_error_mesg_s);
          RAISE NO_DATA_FOUND;
        END IF;

        l_Installed_Date_d    :=  TRUNC(l_Rntl_Rec.Installation_Date);
        l_Shipped_Date_d      :=  TRUNC(l_Rntl_Rec.Installation_Date);

        IF  l_serial_ctrl_c = 'N' THEN
            l_serial_number_s   := NULL;
        ELSE
            l_Serial_Number_s   :=  LTRIM(RTRIM(l_Rntl_Rec.Serial_Number));
        END IF;
            
        debug_mesg( 'Item id : '||l_Original_InvItemId_n);
        debug_mesg( 'rental Item code : '||l_item_Code_s);
        debug_mesg( 'Related item : '||l_Related_Item_Id_n);

        IF LTRIM(RTRIM(l_Rntl_Rec.Placement_Code)) = 'RENTED'
        THEN

          l_CpStatusName_s      := 'RENTED';
          l_contract_status_s   := 'RENTAL';

        END IF;

        -- Get the customer product Status

        OPEN  Cur_CpStatus ( l_CpStatusName_s );

        FETCH   Cur_CpStatus
        INTO    l_CpStatusId_n;

        IF  Cur_CpStatus%NOTFOUND
        THEN
          l_CpStatusId_n    :=  NULL;
          l_Process_Flag_c  :=  'N';
        END IF;

        CLOSE  Cur_CpStatus;

--Customer Product Status

        IF l_Process_Flag_c <> 'Y'
        THEN
          l_Error_Mesg_s  :=  'ERROR: Customer Product Status Not Defined. '|| l_cpstatusname_s ||
                        'Placement Code ' ||l_Rntl_Rec.Placement_Code;
          RAISE NO_DATA_FOUND;
        END IF;


       -- Check the instal base is created, if yes don't create again

       l_create_instal_base :=  'N';

       OPEN Cur_instalbase_check ( l_Customer_Id_n,l_Original_InvItemId_n
                                 ,l_shipto_rec.ship_to_site_use_id            -- Added By Pankaj
                                 ,l_rntl_rec.Serial_Number,l_CpStatusId_n);

        FETCH   Cur_instalbase_check
        INTO    l_CstmrPrdctId_n;

          IF  Cur_instalbase_check%NOTFOUND
          THEN
             l_create_instal_base  :=  'N';
          ELSE
            l_create_instal_base  :=  'Y';
          END IF;

        CLOSE  Cur_instalbase_check;

        ---------------------------
        -- Call to INSTALL BASE API
        ---------------------------

     debug_mesg( 'before call to install base');

     debug_mesg( 'l_Customer_Id_n : '||l_Customer_Id_n);
     debug_mesg( 'l_Original_InvItemId_n : '||l_Original_InvItemId_n );
     debug_mesg( 'l_CpStatusId_n: '||l_CpStatusId_n);

    debug_mesg( 'l_Quantity_n: '||l_Quantity_n);
    debug_mesg( 'l_UomCode_s: '||l_UomCode_s);

    debug_mesg( 'l_shipto_rec.bill_to_address_id: '||l_shipto_rec.bill_to_address_id);
    debug_mesg( 'l_shipto_rec.ship_to_party_site_id: '||l_shipto_rec.ship_to_party_site_id);

    debug_mesg( 'l_rntl_rec.installation_date: '||l_rntl_rec.installation_date);
    debug_mesg( 'l_rntl_rec.Serial_Number: '||l_rntl_rec.Serial_Number);

       IF l_create_instal_base  = 'N' THEN

        debug_mesg( 'Create install base');

        Create_InstalledBase (  in_OrgId_n              =>  l_OrgId_n
                              ,in_CustomerId_n          =>  l_Customer_Id_n
                              ,in_InvItemId_n           =>  l_Original_InvItemId_n
                              ,in_CpStatusId_n          =>  l_CpStatusId_n
                              ,in_Quantity_n            =>  l_Quantity_n
                              ,in_UomCode_s             =>  l_UomCode_s
                              ,in_BillTo_AddressId_n    =>  l_shipto_rec.bill_to_address_id
                              ,in_ShipTo_PartySiteId_n  =>  l_shipto_rec.ship_to_party_site_id
                              ,in_Installed_Date_d      =>  l_rntl_rec.installation_date
                              ,in_Shipped_Date_d        =>  l_rntl_rec.installation_date
                              ,in_Serial_NUmber_s       =>  l_serial_number_s--l_rntl_rec.Serial_Number
                              ,in_escrow_amount_n       =>  NULL            -- when escrow amount = 0
                              ,x_Customer_ProductId_n   =>  l_CstmrPrdctId_n  -- Install base Id
                              ,x_Obj_Version_Num_n      =>  l_ObjVrsn_n
                              ,x_New_CPId_n             =>  l_NewCpId_n
                              ,x_Return_Status_c        =>  l_Return_Status_c
                              ,x_Msg_Count_n            =>  l_Msg_Count_n
                              ,x_MSG_Data_s             =>  l_Msg_Data_S
                              ,x_PlaceofError_s         =>  l_PlaceOfErr_s
                              ,x_cp_rec                 =>  l_cp_rec);

        IF l_Return_Status_c != Fnd_Api.G_RET_STS_SUCCESS
        THEN
          l_Error_Mesg_s    :=  'ERROR: While Creating Installed Base. '||
              'Error: '|| l_Msg_Data_S;
          debug_mesg( ' Error in Base Product API');
          RAISE ERROR_INSTALLBASE;
        ELSE

            -- Added PU 4/24/2008
    
            UPDATE csi_item_instances   
            SET    attribute2    =    l_rntl_rec.dlvry_reason1
                  ,attribute3    =    l_rntl_rec.dlvry_reason2
            WHERE  instance_id   =    l_CstmrPrdctId_n;
    
            -- Added PU 4/24/2008

            l_Process_Flag_C    :=  'Y';
            l_Return_Status_C   :=  'S';
            l_instalbase_recs_written_n :=  l_instalbase_recs_written_n + 1;

            l_start_date_d  := NVL(LEAST(l_cust_rec.customer_start_date,l_rntl_rec.contract_start_date),TRUNC(SYSDATE));


      -- NEW CODE as per Valerie
            IF l_start_date_d <= TO_DATE('20-JUN-2004', 'DD-MON-YYYY') THEN

                debug_mesg('l_start_date_d: '||TO_CHAR(l_start_date_d,'DD-MON-YYYY'));

                IF l_rntl_rec.ESCROW_AMOUNT <>0
                THEN

                    debug_mesg('Deposit Amount: '||TO_CHAR(l_rntl_rec.escrow_amount));

                    IF (LTRIM(RTRIM(l_Rntl_Rec.Placement_Code)) = 'S') AND
                        -- (LTRIM(RTRIM(l_Rntl_Rec.item_Code))  IN ('$74','$9874')) -- 2006/03/09 Jabel
                        (LTRIM(RTRIM(l_Rntl_Rec.model))   IN ('$74','$9874'))

                    THEN
                       l_status_name := 'RETURN';
                    ELSE
                        l_status_name := 'EQUIPMENT DEPOSIT';

                    END IF;

                   BEGIN

                        SELECT      Customer_Product_Status_Id
                  INTO        l_CpStatusId_n
                  FROM        Cs_Customer_Product_Statuses
                  WHERE       name     = l_status_name;

              EXCEPTION

                WHEN OTHERS THEN

                    l_Error_Mesg_s    :=  'ERROR:While selecting product status : '||SQLERRM;
                    RAISE ERROR_INSTALLBASE;

              END;




              -- assign the oracle item depends on the escrow amount as per Valerie

              IF l_rntl_rec.ESCROW_AMOUNT = '75' THEN

                l_item_id     :=  1392; -- Defaulted as per Valerie, 68010002
                l_escrow_amount_n :=  NULL;

              ELSIF    l_rntl_rec.ESCROW_AMOUNT = '25' THEN

                l_item_id :=  1390;  -- Defaulted as per Valerie, 68010001

                l_escrow_amount_n :=  NULL;

              ELSE
                l_item_id := 2542; -- Defaulted as per Valerie, 68010003

                l_escrow_amount_n :=  l_rntl_rec.ESCROW_AMOUNT;

              END IF;


              Create_InstalledBase
                            (in_OrgId_n               =>  l_OrgId_n
                            ,in_CustomerId_n          =>  l_Customer_Id_n
                            ,in_InvItemId_n             =>  l_item_id
                            ,in_CpStatusId_n          =>  l_CpStatusId_n
                            ,in_Quantity_n              =>  l_Quantity_n
                            ,in_UomCode_s             =>  l_UomCode_s
                            ,in_BillTo_AddressId_n      =>  l_shipto_rec.bill_to_address_id
                            ,in_ShipTo_PartySiteId_n    =>  l_shipto_rec.ship_to_party_site_id
                            ,in_Installed_Date_d      =>  l_rntl_rec.installation_date
                            ,in_Shipped_Date_d          =>  l_rntl_rec.installation_date
                            ,in_Serial_NUmber_s         =>  NULL
                            ,in_escrow_amount_n         =>  l_escrow_amount_n        -- Escrow <>0
                            ,x_Customer_ProductId_n     =>  nu_l_CstmrPrdctId_n   -- Install base Id
                            ,x_Obj_Version_Num_n      =>  nu_l_ObjVrsn_n
                            ,x_New_CPId_n             =>  nu_l_NewCpId_n
                            ,x_Return_Status_c          =>  l_Return_Status_c
                            ,x_Msg_Count_n              =>  l_Msg_Count_n
                            ,x_MSG_Data_s             =>  l_Msg_Data_S
                            ,x_PlaceofError_s         =>  l_PlaceOfErr_s
                            ,x_cp_rec                   =>  nu_cp_rec);

            IF l_Return_Status_c != Fnd_Api.G_RET_STS_SUCCESS
            THEN
              l_Error_Mesg_s    :=  'ERROR: While Creating Installed Base. '||
                  'Error: '|| l_Msg_Data_S;
              debug_mesg( 'Error in Base Product API');
              RAISE ERROR_INSTALLBASE;
            ELSE
                        
                                  -- Added PU 4/24/2008

                                  UPDATE csi_item_instances   
                                  SET    attribute2    =    l_rntl_rec.dlvry_reason1
                                        ,attribute3    =    l_rntl_rec.dlvry_reason2
                                  WHERE  instance_id   =    l_CstmrPrdctId_n;

                                  -- Added PU 4/24/2008

              l_Process_Flag_C  :=  'Y';
              l_Return_Status_C :=  'S';
                    END IF;

          END IF;
            END IF;
-- END OF NEW CODE

      UPDATE  Swgcnv_dd_Temp_Customers
      SET Contracts_Proc_Flag = 'I'
      WHERE ROWID     = l_temp_cust_tbl (l_temp_idx_bi).row_id;

    --  COMMIT;

      debug_mesg( ' OK in Base Product API');

        END IF;

     --  END IF; -- l_create_install_base -- Pankaj Commented

        debug_mesg('Customer id:.................. '||l_Customer_Id_n);
        debug_mesg('customer Product Id:.......... '||l_CstmrPrdctId_n);
        debug_mesg('Site Use Id:.................. '||l_shipto_rec.ship_to_site_use_id);
        debug_mesg('Product Status:............... '||l_CpStatusName_s);
        debug_mesg('Inventory Item id:............ '||l_Original_InvItemId_n);
        debug_mesg('Related Item Id:.............. '||l_Related_Item_Id_n);
        debug_mesg('Serial Number:................ '||l_rntl_rec.Serial_Number);
        debug_mesg('Rental amount:................ '||l_rntl_rec.rental_amount);
        debug_mesg('Installation Date:............ '||l_rntl_rec.installation_date);


    -- Set the contract start date and nex_billon date

            l_write_off_date_d  := NULL;
            l_return_date_d     := NULL;

            IF LTRIM(RTRIM(l_Rntl_Rec.Placement_Code))  IN ('PULLED','LOSS')    THEN

                l_return_date_d     := l_rntl_rec.last_billing_date;

            END IF;

            IF LTRIM(RTRIM(l_Rntl_Rec.Placement_Code))  = 'WRITEOFF'    THEN

                l_write_off_date_d  := l_rntl_rec.last_billing_date;

            END IF;


                IF LTRIM(RTRIM(l_Rntl_Rec.Placement_Code))  NOT IN ('RENTED','SOLD')    THEN

                    Update_InstalledBase
                       (in_write_off_date_d     => l_write_off_date_d
                       ,in_return_date_d        => l_return_date_d
                       ,in_cp_id_n              => l_CstmrPrdctId_n
                       ,in_cp_rec               => l_cp_rec
                       ,x_Return_Status_c       => l_Return_Status_c
                       ,x_Msg_Count_n           => l_Msg_Count_n
                       ,x_MSG_Data_s            => l_Msg_Data_S
                       ,x_PlaceofError_s        => l_PlaceOfErr_s);

            IF l_Return_Status_c != Fnd_Api.G_RET_STS_SUCCESS
            THEN
              l_Error_Mesg_s    :=  'ERROR: While Updating the Installed Base. '||
                  'Error: '|| l_Msg_Data_S;
              debug_mesg( 'Error in Base Product API');
              RAISE ERROR_INSTALLBASE;
            ELSE
              l_Process_Flag_C  :=  'Y';
              l_Return_Status_C :=  'S';
                    END IF;

                END IF;

      -- contract next bill on date

      l_next_billon_start_date  :=  l_rntl_rec.next_bill_date;


        -------------------------------------
        -- CALL TO CONTRACT CREATION PROCESS
        -------------------------------------

--For placement code 'RENTED'

        IF  LTRIM(RTRIM(l_Rntl_Rec.Placement_Code)) =       'RENTED'
        THEN
           BEGIN

           /* OPS8. Code To Handle Zero Rentals. Muthu */

              IF l_rntl_rec.rental_amount = 0 
              THEN
                 IF l_next_billon_start_date <= TRUNC(SYSDATE) 
                 THEN
                    l_init_bill_from_date    :=   l_next_billon_start_date;
                 ELSE 
                    l_init_bill_from_date    :=   l_next_billon_start_date;
                 END IF;
              ELSE
                 l_init_bill_from_date       :=   l_rntl_rec.installation_date;
              END IF;

              Swg_Contract_Pub_Pkg.create_contract_main
                                                      (  in_customer_id_n         =>   l_customer_id_n
                                                        ,in_install_base_id_n     =>   l_CstmrPrdctId_n
                                                        ,in_ship_to_site_id_n     =>   l_shipto_rec.ship_to_site_use_id
                                                        ,in_cntr_type_s           =>   l_contract_status_s
                                                        ,in_item_id_n             =>   l_Original_InvItemId_n
                                                        ,in_contract_item_id_n    =>   l_Related_Item_Id_n
                                                        ,in_serial_number_s       =>   l_rntl_rec.Serial_Number
                                                        ,in_minimum_duration_n    =>   NULL
                                                        ,in_cntr_price_n          =>   l_rntl_rec.rental_amount
                                                        ,in_rec_source_code_s     =>   'CONVERSION'
                                                        ,in_cntr_start_date_d     =>   l_rntl_rec.contract_Start_date  -- Commented By Bala Palani Jira EB-1596 TRUNC(SYSDATE)   -- l_rntl_rec.installation_date / Added by Bala Palani as per EB-1555
                                                        ,in_init_bill_from_dt_d   =>   l_init_bill_from_date
                                                        ,in_billing_freq_n        =>   l_rntl_rec.billing_interval
                                                        ,in_next_bill_on_date_d   =>   l_next_billon_start_date
                                                        ,in_loc_at_customer_s     =>   NULL
                                                        ,in_eqip1_txn_reason_s    =>   l_rntl_rec.dlvry_reason1 -- NULL, Added PU 4/24/2008, Should Default From Table
                                                        ,in_eqip2_txn_reason_s    =>   l_rntl_rec.dlvry_reason2 -- NULL, Added PU 4/24/2008, Should Default From Table
                                                        ,in_debug_c               =>   'N'
                                                        ,in_sales_person_id_n     =>   100000670       -- Added For ARS04 Conversion. PN 768. This Should change Based on Conversion.
                                                        ,ou_contract_id_n         =>   l_contract_id_n
                                                        ,ou_status_c              =>   l_return_status_c
                                                        ,ou_message_s             =>   l_msg_data_s
                                                      );

              IF l_return_status_c  !=  'S'
              THEN
                l_error_mesg_s    :=  l_msg_data_s;
                RAISE ERROR_CONTRACT;
              ELSE
                l_contract_recs_written_n :=  l_contract_recs_written_n + 1;
              END IF;

              l_service_type_s    := TO_CHAR(Swg_Get_Item_Svc_Type_Id ( l_Original_InvItemId_n));

              UPDATE  swg_contract
              SET attribute8                    =   l_rntl_rec.customer_number,
                  attribute9                    =   l_rntl_rec.sales_center||'-'||l_rntl_rec.delivery_location_number,
                  attribute10                   =   l_rntl_rec.serial_number,
                  attribute11                   =   l_rntl_rec.rental_amount,
                  attribute12                   =   l_rntl_rec.MODEL,
                  attribute13                   =   l_rntl_rec.placement_code,
                  attribute14                   =   l_rntl_rec.last_billing_date,
                  attribute15                   =   l_rntl_rec.installation_date,
                  last_filter_change_date       =   DECODE(l_service_type_s, '1304',NVL(l_rntl_rec.last_srv_date,NULL)),
                  tentative_next_service_date   =   DECODE(l_service_type_s, '1304',NVL(l_rntl_rec.srvc_due_date,NULL))
                  WHERE contract_id             =   l_contract_id_n;
                   
            EXCEPTION
            WHEN OTHERS THEN
                l_error_mesg_s  :=  'ERROR: While Creating contract. '||NVL(l_msg_data_s,SQLERRM);
                 RAISE ERROR_CONTRACT;
          END;

        END IF;
            
         END IF; -- Added By Pankaj   

    END LOOP;   -- END OF RENTAL LOOP
     END LOOP;      -- END OF SHIP TO LOOP;

     ---------------------------------- SHIP TO ----------------------------------

  IF l_rec_count  =  1 THEN

     UPDATE Swgcnv_dd_Temp_Customers
     SET    contracts_proc_flag = 'Y'
     WHERE  ROWID     = l_temp_cust_tbl (l_temp_idx_bi).row_id;

        IF in_validate_only_c = 'N' THEN
            COMMIT;
        ELSE
            ROLLBACK;
        END IF;

  END IF;

  EXCEPTION
      WHEN NO_DATA_FOUND THEN

            ou_errcode_n    := 1;
        ROLLBACK;

        l_Totl_Recd_Errors_n  :=  l_Totl_Recd_Errors_n  + 1;

        UPDATE  Swgcnv_dd_Temp_Customers
        SET Contracts_Proc_Flag = 'E'
        WHERE ROWID     = l_temp_cust_tbl (l_temp_idx_bi).row_id;

            IF in_validate_only_c = 'N' THEN
            COMMIT;
            ELSE
                ROLLBACK;
            END IF;

        Insert_Exceptions ( 'CONTRACTS'
                           ,l_cust_rec.Legacy_Customer_Number
                           ,l_legacy_addrcode_s
                           ,l_Error_Mesg_s
                           ,l_cust_rec.new_sales_center
                          );

            COMMIT;

      WHEN ERROR_INSTALLBASE THEN

            ou_errcode_n    := 1;

        ROLLBACK;
        l_Totl_Recd_Errors_n    :=  l_Totl_Recd_Errors_n  + 1;

        IF l_Msg_Count_n > 0
        THEN
            FOR I IN 1..l_Msg_Count_n
            LOOP
              l_Errmsg_s  :=  Fnd_Msg_Pub.get(I,'F');

              Insert_Exceptions (  'CONTRACTS'
                          ,l_cust_rec.Legacy_Customer_Number
                          ,l_legacy_addrcode_s
                          ,l_Errmsg_s
                          ,l_cust_rec.new_sales_center);
            END LOOP;
        ELSE
            Insert_Exceptions ( 'CONTRACTS'
                            ,l_cust_rec.Legacy_Customer_Number
                            ,l_legacy_addrcode_s
                            ,l_Error_Mesg_s
                            ,l_cust_rec.new_sales_center);
        END IF;

            COMMIT;

        UPDATE  Swgcnv_dd_Temp_Customers
        SET Contracts_Proc_Flag = 'E'
        WHERE ROWID     = l_temp_cust_tbl (l_temp_idx_bi).row_id;

            IF in_validate_only_c = 'N' THEN
                COMMIT;
            ELSE
                ROLLBACK;
            END IF;

      WHEN ERROR_CONTRACT THEN
            ou_errcode_n    := 1;
        ROLLBACK;

        l_Totl_Recd_Errors_n  :=  l_Totl_Recd_Errors_n  + 1;

        Insert_Exceptions ( 'CONTRACTS'
                        ,l_cust_rec.Legacy_Customer_Number
                        ,l_legacy_addrcode_s
                        ,l_Error_Mesg_s
                        ,l_cust_rec.new_sales_center);

            COMMIT;

        UPDATE  Swgcnv_dd_Temp_Customers
        SET Contracts_Proc_Flag = 'E'
        WHERE ROWID     = l_temp_cust_tbl (l_temp_idx_bi).row_id;

            IF in_validate_only_c = 'N' THEN
                COMMIT;
            ELSE
                ROLLBACK;
            END IF;

      WHEN OTHERS THEN
            ou_errcode_n    := 1;
        ROLLBACK;
        l_Totl_Recd_Errors_n  :=  l_Totl_Recd_Errors_n  + 1;
          l_Error_Mesg_s    :=  SQLERRM;

        Insert_Exceptions (  'CONTRACTS'
                          ,l_cust_rec.Legacy_Customer_Number
                          ,l_legacy_addrcode_s
                          ,l_Error_Mesg_s
                          ,l_cust_rec.new_sales_center);

            COMMIT;

        UPDATE  Swgcnv_dd_Temp_Customers
        SET Contracts_Proc_Flag = 'E'
        WHERE ROWID     = l_temp_cust_tbl (l_temp_idx_bi).row_id;

            IF in_validate_only_c = 'N' THEN
                COMMIT;
            ELSE
                ROLLBACK;
            END IF;

      END;
    END LOOP;   -- End of Main Loop

    l_end_d :=  SYSDATE;

   Fnd_File.Put_Line(Fnd_File.OUTPUT,'------------------------- RUN STATISTICS -----------------------------');
   Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Temp Customer Records Read           : ' || l_recs_read_n);
   Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Data file Records Read               : ' || l_rec_datafile_n);
   Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Instal base Oracle Records Written   : ' || l_instalbase_recs_written_n);
   Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Contract Oracle Records Written      : ' || l_contract_recs_written_n);
   Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Legacy Records in Error              : ' || l_Totl_Recd_Errors_n);
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'----------------------------------------------------------------------');
   Fnd_File.Put_Line(Fnd_File.OUTPUT,' Start Time                       : ' || TO_CHAR(l_start_d, 'MM/DD/RRRR HH24:MI:SS'));
   Fnd_File.Put_Line(Fnd_File.OUTPUT,' End Time                         : ' || TO_CHAR(l_end_d, 'MM/DD/RRRR HH24:MI:SS'));
   Fnd_File.Put_Line(Fnd_File.OUTPUT,'----------------------------------------------------------------------');

END contract_main;

---------------------------------------------------------------------------------------------------------------------------------------------------------------
PROCEDURE cpp
( ou_errbuf_s     OUT VARCHAR2
 ,ou_errcode_n      OUT NUMBER
 ,in_system_code_s    IN  VARCHAR2
 ,in_division_s     IN  VARCHAR2
 ,in_sales_center_s   IN  VARCHAR2
 ,in_debug_c      IN  VARCHAR2    DEFAULT 'N'
 ,in_validate_only_c  IN    VARCHAR2    DEFAULT 'Y'
)
IS

-- Cursor definition

    CURSOR    Cur_Main ( in_system_code_s IN  VARCHAR2
              ,in_division_s  IN  VARCHAR2
              ,in_sales_center_s  IN  VARCHAR2
           )
    IS
    SELECT    a.ROWID   ROW_ID
            ,c.customer_id  legacy_customer_id
        ,a.*
    FROM      swgcnv_dd_temp_customers   a
            ,swgcnv_dd_customer_interface   c
    WHERE a.division      =  in_division_s
    AND   a.new_sales_center    = in_sales_center_s
    AND   a.Cust_Import_Flag    = 'Y'
    AND     a.cpp_proc_flag         = 'N'
    AND     c.sales_center          = a.new_sales_center
    AND     c.customer_number       = a.legacy_customer_number;
--    AND ROWNUM <=100;
--    AND a.legacy_customer_number ='77000007';



    CURSOR  cur_ship (in_customer_id_n  NUMBER)
    IS
    SELECT ship.site_use_id
        ,hca.orig_system_reference  cust_orig_ref
        ,site.orig_system_reference site_orig_ref
        ,RTRIM(LTRIM(SUBSTR(site.orig_system_reference,10,3))) lgcy_sales_center
        ,RTRIM(LTRIM(SUBSTR(
                SUBSTR(site.orig_system_reference,LENGTH(hca.orig_system_reference)+2)
                ,1
                ,DECODE(INSTR(site.orig_system_reference,'-HEADER')
                    ,0,10
                    ,INSTR(site.orig_system_reference,'-HEADER')
                        -(LENGTH(hca.orig_system_reference)+2) ))))   address_code
    FROM hz_cust_acct_sites site
        ,hz_cust_site_uses  ship
        ,hz_cust_accounts   hca
    WHERE hca.cust_account_id  = in_customer_id_n
    AND site.cust_account_id    = hca.cust_account_id
    AND ship.cust_acct_site_id  = site.cust_acct_site_id
    AND ship.site_use_code      = 'SHIP_TO';


-- Get the Rental Information From the Legacy Equipment

    CURSOR  cur_eqp (in_customer_number_s   IN VARCHAR2
                    ,in_deliv_loc_num_s     IN VARCHAR2
                    ,in_sales_center_s      IN VARCHAR2)
    IS
    SELECT  Eqp.*
    FROM  Swgcnv_dd_Eqpmnt_interface    Eqp
    WHERE Eqp.Customer_number               = in_Customer_Number_s
--    AND   Eqp.sales_center                = in_sales_center_s
    AND   Eqp.delivery_location_number      = in_deliv_loc_num_s
    AND     NVL(Eqp.rental_exception_code,'~')  IN ('0','1','3');   -- INCLUDES cpp coolers ONLY

--

    CURSOR  cur_eqp_model (in_sales_center_s IN VARCHAR2)
    IS
    SELECT DISTINCT e.model, e.item_sub_code
    FROM   swgcnv.swgcnv_dd_eqpmnt_interface e
    WHERE  NVL(e.rental_exception_code,'~') IN ('0','1','3')
    AND    e.sales_center = in_sales_center_s;


-- Variable declaration section

    l_cpp_rec             Swg_Cpp_Contract_Pkg.cpp_contract_Rec_type;
    l_cpp_warranty_tbl              Swg_Cpp_Contract_Pkg.cpp_warranty_Tbl_type;

    l_cpp_id_n                      NUMBER;


    l_status_c                    VARCHAR2(1);
    l_error_message_s         VARCHAR2(2000);

    l_conversion_userid_n       NUMBER;

    l_totl_recd_errors_n        NUMBER:=0;
    l_recs_read_n             NUMBER:=0;
    l_contract_recs_written_n       NUMBER:=0;
    l_instalbase_recs_written_n     NUMBER:=0;
    l_rec_datafile_n          NUMBER:=0;

    l_start_d                 DATE;
    l_end_d                     DATE;
    l_installed_date          DATE;
    l_shipped_date_d            DATE;
    l_Installed_Date_d            DATE;

    ERROR_ENCOUNTERED           EXCEPTION;

    l_next_billon_start_date    DATE;
    l_customer_start_date       DATE;
    l_rec_count                 NUMBER;
    l_item_id                 NUMBER;
    l_escrow_amount_n           NUMBER;
    l_status_name             VARCHAR2(100);
    l_cpp_error       BOOLEAN;

    l_service_type_s                VARCHAR2(20);

    TYPE cpp_item_rec_type       IS RECORD
        (cpp_inventory_item_id   NUMBER);

    TYPE cpp_item_tbl_type IS TABLE OF cpp_item_rec_type
    INDEX BY mtl_system_items_b.segment1%TYPE;

    g_cpp_item_tbl        cpp_item_tbl_type;

    l_cpp_inv_item_id   NUMBER;

BEGIN

    ou_errbuf_s     :=  NULL;
    ou_errcode_n    :=  0;

    l_start_d   :=  SYSDATE;
    g_flag_c    :=  in_debug_c;
--    l_OrgId_n   :=  2;

--Set the Context to Direct Delivery Org

    --Fnd_Client_Info.SET_ORG_CONTEXT(2);
    MO_GLOBAL.Set_Policy_Context('S',2);
    

    BEGIN
      SELECT  user_id
      INTO  l_conversion_userid_n
      FROM  fnd_user
      WHERE user_name = 'SWGCNV';
    EXCEPTION
      WHEN OTHERS THEN
          Fnd_File.Put_Line(Fnd_File.LOG,'SWGCNV not defined as an user' );
          RETURN;
    END;

    FOR cur_eqp_model_rec IN cur_eqp_model(in_sales_center_s)
    LOOP

  Initialize_cpp_items(in_sales_center_s
           ,cur_eqp_model_rec.model
           ,cur_eqp_model_rec.item_sub_code
           ,l_cpp_inv_item_id
           ,l_status_c
           ,l_error_message_s);
        Fnd_File.Put_Line(Fnd_File.LOG, 'Cpp Item Id :  '   ||l_cpp_inv_item_id);
        Fnd_File.Put_Line(Fnd_File.LOG, 'Cpp Item Id Status:  ' ||l_status_c);
        Fnd_File.Put_Line(Fnd_File.LOG, 'Cpp Item Id Message: ' ||l_error_message_s);

  IF l_cpp_inv_item_id IS NOT NULL THEN
       g_cpp_item_tbl(cur_eqp_model_rec.model).cpp_inventory_item_id := l_cpp_inv_item_id;
  END IF;

  l_cpp_inv_item_id := NULL;
  l_status_c := NULL;
  l_error_message_s := NULL;

    END LOOP;


    FOR  main_rec IN Cur_Main (in_system_code_s
                            ,in_division_s
                            ,in_sales_center_s)
    LOOP
      BEGIN

      l_cpp_error := FALSE;

            l_recs_read_n := l_recs_read_n + 1;

            FOR ship_rec IN cur_ship (main_rec.oracle_customer_id)
            LOOP
                BEGIN

                    FOR eqp_rec IN cur_eqp (main_rec.legacy_customer_number
                                            ,ship_rec.address_code
                                            ,ship_rec.lgcy_sales_center)
                    LOOP
                        BEGIN

                            l_rec_datafile_n    := l_rec_datafile_n +1;

                            l_cpp_rec   := NULL;

                            l_cpp_rec.customer_id               :=  main_rec.oracle_customer_id;

                            l_cpp_rec.cpp_status                := NULL; --let api populate the default

                            l_cpp_rec.ship_to_site_use_id       := ship_rec.site_use_id;

                            IF g_cpp_item_tbl.EXISTS(eqp_rec.model) THEN
                               l_cpp_rec.inventory_item_id := g_cpp_item_tbl(eqp_rec.model).cpp_inventory_item_id;
          ELSE
                               l_error_message_s   := 'Unable to determine cpp model for legacy model: '
                                                        || eqp_rec.model;
                               RAISE ERROR_ENCOUNTERED;
                            END IF;
                            debug_mesg ('Legacy model: '||eqp_rec.MODEL);
                            debug_mesg ('l_cpp_rec.inventory_item_id: '||l_cpp_rec.inventory_item_id);


                            l_cpp_rec.start_date_active         := TO_DATE(eqp_rec.contract_start_date,'DD-MON-RRRR');
                            l_cpp_rec.amount_per_installment    := eqp_rec.rental_amount;

                            IF eqp_rec.rental_exception_code = '0' THEN

                                l_cpp_rec.number_of_installments    :=  1;

                            ELSIF eqp_rec.rental_exception_code = '1'   THEN

                                l_cpp_rec.number_of_installments    :=  12;

                            ELSIF eqp_rec.rental_exception_code = '3'   THEN

                                l_cpp_rec.number_of_installments    :=  36;

                            ELSE
                                l_error_message_s   := 'Unable to determine the number of installments from the rental exception code. '
                                                        || eqp_rec.rental_exception_code;
                            END IF;

                            IF eqp_rec.rental_exception_code = '0' THEN
                               l_cpp_rec.installments_billed  := 1;
                            ELSE
                               l_cpp_rec.installments_billed := l_cpp_rec.number_of_installments - eqp_rec.cust_remaining_pmt;
                            END IF;

          IF l_cpp_rec.installments_billed IS NULL OR l_cpp_rec.installments_billed < 0 THEN
                               l_cpp_rec.installments_billed := CEIL(MONTHS_BETWEEN (TRUNC(SYSDATE),TO_DATE(eqp_rec.contract_start_date,'DD-MON-RRRR')));
                            END IF;

                            l_cpp_rec.next_bill_on_date  := ADD_MONTHS(TO_DATE(eqp_rec.contract_start_date,'DD-MON-RRRR'),l_cpp_rec.installments_billed);

                            Swg_Cpp_Contract_Pkg.create_cpp_contract
                           (in_cpp_cntr_rec       =>  l_cpp_rec
                           ,in_cpp_warranty_tbl     =>  l_cpp_warranty_tbl
                           ,in_commit_flag_c      =>  Fnd_Api.G_FALSE
                           ,io_status_c       =>  l_status_c
                           ,io_message_s        =>  l_error_message_s
                         ,ou_cpp_id_n       =>  l_cpp_id_n);

                            Fnd_File.Put_Line(Fnd_File.LOG,'l_status_c::'||l_status_c);
                            Fnd_File.Put_Line(Fnd_File.LOG,'error_message::'||l_error_message_s);

                            IF l_status_c != 'S' THEN
             RAISE ERROR_ENCOUNTERED;
                            END IF;

                            l_contract_recs_written_n   := l_contract_recs_written_n + 1;

                            IF eqp_rec.cust_remaining_pmt = 0 THEN
                               l_cpp_rec.cpp_status := 'PAID_WAR';
                            ELSE
                               l_cpp_rec.cpp_status := NULL;
                            END IF;

                            l_cpp_rec.total_billed_amt  := (l_cpp_rec.installments_billed * eqp_rec.rental_amount);
                            l_cpp_rec.last_billed_amt   := eqp_rec.rental_amount;
                            l_cpp_rec.last_billed_date  := ADD_MONTHS(TO_DATE(eqp_rec.contract_start_date,'DD-MON-RRRR'),l_cpp_rec.installments_billed-1);
                            l_cpp_rec.attribute9    := eqp_rec.customer_number;
                            l_cpp_rec.attribute10   := eqp_rec.delivery_location_number;
                            l_cpp_rec.attribute11   := eqp_rec.sales_center;
                            l_cpp_rec.attribute12   := eqp_rec.MODEL;
                            l_cpp_rec.attribute13   := TO_CHAR(TO_DATE(eqp_rec.last_billing_date,'DD-MON-RRRR'));
                            l_cpp_rec.attribute14   := TO_CHAR(TO_DATE(eqp_rec.next_bill_date,'DD-MON-RRRR'));
                            l_cpp_rec.attribute15   := eqp_rec.serial_number;

                            UPDATE swg_cpp_contracts
                            SET total_billed_amt      = l_cpp_rec.total_billed_amt
                            ,last_billed_amt      = l_cpp_rec.last_billed_amt
                            ,last_billed_date     = l_cpp_rec.last_billed_date
                            ,attribute9           = l_cpp_rec.attribute9
                            ,attribute10          = l_cpp_rec.attribute10
                            ,attribute11          = l_cpp_rec.attribute11
                            ,attribute12          = l_cpp_rec.attribute12
                            ,attribute13          = l_cpp_rec.attribute13
                            ,attribute14          = l_cpp_rec.attribute14
                            ,attribute15          = l_cpp_rec.attribute15
                            ,installments_billed  = l_cpp_rec.installments_billed
                            ,cpp_status                 = NVL(l_cpp_rec.cpp_status, cpp_status)
                            WHERE cpp_id    = l_cpp_id_n;


                            EXCEPTION
                            WHEN ERROR_ENCOUNTERED THEN
                                ou_errcode_n    := 1;
                                ROLLBACK;
        l_cpp_error := TRUE;
                                l_Totl_Recd_Errors_n    := l_Totl_Recd_Errors_n + 1;
                                l_error_message_s   := 'Error Encountered in equipment loop::'||l_error_message_s || '-'||SQLERRM;

                                INSERT_EXCEPTIONS
                                    (in_Type_s              =>  'CPP'
                                    ,in_customer_Number_s   =>  eqp_rec.customer_number
                                    ,in_Address_Code_s      =>  eqp_rec.delivery_location_number
                                    ,in_error_message_s     =>  l_error_message_s
                                    ,in_sales_center_s      =>  eqp_rec.sales_center);
                                COMMIT;

                            WHEN OTHERS THEN
                                ou_errcode_n    := 1;
                                ROLLBACK;
        l_cpp_error := TRUE;
                                l_Totl_Recd_Errors_n    := l_Totl_Recd_Errors_n + 1;
                                l_error_message_s   := 'UNEXPECTED ERROR in equipment loop::'||SQLERRM;
                                INSERT_EXCEPTIONS
                                    (in_Type_s              =>  'CPP'
                                    ,in_customer_Number_s   =>  eqp_rec.customer_number
                                    ,in_Address_Code_s      =>  eqp_rec.delivery_location_number
                                    ,in_error_message_s     =>  l_error_message_s
                                    ,in_sales_center_s      =>  eqp_rec.sales_center);
                                COMMIT;
                            END;
                    END LOOP;   --cur_eqp

                EXCEPTION
                    WHEN OTHERS THEN
                        ou_errcode_n    := 1;
                        ROLLBACK;
      l_cpp_error := TRUE;
                        l_Totl_Recd_Errors_n    := l_Totl_Recd_Errors_n + 1;
                        l_error_message_s   := 'UNEXPECTED ERROR in ship loop::'||SQLERRM;

                        INSERT_EXCEPTIONS
                                    (in_Type_s              =>  'CPP'
                                    ,in_customer_Number_s   =>  main_rec.legacy_customer_number
                                    ,in_Address_Code_s      =>  ship_rec.address_code
                                    ,in_error_message_s     =>  l_error_message_s
                                    ,in_sales_center_s      =>  ship_rec.lgcy_sales_center);
                        COMMIT;
                END;
            END LOOP;   --cur_ship

  IF l_cpp_error THEN
     UPDATE swgcnv_dd_temp_customers
     SET cpp_proc_flag = 'E'
           WHERE ROWID = main_rec.row_id;
  ELSE
     UPDATE swgcnv_dd_temp_customers
     SET cpp_proc_flag = 'Y'
           WHERE ROWID = main_rec.row_id;
  END IF;

        IF in_validate_only_c != 'Y' THEN
            COMMIT;
        ELSE
            ROLLBACK;
        END IF;

        EXCEPTION
            WHEN OTHERS THEN
                ou_errcode_n    := 1;

                ROLLBACK;

                l_Totl_Recd_Errors_n    := l_Totl_Recd_Errors_n + 1;

                l_error_message_s   := 'UNEXPECTED ERROR in customer loop::'||SQLERRM;


                INSERT_EXCEPTIONS
                        (in_Type_s              =>  'CPP'
                        ,in_customer_Number_s   =>  main_rec.legacy_customer_number
                        ,in_Address_Code_s      =>  NULL
                        ,in_error_message_s     =>  l_error_message_s
                        ,in_sales_center_s      =>  main_rec.new_sales_center);

                COMMIT;
        END;

    END LOOP;

    l_end_d := SYSDATE;

    Fnd_File.Put_Line(Fnd_File.OUTPUT,'------------------------- RUN STATISTICS -----------------------------');
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Temp Customer Records Read           : ' || l_recs_read_n);
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Data file Records Read               : ' || l_rec_datafile_n);
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of CPP Oracle Records Written           : ' || l_contract_recs_written_n);
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Legacy Records in Error              : ' || l_Totl_Recd_Errors_n);
    Fnd_File.Put_Line(Fnd_File.OUTPUT,'----------------------------------------------------------------------');
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' Start Time                      : ' || TO_CHAR(l_start_d, 'MM/DD/RRRR HH24:MI:SS'));
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' End Time                        : ' || TO_CHAR(l_end_d, 'MM/DD/RRRR HH24:MI:SS'));
    Fnd_File.Put_Line(Fnd_File.OUTPUT,'-------------------------------------------------------------------');
EXCEPTION
    WHEN OTHERS THEN
        ou_errcode_n    := 2;
        Fnd_File.Put_Line(Fnd_File.LOG,'Unexpected error in cpp procedure::'||SQLERRM);
        RETURN;

END cpp;
-------------------------------------------------------------------------------------------------

PROCEDURE CREATE_DEPOSIT_ITEMS
( ou_errbuf_s           OUT     VARCHAR2
 ,ou_retcode_n          OUT     NUMBER
 ,in_system_code_s      IN      VARCHAR2
 ,in_sales_center_s     IN      VARCHAR2  --NO LONGER BEING USED
 ,in_debug_c            IN      VARCHAR2  DEFAULT 'N'
 ,in_validate_only_c    IN      VARCHAR2  DEFAULT 'Y'
)
IS
--
--  Filename:       SWGCNV_HD_IB_UPDT.sql
--  Developer:      Kimberly Piper
--  Creation Date:  09/15/2004
--  Purpose:        To calculate the empty bottle inventory and rack inventory based
--                  on the number of projected purchase items for 14040505 (Hinckley 5 Gallon Water)
--                  and assign the same number of empties (30232001).  Then based on the number of
--                  empties divide by 30 to get the number of racks (31000004) to create.
--  Modifications:  11/02/2004 Modified for RIMKWS/ELP conversion
--          06/22/2005 Modified for SACS7 added deposit_proc_flag to make program re-runable
--
    /*
    CURSOR  cur_custs   (in_sales_center_c  IN VARCHAR2)
    IS
    SELECT c.ROWID row_id, c.*
    FROM swgcnv_dd_temp_customers   c
    WHERE EXISTS (SELECT NULL
                  FROM swgcnv_dd_eqpmnt_interface   e
                  WHERE e.placement_code = 'POSITIVE'
                  AND e.customer_number = c.legacy_customer_number)
    AND c.new_sales_center    = in_sales_center_c
    AND c.deposit_proc_flag	  != 'Y';
--    AND ROWNUM <=100;
    */
    
    
    ------------------ START Added by SU on 08/11/2014  EB-829   --------------------------------------------------------------------

    CURSOR  cur_custs
    IS
    SELECT c.ROWID row_id, c.*
    FROM  swgcnv_dd_temp_customers   c
    WHERE EXISTS (SELECT NULL
                  FROM  swgcnv_dd_eqpmnt_interface   e
                  WHERE e.placement_code  = 'POSITIVE'
                  AND   e.customer_number = c.legacy_customer_number)                 
    AND  c.deposit_proc_flag   != 'Y';

   ------------------ END Added by SU on 08/11/2014  EB-829   --------------------------------------------------------------------

    CURSOR  Cur_NewCstmr ( in_cust_account_id_n IN  NUMBER )
    IS
    SELECT  Party_Id          Party_Id,
            Cust_Account_Id   Customer_Id,
            Account_Number    Customer_Number,
            orig_system_reference  
    FROM    hz_cust_Accounts
    WHERE   cust_account_id   = in_cust_account_id_n;

    CURSOR  cur_shipto_info ( in_Customer_Id_n              IN  NUMBER
                             ,in_orig_system_customer_ref_s IN  VARCHAR2
                             ,in_sale_center_s              IN  VARCHAR2
        )
    IS
    SELECT  ship_site.site_use_id         ship_to_site_use_id,
            ship_site.warehouse_id        salescenter,
    CASE WHEN SUBSTR(ship_addr.orig_system_reference,4,6) = 'SHIPTO' THEN
      in_sale_center_s
    ELSE
      RTRIM(LTRIM(SUBSTR(ship_addr.orig_system_reference,10,3))) 
    END                                                                   lgcy_sales_center,
      ship_addr.orig_system_reference     orig_system_address_ref,
   CASE WHEN SUBSTR(ship_addr.orig_system_reference,4,6) = 'SHIPTO' THEN    --MTS 431
     SUBSTR(ship_addr.orig_system_reference,instr(ship_addr.orig_system_reference,'-',-1) + 1,20) 
   ELSE
    RTRIM(LTRIM(SUBSTR(
                SUBSTR(ship_addr.orig_system_reference,LENGTH(in_orig_system_customer_ref_s)+2)
                ,1
                ,DECODE(INSTR(ship_addr.orig_system_reference,'-HEADER')
                    ,0,10
                    ,INSTR(ship_addr.orig_system_reference,'-HEADER')
                        -(LENGTH(in_orig_system_customer_ref_s)+2) ))))  
   END               address_code,
    ship_addr.party_site_id         ship_to_party_site_id,
    ship_addr.cust_acct_site_id     ship_to_address_id,
    bill_site.site_use_id           bill_to_site_use_id,
    bill_site.payment_term_id       payment_term_id,
    bill_addr.party_site_id         bill_to_party_site_id,
    bill_addr.cust_acct_site_id     bill_to_address_id
    FROM  hz_cust_acct_sites              ship_addr,
          hz_cust_acct_sites              bill_addr,
          hz_cust_site_uses               ship_site,
          hz_cust_site_uses               bill_site,
          hz_cust_accounts                cust
    WHERE cust.cust_account_id          = in_customer_id_n
    AND   cust.cust_account_id          = ship_addr.cust_account_id
    AND   ship_addr.cust_acct_site_id   = ship_site.cust_acct_site_id
    AND   ship_site.site_use_code       = 'SHIP_TO'
    AND   ship_site.bill_to_site_use_id = bill_site.site_use_id
    AND   bill_site.site_use_code       = 'BILL_TO'
    AND   bill_site.cust_acct_site_id   = bill_addr.cust_acct_site_id;


    CURSOR  Cur_item ( in_Division_s         IN  VARCHAR2
                      ,in_new_sales_center_s IN  VARCHAR2
                      ,in_Customer_Number_s  IN  VARCHAR2
                      ,in_Address_Code_s     IN  VARCHAR2
                     )
    IS
    SELECT   Eqp.*
    FROM     Swgcnv_dd_Eqpmnt_interface    Eqp
            ,swgcnv_dd_customer_shipto      s
    WHERE   s.customer_number               = in_Customer_Number_s
    AND     s.delivery_location_number      = in_address_code_s
--    AND   s.ship_to_address_id            = TO_NUMBER(in_Address_Code_s)
--    AND   Eqp.Division                    = in_Division_s
    AND     Eqp.Customer_number             = s.customer_number
    AND     Eqp.sales_center                = s.sales_center--in_new_sales_center_s 
    AND     Eqp.delivery_location_number    = s.delivery_location_number
    AND     NVL(Eqp.rental_exception_code,'~')   NOT IN ('0', '1', '3')-- ignores cpp coolers
    AND     eqp.placement_code              = 'POSITIVE' --ONLY depositable items
    AND     eqp.valid_flag                 != 'E'
    AND     eqp.quantity                   != 0;

    l_ib_status_id_n                csi.csi_instance_statuses.instance_status_id%TYPE;
    l_empty_status_s                csi.csi_instance_statuses.name%TYPE     := 'POSITIVE';
    l_cp_rec                        Swg_Installedbase_Pub_Pkg.ib_instl_rec_type;

    l_ship_read_cnt_n               NUMBER          := 0;
    l_ship_err_cnt_n                NUMBER          := 0;
    l_ship_proc_cnt_n               NUMBER          := 0;
    x_msg_count_n                   NUMBER;
    x_customer_productid_n          NUMBER;
    x_obj_version_num_n             NUMBER;
    l_party_id_n                    NUMBER;
    l_Customer_Id_n                 NUMBER;
    l_customer_number_n             NUMBER;
    l_sales_center_s                VARCHAR2(10);

    l_status_c                      VARCHAR2(1);
    l_process_flag_c                VARCHAR2(1);
    l_uom_code_s                    VARCHAR2(10)    := 'EA';
    x_return_status_c               VARCHAR2(10);
    -- l_item_system_code_s         VARCHAR2(10)  := 'SACS'; -- 2006/03/09 (Jabel)
    l_item_system_code_s            VARCHAR2(10)  := in_system_code_s;
    l_legacy_addrcode_s             VARCHAR2(20);
    l_New_Code_s                    VARCHAR2(100);
    l_Orig_System_Customer_Ref_s    VARCHAR2(240);
    l_orig_system_ref_s             VARCHAR2(240);   --MTS 431
    x_msg_data_s                    VARCHAR2(2000);
    l_error_message_s               VARCHAR2(2000);

    l_item_rec                      Swgcnv_Cntrct_Vldt.item_info_rec_type;
    l_org_rec                       Swgcnv_Cntrct_Vldt.org_info_rec_type;

    l_ship_to_error_b               BOOLEAN;

    ERROR_ENCOUNTERED               EXCEPTION;
    ERROR_INSTALLBASE               EXCEPTION;

BEGIN

    ou_errbuf_s     :=  NULL;
    ou_retcode_n    :=  0;

    --Fnd_Client_Info.set_org_context(2);
    MO_GLOBAL.Set_Policy_Context('S',2);

    g_flag_c    :=  in_debug_c;

    BEGIN

        SELECT instance_status_id
        INTO   l_ib_status_id_n
        FROM   csi.csi_instance_statuses
        WHERE  name          = l_empty_status_s;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            l_error_message_s   := 'Could not retrieve the instance status id for the status:: '|| l_empty_status_s;
            RAISE ERROR_ENCOUNTERED;
        WHEN OTHERS THEN
            l_error_message_s   := 'UNEXPECTED ERROR: Could not retrieve the instance status id for the status:: '|| l_empty_status_s||' error:' ||SQLERRM;
            RAISE ERROR_ENCOUNTERED;
    END;


    FOR cust_rec IN cur_custs
    LOOP

        BEGIN

          l_ship_to_error_b := FALSE;

          --Get Party Id, Customer Id based on Old Customer Number

          OPEN  Cur_NewCstmr ( cust_rec.oracle_customer_id );
          FETCH Cur_NewCstmr  INTO  l_party_id_n,
                                    l_Customer_id_n,
                                    l_customer_number_n,
                                    l_orig_system_ref_s;

            IF  Cur_NewCstmr%NOTFOUND
            THEN
                l_Party_Id_n        :=  NULL;
                l_Customer_Id_n     :=  NULL;
                l_customer_number_n :=  NULL;
                l_process_flag_c    :=  'N';
            END IF;

          CLOSE Cur_NewCstmr;
          
          IF in_system_code_s LIKE  'SHIPTO%' THEN
             l_orig_system_customer_ref_s := l_orig_system_ref_s;
          ELSE
            l_Orig_System_Customer_Ref_s  :=  G_SWG_CNV_DD_PREFIX   ||
                          cust_rec.system_code    ||'-'||
                          cust_rec.new_sales_center ||'-'||
                          cust_rec.legacy_customer_number;
          END IF;

          IF l_process_flag_c <> 'Y'
          THEN
          
             l_error_message_s   :=  'ERROR: Customer Not Found in Oracle. '||'Legacy Customer Number: '|| Cust_Rec.Legacy_Customer_Number;
             RAISE ERROR_ENCOUNTERED;
             
          END IF;

             debug_mesg('Oracle Customer Number: '||l_customer_number_n);

          FOR l_shipto_rec  IN cur_shipto_info  ( l_Customer_Id_n, l_orig_system_customer_ref_s, cust_rec.new_sales_center )
          LOOP

                BEGIN

                    l_ship_read_cnt_n   := l_ship_read_cnt_n + 1;

                    l_legacy_addrcode_s :=  LTRIM(RTRIM(l_shipto_rec.address_code));

                    debug_mesg( 'address_code:    '||l_legacy_addrcode_s);
                    debug_mesg( 'orig system address ref:   '||l_shipto_rec.orig_system_address_ref);
                    debug_mesg('Before Cur_item...');
                    debug_mesg('Division: '|| cust_rec.division);
                    debug_mesg('Branch: '|| l_shipto_rec.lgcy_sales_center);
                    debug_mesg('Legacy Customer: '|| Cust_Rec.Legacy_Customer_Number);
                    debug_mesg('Delivery Location: '|| l_shipto_rec.address_code);

                FOR item_rec   IN Cur_item (cust_rec.division
                                           ,l_shipto_rec.lgcy_sales_center
                                           ,Cust_Rec.Legacy_Customer_Number
                                           ,l_shipto_rec.address_code)
                LOOP
                        BEGIN

--                          l_ship_read_cnt_n               := l_ship_read_cnt_n + 1;
                            l_error_message_s               := NULL;
                            l_cp_rec.customer_id            := cust_rec.oracle_customer_id;
                            l_cp_rec.cp_status_id           := l_ib_status_id_n;
                            l_cp_rec.quantity               := item_rec.quantity;
                            l_cp_rec.uom_code               := l_uom_code_s;
                            l_cp_rec.currency_code          := 'USD';
                            l_cp_rec.installation_date      := item_rec.installation_date;
                            l_cp_rec.shipped_date           := item_rec.installation_date;
                            l_cp_rec.install_site_use_id    := l_shipto_rec.ship_to_party_site_id;

                            Swgcnv_Cntrct_Vldt.Get_Maps_And_Details
                            ( in_sacs_org_s         => item_rec.sales_center
                             ,in_sacs_brand_s       => item_rec.item_sub_code
                            -- ,in_sacs_item_s      => LTRIM(RTRIM(item_rec.item_code)) -- 2006/03/09 Jabel
                             ,in_sacs_item_s        => LTRIM(RTRIM(item_rec.model))
                             ,in_eff_date_d         => TRUNC(SYSDATE)
                             ,io_item_rec           => l_item_rec
                             ,io_org_rec            => l_org_rec
                             ,io_status_c           => l_status_c
                             ,io_message_s          => l_error_message_s
                             ,in_debug_c            => Swgcnv_Cntrct_Vldt.G_DEBUG
                             ,in_system_code_c      => l_item_system_code_s );

                            IF l_status_c != Swgcnv_Cntrct_Vldt.G_STS_SUCCESS THEN

                                l_error_message_s :=  l_item_system_code_s||'-'||LTRIM(RTRIM(l_item_rec.item_code)) -- reverted
                                    || ' - '||'Sales Center :'|| item_rec.sales_center ||' - '  -- Added by SU on 08/11/2014 EB-829   
                                    || 'Error returned from Get_Maps_And_Details: '
                                    || l_error_message_s;
                                RAISE ERROR_ENCOUNTERED;

                            END IF;

                            l_new_code_s            := l_item_rec.item_code; -- reverted
                            l_cp_rec.inv_item_id    := l_item_rec.inventory_item_id;

                        IF l_new_code_s IS NULL THEN
                            RAISE ERROR_ENCOUNTERED;
                        END IF;

                            debug_mesg('New Code: '||l_new_code_s||' - Quantity: '|| TO_CHAR(l_cp_rec.quantity));

                            -- create the deposit items

                            Swg_Installedbase_Pub_Pkg.Create_Base_Product
                                ( p_api_version             =>  1.0
                                ,p_init_msg_list            =>  Fnd_Api.G_TRUE
                                ,p_commit                   =>  Fnd_Api.G_FALSE
                                ,x_return_status            =>  x_return_status_c
                                ,x_msg_count                =>  x_msg_count_n
                                ,x_msg_data                 =>  x_msg_data_s
                                ,p_cp_rec                   =>  l_cp_rec
                                ,p_created_manually_flag    =>  'N'
                                ,p_org_id                   =>  NULL
                                ,x_cp_id                    =>  X_Customer_ProductId_n
                                ,x_object_version_number    =>  X_Obj_Version_Num_n);

                            IF X_Return_Status_c != Fnd_Api.G_RET_STS_SUCCESS THEN

                          l_error_message_s   :=  'ERROR: While Creating Installed Base item. '||
                              'Error: '|| SUBSTR(x_msg_data_s, 1, 1998);
                          RAISE ERROR_INSTALLBASE;

                            END IF;

                        EXCEPTION

                            WHEN ERROR_ENCOUNTERED THEN

                                ROLLBACK;


                                INSERT INTO swgcnv_conversion_exceptions
                                (conversion_type
                                ,conversion_key_value
                                ,conversion_sub_key1
                                ,error_message
                                ,conversion_sub_key2)
                                VALUES
                                    ('DEPOSIT ITEMS'
                                    ,cust_rec.legacy_customer_number
                                    ,item_rec.delivery_location_number
                                    ,l_error_message_s
                                    -- ,'OLD CODE: '||LTRIM(RTRIM(item_rec.item_code))); -- 2006/03/09 (Jabel)
                                    ,'OLD CODE: '||LTRIM(RTRIM(item_rec.model)));

                                COMMIT;
                                ou_retcode_n    := 1;

                l_ship_to_error_b := TRUE;

                            WHEN ERROR_INSTALLBASE THEN

                                ROLLBACK;

                                INSERT INTO swgcnv_conversion_exceptions
                                (conversion_type
                                ,conversion_key_value
                                ,conversion_sub_key1
                                ,error_message
                                ,conversion_sub_key2)
                                VALUES
                                    ('DEPOSIT ITEMS'
                                    ,cust_rec.legacy_customer_number
                                    ,item_rec.delivery_location_number
                                    ,l_error_message_s
                                    -- ,item_rec.item_code||'-'||l_cp_rec.quantity);-- 2006/03/09 (Jabel)
                                    ,item_rec.model||'-'||l_cp_rec.quantity);

                                COMMIT;
                                ou_retcode_n    := 1;
                                l_ship_to_error_b := TRUE;

                            WHEN OTHERS THEN

                                l_error_message_s   := 'UNEXPECTED ERROR in item loop::'||SQLERRM;

                                ROLLBACK;

                                INSERT INTO swgcnv_conversion_exceptions
                                (conversion_type
                                ,conversion_key_value
                                ,conversion_sub_key1
                                ,error_message
                                ,conversion_sub_key2)
                                VALUES
                                    ('DEPOSIT ITEMS'
                                    ,cust_rec.legacy_customer_number
                                    ,item_rec.delivery_location_number
                                    ,l_error_message_s
                                    -- ,item_rec.item_code||'-'||l_cp_rec.quantity); -- 2006/03/09 (Jabel)
                                    ,item_rec.model||'-'||l_cp_rec.quantity);

                                COMMIT;
                                ou_retcode_n    := 2;
                                l_ship_to_error_b := TRUE;
                        END;

                    END LOOP;   -- ITEM LOOP

                    l_ship_proc_cnt_n   := l_ship_proc_cnt_n + 1;

                EXCEPTION
                    WHEN OTHERS THEN

                        l_ship_err_cnt_n    := l_ship_err_cnt_n + 1;

                        l_error_message_s   := 'UNEXPECTED ERROR in SHIP TO loop::'||SQLERRM;

                        ROLLBACK;

                        INSERT INTO swgcnv_conversion_exceptions
                            (conversion_type
                            ,conversion_key_value
                            ,conversion_sub_key1
                            ,error_message)
                        VALUES
                            ('DEPOSIT ITEMS'
                            ,cust_rec.legacy_customer_number--cust_rec.oracle_customer_number
                            ,l_shipto_rec.address_code--l_shipto_rec.ship_to_site_use_id
                            ,l_error_message_s);

                        COMMIT;
                        ou_retcode_n    := 2;
                        l_ship_to_error_b := TRUE;

                END;

            END LOOP;       --ship to loop


      IF l_ship_to_error_b = TRUE THEN
          UPDATE swgcnv.swgcnv_dd_temp_customers
                SET deposit_proc_flag = 'E'
                WHERE ROWID = cust_rec.row_id;
      ELSE
        UPDATE swgcnv.swgcnv_dd_temp_customers
        SET deposit_proc_flag = 'Y'
                WHERE ROWID = cust_rec.row_id;
      END IF;

            IF in_validate_only_c != 'Y' THEN
                COMMIT;
            ELSE
                ROLLBACK;
            END IF;

        EXCEPTION

            WHEN OTHERS THEN

                l_ship_err_cnt_n    := l_ship_err_cnt_n + 1;

                l_error_message_s   := 'UNEXPECTED ERROR in CUSTOMER loop::'||SQLERRM;

                ROLLBACK;


                INSERT INTO swgcnv_conversion_exceptions
                    (conversion_type
                    ,conversion_key_value
                    ,conversion_sub_key1
                    ,error_message)
                VALUES
                    ('DEPOSIT ITEMS'
                    ,cust_rec.legacy_customer_number--cust_rec.oracle_customer_number
                    ,cust_rec.new_sales_center
                    ,l_error_message_s);

                IF in_validate_only_c != 'Y' THEN
             UPDATE swgcnv.swgcnv_dd_temp_customers
                   SET deposit_proc_flag = 'E'
                   WHERE ROWID = cust_rec.row_id;
        END IF;

                COMMIT;

                ou_retcode_n    := 2;

        END;

    END LOOP;   --CUSTOMER

    Fnd_File.Put_Line(Fnd_File.OUTPUT,'Read Count:                 '||l_ship_read_cnt_n);
    Fnd_File.Put_Line(Fnd_File.OUTPUT,'Error Count:                '||l_ship_err_cnt_n);
    Fnd_File.Put_Line(Fnd_File.OUTPUT,'Processed Count:            '||l_ship_proc_cnt_n);


EXCEPTION
    WHEN ERROR_ENCOUNTERED THEN
        ou_errbuf_s     := l_error_message_s;
        ou_retcode_n    := 2;
        RETURN;
    WHEN OTHERS THEN
        l_error_message_s   := 'UNEXPECTED ERROR: '||SQLERRM;
        ou_errbuf_s     := l_error_message_s;
        ou_retcode_n    := 2;
        RETURN;
END     CREATE_DEPOSIT_ITEMS;

PROCEDURE       Initialize_cpp_items
(in_sales_center_s              IN  VARCHAR2
,in_legacy_model    IN  VARCHAR2
,in_item_sub_code   IN  VARCHAR2
,ou_cpp_inventory_item_id OUT NUMBER
,ou_status_c                    OUT VARCHAR2
,ou_message_s                   OUT VARCHAR2)
IS

    l_item_rec                  Swgcnv_Cntrct_Vldt.item_info_rec_type;
    l_org_rec                   Swgcnv_Cntrct_Vldt.org_info_rec_type;
    l_new_code_s      VARCHAR2(100);
    -- l_system_name_s      VARCHAR2(10) := 'SACS'; -- Item mapping referred to SACS code -- 2006/03/09 (Jabel)
    l_system_name_s     VARCHAR2(10) := 'RIMLAP'; -- Item mapping referred to SACS code
    l_status_c        VARCHAR2(1);
    l_error_message_s     VARCHAR2(2000);

BEGIN
  Swgcnv_Cntrct_Vldt.Get_Maps_And_Details
         ( in_sacs_org_s         => in_sales_center_s
         ,in_sacs_brand_s  => in_item_sub_code
         ,in_sacs_item_s   => in_legacy_model
         ,in_eff_date_d    => TRUNC(SYSDATE)
         ,io_item_rec    => l_item_rec
         ,io_org_rec     => l_org_rec
         ,io_status_c    => l_status_c
         ,io_message_s     => l_error_message_s
         ,in_debug_c     => Swgcnv_Cntrct_Vldt.G_DEBUG
         ,in_system_code_c       => l_system_name_s );

       IF l_status_c != Swgcnv_Cntrct_Vldt.G_STS_SUCCESS THEN
            ou_message_s  :=  l_system_name_s||'-'||LTRIM(RTRIM(in_legacy_model))
                                    || 'Error returned from Get_Maps_And_Details: '
                                    || l_error_message_s;
      ou_status_c   := l_status_c;
      ou_cpp_inventory_item_id := NULL;
      RETURN;
   ELSE
      BEGIN
         SELECT item.inventory_item_id
         INTO   ou_cpp_inventory_item_id
         FROM   mtl_item_categories itemcat
    , mtl_system_items item
    , mtl_categories_b cat
    , mtl_category_sets_tl catset
    , org_organization_definitions  org
         WHERE item.inventory_item_id = itemcat.inventory_item_id
         -- AND item.segment1 = l_item_rec.item_code -- 2006/03/09 (Jabel)
         AND item.segment1 = l_item_rec.item_code -- reverted
         AND org.organization_code = in_sales_center_s
         AND itemcat.organization_id = org.organization_id
         AND item.organization_id = org.organization_id
         AND itemcat.category_id = cat.category_id
         AND catset.category_set_id = itemcat.category_set_id
         AND catset.category_set_name = 'DIRECT DELIVERY'
         AND catset.LANGUAGE = USERENV ('LANG')
         AND cat.segment1 = 'CPP';

               ou_message_s :=  l_system_name_s||'-'||LTRIM(RTRIM(in_legacy_model))
                                    || 'CPP Inventory Item Id'||ou_cpp_inventory_item_id
                                    || 'Legacy Item Model '||in_legacy_model;
         ou_status_c    := l_status_c;

      EXCEPTION
      WHEN OTHERS THEN
         NULL; -- Not a CPP Model. Do not populate the PLSQL table.
      END;
         END IF;
END;

END Swgcnv_Dd_Cntrc_Pkg;
/
SHOW ERRORS;
EXIT;
