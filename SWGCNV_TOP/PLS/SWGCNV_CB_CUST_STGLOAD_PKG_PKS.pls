CREATE OR REPLACE PACKAGE Swgcnv_CB_Cust_stgload_Pkg
AS
/*=====================================================================================+
| Copyright (c) 2005 DS Waters, Atlanta, GA 30328 USA All rights reserved.             |
+======================================================================================+
| Name:           SWGCNV_CB_CUST_STGLOAD_PKG                                           |
| File:           SWGCNV_CB_CUST_STGLOAD_PKG_PKS.pls                                       |
| Description:    Package Specification For Loading Data From Pre Staging To           |
|                 Staging Tables                                                       |   
|                                                                                      |
| Company:        DS Waters                                                            |
| Author:         Unknown                                                              |
| Date:           Unknown                                                              |
|                                                                                      |
| Modification History:                                                                |
| Date            Author            Description                                        |
| ----            ------            -----------                                        |
| Unknown         Unknown           Production Release                                 |
| 11/28/2009      Pankaj Umate      Modified For SAGE Conversion. Datptiv No: 1299     | 
| 04/24/2012      Mike Schenk       20129                                              |
| 08/05/2013      Bala Palani       WO #21652                                          |
+=====================================================================================*/

   G_SUCCESS_C          CONSTANT	   VARCHAR2(1)	   :=	   'S';
   G_ERROR_C		      CONSTANT	   VARCHAR2(1)	       :=	   'E';
   G_UNEXP_ERROR_C	   CONSTANT	   VARCHAR2(1)	     :=	   'U';
   G_SWG_DEBUG		      CONSTANT	   VARCHAR2(1)	     :=	   'Y';
   G_SWG_NODEBUG		   CONSTANT	   VARCHAR2(1)	      :=	   'N';
   G_SWG_CONCURRENT	   CONSTANT	   VARCHAR2(1)	    :=	   'C';
   G_SWG_SQLPLUS		   CONSTANT	   VARCHAR2(1)	      :=	   'S';

   TYPE cust_rec_type IS RECORD
      (   CUSTOMER_ID                 NUMBER(15)               -- NOT NULL,
         ,CUSTOMER_NUMBER             VARCHAR2(10 BYTE)        -- NOT NULL,
         ,CUSTOMER_NAME               VARCHAR2(50 BYTE)        -- NOT NULL,
         ,PERSON_FLAG                 VARCHAR2(1 BYTE)         -- NOT NULL,
         ,PERSON_FIRST_NAME           VARCHAR2(150 BYTE)
         ,PERSON_LAST_NAME            VARCHAR2(150 BYTE)
         ,SERVICE_INTERESTED_IN       VARCHAR2(150 BYTE)       -- NOT NULL,
         ,HOW_DID_YOU_HEAR_ABOUT_US   VARCHAR2(150 BYTE)       -- NOT NULL,
         ,SERVICE_LOCATION            VARCHAR2(150 BYTE)       -- NOT NULL,
         ,NO_OF_PEOPLE_USING_SERVICE  VARCHAR2(150 BYTE)       -- NOT NULL,
         ,WHAT_PROMPTED_INTEREST      VARCHAR2(150 BYTE)       -- NOT NULL,
         ,CURRENT_PRODUCT_OR_SERVICE  VARCHAR2(150 BYTE)       -- NOT NULL,
         ,MONTHLY_INVOICE_FORMAT      VARCHAR2(150 BYTE)       -- NOT NULL,
         ,SIGNED_DELVIERY_RECEIPT     VARCHAR2(150 BYTE)       -- NOT NULL,
         ,BILLING_COMMUNICATIONS      VARCHAR2(150 BYTE)       -- NOT NULL,
         ,SALES_CENTER                VARCHAR2(3 BYTE)         -- NOT NULL,
         ,DIVISION                    VARCHAR2(20 BYTE)        -- NOT NULL,
         ,ATTRIBUTE1                  VARCHAR2(50 BYTE)
         ,CUSTOMER_START_DATE         DATE
         ,MARKET_CODE                 VARCHAR2(20 BYTE)
         ,ACCOUNT_DEPOSIT             NUMBER
         ,SEQ                         NUMBER
         ,PREFERRED_CUSTOMER_FLAG     VARCHAR2(1 BYTE)  DEFAULT 'N'
      );

   g_cust_rec cust_rec_type;

   TYPE addr_rec_type IS RECORD
      (   ADDRESS_ID             NUMBER(15)              --    NOT NULL,  
         ,CUSTOMER_ID            NUMBER(15)              --    NOT NULL,
    		,CUSTOMER_NUMBER        VARCHAR2(10 BYTE)       --    NOT NULL,
    		,ADDRESS1               VARCHAR2(240 BYTE)
    		,ADDRESS2               VARCHAR2(240 BYTE)
    		,ADDRESS3               VARCHAR2(240 BYTE)
    		,ADDRESS4               VARCHAR2(240 BYTE)
    		,CITY                   VARCHAR2(60 BYTE)
    		,STATE                  VARCHAR2(60 BYTE)
    		,PROVINCE               VARCHAR2(60 BYTE)
    		,COUNTY                 VARCHAR2(60 BYTE)
    		,POSTAL_CODE            VARCHAR2(60 BYTE)
    		,COUNTRY                VARCHAR2(60 BYTE)       --    NOT NULL,
    		,LATITUDE               VARCHAR2(150 BYTE)
    		,LONGITUDE              VARCHAR2(150 BYTE)
    		,COMPLEX_TYPE           VARCHAR2(150 BYTE)
    		,VARIABLE_UNLOAD_TIME   VARCHAR2(150 BYTE)
    		,FIXED_UNLOAD_TIME      VARCHAR2(150 BYTE)
    		,DOCK_TYPE              VARCHAR2(150 BYTE)
    		,SALES_CENTER           VARCHAR2(3 BYTE)        --    NOT NULL,
    		,ADDR_CLEAN_UP_FLAG     VARCHAR2(1 BYTE)     DEFAULT 'N'
    		,DIVISION               VARCHAR2(10 BYTE)       --    NOT NULL,
    		,SEQ                    NUMBER
      );

   g_addr_rec addr_rec_type;

   TYPE billto_rec_type IS RECORD
      (   BILLTO_SITE_ID               NUMBER(15)           -- NOT NULL
         ,CUSTOMER_ID                  NUMBER(15)           -- NOT NULL
         ,BILL_TO_ADDRESS_ID           NUMBER(15)           -- NOT NULL
         ,CUSTOMER_NUMBER              VARCHAR2(10 BYTE)    -- NOT NULL
         ,BILLING_LOCATION_NUMBER      VARCHAR2(10 BYTE)    -- NOT NULL
         ,PO_NUMBER                    VARCHAR2(150 BYTE)
         ,PO_EFFECTIVE_FROM_DATE       VARCHAR2(150 BYTE)
         ,PO_EFFECTIVE_TO_DATE         VARCHAR2(150 BYTE)
         ,PO_TOTAL_DOLLARS             VARCHAR2(150 BYTE)
         ,PO_TOTAL_UNITS               VARCHAR2(150 BYTE)
         ,CUSTOMER_REFERENCE_NUMBER    VARCHAR2(150 BYTE)
         ,REMIT_TO_ADDRESS             VARCHAR2(150 BYTE)   -- NOT NULL
         ,CUSTOMER_PROFILE_CLASS_NAME  VARCHAR2(30 BYTE)    -- NOT NULL
         ,PAYMENT_METHOD_NAME          VARCHAR2(30 BYTE)
         ,ACCOUNT_STATUS               VARCHAR2(40 BYTE)    -- NOT NULL
         ,SALES_CENTER                 VARCHAR2(3 BYTE)     -- NOT NULL
         ,DIVISION                     VARCHAR2(50 BYTE)    -- NOT NULL
         ,STATEMENT_MAILED             VARCHAR2(1 BYTE)
         ,BILLING_CYCLE_DAY            VARCHAR2(2 BYTE)
         ,CYCLE_TYPE                   NUMBER
         ,CREDIT_SCORE                 VARCHAR2(4 BYTE)
         ,PROTECT_FLAG                 VARCHAR2(1 BYTE)
         ,LATE_FEE_FLAG                VARCHAR2(1 BYTE)
         ,NEXT_DAY_INVOICE_FLAG        VARCHAR2(1 BYTE)
         ,BSC_FLAG                     VARCHAR2(1 BYTE)
         ,TERM_FEE_AMOUNT              NUMBER
         ,AGREEMENT_TERM               VARCHAR2(30 BYTE)
      );

   g_billto_rec billto_rec_type;

   TYPE shipto_rec_type IS RECORD
      (   SHIPTO_SITE_ID               NUMBER(15)       --NOT NULL,
  			,CUSTOMER_ID                  NUMBER(15)       --NOT NULL,
    		,SHIP_TO_ADDRESS_ID           NUMBER(15)       --NOT NULL,
    		,BILLING_SITE_ID              NUMBER(15)       --NOT NULL,
    		,CUSTOMER_NUMBER              VARCHAR2(10 BYTE) --NOT NULL,
    		,DELIVERY_LOCATION_NUMBER     VARCHAR2(10 BYTE) --NOT NULL,
    		,CUSTOMER_TAX_CLASS           VARCHAR2(150 BYTE)
    		,PO_NUMBER                    VARCHAR2(150 BYTE)
    		,PO_EFFECTIVE_FROM_DATE       VARCHAR2(150 BYTE)
    		,PO_EFFECTIVE_TO_DATE         VARCHAR2(150 BYTE)
    		,PO_TOTAL_DOLLARS             VARCHAR2(150 BYTE)
    		,PO_TOTAL_UNITS               VARCHAR2(150 BYTE)
    		,CUSTOMER_REFERENCE_NUMBER    VARCHAR2(150 BYTE)
    		,TAX_EXEMPT_NUMBER            VARCHAR2(150 BYTE)
    		,TAX_EXEMPT_EXP_DATE          VARCHAR2(150 BYTE)
    		,TAX_EXEMPT_CERTIFICATE_RCVD  VARCHAR2(150 BYTE)
    		,SALES_CENTER                 VARCHAR2(3 BYTE) --NOT NULL,
    		,DIVISION                     VARCHAR2(50 BYTE) --NOT NULL,
    		,ROUTE_NUMBER                 VARCHAR2(10 BYTE)
    		,ROUTE_DELIVERY_FREQUENCY     VARCHAR2(10 BYTE)
    		,NEXT_REGULAR_DELIVER_DATE    DATE
    		,DELIVERY_INSTRUCTIONS        VARCHAR2(1000 BYTE)
    		,ROUTE_MESSAGE                VARCHAR2(240 BYTE)
    		,COLLECTION_MESSAGE           VARCHAR2(240 BYTE)
    		,ADDRESSEE                    VARCHAR2(100 BYTE)
    		,FREQUENCY                    VARCHAR2(10 BYTE)
    		,CUSTOMER_START_DATE          DATE
    		,SHIP_TO_START_DATE           DATE
    		,SUPPRESS_PRICE_HH_TICKET     VARCHAR2(1 BYTE)
    		,RSR_OVERIDE_SUPPRESS_PRICE   VARCHAR2(1 BYTE)
    		,BOTTLE_INITIAL_INVENTORY     VARCHAR2(3 BYTE)
    		,RATE_SCHEDULE                VARCHAR2(4 BYTE)
    		,CHARGE_DEPOSIT               VARCHAR2(1 BYTE)
    		,PREFERRED_CUSTOMER_FLAG      VARCHAR2(1 BYTE)
    		,PENDING                      VARCHAR2(1 BYTE)
    		,BSC_FLAG                     VARCHAR2(1 BYTE)
    		,CREDIT_SCORE                 VARCHAR2(4 BYTE)
    		,TERM_FEE_AMOUNT              NUMBER
    		,AGREEMENT_TERM               VARCHAR2(30 BYTE)
    		,BOTTLE_DEPOSIT_AMT           NUMBER
    		,DELIVERY_TICKET_PRINT_FLAG   VARCHAR2(1 BYTE)
    		,TIER_PRICE_PROC_FLAG         VARCHAR2(1 BYTE) DEFAULT 'N'
    		,BOT_DEPOSIT_PROC_FLAG        VARCHAR2(1 BYTE) DEFAULT 'N'
  			--,HOLD_REASON			VARCHAR2(10),
  			--,WILL_CALL_FLAG			VARCHAR2(1)
      );

   g_shipto_rec shipto_rec_type;

   TYPE contact_rec_type IS RECORD
      (
          CUSTOMER_ID            NUMBER(15)               --NOT NULL,
         ,ADDRESS_ID             NUMBER(15)
    		,CONTACT_FIRST_NAME     VARCHAR2(40 BYTE)
    		,CONTACT_LAST_NAME      VARCHAR2(50 BYTE)
    		,TELEPHONE_AREA_CODE    VARCHAR2(10 BYTE)
    		,TELEPHONE              VARCHAR2(25 BYTE)        --NOT NULL,
    		,TELEPHONE_EXTENSION    VARCHAR2(20 BYTE)
    		,TELEPHONE_TYPE         VARCHAR2(30 BYTE)        --NOT NULL,
    		,EMAIL_ADDRESS          VARCHAR2(240 BYTE)
      );

   g_contact_rec contact_rec_type;

   TYPE cycleday_rec_type IS RECORD
      (
          CUSTOMER_ID            NUMBER(15)
  			,SHIPPING_SITE_ID       NUMBER(15)
  			,ROUTE_SERVICE_DAY      VARCHAR2(2 BYTE)
  			,ROUTE_SEQUENCE         NUMBER(15)
  			,CYCLE_DAY              VARCHAR2(2 BYTE)
  			,DRIVING_INSTRUCTIONS   VARCHAR2(2000 BYTE)
      );

   g_cycleday_rec cycleday_rec_type;

   TYPE eqp_rec_type IS RECORD
      (
          CUSTOMER_NUMBER              VARCHAR2(20 BYTE)   --NOT NULL,
         ,DELIVERY_LOCATION_NUMBER     VARCHAR2(10 BYTE)   --NOT NULL,
         ,ITEM_CODE                    VARCHAR2(20 BYTE)   --NOT NULL,
         ,PLACEMENT_CODE               VARCHAR2(20 BYTE)   --NOT NULL,
         ,SERIAL_NUMBER                VARCHAR2(30 BYTE)   --NOT NULL,
         ,RENTAL_AMOUNT                NUMBER              --NOT NULL,
         ,INSTALLATION_DATE            DATE                --NOT NULL,
         ,LAST_BILLING_DATE            DATE                --NOT NULL,
         ,PAYMENT_TERMS                VARCHAR2(30 BYTE)
         ,ACCOUNTING_RULE              VARCHAR2(20 BYTE)   --NOT NULL,
         ,INVOICING_RULE               VARCHAR2(20 BYTE)   --NOT NULL,
         ,BILLING_METHOD               VARCHAR2(30 BYTE)   --NOT NULL,
         ,BILLING_INTERVAL             VARCHAR2(20 BYTE)   --NOT NULL,
         ,SALES_CENTER                 VARCHAR2(3 BYTE)    --NOT NULL,
         ,DIVISION                     VARCHAR2(10 BYTE)   --NOT NULL,
         ,MODEL                        VARCHAR2(50 BYTE)
         ,ESCROW_AMOUNT                NUMBER
         ,CONTRACT_START_DATE          DATE
         ,NEXT_BILL_DATE               DATE
         ,VALID_FLAG                   VARCHAR2(1 BYTE)    DEFAULT 'N'
         ,LAST_SRV_DATE                DATE
         ,RENTAL_EXCEPTION_CODE        VARCHAR2(10 BYTE)
         ,SRVC_DUE_DATE                DATE
         ,QUANTITY                     NUMBER
         ,ITEM_SUB_CODE                VARCHAR2(50 BYTE)
         ,GRATIS_COUNT                 VARCHAR2(10 BYTE)
         ,CUST_EQPMNT_OWNED_STATUS     VARCHAR2(1 BYTE)
         ,CUST_REMAINING_PMT           NUMBER
      );

   g_eqp_rec eqp_rec_type;

   PROCEDURE insert_row
      (   in_entity_name_s    IN    VARCHAR2
         ,in_cust_rec         IN    cust_rec_type      --1.  Customer staging table: 	SWGCNV_DD_CUSTOMER_INTERFACE
         ,in_addr_rec         IN    addr_rec_type      --2.  Addresses table	    :		SWGCNV_DD_ADDRESSES
         ,in_billto_rec       IN    billto_rec_type    --3.  Billing Locations     :		SWGCNV_DD_CUSTOMER_BILLTO
         ,in_shipto_rec       IN    shipto_rec_type    --4.  Shipping Locations    :		SWGCNV_DD_CUSTOMER_SHIPTO
         ,in_contact_rec      IN    contact_rec_type   --5.  Contacts		    :		SWGCNV_DD_CUSTOMER_CONTACT
         ,in_cycleday_rec     IN    cycleday_rec_type  --6.  Shipping Cycle Day    :		SWGCNV_DD_CYCLEDAYS
         ,in_eqp_rec          IN    eqp_rec_type       --7.  Contracts/Equipment   :		SWGCNV_DD_EQPMNT_INTERFACE
      );

   FUNCTION check_cust_exists
      (   in_cust_num_s	   IN	   VARCHAR2
         ,in_cust_type_s	IN	   VARCHAR2
         ,in_cust_name_s	IN	   VARCHAR2
         ,in_sales_ctr_s	IN	   VARCHAR2
         ,in_division_s	   IN	   VARCHAR2
      )
   RETURN NUMBER;

   FUNCTION  check_mast_cust_exists
      (   in_cust_num_s			   IN		   VARCHAR2
         ,in_sales_ctr_s		   IN		   VARCHAR2
         ,in_division_s			   IN		   VARCHAR2
         ,io_mast_cust_name_s		IN OUT	VARCHAR2
      ) 
   RETURN NUMBER;

   FUNCTION  get_master_cust_billto
      (   in_cust_id_n		IN	   NUMBER
         ,in_sales_ctr_s	IN	   VARCHAR2
         ,in_division_s		IN	   VARCHAR2
      ) 
   RETURN NUMBER;

   FUNCTION check_bill_addr_exists
      (   in_cust_num_s	      IN	   VARCHAR2
         ,in_bill_addr1_s	   IN	   VARCHAR2
         ,in_bill_addr2_s	   IN	   VARCHAR2
         ,in_bill_city_s		IN	   VARCHAR2
         ,in_bill_state_s	   IN	   VARCHAR2
         ,in_bill_zip		   IN	   VARCHAR2
         ,in_sales_ctr_s	   IN	   VARCHAR2
         ,in_division_s	      IN	   VARCHAR2
      )
   RETURN NUMBER;

   FUNCTION check_ship_addr_exists
      (   in_cust_num_s	      IN	   VARCHAR2
         ,in_ship_addr1_s	   IN	   VARCHAR2
         ,in_ship_addr2_s	   IN	   VARCHAR2
         ,in_ship_addr3_s	   IN	   VARCHAR2       -- Added For SAGE Acquisition
         ,in_ship_city_s		IN	   VARCHAR2
         ,in_ship_state_s	   IN	   VARCHAR2
         ,in_ship_zip		   IN	   VARCHAR2
         ,in_sales_ctr_s	   IN	   VARCHAR2
         ,in_division_s	      IN	   VARCHAR2
      )
   RETURN NUMBER;

   FUNCTION  get_bill_site_id
      (   in_cust_id_n	            NUMBER
         ,in_bill_addr_id_n	      NUMBER  
         ,in_cust_num_s	            VARCHAR2
         ,in_sales_ctr_s	   IN	   VARCHAR2
         ,in_division_s	      IN	   VARCHAR2
      )
   RETURN NUMBER;

   FUNCTION get_ship_to_site_id 
      (   in_cust_id_n	            NUMBER
         ,in_ship_addr_id_n	      NUMBER  
         ,in_bill_site_id_n	      NUMBER
         ,in_cust_num_s	            VARCHAR2
         ,in_sales_ctr_s	   IN	   VARCHAR2
         ,in_division_s	      IN	   VARCHAR2
      )
   RETURN NUMBER;

   FUNCTION check_cust_contact_exists
      (   in_customer_id_n	   IN	   NUMBER
         ,in_address_id_n	   IN	   NUMBER
         ,in_area_code_s	   IN	   VARCHAR2
         ,in_number_s		   IN	   VARCHAR2
         ,in_email_address_s  IN    VARCHAR2
      )
   RETURN BOOLEAN;

   FUNCTION check_contract_exists
      (   in_cust_num_s	      IN	   VARCHAR2
         ,in_ship_site_id_s   IN	   VARCHAR2
         ,in_item_code_s	   IN	   VARCHAR2
         ,in_serial_num_s     IN    VARCHAR2
         ,in_sales_ctr_s	   IN	   VARCHAR2
         ,in_division_s	      IN	   VARCHAR2
      )
   RETURN BOOLEAN;

   -- The following function can be commented out if the check_contract_exists, SIGNED_DELVIERY_RECEIPT (Customers)) col do not need to use it.
   FUNCTION get_mapped_value
      (   in_system_name_s		   IN	   VARCHAR2
         ,in_entity_s			   IN	   VARCHAR2
         ,in_old_entity_value_s	IN	   VARCHAR2
      )
   RETURN VARCHAR2;

   -----------------------------------------------------------------
   -- 
   FUNCTION get_mapped_value
      (   in_system_name_s		   IN	   VARCHAR2
         ,in_entity_s			   IN	   VARCHAR2
         ,in_old_entity_value_s	IN	   VARCHAR2
			,in_sales_center_s      IN    VARCHAR2
      )
   RETURN VARCHAR2;

   -----------------------------------------------------------------
   
   --
   -- Function added by Bala Palani as per WO : 21652
   -- 
   
	  FUNCTION swgcnv_get_restrctd_prclst
	                               ( p_legacy_system  VARCHAR2
										                      , p_leg_cust_nbr   VARCHAR2
										                       )
   RETURN VARCHAR2;
   
   -----------------------------------------------------------------   

   PROCEDURE   insert_sub_cust
      (   ou_errbuf2_s        OUT	VARCHAR2
         ,ou_errcode2_n			OUT	NUMBER
         ,in_sales_center_s   IN  	VARCHAR2	DEFAULT	'SAC'
         ,in_system_name_s		IN	   VARCHAR2	DEFAULT	'ARS01'
         ,in_mode_c			   IN	   VARCHAR2	DEFAULT	G_SWG_CONCURRENT
         ,in_debug_flag_c		IN	   VARCHAR2	DEFAULT	G_SWG_NODEBUG
      );


   PROCEDURE   insert_main
      (   ou_errbuf_s			OUT	VARCHAR2
         ,ou_errcode_n			OUT	NUMBER
         ,in_sales_center_s             IN      VARCHAR2
         ,in_system_name_s              IN      VARCHAR2
         ,in_proc_mstr_only_c           IN      VARCHAR2
         ,in_mode_c                     IN	VARCHAR2 DEFAULT G_SWG_CONCURRENT
         ,in_debug_flag_c               IN      VARCHAR2 DEFAULT G_SWG_NODEBUG
      );


END Swgcnv_CB_Cust_stgload_Pkg;
/
SHOW ERRORS;
EXIT;
