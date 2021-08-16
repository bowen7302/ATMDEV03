LOAD DATA                                                                       
REPLACE INTO TABLE SWGCNV_DD_CUSTOMER_CREDITCARD
FIELDS TERMINATED BY '|'                                                        
TRAILING NULLCOLS                                                               
(                                                                              
BILLING_SITE_ID                  "TO_NUMBER(Ltrim(Rtrim(:BILLING_SITE_ID)))",               
CUSTOMER_ID                      "TO_NUMBER(Ltrim(Rtrim(:CUSTOMER_ID)))",                  
CUSTOMER_NUMBER                  "TO_NUMBER(Ltrim(Rtrim(:CUSTOMER_NUMBER)))",             
CREDIT_CARD_TYPE                 "UPPER(Ltrim(Rtrim(:CREDIT_CARD_TYPE)))",             
CREDIT_CARD_NUMBER               "Ltrim(Rtrim(:CREDIT_CARD_NUMBER))",           
CREDIT_CARD_EXP_DATE             "NVL(Ltrim(Rtrim(LPAD(:CREDIT_CARD_EXP_DATE, 4, '0'))),'0000')",         
CREDIT_CARD_HOLDER_NAME          "Ltrim(Rtrim(:CREDIT_CARD_HOLDER_NAME))",      
CREDIT_CARD_HOLDER_ADDRESS       "Ltrim(Rtrim(:CREDIT_CARD_HOLDER_ADDRESS))",   
CREDIT_CARD_HOLDER_ZIP_CODE      "NVL(Ltrim(Rtrim(:CREDIT_CARD_HOLDER_ZIP_CODE)),'00000')",
CREDIT_CARD_VERFICATION_NMBR     "Ltrim(Rtrim(:CREDIT_CARD_VERFICATION_NMBR))",
RECURRING_CUSTOMER               "Ltrim(Rtrim(:RECURRING_CUSTOMER))",           
CARD_START_DATE		         "NVL(TO_DATE(Ltrim(Rtrim(:CARD_START_DATE)),'MM/DD/RRRR'), TO_DATE(SYSDATE))",
CARD_END_DATE		         "TO_DATE(Ltrim(Rtrim(:CARD_END_DATE)),'MM/DD/RRRR')",
SALES_CENTER                      "UPPER(Ltrim(Rtrim(:SALES_CENTER)))", 
DIVISION                          "UPPER(Ltrim(Rtrim(:DIVISION)))", 
PROCESS_FLAG			  CONSTANT "N",
TOKEN_STATUS			  CONSTANT "N"
)                                                                               
