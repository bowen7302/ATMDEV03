/* $Header: SWG_PRICELIST_CONVERSION.sql 1.0       2012/04/02           02:55:54 BP $ */
/*==============================================================================+
| Copyright (c) 2006 DS Waters, Atlanta, GA 30328 USA All rights reserved.      |
+===============================================================================+
|   Name:                    SWG_PRICELIST_CONVERSION.sql                       |
|   File:                    SWG_PRICELIST_CONVERSION.sql                       |
|   Description:             Script to Create SWG_PRICELIST_CONVERSION Table    |
|                            Definition.                                        |
|                                                                               |
|   Copyright:               Copyright(c) DS Waters                             |
|   Company:                 DS Waters                                          |
|                                                                               |
|   Author:                  Stephen Bowen                                      |
|   Date:                    04/02/2012                                         |
|   Modification History:                                                       |
|   Date        Author              WO #    Description                         |
|   ----        --------------      -----   -----------                         |
|   04/02/2012  Stephen Bowen       20129   Initial Creation                    |
+==============================================================================*/

SET LINESIZE 150
SET SERVEROUTPUT ON SIZE 1000000

PROMPT SWGCNV PWD.....

CONNECT SWGCNV/&5;

DROP TABLE SWGCNV.SWG_PRICELIST_CONVERSION;

CREATE TABLE SWGCNV.SWG_PRICELIST_CONVERSION
                           (
                            ITEM_CODE          VARCHAR2(50)   NOT NULL,
                            PRICE_LIST_NAME    VARCHAR2(100)  NOT NULL,
                            ITEM_PRICE         NUMBER         NOT NULL,
                            START_DATE         DATE           NOT NULL,
                            PREFERRED          VARCHAR2(50),                                    
                            CU_ORDER           VARCHAR2(50),                                   
                            CU_LINE            VARCHAR2(50),                                  
                            IVR_PREFERRED      VARCHAR2(50),                                 
                            VP_VALUE           VARCHAR2(50),                                
                            REQUEST_ID         NUMBER                                    
                           );  
     
GRANT ALL ON SWGCNV.SWG_PRICELIST_CONVERSION TO APPS;

PROMPT CONNECTING APPS...

CONNECT APPS/&1;

DROP SYNONYM SWG_PRICELIST_CONVERSION;

CREATE SYNONYM SWG_PRICELIST_CONVERSION FOR SWGCNV.SWG_PRICELIST_CONVERSION;

EXIT;



