CREATE OR REPLACE PACKAGE Swgcnv_Ar_Conv_Pkg
IS
/*===============================================================================+
| Copyright (c) 2005 DS Waters, Atlanta, GA 30328 USA All rights reserved.       |
+================================================================================+
|                                                                                |
| File Name:     SWGCNV_AR_CONV_PKB.pls                                          |
| Description:   Converion AR Package                                            |
|                                                                                |
| Revision History:                                                              |
| Date        Author          Change Description                                 |
| ---------   ----------      -------------------------------------------        |
| Unknown     Unknown         Production Release                                 |
| 12/08/2008  Pankaj Umate    Changes For ARS03 Conversion.                      |
| 01/22/2009  Pankaj Umate    Moved Standalone Procedure SWGCNV_UPD_AR_STAGING_P |
|                             Into Package. ARS04 Conversion. Daptiv # 768       |
| 12/14/2009  Pankaj Umate    Added Procedure To Unapply And Apply Receipts.     |
|                             Daptiv # 1299                                      |
| 03/20/2012  Mike Schenk     #20129 moved updates from script to package        |
| 06/06/2012  Mike Schenk     #20429  Procedure to load and submit Autoinvoice   |
+===============================================================================*/

   PROCEDURE   SWGCNV_AR_CONVERSION
      (   ou_errmsg_s      OUT   VARCHAR2
         ,ou_errcode_n     OUT   NUMBER
         ,p_legacy_system  IN    VARCHAR2
         ,p_division       IN    VARCHAR2
         ,p_sales_center   IN    VARCHAR2
      );
                                        
   FUNCTION    SWGCNV_SHIPTO_ADDRESS_ID
      (   p_legacy_system       IN     VARCHAR2
         ,p_sales_center        IN     VARCHAR2
         ,p_customer_ref        IN     VARCHAR2
         ,p_ship_address_ref    IN     VARCHAR2
         ,p_cust_account_id     IN     NUMBER
      )
   RETURN  NUMBER;
    
   FUNCTION    SWGCNV_BILLTO_ADDRESS_ID
      (   p_legacy_system       IN    VARCHAR2
         ,p_sales_center        IN    VARCHAR2
         ,p_customer_ref        IN    VARCHAR2
         ,p_bill_address_ref    IN    VARCHAR2
         ,p_cust_account_id     IN    NUMBER
      )
   RETURN  NUMBER;
    
   FUNCTION    SWGCNV_NEWITEM_CODE
      (   p_sales_center    IN    VARCHAR2
         ,p_old_item_code   IN    VARCHAR2
      )
   RETURN  VARCHAR2;
    
   FUNCTION    SWGCNV_SALESREP
      (   p_legacy_system   IN    VARCHAR2
         ,p_old_code        IN    VARCHAR2
      )
   RETURN NUMBER;
    
   PROCEDURE   INSERT_RA_LINES ( p_ra_lines_rec    IN      ra_interface_lines_all%ROWTYPE);
    
   PROCEDURE   SWGCNV_UPDATE_DUEDATE
      (   ou_errmsg_s      OUT     VARCHAR2
         ,ou_errcode_n     OUT     NUMBER
         ,p_sales_center   IN      VARCHAR2
      );
                                        
   PROCEDURE   swgcnv_post_update1
      (   ou_errmsg_s       OUT     VARCHAR2
         ,ou_errcode_n      OUT     NUMBER
         ,p_sales_center    IN      VARCHAR2
      );
                                        
   PROCEDURE   SWGCNV_POST_UPDATE2  
      (   ou_errmsg_s      OUT    VARCHAR2
         ,ou_errcode_n     OUT    NUMBER
         ,p_sales_center   IN     VARCHAR2
      );
                                        
   PROCEDURE   SWGCNV_AR_TRX_NUMBER 
      (   ou_errmsg_s      OUT    VARCHAR2
         ,ou_errcode_n     OUT    NUMBER
         ,p_sales_center   IN     VARCHAR2
         ,p_legacy_system  IN     VARCHAR2
      );
                                        
   PROCEDURE   SWGCNV_AR_PREUPDATES
      (   ou_errmsg_s      OUT    VARCHAR2
         ,ou_errcode_n     OUT    NUMBER
         ,p_division       IN     VARCHAR2
         ,p_sales_center   IN     VARCHAR2
      );
      
   PROCEDURE   SWGCNV_AR_PRECONV_REPORTS
      (   ou_errmsg_s      OUT   VARCHAR2
         ,ou_errcode_n     OUT   NUMBER
         ,p_sales_center   IN    VARCHAR2
      );
                                            
   PROCEDURE   SWGCNV_AR_PRECONV_REPORTS1
      (   ou_errmsg_s      OUT       VARCHAR2
         ,ou_errcode_n     OUT       NUMBER
         ,p_sales_center   IN        VARCHAR2
      );
                                            
   PROCEDURE   SWGCNV_SEQ_PROG
      (   out_errbuf_s        OUT     VARCHAR2
         ,out_errnum_n        OUT     NUMBER
         ,p_legacy_system     IN      VARCHAR2
         ,p_sales_center      IN      VARCHAR2
      );
      
   -- Added As Part Of R12 Upgrade To Calculate Tax   
                                            
   PROCEDURE   SWGCNV_ADD_TAX_LINES
      (   ou_errbuff_s       OUT    VARCHAR2
         ,ou_errcode_n       OUT    NUMBER
         ,in_sales_center_s  IN     VARCHAR2
         ,in_division_id_n   IN     VARCHAR2
         ,in_system_code_s   IN     VARCHAR2
      );
      
   -- Moved Standalone Procedure SWGCNV_UPD_AR_STAGING_P Into Package

   PROCEDURE   SWGCNV_UPD_CUST_REF
      (   ou_errbuf_s         OUT   VARCHAR2
         ,ou_errcode_n        OUT   NUMBER
         ,in_sales_center_s   IN    VARCHAR2
         ,in_system_name_s    IN    VARCHAR2
         ,in_division_s       IN    VARCHAR2
         ,in_mode_c           IN    VARCHAR2
         ,in_debug_flag_c     IN    VARCHAR2    DEFAULT     'N'
      );
      
   PROCEDURE   Unapply_Receipt
      (   ou_errbuff_s        OUT   VARCHAR2
         ,ou_errcode_n        OUT   NUMBER
         ,in_system_code_s    IN    VARCHAR2
         ,in_sales_center_s   IN    VARCHAR2
         ,in_validate_only_c  IN    VARCHAR2  
      );
      
   PROCEDURE   Apply_CashCredit
      (   out_errbuf_s        OUT   VARCHAR2
         ,out_errnum_n        OUT   NUMBER
         ,in_type_s           IN    VARCHAR2
         ,in_system_code_s    IN    VARCHAR2
         ,in_division_n       IN    NUMBER
         ,in_location_n       IN    NUMBER
         ,in_customer_n       IN    NUMBER
         ,in_debug_s          IN    VARCHAR2
      );  

   PROCEDURE SWGCNV_UPDATE_AR_HISTORY        --MTS 20129
          (ou_errbuff_s            OUT        VARCHAR2
          ,ou_errcode_n            OUT        NUMBER
          ,in_legacy_system_s      IN         VARCHAR2);

  

   PROCEDURE SWGCNV_AR_HISTORY_DIAGS         --MTS 20129
          (ou_errbuff_s            OUT        VARCHAR2
          ,ou_errcode_n            OUT        NUMBER
          ,in_legacy_system_s      IN         VARCHAR2);

   PROCEDURE SWGCNV_AR_PROC_AUTOINVOICE         --MTS 20429
          (ou_errbuff_s            OUT        VARCHAR2
          ,ou_errcode_n            OUT        NUMBER
          ,in_legacy_system_s      IN         VARCHAR2);
      
END Swgcnv_Ar_Conv_Pkg;
/
SHOW ERRORS;
EXIT;
