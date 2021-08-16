LOAD DATA
--INFILE *
INSERT INTO TABLE swgcnv.swgcnv_dd_avrg_order 
--APPEND FIELDS TERMINATED BY '|' OPTIONALLY ENCLOSED BY '"' 
 REPLACE FIELDS TERMINATED BY '|' OPTIONALLY ENCLOSED BY '"' 
TRAILING NULLCOLS
(
  CUSTOMER_NUMBER               "Ltrim(Rtrim(LPAD(:CUSTOMER_NUMBER, 8, '0')))"
 ,DELIVERY_LOCATION_NUMBER      "nvl(Ltrim(Rtrim(LPAD(:DELIVERY_LOCATION_NUMBER, 8, '0'))),1)"
 ,ITEM_CODE                     "RTRIM(LTRIM(:ITEM_CODE, '0'))"
 ,SALES_CENTER                  "NVL(Ltrim(Rtrim(:SALES_CENTER)),'XXX')"
 ,DIVISION                      "NVL(Ltrim(Rtrim(:DIVISION)), '3171')"
 ,AVERAGE_QTY                   "NVL(Ltrim(Rtrim(:AVERAGE_QTY)),1)"
 ,VALID_FLAG                    CONSTANT 'N'
 --,LEGACY_SYSTEM_CODE            CONSTANT 'WTRFLX2' 
)