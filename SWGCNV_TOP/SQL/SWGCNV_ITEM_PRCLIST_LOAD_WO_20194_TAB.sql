/* $Header: SWGCNV_ITEM_PRCLIST_LOAD_WO_20194_TAB.sql 1.00 2012/04/19 10:43:00 VP   $ */

/*==========================================================================================================
| Copyright (c) 2006 DS Waters, Atlanta, GA 30328 USA All rights reserved.                                  |
+===========================================================================================================+
|   Name:                    SWGCNV_ITEM_PRCLIST_LOAD                                                       |
|                                                                                                           |
|   File:                    SWGCNV_ITEM_PRCLIST_LOAD_WO_20194_TAB.sql                                      |
|                                                                                                           |
|   Description:             Script to create table definition                                              |
|                                                                                                           |
|   Copyright:               Copyright(c) DS Waters                                                         |
|                                                                                                           |
|   Company:                 DS Waters                                                                      |
|                                                                                                           |
|   Author:                  Vijay Padmanabhan                                                              |
|                                                                                                           |
|   Date:                    04/18/2012                                                                     |
|                                                                                                           |
|   Modification History:                                                                                   |
|                                                                                                           |
|   Date         Author               WO #    Description                                                   |
|   ----         --------------       -----   -----------                                                   |
|   4/18/2012    Vijay Padmanabhan    20194     Creation of new table structure                             |      
===========================================================================================================*/

PROMPT SWGCNV PWD.....

CONNECT SWGCNV/&5;

--DROP TABLE SWGCNV.SWGCNV_ITEM_PRCLIST_LOAD;

CREATE TABLE SWGCNV.SWGCNV_ITEM_PRCLIST_LOAD
(
  ITEM_CODE                  VARCHAR2(20 BYTE),
  PRICE_HEADER               VARCHAR2(200 BYTE),  
  ITEM_PRC                   NUMBER,
  ITEM_STRT_DT               DATE,  
  CONTEXT                    VARCHAR2(100 BYTE),  
  PREFERRED                  VARCHAR2(150 BYTE),  
  CU_ORDER                   VARCHAR2(150 BYTE),  
  CU_LINE                    VARCHAR2(150 BYTE),  
  IVR_PREFERRED              VARCHAR2(150 BYTE),  
  VP_VALUE                   VARCHAR2(150 BYTE),  
  ATTRIBUTE1                 VARCHAR2(150 BYTE),  
  ATTRIBUTE2                 VARCHAR2(150 BYTE),  
  ATTRIBUTE3                 VARCHAR2(150 BYTE),  
  ATTRIBUTE4                 VARCHAR2(150 BYTE),  
  ATTRIBUTE5                 VARCHAR2(150 BYTE),  
  CREATED_BY                 NUMBER,
  CREATION_DATE              DATE,
  LAST_UPDATED_BY            NUMBER,
  LAST_UPDATE_DATE           DATE  
) TABLESPACE APPS_TS_INTERFACE;


GRANT ALTER, DELETE, INDEX, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON SWGCNV.SWGCNV_ITEM_PRCLIST_LOAD TO APPS;

PROMPT APPS PWD.....

CONNECT APPS/&1

DROP SYNONYM APPS.SWGCNV_ITEM_PRCLIST_LOAD;

CREATE SYNONYM APPS.SWGCNV_ITEM_PRCLIST_LOAD FOR SWGCNV.SWGCNV_ITEM_PRCLIST_LOAD;

PROMPT SWGCNV PWD.....

CONNECT SWGCNV/&5;

--DROP TABLE SWGCNV.SWGCNV_PRCLIST_LOAD;

CREATE TABLE SWGCNV.SWGCNV_PRCLIST_LOAD
( PRC_LIST                   VARCHAR2(500),
  CREATED_BY                 NUMBER,
  CREATION_DATE              DATE,
  LAST_UPDATED_BY            NUMBER,
  LAST_UPDATE_DATE           DATE  
) TABLESPACE APPS_TS_INTERFACE;


GRANT ALTER, DELETE, INDEX, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON SWGCNV.SWGCNV_PRCLIST_LOAD TO APPS;

PROMPT APPS PWD.....

CONNECT APPS/&1

DROP SYNONYM APPS.SWGCNV_PRCLIST_LOAD;

CREATE SYNONYM APPS.SWGCNV_PRCLIST_LOAD FOR SWGCNV.SWGCNV_PRCLIST_LOAD;

---------------------------------------------------------------------------------------------------------------------------------------------------
PROMPT SWGCNV PWD.....

CONNECT SWGCNV/&5;

--DROP TABLE SWGCNV.SWGCNV_UOM_CONV_LIST;

CREATE TABLE SWGCNV.SWGCNV_UOM_CONV_LIST
  ( STD_ITEM_NBR    VARCHAR2(50),
    MULTIPLY_FACTOR NUMBER
  );

GRANT ALTER, DELETE, INDEX, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON SWGCNV.SWGCNV_UOM_CONV_LIST TO APPS;

PROMPT APPS PWD.....

CONNECT APPS/&1

DROP SYNONYM APPS.SWGCNV_UOM_CONV_LIST;

CREATE SYNONYM APPS.SWGCNV_UOM_CONV_LIST FOR SWGCNV.SWGCNV_UOM_CONV_LIST;

EXIT;


