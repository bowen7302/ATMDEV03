/* $Header: SWG_WEB_USER_CONVERSION_TAB.sql 1.00 2012/07/13 10:43:00 VSP   $ */

/*==========================================================================================================
| Copyright (c) 2006 DS Waters, Atlanta, GA 30328 USA All rights reserved.                                  |
+===========================================================================================================+
|   Name:                    SWG_WEB_USER_CONVERSION_TAB                                                    |
|                                                                                                           |
|   File:                    SWG_WEB_USER_CONVERSION_TAB.sql                                                |
|                                                                                                           |
|   Description:             Script to create table definition                                              |
|                                                                                                           |
|   Copyright:               Copyright(c) DS Waters                                                         |
|                                                                                                           |
|   Company:                 DS Waters                                                                      |
|                                                                                                           |
|   Author:                  Bala Palani                                                                    |
|                                                                                                           |
|   Date:                    07/13/2010                                                                     |
|                                                                                                           |
|   Modification History:                                                                                   |
|                                                                                                           |
|   Date         Author               WO #    Description                                                   |
|   ----         --------------       -----   -----------                                                   |
|   12/11/2012   Bala Palani          xxxxx   Creation of new table structure                               |                   
===========================================================================================================*/

PROMPT SWGCNV PWD.....

CONNECT SWGCNV/&2;

CREATE TABLE SWGCNV.SWG_WEB_USER_CONVERSION
               (
                USER_ID                 NUMBER
               ,ORACLE_PARTY_ID         NUMBER
       --        ,ACTIV	                  VARCHAR2(10)
       --        ,CMPNO                   VARCHAR2(10)	
       --        ,PLTNO	                  VARCHAR2(10)
               ,WOUSR	                  VARCHAR2(20)	
               ,WOPWD           	       VARCHAR2(20)	
               ,WOROL           	       VARCHAR2(20)	
               ,R210_CUST_NUMBER	       VARCHAR2(20)	
               ,WOEML           	       VARCHAR2(100)	
       --        ,WOVPC                   VARCHAR2(10)	
       --        ,R210_SERV_UNIT_NUMBER	  VARCHAR2(10)	
               ,WOCPH           		      VARCHAR2(20)
               ,WOFPW           	       VARCHAR2(10)	
               ,WOLDT           	       VARCHAR2(50)	
               ,WOWSF           	       VARCHAR2(10)	
       --        ,WORAC           	       VARCHAR2(10)	
       --        ,WOLRD           		      VARCHAR2(10)
       --        ,WORFR           	       VARCHAR2(10)	
       --        ,WORBD           	       VARCHAR2(10)	
               ,WOMAS           	       VARCHAR2(10)	
               ,WOWE1           	       VARCHAR2(100)	
               ,WOWE2           	       VARCHAR2(100)	
               ,WOGPC           	       VARCHAR2(10)	
               ,WOPDL           	       VARCHAR2(10)
               ,R210_CUST_NU0001	       VARCHAR2(100)	
               ,R210_CUST_NAME	               VARCHAR2(1000)	
               ,R210_DATE_LAST_SALE	       VARCHAR2(100)	
               ) 
               TABLESPACE SWGCNVD NOLOGGING 
               PCTFREE 10  
               PCTUSED 40  
               INITRANS 1  
               MAXTRANS 255        
               NOCACHE;


GRANT ALTER, DELETE, INDEX, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE,DEBUG, FLASHBACK ON SWGCNV.SWG_WEB_USER_CONVERSION TO APPS;

PROMPT APPS PWD.....

CONNECT APPS/&1

CREATE SYNONYM APPS.SWG_WEB_USER_CONVERSION FOR SWGCNV.SWG_WEB_USER_CONVERSION;

EXIT;
