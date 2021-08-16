PROMPT CONNECTING APPS..
CONNECT APPS/&1
CREATE OR REPLACE PROCEDURE Swgcnv_Cust_Agree_Conv
   (   ou_errbuf_s            OUT      VARCHAR2
      ,ou_retcode_n           OUT      NUMBER
      ,in_sales_center_s      IN       VARCHAR2
      ,in_debug_c             IN       VARCHAR2    DEFAULT  'N'
      ,in_validate_only_c     IN       VARCHAR2    DEFAULT  'Y'
   )
   
/* $Header: SWGCNV_CUST_AGREE_CONV.pls 1.0 2009/12/11 09:33:33 DevInt $ */
/*==================================================================================+
| Copyright (c) 2005 DS Waters, Atlanta, GA 30328 USA All rights reserved.          |
+===================================================================================+
| Name:           Swgcnv_Cust_Agree_Conv.pls                                        |
| File:           Swgcnv_Cust_Agree_Conv.pls                                        |
| Description:    Procedure For Creating Customer Agreement During Acquisitions     |
|                                                                                   |
| Company:        DS Waters                                                         |
| Author:         Muthu Ramanathan                                                  |
| Date:           12/21/2005                                                        |
|                                                                                   |
| Modification History:                                                             |
| Date            Author            Description                                     |
| ----            ------            -----------                                     |
| 12/21/2005      Muthu Ramanathan  Initial Version Created From OPS6 Script.       |
| 12/11/2009      Pankaj Umate      Changes For SAGE Acquisition # 1299             |
| 04/11/2012      Stephen Bowen     Use Sales Center Parm in cursor  WO 20129       |
+==================================================================================*/
IS

   CURSOR cur_agreement
   IS
   SELECT cth.term_code	term_code
         ,cth.agreement_term_id							agreement_term_id
		,MAX(DECODE(ctd.attribute_code,	'FINANCE_CHARGE_TYPE',	ctd.attribute_value, NULL))	finance_charge_type
		,MAX(DECODE(ctd.attribute_code,	'FINANCE_CHARGE_AMT',	ctd.attribute_value, NULL))	finance_charge_amt
		,MAX(DECODE(ctd.attribute_code,	'TERM_FEE_WAIVER_DAYS', ctd.attribute_value, NULL)) term_fee_waiver_days
    FROM	swgdd.swg_cust_agreement_terms		cth,
		swgdd.swg_cust_agreement_term_dtls	ctd
    WHERE ctd.agreement_term_id		=	cth.agreement_term_id
    GROUP BY cth.term_code
	    ,cth.agreement_term_id;


    CURSOR	cur_cust    (in_sales_center_s  VARCHAR2)
    IS
    SELECT	cust.account_number		account_number
		,cust.cust_account_id		cust_account_id
		,cust.status			status
		,t.legacy_customer_number legacy_customer_number
	        ,i.account_deposit  		account_deposit
    FROM	ar.hz_cust_accounts		cust
		,swgcnv.swgcnv_dd_customer_interface	i
        	,swgcnv.swgcnv_dd_temp_customers	t
    WHERE      i.customer_number	= t.legacy_customer_number
    AND        cust.cust_account_id	= t.oracle_customer_id
    AND        i.sales_center           = in_sales_center_s    --Use Sales Center Parm in cursor SGB WO 20129
    AND NOT EXISTS
        (SELECT     1
         FROM   swgdd.swg_cust_agreements a
         WHERE  a.cust_account_id   = cust.cust_account_id);

	-- 2005/12/21 (Kim): old logic commented
	/*
    CURSOR	cur_shipto    (in_sales_center_s  VARCHAR2
			       ,in_customer_number   VARCHAR2)
    IS
    SELECT customer_number
	   ,shipto_site_id
	   ,ship_to_start_date
	   ,agreement_term
	   ,term_fee_amount
    FROM   swgcnv_dd_customer_shipto s
    WHERE  customer_number = in_customer_number
      AND  sales_center = in_sales_center_s
    GROUP BY customer_number
	     ,shipto_site_id
	     ,ship_to_start_date
	     ,agreement_term
	     ,term_fee_amount
    ORDER BY customer_number
	     ,ship_to_start_date
	     ,DECODE(agreement_term,'GFAGR',1,'PERIOD TO PERIOD',2,'1 YEAR AGREEMENT',3,'3 YEAR AGREEMENT',4)
	     ,term_fee_amount;
	*/

	-- 2005/12/21 (Kim, Jabel): obtain agreement of highest precedence, lowest
	--                          termination fee and oldest date according to
	--                          OPS11, issue 53
	CURSOR cur_shipto (in_customer_number VARCHAR2) IS -- remove sales center - a customer sales center can differ from a ship to sales center
	SELECT customer_number,
	       min_ship_to_start_date ship_to_start_date,
	       agreement_term,
	       min_term_fee_amount    term_fee_amount
	FROM (
		SELECT customer_number,
		       shipto_site_id,
		       ship_to_start_date,
		       min(ship_to_start_date) OVER (PARTITION BY customer_number) min_ship_to_start_date,
		       agreement_term,
		       decode(agreement_term,
		              'GFAGR', 1,
		              'PERIOD TO PERIOD', 2,
		              '1 YEAR AGREEMENT', 3,
		              '3 YEAR AGREEMENT', 4) agree_term,
		       term_fee_amount,
		       min(decode(agreement_term,
		                  'GFAGR', 1,
		                  'PERIOD TO PERIOD', 2,
		                  '1 YEAR AGREEMENT', 3,
		                  '3 YEAR AGREEMENT', 4)) OVER (PARTITION BY customer_number) min_agree_term,  -- shows precedence for agreement terms
		       min(term_fee_amount) OVER (PARTITION BY customer_number) min_term_fee_amount
		FROM swgcnv_dd_customer_shipto s
		WHERE customer_number = in_customer_number
		GROUP BY customer_number,
		         shipto_site_id,
		         ship_to_start_date,
		         agreement_term,
		         decode(agreement_term,
		              'GFAGR', 1,
		              'PERIOD TO PERIOD', 2,
		              '1 YEAR AGREEMENT', 3,
		              '3 YEAR AGREEMENT', 4),
		         term_fee_amount
		ORDER BY customer_number,
		         ship_to_start_date,
		         decode(agreement_term,
		              'GFAGR', 1,
		              'PERIOD TO PERIOD', 2,
		              '1 YEAR AGREEMENT', 3,
		              '3 YEAR AGREEMENT', 4),
		         term_fee_amount
	)
	WHERE agree_term = min_agree_term
	GROUP BY customer_number,
	         min_ship_to_start_date,
	         agreement_term,
	         min_term_fee_amount;

    TYPE	agreement_rec_type	IS	RECORD
	( agreement_term_id	NUMBER
	 ,finance_charge_type	VARCHAR2(10)
	 ,finance_charge_amt	NUMBER
	 ,term_fee_waiver_days	NUMBER
	);

    TYPE agreement_tbl_type IS TABLE OF agreement_rec_type
    INDEX BY swgdd.swg_cust_agreement_terms.term_code%TYPE;

    g_agreement_tbl_type		agreement_tbl_type;

    l_agreement_term			swgdd.swg_cust_agreement_terms.term_code%TYPE;

    l_start_time_d			DATE;
    l_end_time_d			DATE;
    l_cust_recs_read_n			NUMBER := 0;
    l_agreements_created_n		NUMBER := 0;
    l_error_cnt_n			NUMBER := 0;
	l_err_msg			    VARCHAR2(100);

BEGIN
    l_start_time_d := SYSDATE;
    FOR cur_agreement_rec IN cur_agreement
    LOOP
	g_agreement_tbl_type(cur_agreement_rec.term_code).agreement_term_id := cur_agreement_rec.agreement_term_id;
	g_agreement_tbl_type(cur_agreement_rec.term_code).finance_charge_type := cur_agreement_rec.finance_charge_type;
	g_agreement_tbl_type(cur_agreement_rec.term_code).finance_charge_amt := cur_agreement_rec.finance_charge_amt;
	g_agreement_tbl_type(cur_agreement_rec.term_code).term_fee_waiver_days := cur_agreement_rec.term_fee_waiver_days;
	fnd_file.put_line(fnd_file.LOG, 'Term Code: '||cur_agreement_rec.term_code);
	fnd_file.put_line(fnd_file.LOG, 'Term Id: '||g_agreement_tbl_type(cur_agreement_rec.term_code).agreement_term_id);
	fnd_file.put_line(fnd_file.LOG, 'Finance Charge Type: '||g_agreement_tbl_type(cur_agreement_rec.term_code).finance_charge_type);
	fnd_file.put_line(fnd_file.LOG, 'Finance Charge Amt: '||g_agreement_tbl_type(cur_agreement_rec.term_code).finance_charge_amt);
	fnd_file.put_line(fnd_file.LOG, 'Term Fee Waiver Days: '||g_agreement_tbl_type(cur_agreement_rec.term_code).term_fee_waiver_days);
    END LOOP;

    FOR cur_cust_rec IN cur_cust(in_sales_center_s)
    LOOP
	    l_cust_recs_read_n := l_cust_recs_read_n + 1;
	    -- 2005/12/21 (Jabel): removed sales center parameter
	    FOR cur_shipto_rec IN cur_shipto(cur_cust_rec.legacy_customer_number)
	    -- FOR cur_shipto_rec IN cur_shipto( in_sales_center_s, cur_cust_rec.legacy_customer_number)
            LOOP
			BEGIN
         -- Commented For SAGE  Acquisition
         /*
			IF (cur_shipto_rec.ship_to_start_date < TO_DATE('21-JUN-2004','DD-MON-YYYY') )
			   AND (cur_shipto_rec.agreement_term = 'GFAGR')
			   AND (cur_shipto_rec.term_fee_amount <> 0 ) THEN
			      l_agreement_term := 'PERIOD TO PERIOD';
			ELSE
			      l_agreement_term := cur_shipto_rec.agreement_term;
			END IF;

			IF (cur_shipto_rec.ship_to_start_date < TO_DATE('21-JUN-2004','DD-MON-YYYY') ) THEN
			   l_agreement_term := 'GFAGR';
			END IF;
         */
         -- Commented For SAGE Acquisition

         l_agreement_term  :=    NVL(cur_shipto_rec.agreement_term,'GFAGR');
         
			UPDATE swgcnv.swgcnv_dd_customer_billto
			   SET agreement_term = l_agreement_term
			       ,term_fee_amount = cur_shipto_rec.term_fee_amount
			 WHERE customer_number = cur_shipto_rec.customer_number;

			INSERT INTO swgdd.swg_cust_agreements
			(cust_agreement_id
			,document_number
			,cust_account_id
			,agreement_status
			,start_date_active
			,end_date_active
			,contract_end_date
			,agreement_term_id
			,finance_charge_type
			,finance_charge_amt
			,termination_fee
			,deposit_item_id
			,deposit_amount
			,term_fee_waiver_days
			,first_thr_id
			,first_rte_id
			,first_ticket_number
			,first_route_number
			,first_delivery_day_date
			,created_by
			,creation_date
			,last_updated_by
			,last_update_date
			,last_update_login)
			VALUES
			(swgdd.swg_cust_agreements_s1.NEXTVAL
			,NULL
			,cur_cust_rec.cust_account_id
			,DECODE(cur_cust_rec.status,'A','ACTIVE','INACTIVE')
			,cur_shipto_rec.ship_to_start_date
			,NULL
			,DECODE(l_agreement_term, '1 YEAR AGREEMENT', ADD_MONTHS(cur_shipto_rec.ship_to_start_date, 12)
							, '3 YEAR AGREEMENT', ADD_MONTHS(cur_shipto_rec.ship_to_start_date, 36)
							, NULL)
			,g_agreement_tbl_type(l_agreement_term).agreement_term_id
			,g_agreement_tbl_type(l_agreement_term).finance_charge_type
			,g_agreement_tbl_type(l_agreement_term).finance_charge_amt
			,cur_shipto_rec.term_fee_amount
			,NULL
			,cur_cust_rec.account_deposit
			,g_agreement_tbl_type(l_agreement_term).term_fee_waiver_days
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NVL(fnd_global.user_id, -1)
			,SYSDATE
			,NVL(fnd_global.user_id, -1)
			,SYSDATE
			,NVL(fnd_global.login_id, -1));
			IF in_validate_only_c = 'N' THEN
			   COMMIT;
			ELSE
			   ROLLBACK;
			END IF;
			l_agreements_created_n := l_agreements_created_n + 1;
			EXCEPTION
			WHEN OTHERS THEN
			    l_err_msg := SUBSTR(SQLERRM,1,100);
			    ROLLBACK;
			    INSERT
			    INTO swgcnv.swgcnv_conversion_exceptions
				( conversion_type
				 ,conversion_key_value
				 ,error_message
				 ,conversion_sub_key1
				 ,conversion_sub_key2
				 ,creation_date
				)
			     VALUES ( 'CUSTOMER_AGREEMENT'
				 , cur_shipto_rec.customer_number
				 , 'Error during agreement insertion' || l_err_msg
				 , NULL
				 , NULL
				 , SYSDATE
				);
			    COMMIT;
			    l_error_cnt_n := l_error_cnt_n + 1;
			END;
			EXIT;
	    END LOOP;
    END LOOP;
	l_end_time_d := SYSDATE;
    Fnd_File.Put_Line(Fnd_File.OUTPUT,'*************************  RUN STATISTICS *******************************');
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Customer Records Read           : ' || l_cust_recs_read_n);
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Agreements Created              : ' || l_agreements_created_n);
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of Errorred Records                : ' || l_error_cnt_n);
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' ------------------------------------------------------------------------');
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' Start Time : ' || TO_CHAR(l_start_time_d, 'MM/DD/RRRR HH24:MI:SS'));
    Fnd_File.Put_Line(Fnd_File.OUTPUT,' End Time   : ' || TO_CHAR(l_end_time_d, 'MM/DD/RRRR HH24:MI:SS'));
    Fnd_File.Put_Line(Fnd_File.OUTPUT,'*************************************************************************');

END;
/
sho err
EXIT;
