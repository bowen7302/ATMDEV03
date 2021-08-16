LOAD DATA 
--infile * 
-- INSERT 00408484
-- APPEND INTO TABLE swgcnv.swgcnv_dd_eqpmnt_interface
   REPLACE INTO TABLE swgcnv.swgcnv_dd_eqpmnt_interface
FIELDS TERMINATED BY '|' OPTIONALLY ENCLOSED BY '"' TRAILING NULLCOLS
 (
  CUSTOMER_NUMBER		"Ltrim(Rtrim(LPAD(:CUSTOMER_NUMBER, 8, '0')))"
 ,DELIVERY_LOCATION_NUMBER	"Ltrim(Rtrim(LPAD(:DELIVERY_LOCATION_NUMBER, 8, '0')))"
 ,ITEM_CODE			"NVL(Ltrim(Rtrim(:ITEM_CODE), '0'),'NULL')"
 ,PLACEMENT_CODE		"Ltrim(Rtrim(:PLACEMENT_CODE))"
 ,SERIAL_NUMBER			"NVL(Ltrim(Rtrim(:SERIAL_NUMBER), '0'), 'OCN'||to_char(swgdd.SWG_SER_NUM_S.NEXTVAL))"
 ,RENTAL_AMOUNT			"nvl(Replace(Ltrim(Rtrim(:RENTAL_AMOUNT)),','), 0)"
 ,INSTALLATION_DATE		"NVL(TO_DATE(Ltrim(Rtrim(:INSTALLATION_DATE)),'MM/DD/RRRR'),TO_DATE(SYSDATE))"
 ,LAST_BILLING_DATE		"NVL(TO_DATE(Ltrim(Rtrim(:LAST_BILLING_DATE)),'MM/DD/RRRR'),TO_DATE(SYSDATE))"
 ,PAYMENT_TERMS			"NVL(Ltrim(Rtrim(:PAYMENT_TERMS)),'')"
 ,ACCOUNTING_RULE		"Ltrim(Rtrim(:ACCOUNTING_RULE))"
 ,INVOICING_RULE		"Ltrim(Rtrim(:INVOICING_RULE))"
 ,BILLING_METHOD		"Ltrim(Rtrim(:BILLING_METHOD))"
 ,BILLING_INTERVAL		"nvl(Ltrim(Rtrim(:BILLING_INTERVAL)), 'MONTHLY')"
 ,SALES_CENTER			"NVL(Ltrim(Rtrim(:SALES_CENTER)), 'XXX')"
 ,DIVISION			"NVL(Ltrim(Rtrim(:DIVISION)), '3171')"
 ,MODEL				"Ltrim(Rtrim(:MODEL))"
 ,ESCROW_AMOUNT			"Ltrim(Rtrim(:ESCROW_AMOUNT))"
 ,CONTRACT_START_DATE		"NVL(TO_DATE(Ltrim(Rtrim(:CONTRACT_START_DATE)),'MM/DD/RRRR'),TO_DATE(SYSDATE))"
 ,NEXT_BILL_DATE		"NVL(TO_DATE(Ltrim(Rtrim(:NEXT_BILL_DATE)),'MM/DD/RRRR'),TO_DATE(SYSDATE))"
 --,NEXT_BILL_DATE		"NVL(TO_DATE(Ltrim(Rtrim(:NEXT_BILL_DATE)),'MM/DD/RRRR'),TO_DATE('01/01/2012','MM/DD/RRRR'))"
 ,LAST_SRV_DATE                 "TO_DATE(Ltrim(Rtrim(:LAST_SRV_DATE)),'MM/DD/RRRR')"
 ,RENTAL_EXCEPTION_CODE         "Ltrim(Rtrim(:RENTAL_EXCEPTION_CODE))"
 ,SRVC_DUE_DATE                 "TO_DATE(Ltrim(Rtrim(:SRVC_DUE_DATE)),'MM/DD/RRRR')" 
 ,QUANTITY                      "Ltrim(Rtrim(:QUANTITY))"
 ,ITEM_SUB_CODE                 "Ltrim(Rtrim(:ITEM_SUB_CODE))"
 ,GRATIS_COUNT                  "Ltrim(Rtrim(:GRATIS_COUNT))" 
 ,CUST_EQPMNT_OWNED_STATUS      "Ltrim(Rtrim(:CUST_EQPMNT_OWNED_STATUS))" 
 ,CUST_REMAINING_PMT            "Ltrim(Rtrim(:CUST_REMAINING_PMT))"  
 ,DLVRY_REASON1                 "Ltrim(Rtrim(:DLVRY_REASON1))"
 ,DLVRY_REASON2                 "Ltrim(Rtrim(:DLVRY_REASON2))"
 --,LEGACY_SYSTEM_CODE            CONSTANT 'WTRFLX2'
)