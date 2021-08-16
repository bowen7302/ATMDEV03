LOAD DATA
--INFILE *
--APPEND INTO TABLE SWGCNV.SWGCNV_DD_CB_PRESTAGING_CUST
REPLACE INTO TABLE SWGCNV.SWGCNV_DD_CB_PRESTAGING_CUST
FIELDS TERMINATED BY '|' OPTIONALLY ENCLOSED '"'
TRAILING NULLCOLS
(
RECORD_NUM                                               "LTRIM(RTRIM(:RECORD_NUM))",
SALES_CENTER                                             "NVL(LTRIM(RTRIM(:SALES_CENTER)), 'XXX')",
CUSTOMER_NUMBER                                          "LTRIM(RTRIM(LPAD(:CUSTOMER_NUMBER, 8, '0')))",
CUSTOMER_NAME                                            "UPPER(LTRIM(RTRIM(:CUSTOMER_NAME)))",
BILL_TO_ADDRESS1                                         "UPPER(LTRIM(RTRIM(:BILL_TO_ADDRESS1)))",
BILL_TO_ADDRESS2                                         "UPPER(LTRIM(RTRIM(:BILL_TO_ADDRESS2)))",
BILL_TO_CITY                                             "UPPER(LTRIM(RTRIM(:BILL_TO_CITY)))",
BILL_TO_STATE                                            "UPPER(LTRIM(RTRIM(:BILL_TO_STATE)))",
BILL_TO_POSTAL_CODE                                      "LTRIM(RTRIM(:BILL_TO_POSTAL_CODE))",
AR_BALANCE                                               "LTRIM(RTRIM(:AR_BALANCE))",
LAST_PMT_DATE                                            "to_date(LTRIM(RTRIM(:LAST_PMT_DATE)),'MM/DD/RRRR')",
SHIP_TO_ADDRESS1                                         "UPPER(LTRIM(RTRIM(:SHIP_TO_ADDRESS1)))",
SHIP_TO_ADDRESS2                                         "UPPER(LTRIM(RTRIM(:SHIP_TO_ADDRESS2)))",
SHIP_TO_CITY                                             "UPPER(LTRIM(RTRIM(:SHIP_TO_CITY)))",
SHIP_TO_STATE                                            "UPPER(LTRIM(RTRIM(:SHIP_TO_STATE)))",
SHIP_TO_POSTAL_CODE                                      "LTRIM(RTRIM(:SHIP_TO_POSTAL_CODE))",
CUST_START_DATE                                          "NVL(to_date(LTRIM(RTRIM(:CUST_START_DATE)),'MM/DD/RRRR'), TO_DATE(SYSDATE))",
CUST_END_DATE                                            "to_date(LTRIM(RTRIM(:CUST_END_DATE)),'MM/DD/RRRR')",
CUST_END_REASON                                          "LTRIM(RTRIM(:CUST_END_REASON))",
PO_NUMBER                                                "LTRIM(RTRIM(:PO_NUMBER))",
LAST_PMT_AMT                                             "LTRIM(RTRIM(:LAST_PMT_AMT))",
CUSTOMER_TYPE                                            "NVL(UPPER(LTRIM(RTRIM(:CUSTOMER_TYPE))),'~')",
RENT                                                     "LTRIM(RTRIM(:RENT))",
RENT_PERIOD                                              "LTRIM(RTRIM(:RENT_PERIOD))",
EQUIPMENT_COUNT                                          "LTRIM(RTRIM(:EQUIPMENT_COUNT))",
EQUIPMENT_ID                                             "LTRIM(RTRIM(:EQUIPMENT_ID))",
EQUIPMENT_TYPE                                           "UPPER(LTRIM(RTRIM(:EQUIPMENT_TYPE)))",
SALES_TAX                                                "UPPER(LTRIM(RTRIM(:SALES_TAX)))",
CUST_START_REASON                                        "UPPER(LTRIM(RTRIM(:CUST_START_REASON)))",
CREDIT_CLASS                                             "NVL(LTRIM(RTRIM(:CREDIT_CLASS)), 'APPROVED')",
PHONE                                                    "LTRIM(RTRIM(:PHONE))",
ROUTE_NUMBER                                             "LTRIM(RTRIM(:ROUTE_NUMBER))",
ROUTE_DAY                                                "LTRIM(RTRIM(:ROUTE_DAY))",
ROUTE_SEQ                                                "LTRIM(RTRIM(:ROUTE_SEQ))",
DELIVERY_FREQUENCY                                       "LTRIM(RTRIM(:DELIVERY_FREQUENCY))",
PRICE_LIST                                               "LTRIM(RTRIM(:PRICE_LIST))",
STMT_TYPE                                                "LTRIM(RTRIM(:STMT_TYPE))",
BILL_TO_MASTER                                           "LTRIM(RTRIM(LPAD(:BILL_TO_MASTER, 8, '0')))",
MTD_SALES                                                "LTRIM(RTRIM(:MTD_SALES))",
YTD_SALES                                                "LTRIM(RTRIM(:YTD_SALES))",
LATE_FEE                                                 "LTRIM(RTRIM(:LATE_FEE))",
CUSTOMER_STATUS                                          "NVL(LTRIM(RTRIM(:CUSTOMER_STATUS)), 'APPROVED')",
EMAIL_ADDRESS                                            "UPPER(LTRIM(RTRIM(:EMAIL_ADDRESS)))",
WILLCALL_FLAG                                            "LTRIM(RTRIM(:WILLCALL_FLAG))",
CONTACT_FIRST_NAME                                       "LTRIM(RTRIM(:CONTACT_FIRST_NAME))",
CONTACT_LAST_NAME                                        "LTRIM(RTRIM(:CONTACT_LAST_NAME))",
ADDRESSEE                                                "LTRIM(RTRIM(:ADDRESSEE))",
PROCESSED_FLAG                                           CONSTANT 'N',
CREATION_DATE                                            SYSDATE,
CREATED_BY                                               CONSTANT '1053',
LAST_UPDATE_DATE                                         SYSDATE,
LAST_UPDATED_BY                                          CONSTANT '1053',
DIVISION                                                 CONSTANT '3171'
)
