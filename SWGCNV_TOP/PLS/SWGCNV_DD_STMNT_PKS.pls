CREATE OR REPLACE PACKAGE	Swgcnv_Dd_Stmnt_Pkg	AS

PROCEDURE Swgcnv_Dd_Stmnt_Cnv
( Ou_errmsg_s      	        OUT   VARCHAR2
 ,Ou_errcode_n     	        OUT   NUMBER
 ,in_system_code		IN    VARCHAR2
 ,in_sales_center		IN    VARCHAR2
 ,in_stmt_date_s                IN    VARCHAR2 
);

PROCEDURE	swg_output(in_outmsg_s	VARCHAR2);

END	Swgcnv_Dd_Stmnt_Pkg;
/
sho err
EXIT;
