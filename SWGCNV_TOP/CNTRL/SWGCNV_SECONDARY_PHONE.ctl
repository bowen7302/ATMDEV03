LOAD DATA 
--INFILE *                                                                      
INSERT INTO TABLE SWGCNV.SWGCNV_SECONDARY_PHONE
--APPEND
REPLACE
FIELDS TERMINATED BY '|'                                                        
TRAILING NULLCOLS                                                               
(                                                                               
CUSTOMER_NUMBER                  "Ltrim(Rtrim(LPAD(:CUSTOMER_NUMBER, 8, '0')))",
DELIVERY_LOCATION_NUMBER	  "NVL(Ltrim(Rtrim(LPAD(:DELIVERY_LOCATION_NUMBER, 8, '0'))), '1')",
HOME_PHONE                  	 "Ltrim(Rtrim(:HOME_PHONE))",
CELL_PHONE                 	 "Ltrim(Rtrim(:CELL_PHONE))",             
WORK_PHONE               	 "Ltrim(Rtrim(:WORK_PHONE))",
CELL_PHONE2          		 "Ltrim(Rtrim(:CELL_PHONE2))",      
PROCESSED_FLAG                    constant "N",
SALES_CENTER			 "NVL(Ltrim(Rtrim(:SALES_CENTER)),'XXX')",
LEGACY_SYSTEM_CODE                CONSTANT 'WTRFLX2'
)   