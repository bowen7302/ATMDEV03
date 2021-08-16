/* $Header: Swgcnv_Billto_Credit_Card.pls   1.1 2008/31/10 18:00:00 AM                  $ */
/*======================================================================================+
 | Copyright (c) 2007 DS Waters, Atlanta, GA 30152 USA All rights reserved.             |
+=====================================================================-=================+
 | FILENAME       Swgcnv_Billto_Credit_Card.pls                                         |
 |                                                                                      |
 | DESCRIPTION    UNKNOWN                                                               |
 |                                                                                      |
 | HISTORY                                                                              |
 | unknown            Unknown         Initial version                                   |
 | Ajay              31-OCT-2008      R12 Change(replaced fnd_client_info)              |  
 | Stephen           28-SEP-2015      Tokenizing clear no                               |                  
 |                                                                                      |
+======================================================================================*/
--conn apps/&1
CREATE OR REPLACE PROCEDURE Swgcnv_Billto_Credit_Card
(ou_errbuf_s            OUT VARCHAR2
,ou_errcode_n           OUT NUMBER
,in_sales_center        IN  VARCHAR2   --no longer used
,in_system_code_s       IN  VARCHAR2)
IS

CURSOR cur_creditcard_info
IS
SELECT  cb.customer_number               customer_number
       ,to_char(cb.bill_to_address_id)   billing_location_number -- changed to work with alternate mailing addresses a.billing_location_number
       ,b.customer_id                    customer_id
       ,b.billing_site_id                billing_site_id
       ,b.credit_card_number             card_number
       ,b.credit_card_type               card_type
       ,b.credit_card_exp_date           card_expiry_date
       ,b.credit_card_holder_name        card_holder_name
       ,b.credit_card_holder_address     card_holder_address
       ,b.credit_card_holder_zip_code    card_holder_zip
       ,DECODE(b.recurring_customer,'Y','Y','N') card_include_in_batch
       ,'Y'                              card_include_in_statement
       ,b.card_start_date                card_start_date
       ,b.card_end_date                  card_end_date
       ,b.credit_card_verfication_nmbr   card_cvv2
       ,cb.sales_center                  sales_center
       ,tc.oracle_customer_id            oracle_customer_id
FROM     swgcnv.swgcnv_dd_temp_customers   tc
        ,swgcnv.swgcnv_dd_customer_billto  cb
        ,swgcnv_dd_customer_creditcard     b
WHERE   cb.customer_number        =  tc.legacy_customer_number
AND     b.customer_number         =  cb.customer_number
AND     NVL(b.process_flag,'N')   =  'N'
AND     tc.cust_import_flag       =  'Y'
AND     b.token_status            =  'T'
AND	    b.sales_center		        =  in_sales_center;

CURSOR  cur_bill_to_info ( in_customer_id_n NUMBER
                          ,in_b_ref_s       VARCHAR2
                         )
IS
SELECT site.site_use_id          site_use_id
FROM   hz_cust_site_uses_all     site,
       hz_cust_acct_sites_all        addr
WHERE  addr.cust_account_id        = in_customer_id_n
AND    addr.cust_acct_site_id      = site.cust_acct_site_id
AND    site.site_use_code          = 'BILL_TO'
AND    addr.orig_system_reference  = in_b_ref_s
AND    site.org_id                 = 2
AND    addr.org_id                 = 2;


l_b_ref_s             VARCHAR2(100);
l_cust_ref            VARCHAR2(100);
l_error_msg           VARCHAR2(2000);

l_customer_id         NUMBER;
l_billto_addr_id      NUMBER;
l_credit_card_id      NUMBER;
l_rec_ins_n           NUMBER;
l_rec_err_n           NUMBER  :=  0;
l_rec_read            NUMBER  :=  0;
l_rec_upd             NUMBER;

ERROR_ENCOUNTERED     EXCEPTION;

l_trx_id              NUMBER;
l_card_id             NUMBER;
l_card_error_message  VARCHAR2(2000);
l_token_s             VARCHAR2(30);

BEGIN

    ou_errbuf_s     :=  NULL;
    ou_errcode_n    :=  0;

  --fnd_client_info.set_org_context(2);

  l_rec_err_n :=  0;
  
  FOR j IN  ( SELECT rowid ccid, credit_card_number FROM swgcnv_dd_customer_creditcard a WHERE token_status = 'N' AND	 a.sales_center	=  in_sales_center ) LOOP
  
    l_token_s  :=  SWG_TOKENEX_PKG.Secure_Credit_Card  ( j.credit_card_number );
  
    UPDATE swgcnv_dd_customer_creditcard
    SET    credit_card_number = l_token_s, token_status = 'T'
    WHERE  ROWID  = j.ccid;
  
  END LOOP;
  
  COMMIT;

  FOR creditcard_info_rec IN cur_creditcard_info
  LOOP

  BEGIN

    l_rec_read  :=  NVL(l_rec_read,0) + 1;


          l_b_ref_s :=  'DD'        ||  '-'  ||
                        in_system_code_s                 ||  '-' ||
                        creditcard_info_rec.sales_center         ||  '-' ||
                        LTRIM(RTRIM(creditcard_info_rec.customer_number))||  '-' ||
                        LTRIM(RTRIM(creditcard_info_rec.billing_location_number)) ||'-HEADER';

    -- Get the billto address id

    OPEN  cur_bill_to_info(creditcard_info_rec.oracle_customer_id,l_b_ref_s);
    FETCH cur_bill_to_info INTO l_billto_addr_id;
    IF cur_bill_to_info%NOTFOUND THEN

      l_billto_addr_id := NULL;
      l_rec_err_n :=  NVL(l_rec_err_n,0) + 1;

    END IF;
    CLOSE cur_bill_to_info;

    IF l_billto_addr_id IS NULL THEN

      l_error_msg :=  'Billto Address id not found for '||l_b_ref_s;
      RAISE ERROR_ENCOUNTERED;

    END IF;

    -- Call the credit card API to insert the credit card info

    l_card_error_message  :=  NULL;
    l_trx_id    :=  NULL;
    l_card_id   :=  NULL;

    BEGIN

      swg_cc_pkg.swg_cc_insert_request
              (in_custid_n        => creditcard_info_rec.oracle_customer_id
              ,in_siteid_n        => l_billto_addr_id
              ,in_cardtype_s      => creditcard_info_rec.card_type
              ,in_cardnum_s       => creditcard_info_rec.card_number
              ,in_cc_ref_num_s    => creditcard_info_rec.card_number   --Tokenex
              ,in_expdate_s       => creditcard_info_rec.card_expiry_date
              ,in_cvv2_s          => NULL
              ,in_name_s          => creditcard_info_rec.card_holder_name
              ,in_address_s       => creditcard_info_rec.card_holder_address
              ,in_zip_s           => creditcard_info_rec.card_holder_zip
              ,in_recurring_s     => creditcard_info_rec.card_include_in_batch
              ,in_stmt_s          => creditcard_info_rec.card_include_in_statement
              ,in_start_d         => creditcard_info_rec.card_start_date
              ,in_end_d           => creditcard_info_rec.card_end_date
              ,in_trxn_b          => FALSE
              ,in_approve_b       => NULL
              ,in_mode_s          => NULL
              ,in_action_s        => NULL
              ,in_reqamount_n     => NULL
              ,io_trxnid_n        => l_trx_id
              ,io_cardid_n        => l_card_id
              ,out_mesg_s         => l_card_error_message);

    EXCEPTION

      WHEN OTHERS THEN

      l_rec_err_n :=  NVL(l_rec_err_n,0) + 1;
      l_error_msg :=  'Calling credit card API'||SQLERRM;
      RAISE ERROR_ENCOUNTERED;

    END;


    IF l_card_error_message IS NOT NULL THEN

      l_rec_err_n :=  NVL(l_rec_err_n,0) + 1;
      l_error_msg :=  l_card_error_message;
      RAISE ERROR_ENCOUNTERED;

    ELSE

      l_rec_ins_n :=  NVL(l_rec_ins_n,0) + 1;

      -- Update the process flag

      UPDATE  swgcnv_dd_customer_creditcard
      SET     process_flag  =   'Y'
      WHERE   customer_id   = creditcard_info_rec.customer_id
      AND billing_site_id   = creditcard_info_rec.billing_site_id;

      IF SQL%ROWCOUNT != 0 THEN

        l_rec_upd :=  NVL(l_rec_upd,0)  + 1;

      END IF;

      COMMIT;


    END IF;


  EXCEPTION

    WHEN ERROR_ENCOUNTERED  THEN
            ou_errbuf_s         := l_error_msg;
            ou_errcode_n        := 1;
        ROLLBACK;

        INSERT INTO swgcnv_conversion_exceptions
      (
        CONVERSION_TYPE
        ,CONVERSION_KEY_VALUE
        ,ERROR_MESSAGE
        ,CONVERSION_SUB_KEY1
        ,CONVERSION_SUB_KEY2
      )
        VALUES
      (
      'CUSTOMER CARD'
      , creditcard_info_rec.customer_number
      , l_error_msg
      , creditcard_info_rec.billing_location_number
      , creditcard_info_rec.sales_center
      );
        COMMIT;

  END;

  END LOOP;

  Fnd_File.Put_Line ( Fnd_File.OUTPUT,'Total Records Read         '||l_rec_read);
  Fnd_File.Put_Line ( Fnd_File.OUTPUT,'Total Records Inserted     '||l_rec_ins_n);
  Fnd_File.Put_Line ( Fnd_File.OUTPUT,'Total Records Updated      '||l_rec_upd);
  Fnd_File.Put_Line ( Fnd_File.OUTPUT,'Total Error Records        '||l_rec_err_n);


END Swgcnv_Billto_Credit_Card;
/
sho err
EXIT;
