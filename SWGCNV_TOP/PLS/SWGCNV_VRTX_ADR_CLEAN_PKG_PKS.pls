
conn apps/&1
CREATE OR REPLACE PACKAGE SWGCNV_VRTX_ADR_CLEAN_PKG
AS

--
-- File name:  		SWGCNV_VRTX_ADR_CLEAN.sql
-- Modification History:	Kimberly Piper	10/12/2004 Modified for RIMKWS and El Paso conversion
--

    G_SUCCESS_C		CONSTANT	VARCHAR2(1)	:=	'S';
    G_ERROR_C		    	CONSTANT	VARCHAR2(1)	:=	'E';
    G_UNEXP_ERROR_C	    	CONSTANT	VARCHAR2(1)	:=	'U';

    G_SWG_DEBUG		CONSTANT	VARCHAR2(1)	:=	'Y';
    G_SWG_NODEBUG		CONSTANT	VARCHAR2(1)	:=	'N';

    G_SWG_CONCURRENT		CONSTANT	VARCHAR2(1)	:=	'C';
    G_SWG_SQLPLUS		CONSTANT	VARCHAR2(1)	:=	'S';
    G_EXECUTION_MODE				VARCHAR2(1);

PROCEDURE	ADDR_CLNUP
(ou_errbuf_s			OUT	VARCHAR2
,ou_errcode_n			OUT	NUMBER
,in_sales_center 			IN 	VARCHAR2
,in_seq_num_n           		IN  	NUMBER
--,in_mode_c			IN	VARCHAR2	DEFAULT		G_SWG_CONCURRENT
--,in_debug_flag_c			IN	VARCHAR2	DEFAULT		G_SWG_NODEBUG
--,in_validate_only_c     		IN  	VARCHAR2    	DEFAULT     		'Y'
);

PROCEDURE	Master_Program
(ou_errbuf_s			OUT	VARCHAR2
,ou_errcode_n			OUT	NUMBER
,in_sales_center_s      		IN  	VARCHAR2
--,in_system_name_s		IN	VARCHAR2
,in_split_proc_cnt_n    		IN  	NUMBER
--,in_mode_c			IN	VARCHAR2	DEFAULT		G_SWG_CONCURRENT
--,in_debug_flag_c			IN	VARCHAR2	DEFAULT		G_SWG_NODEBUG
--,in_validate_only_c     		IN  	VARCHAR2    	DEFAULT     		'Y'
);

END		SWGCNV_VRTX_ADR_CLEAN_PKG;
/
sho err
EXIT;
