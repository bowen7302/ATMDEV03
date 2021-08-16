CREATE OR REPLACE PACKAGE Swgcnv_Dd_Customer_Pub_Pkg AS

/* $Header: SWGCNV_DD_CUSTOMER_PUB_PKS.pls  1.1 2010/04/09 09:33:33 PU $ */
/*==========================================================================================+
| Copyright (c) 2005 DS Waters, Atlanta, GA 30328 USA All rights reserved.                  |
+===========================================================================================+
|  Name:           SWGCNV_DD_CUSTOMER_PUB_PKG                                               |
|  File:           SWGCNV_DD_CUSTOMER_PUB_PKS.pls                                           |
|                                                                                           |
|  Description:    Package For Customer Conversion                                          |
|  Company:        DS Waters                                                                |
|  Author:         Unknown                                                                  |
|  Date:           Unknown                                                                  |
|                                                                                           |
|  Modification History:                                                                    |
|  Date            Author            Description                                            |
|  ----            ------            -----------                                            |
|  Unknown         Unknown           Production Release                                     |
|  04/09/2010      Pankaj Umate      Daptiv # 1471. Conversion Mapping Table Migration      |
+==========================================================================================*/
-- Table Data Type Variable

	TYPE orcl_cust_tab_type		IS	TABLE	OF	swgcnv_dd_customers%ROWTYPE
	INDEX BY BINARY_INTEGER;

-- Customer API variables

	g_party_rec		Hz_Party_V2pub.party_rec_type;
	g_person_rec		Hz_Party_V2pub.person_rec_type;
	g_organization_rec	Hz_Party_V2pub.organization_rec_type;
	g_party_site_rec	Hz_Party_Site_V2pub.party_site_rec_type;
	g_cust_account_rec	Hz_Cust_Account_V2pub.cust_account_rec_type;
	g_cust_acct_site_rec	Hz_Cust_Account_Site_V2pub.cust_acct_site_rec_type;
	g_cust_site_use_rec	Hz_Cust_Account_Site_V2pub.cust_site_use_rec_type;
	g_customer_profile_rec	Hz_Customer_Profile_V2pub.customer_profile_rec_type;
	g_cust_profile_amt_rec	Hz_Customer_Profile_V2pub.cust_profile_amt_rec_type;
	g_location_rec		Hz_Location_V2pub.location_rec_type;
	g_org_contact_rec	Hz_Party_Contact_V2pub.org_contact_rec_type;
	g_cust_acc_role_rec	Hz_Cust_Account_Role_V2pub.cust_account_role_rec_type;
	g_contact_point_rec	Hz_Contact_Point_V2pub.contact_point_rec_type;
	g_edi_rec		Hz_Contact_Point_V2pub.edi_rec_type;
	g_email_rec		Hz_Contact_Point_V2pub.email_rec_type;
	g_phone_rec		Hz_Contact_Point_V2pub.phone_rec_type;
	g_telex_rec		Hz_Contact_Point_V2pub.telex_rec_type;
	g_web_rec		Hz_Contact_Point_V2pub.web_rec_type;
	g_eft_rec		Hz_Contact_Point_V2pub.eft_rec_type;

	g_created_by_module	VARCHAR2(100):= 'SWGCNV CONVERSION API';

	G_MODE_INSERT_S		VARCHAR2(1):='I';
	G_MODE_UPDATE_S		VARCHAR2(1):='U';

    G_SUCCESS_C		    CONSTANT	VARCHAR2(1)	:=	'S';
    G_ERROR_C		    CONSTANT	VARCHAR2(1)	:=	'E';
    G_UNEXP_ERROR_C	    CONSTANT	VARCHAR2(1)	:=	'U';

    g_price_list_id_n   NUMBER;
    g_warehouse_id_n    NUMBER;

    G_SWG_DEBUG			CONSTANT	VARCHAR2(1)	:=	'Y';
    G_SWG_NODEBUG		CONSTANT	VARCHAR2(1)	:=	'N';

    G_SWG_CONCURRENT		CONSTANT	VARCHAR2(1)	:=	'C';
    G_SWG_SQLPLUS		CONSTANT	VARCHAR2(1)	:=	'S';
    G_EXECUTION_MODE				VARCHAR2(1);

	-- Record Type

	TYPE swgcnv_customer_rec_type IS RECORD(
		cust_account_id 		NUMBER,
		party_id 			NUMBER,
		profile_id			NUMBER,
		account_number 			VARCHAR2(30),
		customer_number VARCHAR2(30),   --MTS 431
		party_number 			VARCHAR2(30),
                person_flag                     VARCHAR2(1),
		msg_count			NUMBER,
		return_status			VARCHAR2(2000),
		msg_data			VARCHAR2(2000));


	TYPE swgcnv_address_rec_type IS RECORD(
		location_id 			NUMBER,
		party_site_id 			NUMBER,
		party_site_number		VARCHAR2(30),
		cust_acct_site_id		NUMBER,
		msg_count			NUMBER,
		return_status			VARCHAR2(2000),
		msg_data			VARCHAR2(2000));


	TYPE swgcnv_site_use_rec_type IS RECORD(
		site_use_id 			NUMBER,
		msg_count			NUMBER,
		return_status			VARCHAR2(2000),
		msg_data			VARCHAR2(2000));


	TYPE swgcnv_contact_rec_type IS RECORD(
		insert_update_flag		VARCHAR2(1),
		contact_person_first_name 	VARCHAR2(150),
		contact_person_middle_name 	VARCHAR2(60),
		contact_person_last_name 	VARCHAR2(150),
		contact_person_name_suffix 	VARCHAR2(30),
		contact_person_title 		VARCHAR2(60),
		contact_party_id		NUMBER,
		contact_party_number		VARCHAR2(30),
		contact_party_profile_id	NUMBER,
		account_party_id		NUMBER,
		account_party_type		VARCHAR2(30),
		related_party_id		NUMBER,
		related_party_number		VARCHAR2(30),
		relationship_id			NUMBER,
		org_contact_id			NUMBER,
		cust_acct_site_id		NUMBER,
		contact_id			NUMBER,
		contact_number			VARCHAR2(30),
		cust_account_id			NUMBER,
		status				VARCHAR2(1),
		primary_flag			VARCHAR2(1),
		start_date			DATE,
		end_date			DATE,
		title				VARCHAR2(30),
		job_title 			VARCHAR2(100),
		job_title_code 			VARCHAR2(60),
		orig_system_reference		VARCHAR2(1000),
		attribute_category 		VARCHAR2(30),
		attribute1 			VARCHAR2(150),
		attribute2 			VARCHAR2(150),
		attribute3 			VARCHAR2(150),
		attribute4 			VARCHAR2(150),
		attribute5 			VARCHAR2(150),
		attribute6 			VARCHAR2(150),
		attribute7 			VARCHAR2(150),
		attribute8 			VARCHAR2(150),
		attribute9 			VARCHAR2(150),
		attribute10 			VARCHAR2(150),
		attribute11 			VARCHAR2(150),
		attribute12 			VARCHAR2(150),
		attribute13 			VARCHAR2(150),
		attribute14 			VARCHAR2(150),
		attribute15 			VARCHAR2(150),
		contact_party_object_version	NUMBER,
		related_party_object_version	NUMBER,
		relation_object_version		NUMBER,
		contact_object_version		NUMBER,
		org_contact_object_version	NUMBER,
		return_status			VARCHAR2(2000),
		msg_count			NUMBER,
		msg_data			VARCHAR2(2000));


	TYPE	swgcnv_contact_point_rec_type IS RECORD(
		insert_update_flag		VARCHAR2(1),
		contact_point_id 		NUMBER,
		related_party_id		NUMBER,
		contact_point_type		VARCHAR2(30),
		contact_point_purpose 		VARCHAR2(30),
		status				VARCHAR2(1),
		primary_flag			VARCHAR2(1),
		contact_point_object_version	NUMBER,
		phone_calling_calendar 		VARCHAR2(30),
		last_contact_dt_time 		DATE,
		timezone_id 			NUMBER,
		phone_area_code 		VARCHAR2(10),
		phone_country_code 		VARCHAR2(10),
		phone_number 			VARCHAR2(40),
		phone_extension 		VARCHAR2(20),
		phone_line_type 		VARCHAR2(30),
		raw_phone_number 		VARCHAR2(60),
		edi_transaction_handling 	VARCHAR2(25),
		edi_id_number 			VARCHAR2(30),
		edi_payment_method 		VARCHAR2(30),
		edi_payment_format 		VARCHAR2(30),
		edi_remittance_method 		VARCHAR2(30),
		edi_remittance_instruction	VARCHAR2(30),
		edi_tp_header_id 		NUMBER,
		edi_ece_tp_location_code 	VARCHAR2(40),
		email_format 			VARCHAR2(30),
		email_address 			VARCHAR2(2000),
		telex_number 			VARCHAR2(50),
		web_type 			VARCHAR2(60),
		url 				VARCHAR2(2000),
		eft_transmission_program_id 	NUMBER,
		eft_printing_program_id 	NUMBER,
		eft_user_number 		VARCHAR2(30),
		eft_swift_code 			VARCHAR2(30),
		orig_system_reference 		VARCHAR2(240),
		attribute_category 		VARCHAR2(30),
		attribute1 			VARCHAR2(150),
		attribute2 			VARCHAR2(150),
		attribute3 			VARCHAR2(150),
		attribute4 			VARCHAR2(150),
		attribute5 			VARCHAR2(150),
		attribute6 			VARCHAR2(150),
		attribute7 			VARCHAR2(150),
		attribute8 			VARCHAR2(150),
		attribute9 			VARCHAR2(150),
		attribute10 			VARCHAR2(150),
		attribute11 			VARCHAR2(150),
		attribute12 			VARCHAR2(150),
		attribute13 			VARCHAR2(150),
		attribute14 			VARCHAR2(150),
		attribute15 			VARCHAR2(150),
		return_status			VARCHAR2(2000),
		msg_count			NUMBER,
		msg_data			VARCHAR2(2000));


    TYPE map_rec_type       IS RECORD
        (new_code           swgcnv_map.new_code%TYPE);

    TYPE prfl_cls_rec_type  IS RECORD
        ( profile_class_id     hz_cust_profile_classes.profile_class_id%TYPE
         ,interest_charges     hz_cust_profile_classes.interest_charges%TYPE
	 ,interest_period_days hz_cust_profile_classes.interest_period_days%TYPE);


    TYPE map_tbl_type       IS TABLE OF map_rec_type
    INDEX BY  swgcnv_map.old_code%TYPE;


    TYPE prfl_cls_tbl_type  IS TABLE OF prfl_cls_rec_type
    INDEX BY hz_cust_profile_classes.name%TYPE;


    g_svc_intrst        map_tbl_type;
    g_cust_mrkt         map_tbl_type;

   -- Added by Ashok Krishnamurthy on 06/15/07 for ARS02 conversion (populate Details DFF -- ATTRIBUTE5 -- at Customer Header level) Begin
    g_cust_mrkt_dtls    map_tbl_type;
   -- Added by Ashok Krishnamurthy on 06/15/07 for ARS02 conversion (populate Details DFF -- ATTRIBUTE5 -- at Customer Header level) End

    g_cust_prfl         map_tbl_type;
    g_acct_stts         map_tbl_type;
    g_tax_cls           map_tbl_type;

    g_stmt_cycle_map    map_tbl_type;

	TYPE stmt_rec_type       IS RECORD
    (stmt_cycle_id           ar_statement_cycles.statement_cycle_id%TYPE);
    TYPE stmt_tbl_type       IS TABLE OF stmt_rec_type
    INDEX BY	ar_statement_cycles.name%TYPE;
	g_stmt_cycle_id     stmt_tbl_type;
	g_ddnational_stmt_cycle_id			 NUMBER;
	g_state_sc				VARCHAR2(10);

    g_prfl_cls          prfl_cls_tbl_type;

-- Global Date variable

    g_phone_seq_n		NUMBER		:=	0;
    g_conv_userid_n		NUMBER		:=	-1;

    g_ship_recs_read_n  NUMBER;
    g_bill_recs_read_n  NUMBER;

	g_assoc_price_list_id NUMBER;

-- lOcal variables

--   l_new_code_s		VARCHAR2(100);
--   l_new_sub_code_s	VARCHAR2(100);

--
--   PROCEDURE	swgcnv_dd_Customer_Convert
-- 	(in_sales_center_s		IN	VARCHAR2
-- 	,in_system_name_s		IN	VARCHAR2
-- 	,in_route_num_s			IN 	VARCHAR2
-- 	,in_debug_c				IN	VARCHAR2	DEFAULT	'N'
-- 	,in_validate_only_c		IN	VARCHAR2	DEFAULT 'Y'
--   );

PROCEDURE	Child_Program--Swgcnv_Dd_Customer_Convert
(ou_errbuf_s			OUT	VARCHAR2
,ou_errcode_n			OUT	NUMBER
,in_sales_center_s		IN	VARCHAR2
,in_system_name_s		IN	VARCHAR2
,in_seq_num_n                   IN      NUMBER
--,in_route_num_s		IN 	VARCHAR2
,in_debug_c			IN	VARCHAR2	DEFAULT	'N'
,in_validate_only_c	        IN	VARCHAR2	DEFAULT 'Y'	-- if set to Y then the
													-- program will only commit
													-- the exceptions
);

  PROCEDURE SWGCNV_CONTACT_API(io_contact_rec 		IN OUT SWGCNV_CONTACT_REC_TYPE);

  PROCEDURE SWGCNV_CONTACT_POINT_API(io_contact_point_rec	IN OUT SWGCNV_CONTACT_POINT_REC_TYPE);

PROCEDURE   Master_Program
(ou_errbuf_s			OUT	VARCHAR2
,ou_errcode_n			OUT	NUMBER
,in_sales_center_s              IN      VARCHAR2
,in_system_name_s		IN	VARCHAR2
,in_split_proc_cnt_n            IN      NUMBER
,in_mode_c	                IN      VARCHAR2	DEFAULT		G_SWG_CONCURRENT
,in_debug_flag_c		IN	VARCHAR2	DEFAULT		G_SWG_NODEBUG
,in_validate_only_c             IN      VARCHAR2        DEFAULT         'Y'
);


PROCEDURE   Master_Program_Post
(ou_errbuf_s			OUT	VARCHAR2
,ou_errcode_n			OUT	NUMBER
,in_sales_center_s              IN      VARCHAR2
,in_system_name_s		IN	VARCHAR2
,in_split_proc_cnt_n            IN      NUMBER
,in_mode_c			IN	VARCHAR2	DEFAULT		G_SWG_CONCURRENT
,in_debug_flag_c		IN	VARCHAR2	DEFAULT		G_SWG_NODEBUG
,in_validate_only_c             IN      VARCHAR2        DEFAULT         'Y'
);

--HAD TO DUMP THIS HERE FOR RANAJAYS CONVERSION QUERY -- SOME ADHOC SCRIPT

FUNCTION     Get_List_Price
( in_price_list_id_n		IN		NUMBER
,in_item_id_n			IN		NUMBER
,in_pricing_date_d			IN		DATE		DEFAULT		TRUNC(SYSDATE)
)
RETURN	NUMBER;

FUNCTION     Get_Price
( in_customer_id_n			IN		NUMBER
,in_ship_to_id_n			IN		NUMBER
,in_item_id_n			IN		NUMBER
,in_quantity_n			IN		NUMBER		DEFAULT		0
,in_price_list_id_n		IN		NUMBER		DEFAULT		NULL
,in_pricing_date_d			IN		DATE		DEFAULT		TRUNC(SYSDATE)
)
RETURN	NUMBER;

PROCEDURE   SWGCNV_DD_SHIPTO_CONVERT  --sgb
      (   ou_errbuf_s         OUT   VARCHAR2
         ,ou_errcode_n        OUT   NUMBER
         ,in_sales_center_s   IN    VARCHAR2
         ,in_system_name_s    IN    VARCHAR2
         ,in_debug_c          IN    VARCHAR2 DEFAULT 'N'
         ,in_validate_only_c  IN    VARCHAR2 DEFAULT 'Y' -- if set to Y then the program will only commit the exceptions
      );

END Swgcnv_Dd_Customer_Pub_Pkg;
/
show errors;
EXIT;
