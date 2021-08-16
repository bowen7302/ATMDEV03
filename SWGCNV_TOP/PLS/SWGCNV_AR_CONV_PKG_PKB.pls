/* Formatted on 2005/11/09 09:55 (Formatter Plus v4.8.6) */
CREATE OR REPLACE PACKAGE BODY swgcnv_ar_conv_pkg
IS
   FUNCTION swgcnv_shipto_address_id (
      p_legacy_system      IN   VARCHAR2
     ,p_sales_center       IN   VARCHAR2
     ,p_customer_ref       IN   VARCHAR2
     ,p_ship_address_ref   IN   VARCHAR2
     ,p_cust_account_id    IN   NUMBER
   )
      RETURN NUMBER
   IS
      CURSOR cur_ship_address (l_ship_address_ref VARCHAR2)
      IS
         SELECT hzcas.cust_acct_site_id
           FROM hz_cust_site_uses hzcsu, hz_cust_acct_sites hzcas
          WHERE hzcas.cust_acct_site_id = hzcsu.cust_acct_site_id
            AND hzcsu.site_use_code = 'SHIP_TO'
            AND hzcas.cust_account_id = p_cust_account_id
            AND hzcas.orig_system_reference = l_ship_address_ref;

      CURSOR cur_alt_ship_address
      IS
         SELECT hzcas.cust_acct_site_id
           FROM hz_cust_site_uses hzcsu, hz_cust_acct_sites hzcas
          WHERE hzcas.cust_acct_site_id = hzcsu.cust_acct_site_id
            AND hzcsu.site_use_code = 'SHIP_TO'
            AND hzcas.cust_account_id = p_cust_account_id
            AND ROWNUM = 1;

      l_shipto_address_ref   VARCHAR2 (200) := NULL;
      l_shipto_address_id    NUMBER         := NULL;
      l_shipto_number        VARCHAR2 (20)  := NULL;
   BEGIN
      fnd_client_info.set_org_context (2);
      l_shipto_address_ref := NULL;
      l_shipto_address_id := NULL;
      l_shipto_number := NULL;

      IF SUBSTR (p_ship_address_ref, 1, 1) = '0'
      THEN
         IF SUBSTR (p_ship_address_ref, 1, 2) = '00'
         THEN
            l_shipto_number := SUBSTR (p_ship_address_ref, 3);
         ELSE
            l_shipto_number := SUBSTR (p_ship_address_ref, 2);
         END IF;
      ELSE
         l_shipto_number := p_ship_address_ref;
      END IF;

      l_shipto_address_ref := 'DD'		   	  	   		  	   						||'-'||
	 					     p_legacy_system	 									||'-'||
						     p_sales_center	  										||'-'||
						     p_customer_ref	  										||'-'||
					   	     l_shipto_number										||'-'||
						     'HEADER'												;

      FOR i IN cur_ship_address (l_shipto_address_ref)
      LOOP
         l_shipto_address_id := i.cust_acct_site_id;
      END LOOP;

      IF l_shipto_address_id IS NULL
      THEN
         FOR j IN cur_alt_ship_address
         LOOP
            l_shipto_address_id := j.cust_acct_site_id;
         END LOOP;
      END IF;

      RETURN l_shipto_address_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         DBMS_OUTPUT.put_line ('No Data found : ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG
                           , 'No Data found for shipto : ' || SQLERRM
                           );
         RETURN NULL;
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('eRROR         : ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG
                           , 'eRROR while retreving shipto : ' || SQLERRM
                           );
         RETURN NULL;
   END swgcnv_shipto_address_id;

----
   FUNCTION swgcnv_newitem_code (
      p_sales_center    VARCHAR2
     ,p_old_item_code   VARCHAR2
   )
      RETURN VARCHAR2
   IS
      CURSOR cur_new_code1
      IS
         SELECT new_code
           FROM swg_map
          WHERE type_code = 'ITEM'
            AND old_sub_code_1 = p_sales_center
            AND old_code = p_old_item_code
            AND old_sub_code = '00069091'
            AND system_code = 'SACS';

      CURSOR cur_new_code2
      IS
         SELECT new_code
           FROM swg_map
          WHERE type_code = 'ITEM'
            AND old_code = p_old_item_code
            AND old_sub_code = '00069091'
            AND system_code = 'SACS'
            AND old_sub_code_1 IS NULL;

      l_new_item_code   VARCHAR2 (20) := NULL;
   BEGIN
      FOR i IN cur_new_code1
      LOOP
         l_new_item_code := i.new_code;
      END LOOP;

      IF l_new_item_code IS NULL
      THEN
         FOR j IN cur_new_code2
         LOOP
            l_new_item_code := j.new_code;
         END LOOP;
      END IF;

      RETURN l_new_item_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         DBMS_OUTPUT.put_line ('No Data found : ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, 'No Data found : ' || SQLERRM);
         RETURN NULL;
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('eRROR         : ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG, 'eRROR         : ' || SQLERRM);
         RETURN NULL;
   END swgcnv_newitem_code;

----
   FUNCTION swgcnv_salesrep (p_legacy_system VARCHAR2, p_old_code VARCHAR2)
      RETURN NUMBER
   IS
      CURSOR cur_new_code
      IS
         SELECT new_code
           FROM swg_map
          WHERE system_code = p_legacy_system
            AND type_code = 'SALESREP'
            AND old_code = p_old_code;

      CURSOR cur_salesrep (l_new_code VARCHAR2)
      IS
         SELECT salesrep_id
           FROM jtf_rs_salesreps
          WHERE salesrep_number = l_new_code;

      l_new_salesrep   VARCHAR2 (20) := NULL;
      l_salesrep_id    NUMBER        := NULL;
   BEGIN
      fnd_client_info.set_org_context (2);

      FOR i IN cur_new_code
      LOOP
         FOR j IN cur_salesrep (i.new_code)
         LOOP
            l_salesrep_id := j.salesrep_id;
         END LOOP;
      END LOOP;

      RETURN NVL (l_salesrep_id, 100000670);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN 100000670;
      WHEN OTHERS
      THEN
         RETURN 100000670;
   END swgcnv_salesrep;

----
   FUNCTION swgcnv_billto_address_id (
      p_legacy_system      VARCHAR2
     ,p_sales_center       VARCHAR2
     ,p_customer_ref       VARCHAR2
     ,p_bill_address_ref   VARCHAR2
     ,p_cust_account_id    NUMBER
   )
      RETURN NUMBER
   IS
      CURSOR cur_billto_address (l_bill_address_ref VARCHAR2)
      IS
         SELECT hzcas.cust_acct_site_id
           FROM hz_cust_site_uses hzcsu, hz_cust_acct_sites hzcas
          WHERE hzcas.cust_acct_site_id = hzcsu.cust_acct_site_id
            AND hzcsu.site_use_code = 'BILL_TO'
            AND hzcas.cust_account_id = p_cust_account_id
            AND hzcas.orig_system_reference = l_bill_address_ref;

      CURSOR cur_alt_billto_address
      IS
         SELECT hzcas.cust_acct_site_id
           FROM hz_cust_site_uses hzcsu, hz_cust_acct_sites hzcas
          WHERE hzcas.cust_acct_site_id = hzcsu.cust_acct_site_id
            AND hzcsu.site_use_code = 'BILL_TO'
            AND hzcas.cust_account_id = p_cust_account_id
            AND ROWNUM = 1;

      l_billto_address_ref   VARCHAR2 (200) := NULL;
      l_billto_address_id    NUMBER         := NULL;
      l_billto_number        VARCHAR2 (20)  := NULL;
   BEGIN
      fnd_client_info.set_org_context (2);
      l_billto_address_ref := NULL;
      l_billto_address_id := NULL;
      l_billto_number := NULL;

      IF SUBSTR (p_bill_address_ref, 1, 1) = '0'
      THEN
         IF SUBSTR (p_bill_address_ref, 1, 2) = '00'
         THEN
            l_billto_number := SUBSTR (p_bill_address_ref, 3);
         ELSE
            l_billto_number := SUBSTR (p_bill_address_ref, 2);
         END IF;
      ELSE
         l_billto_number := p_bill_address_ref;
      END IF;

      l_billto_address_ref :=
            'DD'
         || '-'
         || p_legacy_system
         || '-'
         || p_sales_center
         || '-'
         || p_customer_ref
         || '-'
         || l_billto_number
         || '-'
         || 'HEADER';

      FOR i IN cur_billto_address (l_billto_address_ref)
      LOOP
         l_billto_address_id := i.cust_acct_site_id;
      END LOOP;

      IF l_billto_address_id IS NULL
      THEN
         FOR j IN cur_alt_billto_address
         LOOP
            l_billto_address_id := j.cust_acct_site_id;
         END LOOP;
      END IF;

      RETURN l_billto_address_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         DBMS_OUTPUT.put_line ('No Data found : ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG
                           , 'No Data found for billto : ' || SQLERRM
                           );
         RETURN NULL;
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('eRROR         : ' || SQLERRM);
         fnd_file.put_line (fnd_file.LOG
                           , 'eRROR while retreving billto : ' || SQLERRM
                           );
         RETURN NULL;
   END swgcnv_billto_address_id;

----
   PROCEDURE swgcnv_ar_conversion (
      ou_errmsg_s       OUT      VARCHAR2
     ,ou_errcode_n      OUT      NUMBER
     ,p_legacy_system   IN       VARCHAR2
     ,p_division        IN       VARCHAR2
     ,p_sales_center    IN       VARCHAR2
   )
   IS
      CURSOR cur_customer_trx
      IS
         SELECT a.*, b.oracle_customer_id, b.legacy_customer_number
           FROM swgcnv_dd_ar_interface a, swgcnv_dd_temp_customers b
          WHERE b.division = p_division
            AND a.sales_center = p_sales_center
            AND a.orig_system_bill_customer_ref = b.legacy_customer_number
            AND a.division = b.division
--AND     b.ar_proc_flag                 = 'N'
            AND b.cust_import_flag = 'Y'
            AND a.cust_trx_type_name <> 'PAYMENT';

      CURSOR cur_inv_item (in_segment1_s VARCHAR2)
      IS
         SELECT segment1, inventory_item_id, primary_uom_code, description
               ,invoice_enabled_flag
           FROM mtl_system_items_b
          WHERE segment1 = in_segment1_s AND organization_id = 5;

      l_ra_int_lines_rec      ra_interface_lines_all%ROWTYPE;
      l_ra_int_dist_rec       ra_interface_distributions_all%ROWTYPE;
      l_ra_int_sales_rec      ra_interface_salescredits_all%ROWTYPE;
      l_scredit_rec           oe_sales_credit_types%ROWTYPE;
      l_cust_trx_cnt          NUMBER                                   := 0;
      l_user_id               NUMBER;
      l_new_item_code         VARCHAR2 (20)                            := NULL;
      l_err_cnt               NUMBER                                   := 0;
      l_item_rec              swgcnv_cntrct_vldt.item_info_rec_type;
      l_org_rec               swgcnv_cntrct_vldt.org_info_rec_type;
      l_status_c              VARCHAR2 (1);
      l_error_msg             VARCHAR2 (400)                           := NULL;
      l_primary_salesrep_id   NUMBER;
   BEGIN
      fnd_client_info.set_org_context (2);

      SELECT user_id
        INTO l_user_id
        FROM fnd_user
       WHERE user_name = 'SWGCNV';

      SELECT *
        INTO l_scredit_rec
        FROM oe_sales_credit_types
       WHERE NAME = 'Quota Sales Credit' AND enabled_flag = 'Y';

      FOR cur_trx_rec IN cur_customer_trx
      LOOP
         l_cust_trx_cnt := l_cust_trx_cnt + 1;

         IF cur_trx_rec.cust_trx_type_name = 'INVOICE'
         THEN
            l_ra_int_lines_rec.cust_trx_type_name := 'DDCONV INVOICE';
         ELSIF cur_trx_rec.cust_trx_type_name = 'CREDIT MEMO'
         THEN
            l_ra_int_lines_rec.cust_trx_type_name := 'DDCONV CREDIT MEMO';
         ELSIF cur_trx_rec.cust_trx_type_name = 'PAYMENT'
         THEN
            l_ra_int_lines_rec.cust_trx_type_name := 'DDCONV PAYMENT';
         ELSIF cur_trx_rec.cust_trx_type_name = 'DEBIT MEMO'
         THEN
            l_ra_int_lines_rec.cust_trx_type_name := 'DDCONV DEBIT MEMO';
         END IF;

         l_ra_int_dist_rec.interface_line_context := 'DD CONVERSION';
         l_ra_int_dist_rec.interface_line_attribute1 :=
                                         cur_trx_rec.interface_line_attribute1;
                             --p_sales_center||'*'||interface_line_attribute1;
         l_ra_int_dist_rec.interface_line_attribute2 :=
                                         cur_trx_rec.interface_line_attribute2;
         l_ra_int_lines_rec.interface_line_context := 'DD CONVERSION';
         l_ra_int_lines_rec.interface_line_attribute1 :=
                                         cur_trx_rec.interface_line_attribute1;
                             --p_sales_center||'*'||interface_line_attribute1;
         l_ra_int_lines_rec.interface_line_attribute2 :=
                                         cur_trx_rec.interface_line_attribute2;
         l_ra_int_lines_rec.trx_number :=
                                         cur_trx_rec.interface_line_attribute1;
                             --p_sales_center||'*'||interface_line_attribute1;
         l_ra_int_lines_rec.trx_date := cur_trx_rec.trx_date;
         l_ra_int_lines_rec.sales_order :=
            'Legacy Sales Order#: ' || LTRIM (RTRIM (cur_trx_rec.sales_order));
         l_ra_int_lines_rec.sales_order_date := cur_trx_rec.sales_order_date;
         l_ra_int_lines_rec.ship_date_actual := NULL;
         l_ra_int_lines_rec.orig_system_bill_customer_id :=
                                                cur_trx_rec.oracle_customer_id;
         l_ra_int_lines_rec.orig_system_ship_customer_id :=
                                                cur_trx_rec.oracle_customer_id;
         l_ra_int_lines_rec.tax_code := 'DDCONV TAX';
         l_ra_int_lines_rec.reference_line_context := 'DD CONVERSION';
         l_ra_int_lines_rec.reference_line_attribute1 := NULL;
         l_ra_int_lines_rec.reference_line_attribute2 := NULL;
         l_ra_int_lines_rec.amount := cur_trx_rec.amount;
         l_ra_int_lines_rec.quantity := cur_trx_rec.quantity;
         l_ra_int_lines_rec.quantity_ordered := cur_trx_rec.quantity;
         l_ra_int_lines_rec.unit_selling_price :=
                                                cur_trx_rec.unit_selling_price;
         l_ra_int_lines_rec.unit_standard_price :=
                                               cur_trx_rec.unit_standard_price;
         l_ra_int_lines_rec.sales_order_line := cur_trx_rec.sales_order_line;
         l_ra_int_lines_rec.purchase_order := cur_trx_rec.purchase_order;
         l_ra_int_lines_rec.attribute10 := cur_trx_rec.attribute10;
         l_ra_int_lines_rec.attribute11 := cur_trx_rec.attribute1;
         l_ra_int_lines_rec.attribute12 := cur_trx_rec.attribute2;
         l_ra_int_lines_rec.header_attribute15 := cur_trx_rec.due_date;
         l_ra_int_lines_rec.header_attribute_category := 'DIRECT DELIVERY';
         l_ra_int_lines_rec.batch_source_name := 'DD CONVERSION';
         l_ra_int_lines_rec.set_of_books_id := 1;
         l_ra_int_lines_rec.line_type := 'LINE';
         l_ra_int_lines_rec.currency_code := 'USD';
         l_ra_int_lines_rec.conversion_type := 'User';
         l_ra_int_lines_rec.conversion_rate := 1;
         l_ra_int_lines_rec.created_by := l_user_id;
         l_ra_int_lines_rec.creation_date := SYSDATE;
         l_ra_int_lines_rec.last_updated_by := l_user_id;
         l_ra_int_lines_rec.last_update_date := SYSDATE;
         l_ra_int_lines_rec.org_id := 2;

         IF cur_trx_rec.tax_status IN ('UI', 'UP', 'UR', 'UN', 'UC')
         THEN
            l_ra_int_lines_rec.header_attribute14 := NULL;
         ELSE
            l_ra_int_lines_rec.header_attribute14 := 'NA';
         END IF;

--Shipto Address ID
         SELECT swgcnv_shipto_address_id
                                    (p_legacy_system
                                    ,p_sales_center
                                    ,cur_trx_rec.legacy_customer_number
                                    ,cur_trx_rec.orig_system_ship_address_ref
                                    ,cur_trx_rec.oracle_customer_id
                                    )
           INTO l_ra_int_lines_rec.orig_system_ship_address_id
           FROM DUAL;

         IF l_ra_int_lines_rec.orig_system_ship_address_id IS NULL
         THEN
            INSERT INTO swgcnv_conversion_exceptions
                        (conversion_type
                        ,conversion_key_value
                        ,error_message
                        )
                 VALUES ('AR Validation'
                        ,NVL (cur_trx_rec.oracle_customer_id
                             ,cur_trx_rec.legacy_customer_number
                             )
                        ,'Shipto Addressid Not found'
                        );
         END IF;

--Billto Address Id
         SELECT swgcnv_billto_address_id
                                    (p_legacy_system
                                    ,p_sales_center
                                    ,cur_trx_rec.legacy_customer_number
                                    ,cur_trx_rec.orig_system_bill_address_ref
                                    ,cur_trx_rec.oracle_customer_id
                                    )
           INTO l_ra_int_lines_rec.orig_system_bill_address_id
           FROM DUAL;

         IF l_ra_int_lines_rec.orig_system_bill_address_id IS NULL
         THEN
            INSERT INTO swgcnv_conversion_exceptions
                        (conversion_type
                        ,conversion_key_value
                        ,error_message
                        )
                 VALUES ('AR Validation'
                        ,NVL (cur_trx_rec.oracle_customer_id
                             ,cur_trx_rec.legacy_customer_number
                             )
                        ,'Billto Addressid Not found'
                        );
         END IF;

--Payment Terms
         IF l_ra_int_lines_rec.cust_trx_type_name NOT IN
                                     ('DDCONV PAYMENT', 'DDCONV CREDIT MEMO')
         THEN
            BEGIN
               SELECT standard_terms
                 INTO l_ra_int_lines_rec.term_id
                 FROM hz_customer_profiles
                WHERE cust_account_id = cur_trx_rec.oracle_customer_id
                  AND site_use_id IS NULL;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  l_ra_int_lines_rec.term_id := 5;
               WHEN OTHERS
               THEN
                  l_ra_int_lines_rec.term_id := 5;
            END;
         ELSE
            l_ra_int_lines_rec.term_id := NULL;
         END IF;

--Salesrep id
         SELECT swgcnv_salesrep (p_legacy_system
                                ,cur_trx_rec.primary_salesrep_number
                                )
           INTO l_primary_salesrep_id
           FROM DUAL;

         l_ra_int_lines_rec.primary_salesrep_id := l_primary_salesrep_id;
--Inventory item id
/*
   SELECT   swgcnv_newitem_code(p_sales_center,cur_trx_rec.item_code)
   INTO    l_new_item_code
   FROM    dual;
*/
--Updated on 09/30/05
         swgcnv_cntrct_vldt.get_maps_and_details
                       (in_sacs_org_s         => p_sales_center
                       ,in_sacs_brand_s       => cur_trx_rec.item_sub_code
                       ,in_sacs_item_s        => LTRIM
                                                    (RTRIM
                                                        (cur_trx_rec.item_code)
                                                    )
                       ,in_eff_date_d         => TRUNC (SYSDATE)
                       ,io_item_rec           => l_item_rec
                       ,io_org_rec            => l_org_rec
                       ,io_status_c           => l_status_c
                       ,io_message_s          => l_error_msg
                       ,in_debug_c            => 'N'
                                                  --swgcnv_cntrct_vldt.g_debug
                       ,in_system_code_c      => 'SACS'
                       );

         IF l_status_c != swgcnv_cntrct_vldt.g_sts_success
         THEN
            l_new_item_code := NULL;
            l_error_msg :=
                  'SACS -'
               || LTRIM (RTRIM (cur_trx_rec.item_code))
               || 'Sub Code'
               || cur_trx_rec.item_sub_code
               || 'Sales Center'
               || p_sales_center
               || 'Error returned from Get_Maps_And_Details: '
               || l_error_msg;
            fnd_file.put_line (fnd_file.LOG, l_error_msg);
         ELSE
            l_new_item_code := l_item_rec.item_code;
         END IF;

--09/30/05
         IF l_new_item_code IS NOT NULL
         THEN
            FOR inv_item_rec IN cur_inv_item (l_new_item_code)
            LOOP
               IF inv_item_rec.invoice_enabled_flag = 'N'
               THEN
                  l_ra_int_lines_rec.mtl_system_items_seg1 := NULL;
                  l_ra_int_lines_rec.inventory_item_id := NULL;
                  l_ra_int_lines_rec.uom_code := NULL;
                  l_ra_int_lines_rec.description := cur_trx_rec.description;
               ELSE
                  l_ra_int_lines_rec.mtl_system_items_seg1 :=
                                                        inv_item_rec.segment1;
                  l_ra_int_lines_rec.inventory_item_id :=
                                               inv_item_rec.inventory_item_id;
                  l_ra_int_lines_rec.uom_code :=
                                                inv_item_rec.primary_uom_code;
                  l_ra_int_lines_rec.description := inv_item_rec.description;
               END IF;                     --inv_item_rec.invoice_enabled_flag
            END LOOP;
         ELSE
            l_ra_int_lines_rec.mtl_system_items_seg1 := NULL;
            l_ra_int_lines_rec.inventory_item_id := NULL;
            l_ra_int_lines_rec.uom_code := NULL;
            l_ra_int_lines_rec.description := cur_trx_rec.description;
         END IF;                                             --l_new_item_code

         IF SUBSTR (cur_trx_rec.description, 1, 16) = 'UNBILLED PAYMENT'
         THEN
            l_ra_int_lines_rec.description := l_ra_int_lines_rec.description;
                                                           --||'-UN-PAYMENT';
         ELSIF SUBSTR (cur_trx_rec.description, 1, 16) = 'UNBILLED INVOICE'
         THEN
            l_ra_int_lines_rec.description := l_ra_int_lines_rec.description;
                                                           --||'-UN-INVOICE';
         ELSIF l_ra_int_lines_rec.description IS NULL
         THEN
            l_ra_int_lines_rec.description := cur_trx_rec.description;
         END IF;

--
--Sales Credits
         l_ra_int_sales_rec.interface_line_context :=
                                     l_ra_int_lines_rec.interface_line_context;
         l_ra_int_sales_rec.interface_line_attribute1 :=
                                  l_ra_int_lines_rec.interface_line_attribute1;
         l_ra_int_sales_rec.interface_line_attribute2 :=
                                  l_ra_int_lines_rec.interface_line_attribute2;
         l_ra_int_sales_rec.salesrep_id := l_primary_salesrep_id;
                                     --l_ra_int_lines_rec.primary_salesrep_id;
         l_ra_int_sales_rec.sales_credit_type_name := l_scredit_rec.NAME;
         l_ra_int_sales_rec.sales_credit_type_id :=
                                            l_scredit_rec.sales_credit_type_id;
         l_ra_int_sales_rec.sales_credit_percent_split := 100;
         l_ra_int_sales_rec.attribute_category :=
                                         l_ra_int_lines_rec.attribute_category;
         l_ra_int_sales_rec.attribute15 := l_scredit_rec.NAME;
         l_ra_int_sales_rec.org_id := l_ra_int_lines_rec.org_id;
         insert_ra_lines (l_ra_int_lines_rec);

         INSERT INTO ra_interface_salescredits_all
              VALUES l_ra_int_sales_rec;
/*          INSERT INTO ra_interface_distributions_all
            (interface_line_context
            ,interface_line_attribute1
            ,interface_line_attribute2
            ,account_class
            ,amount
            ,code_combination_id
            )
            VALUES
            (l_ra_int_dist_rec.interface_line_context
            ,l_ra_int_dist_rec.interface_line_attribute1
            ,l_ra_int_dist_rec.interface_line_attribute2
            ,'REC'
            ,NVL(cur_trx_rec.amount,0)
            ,311228
            ) ;

            INSERT INTO ra_interface_distributions_all
            (interface_line_context
            ,interface_line_attribute1
            ,interface_line_attribute2
            ,account_class
            ,amount
            ,code_combination_id
            )
            VALUES
            (l_ra_int_dist_rec.interface_line_context
            ,l_ra_int_dist_rec.interface_line_attribute1
            ,l_ra_int_dist_rec.interface_line_attribute2
            ,'TAX'
            ,NVL (cur_trx_rec.attribute10,0)
            ,278355
            ) ;

               INSERT INTO ra_interface_distributions_all
            (interface_line_context
            ,interface_line_attribute1
            ,interface_line_attribute2
            ,account_class
            ,amount
            ,code_combination_id
            )
            VALUES
            (l_ra_int_dist_rec.interface_line_context
            ,l_ra_int_dist_rec.interface_line_attribute1
            ,l_ra_int_dist_rec.interface_line_attribute2
            ,'REV'
            ,NVL(cur_trx_rec.amount,0) + NVL (cur_trx_rec.attribute10,0)
            ,311228
            ) ;
*/
      END LOOP;                                             --cur_customer_trx

      fnd_file.put_line (fnd_file.LOG
                        , 'no of records are inserted : ' || l_cust_trx_cnt
                        );
      DBMS_OUTPUT.put_line ('l_err_cnt : ' || l_err_cnt);
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line
                         (   'error while calling ar conversion procedure : '
                          || SQLERRM
                         );
         fnd_file.put_line
                          (fnd_file.LOG
                          ,    'error while calling ar conversion procedure : '
                            || SQLERRM
                          );
   END swgcnv_ar_conversion;

   PROCEDURE insert_ra_lines (
      p_ra_lines_rec   IN   ra_interface_lines_all%ROWTYPE
   )
   IS
      l_err_message   VARCHAR2 (2000) := NULL;
   BEGIN
      INSERT INTO ra_interface_lines_all
                  (cust_trx_type_name
                  ,interface_line_attribute1
                  ,trx_number, trx_date
                  ,sales_order
                  ,sales_order_date
                  ,ship_date_actual, term_id
                  ,term_name
                  ,orig_system_bill_customer_id
                  ,orig_system_bill_address_id
                  ,orig_system_ship_customer_id
                  ,orig_system_ship_address_id
                  ,interface_line_attribute2
                  ,line_number
                  ,mtl_system_items_seg1
                  ,inventory_item_id
                  ,description, amount
                  ,quantity, quantity_ordered
                  ,unit_selling_price
                  ,unit_standard_price
                  ,sales_order_line
                  ,attribute10
                  ,reference_line_context
                  ,reference_line_attribute1
                  ,reference_line_attribute2
                  ,interface_line_context
                  ,batch_source_name
                  ,set_of_books_id, line_type
                  ,currency_code
                  ,conversion_type
                  ,conversion_date
                  ,conversion_rate, tax_code
                  ,created_by, creation_date
                  ,last_updated_by
                  ,last_update_date, org_id
                  ,uom_code
                  ,primary_salesrep_number
                  ,primary_salesrep_id
                  ,purchase_order
                  ,header_attribute14
                  ,header_attribute15
                  ,header_attribute_category
                  ,attribute11, attribute12
                  )
           VALUES (p_ra_lines_rec.cust_trx_type_name
                  ,p_ra_lines_rec.interface_line_attribute1
                  ,p_ra_lines_rec.trx_number, p_ra_lines_rec.trx_date
                  ,p_ra_lines_rec.sales_order
                  ,p_ra_lines_rec.sales_order_date
                  ,p_ra_lines_rec.ship_date_actual, p_ra_lines_rec.term_id
                  ,p_ra_lines_rec.term_name
                  ,p_ra_lines_rec.orig_system_bill_customer_id
                  ,p_ra_lines_rec.orig_system_bill_address_id
                  ,p_ra_lines_rec.orig_system_ship_customer_id
                  ,p_ra_lines_rec.orig_system_ship_address_id
                  ,p_ra_lines_rec.interface_line_attribute2
                  ,p_ra_lines_rec.line_number
                  ,p_ra_lines_rec.mtl_system_items_seg1
                  ,p_ra_lines_rec.inventory_item_id
                  ,p_ra_lines_rec.description, p_ra_lines_rec.amount
                  ,p_ra_lines_rec.quantity, p_ra_lines_rec.quantity_ordered
                  ,p_ra_lines_rec.unit_selling_price
                  ,p_ra_lines_rec.unit_standard_price
                  ,p_ra_lines_rec.sales_order_line
                  ,p_ra_lines_rec.attribute10           -- sales tax goes here
                  ,p_ra_lines_rec.reference_line_context
                  ,p_ra_lines_rec.reference_line_attribute1
                  ,p_ra_lines_rec.reference_line_attribute2
                  ,p_ra_lines_rec.interface_line_context
                  ,p_ra_lines_rec.batch_source_name
                  ,p_ra_lines_rec.set_of_books_id, p_ra_lines_rec.line_type
                  ,p_ra_lines_rec.currency_code
                  ,p_ra_lines_rec.conversion_type
                  ,p_ra_lines_rec.conversion_date
                  ,p_ra_lines_rec.conversion_rate, p_ra_lines_rec.tax_code
                  ,p_ra_lines_rec.created_by, p_ra_lines_rec.creation_date
                  ,p_ra_lines_rec.last_updated_by
                  ,p_ra_lines_rec.last_update_date, p_ra_lines_rec.org_id
                  ,p_ra_lines_rec.uom_code
                  ,p_ra_lines_rec.primary_salesrep_number
                  ,p_ra_lines_rec.primary_salesrep_id
                  ,p_ra_lines_rec.purchase_order
                  ,p_ra_lines_rec.header_attribute14
                  ,p_ra_lines_rec.header_attribute15
                  ,p_ra_lines_rec.header_attribute_category
                  ,p_ra_lines_rec.attribute11, p_ra_lines_rec.attribute12
                  );

      UPDATE swgcnv_dd_temp_customers
         SET ar_proc_flag = 'I'
       WHERE oracle_customer_id = p_ra_lines_rec.orig_system_bill_customer_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_err_message := SQLERRM;

         INSERT INTO swgcnv_conversion_exceptions
                     (conversion_type
                     ,conversion_key_value
                     ,error_message
                     )
              VALUES ('AR Validation'
                     ,p_ra_lines_rec.orig_system_bill_customer_id
                     ,l_err_message
                     );

         UPDATE swgcnv_dd_temp_customers
            SET ar_proc_flag = 'E'
          WHERE oracle_customer_id =
                                   p_ra_lines_rec.orig_system_bill_customer_id;
   END insert_ra_lines;

--
   PROCEDURE swgcnv_update_duedate (
      ou_errmsg_s      OUT      VARCHAR2
     ,ou_errcode_n     OUT      NUMBER
     ,p_sales_center   IN       VARCHAR2
   )
   IS
      CURSOR cur_custtrx (in_batch_source_id NUMBER)
      IS
         SELECT a.trx_date, a.customer_trx_id, attribute15, a.trx_number
           FROM ra_customer_trx_all a, swgcnv_dd_temp_customers b
          WHERE SUBSTR (a.trx_number, 1, 3) = p_sales_center
            AND batch_source_id = in_batch_source_id
            AND a.bill_to_customer_id = b.oracle_customer_id;

      l_cnt               NUMBER          := 0;
      l_batch_source_id   NUMBER;
      l_err_message       VARCHAR2 (2000) := NULL;
   BEGIN
      fnd_client_info.set_org_context (2);

      BEGIN
         SELECT batch_source_id
           INTO l_batch_source_id
           FROM ra_batch_sources
          WHERE NAME = 'DD CONVERSION';
      EXCEPTION
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG
                              ,    'Error while retriving batch source id : '
                                || SQLERRM
                              );
      END;

      FOR i IN cur_custtrx (l_batch_source_id)
      LOOP
         UPDATE ar_payment_schedules_all
            SET due_date = i.attribute15
          WHERE customer_trx_id = i.customer_trx_id
            AND trx_date = i.trx_date
            AND trx_number = i.trx_number;

         l_cnt := l_cnt + 1;
      END LOOP;

      COMMIT;
      fnd_file.put_line (fnd_file.LOG
                        , 'No of transactions are updated : ' || l_cnt
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         l_err_message := SQLERRM;

         INSERT INTO swgcnv_conversion_exceptions
                     (conversion_type, conversion_key_value, error_message
                     )
              VALUES ('AR Update Duedate', p_sales_center, l_err_message
                     );

         fnd_file.put_line (fnd_file.LOG, 'Error : ' || SQLERRM);
   END swgcnv_update_duedate;

--
   PROCEDURE swgcnv_post_update1 (
      ou_errmsg_s      OUT      VARCHAR2
     ,ou_errcode_n     OUT      NUMBER
     ,p_sales_center   IN       VARCHAR2
   )
   IS
      CURSOR cur_arpaysch
      IS
         SELECT customer_id, customer_site_use_id, due_date
               ,amount_due_remaining, payment_schedule_id
               ,amount_due_original, CLASS, customer_trx_id, cash_receipt_id
               ,cust_trx_type_id, trx_date, trx_number
           FROM ar_payment_schedules arps, swgcnv_dd_temp_customers swgtemp
          WHERE swgtemp.new_sales_center = p_sales_center
            AND arps.customer_id = swgtemp.oracle_customer_id
            AND arps.status = 'OP'
            AND arps.customer_id IS NOT NULL
            AND arps.customer_site_use_id IS NOT NULL;

      l_cnt   NUMBER := 0;
   BEGIN
      fnd_client_info.set_org_context (2);

      FOR i IN cur_arpaysch
      LOOP
         INSERT INTO swg_ar_open_trx
              VALUES (i.customer_id, i.customer_site_use_id, i.due_date
                     ,i.amount_due_remaining, i.payment_schedule_id
                     ,i.amount_due_original, i.CLASS, i.customer_trx_id
                     ,i.cash_receipt_id, i.cust_trx_type_id, i.trx_date
                     ,i.trx_number);

         l_cnt := l_cnt + 1;
      END LOOP;

      COMMIT;
      DBMS_OUTPUT.put_line ('No of transactions are inserted : ' || l_cnt);
      fnd_file.put_line (fnd_file.LOG
                        , 'No of transactions are inserted : ' || l_cnt
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Error : ' || SQLERRM);
   END swgcnv_post_update1;

--
   PROCEDURE swgcnv_post_update2 (
      ou_errmsg_s      OUT      VARCHAR2
     ,ou_errcode_n     OUT      NUMBER
     ,p_sales_center   IN       VARCHAR2
   )
   IS
      CURSOR cur_swgopentrx
      IS
         SELECT   customer_id, bill_to_id, SUM (open_amount) open_balance
                 ,MIN (due_date) oldest_due_date
                 ,SUM (DECODE (CLASS, 'DM', open_amount, NULL)) dm_amount
                 ,SUM (DECODE (CLASS, 'CM', open_amount, NULL)) cm_amount
                 ,SUM (DECODE (CLASS, 'INV', open_amount, NULL)) inv_amount
                 ,SUM (DECODE (CLASS, 'PMT', open_amount, NULL)) pmt_amount
                 ,MAX (DECODE (CLASS, 'DM', 'Y', NULL)) dm_flag
                 ,MAX (DECODE (CLASS, 'CM', 'Y', NULL)) cm_flag
                 ,MAX (DECODE (CLASS, 'INV', 'Y', NULL)) inv_flag
                 ,MAX (DECODE (CLASS, 'PMT', 'Y', NULL)) pmt_flag
                 ,MAX (SYSDATE) creation_date
             FROM swg_ar_open_trx swgarot, swgcnv_dd_temp_customers swgtemp
            WHERE swgarot.customer_id = swgtemp.oracle_customer_id
              AND swgtemp.new_sales_center = p_sales_center
         GROUP BY swgarot.customer_id, swgarot.bill_to_id;

      l_cnt   NUMBER := 0;
   BEGIN
      fnd_client_info.set_org_context (2);

      FOR i IN cur_swgopentrx
      LOOP
         INSERT INTO swg_cust_billto_open_balance
                     (customer_id, bill_to_id, open_balance
                     ,oldest_due_date, dm_amount, cm_amount
                     ,inv_amount, pmt_amount, dm_flag, cm_flag
                     ,inv_flag, pmt_flag, creation_date
                     )
              VALUES (i.customer_id, i.bill_to_id, i.open_balance
                     ,i.oldest_due_date, i.dm_amount, i.cm_amount
                     ,i.inv_amount, i.pmt_amount, i.dm_flag, i.cm_flag
                     ,i.inv_flag, i.pmt_flag, i.creation_date
                     );

         l_cnt := l_cnt + 1;
      END LOOP;

      COMMIT;
      DBMS_OUTPUT.put_line ('No of transactions are inserted : ' || l_cnt);
      fnd_file.put_line (fnd_file.LOG
                        , 'No of transactions are inserted : ' || l_cnt
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Error : ' || SQLERRM);
   END swgcnv_post_update2;

--
   PROCEDURE swgcnv_ar_trx_number (
      ou_errmsg_s      OUT      VARCHAR2
     ,ou_errcode_n     OUT      NUMBER
     ,p_sales_center   IN       VARCHAR2
   )
   IS
      CURSOR a
      IS
         SELECT   orig_system_bill_customer_ref
                 ,orig_system_ship_customer_ref, interface_line_attribute1
                 ,cust_trx_type_name, tax_status, trx_date, sales_center
                 ,primary_salesrep_number
             FROM swgcnv_dd_ar_interface
            WHERE sales_center = p_sales_center
              AND cust_trx_type_name <> 'PAYMENT'
         GROUP BY orig_system_bill_customer_ref
                 ,orig_system_ship_customer_ref
                 ,interface_line_attribute1
                 ,cust_trx_type_name
                 ,tax_status
                 ,trx_date
                 ,sales_center
                 ,primary_salesrep_number;

      CURSOR b (
         l_orig_cust_ref         VARCHAR2
        ,l_orig_ship_cust_ref    VARCHAR2
        ,l_interface_line_att1   VARCHAR2
        ,l_trx_date              DATE
        ,l_sales_center          VARCHAR2
        ,l_cust_trx_type         VARCHAR2
        ,l_tax_status            VARCHAR2
        ,l_pri_salesrep_number   VARCHAR2
      )
      IS
         SELECT *
           FROM swgcnv_dd_ar_interface
          WHERE sales_center = l_sales_center
            AND orig_system_bill_customer_ref = l_orig_cust_ref
            AND interface_line_attribute1 = l_interface_line_att1
            AND trx_date = l_trx_date
            AND cust_trx_type_name = l_cust_trx_type
            AND tax_status = l_tax_status
            AND primary_salesrep_number = l_pri_salesrep_number
            AND orig_system_ship_customer_ref = l_orig_ship_cust_ref;

      l_header_cnt   NUMBER := 0;
      l_line_cnt     NUMBER := 0;
      l_total_cnt    NUMBER := 0;
   BEGIN
      FOR i IN a
      LOOP
         l_header_cnt := l_header_cnt + 1;

         FOR j IN b (i.orig_system_bill_customer_ref
                    ,i.orig_system_ship_customer_ref
                    ,i.interface_line_attribute1
                    ,i.trx_date
                    ,i.sales_center
                    ,i.cust_trx_type_name
                    ,i.tax_status
                    ,i.primary_salesrep_number
                    )
         LOOP
            l_line_cnt := l_line_cnt + 1;

            UPDATE swgcnv_dd_ar_interface
               SET interface_line_attribute2 = l_line_cnt
                  ,interface_line_attribute1 =
                                         j.sales_center || '_' || l_header_cnt
                  ,line_number = l_line_cnt
                  ,attribute1 = j.interface_line_attribute1
                  ,attribute2 = j.interface_line_attribute2
             WHERE interface_line_attribute1 = j.interface_line_attribute1
               AND interface_line_attribute2 = j.interface_line_attribute2
               AND orig_system_bill_customer_ref =
                                               j.orig_system_bill_customer_ref
               AND orig_system_ship_customer_ref =
                                               j.orig_system_ship_customer_ref
               AND trx_date = j.trx_date
               AND cust_trx_type_name = j.cust_trx_type_name
               AND tax_status = j.tax_status
               AND sales_center = j.sales_center
               AND primary_salesrep_number = j.primary_salesrep_number;

            l_total_cnt := l_total_cnt + 1;
            COMMIT;
         END LOOP;

         l_line_cnt := 0;
      END LOOP;

      COMMIT;
      fnd_file.put_line (fnd_file.LOG
                        ,    'Total No of Transactions are Updated : '
                          || l_total_cnt
                        );
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         fnd_file.put_line (fnd_file.LOG, 'No data found  : ' || SQLERRM);
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Others         : ' || SQLERRM);
   END swgcnv_ar_trx_number;

--
   PROCEDURE swgcnv_ar_preupdates (
      ou_errmsg_s      OUT      VARCHAR2
     ,ou_errcode_n     OUT      NUMBER
     ,p_division       IN       VARCHAR2
     ,p_sales_center   IN       VARCHAR2
   )
   IS
      l_sales_center   VARCHAR2 (3) := p_sales_center;
      l_division       VARCHAR2 (4) := p_division;
   BEGIN
      fnd_client_info.set_org_context (2);

--1)
      BEGIN
         UPDATE swgcnv_dd_ar_interface
            SET division = l_division
          WHERE sales_center = l_sales_center;

         DBMS_OUTPUT.put_line (' 1 ');
         fnd_file.put_line (fnd_file.LOG, ' 1 ');
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line
                         (fnd_file.LOG
                         ,    'NDF FOR swgcnv_dd_ar_interface table        : '
                           || SQLERRM
                         );
         WHEN OTHERS
         THEN
            fnd_file.put_line
                         (fnd_file.LOG
                         ,    'ERR while updating replace trx_number -     : '
                           || SQLERRM
                         );
      END;

      COMMIT;

--2)
      BEGIN
         UPDATE swgcnv_dd_ar_interface
            SET cust_trx_type_name = 'INVOICE'
          WHERE tax_status = 'UI' AND sales_center = l_sales_center;

         fnd_file.put_line (fnd_file.LOG, ' 2 ');
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line
                         (fnd_file.LOG
                         ,    'NDF for tax_status = UI                     : '
                           || SQLERRM
                         );
         WHEN OTHERS
         THEN
            fnd_file.put_line
                         (fnd_file.LOG
                         ,    'ERR for tax_status = UI                     : '
                           || SQLERRM
                         );
      END;

      COMMIT;

--3)
      BEGIN
         UPDATE swgcnv_dd_ar_interface
            SET cust_trx_type_name = 'PAYMENT'
          WHERE tax_status = 'UP'
            AND amount < 0
            AND sales_center = l_sales_center;

         fnd_file.put_line (fnd_file.LOG, ' 3 ');
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line
                         (fnd_file.LOG
                         ,    'NDF for tax_status = UP  AND AMT < 0        : '
                           || SQLERRM
                         );
         WHEN OTHERS
         THEN
            fnd_file.put_line
                         (fnd_file.LOG
                         ,    'ERR for tax_status = UP  AND AMT < 0        : '
                           || SQLERRM
                         );
      END;

      COMMIT;

--4)
      BEGIN
         UPDATE swgcnv_dd_ar_interface
            SET cust_trx_type_name = 'INVOICE'
          WHERE tax_status = 'UP'
            AND amount >= 0
            AND sales_center = l_sales_center;

         fnd_file.put_line (fnd_file.LOG, ' 4 ');
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line
                          (fnd_file.LOG
                          ,    'NDF for tax_status = UP  AND AMT >= 0      : '
                            || SQLERRM
                          );
         WHEN OTHERS
         THEN
            fnd_file.put_line
                          (fnd_file.LOG
                          ,    'ERR for tax_status = UP  AND AMT >= 0      : '
                            || SQLERRM
                          );
      END;

      COMMIT;

--5)
      BEGIN
         UPDATE swgcnv_dd_ar_interface
            SET cust_trx_type_name = 'CREDIT MEMO'
          WHERE tax_status = 'B'
            AND cust_trx_type_name = 'INVOICE'
            AND amount < 0
            AND sales_center = l_sales_center;

         fnd_file.put_line (fnd_file.LOG, ' 5 ');
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line
                           (fnd_file.LOG
                           ,    'NDF for tax_status = B  AND AMT < 0       : '
                             || SQLERRM
                           );
         WHEN OTHERS
         THEN
            fnd_file.put_line
                           (fnd_file.LOG
                           ,    'ERR for tax_status = B  AND AMT < 0       : '
                             || SQLERRM
                           );
      END;

      COMMIT;

--6)
      BEGIN
         UPDATE swgcnv_dd_ar_interface
            SET cust_trx_type_name = 'INVOICE'
          WHERE cust_trx_type_name = 'PAYMENT'
            AND amount > 0
            AND sales_center = l_sales_center;

         fnd_file.put_line (fnd_file.LOG, ' 6 ');
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line
                           (fnd_file.LOG
                           ,    'NDF for trx type = PAYMENT  AND AMT > 0   : '
                             || SQLERRM
                           );
         WHEN OTHERS
         THEN
            fnd_file.put_line
                           (fnd_file.LOG
                           ,    'ERR for trx type = PAYMENT  AND AMT > 0   : '
                             || SQLERRM
                           );
      END;

      COMMIT;

--7)
      BEGIN
         UPDATE swgcnv_dd_ar_interface
            SET attribute10 =
                      SUBSTR (attribute10, 1, 1)
                   || LTRIM (RTRIM (SUBSTR (attribute10, 2)))
          WHERE attribute10 IS NOT NULL
            AND SUBSTR (attribute10, 1, 1) = '-'
            AND sales_center = l_sales_center;

         fnd_file.put_line (fnd_file.LOG, ' 7 ');
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line
                             (fnd_file.LOG
                             ,    'NDF for -      7                        : '
                               || SQLERRM
                             );
         WHEN OTHERS
         THEN
            fnd_file.put_line
                             (fnd_file.LOG
                             ,    'ERR for -      7                        : '
                               || SQLERRM
                             );
      END;

      COMMIT;

--8)
      BEGIN
         UPDATE swgcnv_dd_ar_interface
            SET cust_trx_type_name = 'CREDIT MEMO'
          WHERE sales_center = l_sales_center
            AND tax_status IN ('UP', 'B')
            AND cust_trx_type_name IN ('PAYMENT', 'UNBILLED')
            AND attribute10 <> 0;

         fnd_file.put_line (fnd_file.LOG, ' 8 ');
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line
                            (fnd_file.LOG
                            ,    'NDF for -      8                         : '
                              || SQLERRM
                            );
         WHEN OTHERS
         THEN
            fnd_file.put_line
                            (fnd_file.LOG
                            ,    'ERR for -      8                         : '
                              || SQLERRM
                            );
      END;

      COMMIT;

--9)
      BEGIN
         UPDATE swgcnv_dd_ar_interface
            SET primary_salesrep_number = 'DEFAULT'
          WHERE primary_salesrep_number IS NULL
            AND sales_center = l_sales_center;

         DBMS_OUTPUT.put_line (' 9 ');
         fnd_file.put_line (fnd_file.LOG, ' 9 ');
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line
                         (fnd_file.LOG
                         ,    'NDF FOR swgcnv_dd_ar_interface table        : '
                           || SQLERRM
                         );
         WHEN OTHERS
         THEN
            fnd_file.put_line
                         (fnd_file.LOG
                         ,    'ERR while updating replace trx_number -     : '
                           || SQLERRM
                         );
      END;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'ERR for : ' || SQLERRM);
   END swgcnv_ar_preupdates;

--
   PROCEDURE swgcnv_ar_preconv_reports (
      ou_errmsg_s      OUT      VARCHAR2
     ,ou_errcode_n     OUT      NUMBER
     ,p_sales_center   IN       VARCHAR2
   )
   IS
      CURSOR a
      IS
         SELECT   sales_center, COUNT (*) transactions
                 ,SUM (NVL (amount, 0)) amt, SUM (NVL (attribute10, 0)) tax
                 ,SUM (NVL (amount, 0) + NVL (attribute10, 0)) total
             FROM swgcnv_dd_ar_history
            WHERE sales_center = p_sales_center
         GROUP BY sales_center
         ORDER BY 2;

      CURSOR b
      IS
         SELECT   sales_center, cust_trx_type_name, COUNT (*) transactions
                 ,SUM (NVL (amount, 0)) amt, SUM (NVL (attribute10, 0)) tax
                 ,SUM (NVL (amount, 0) + NVL (attribute10, 0)) total
                 ,tax_status
             FROM swgcnv_dd_ar_history
            WHERE sales_center = p_sales_center
         GROUP BY cust_trx_type_name, tax_status, sales_center
         ORDER BY 6;

      CURSOR c
      IS
         SELECT COUNT (*)
           FROM swgcnv_dd_ar_history
          WHERE sales_center = p_sales_center AND attribute10 <> 0;

      CURSOR d
      IS
         SELECT   orig_system_bill_customer_ref
                 ,orig_system_bill_address_ref, cust_trx_type_name
                 ,COUNT (*) transactions, SUM (NVL (amount, 0)) amt
                 ,SUM (NVL (attribute10, 0)) tax
                 ,SUM (NVL (amount, 0) + NVL (attribute10, 0)) total
                 ,tax_status
             FROM swgcnv_dd_ar_history
            WHERE sales_center = p_sales_center
              AND orig_system_bill_customer_ref IN (
                     SELECT orig_system_bill_customer_ref
                       FROM swgcnv_dd_ar_history
                      WHERE sales_center = p_sales_center
                     MINUS
                     SELECT legacy_customer_number
                       FROM swgcnv_dd_temp_customers)
         GROUP BY cust_trx_type_name
                 ,tax_status
                 ,orig_system_bill_customer_ref
                 ,orig_system_bill_address_ref
         ORDER BY 1, 2;

      CURSOR e
      IS
         SELECT   sales_center, COUNT (*) cnt
                 ,SUM (customer_balance) total_amt
             FROM swgcnv_dd_stmt_interface
            WHERE sales_center = p_sales_center
         GROUP BY sales_center;

      CURSOR f
      IS
         SELECT   sales_center, COUNT (*) cnt
                 ,SUM (NVL (amount, 0) + NVL (attribute10, 0)) total_amt
             FROM swgcnv_dd_ar_history
            WHERE tax_status NOT IN ('UI', 'UN', 'UP', 'UR', 'UC')
              AND sales_center = p_sales_center
         GROUP BY sales_center;

      CURSOR g
      IS
         SELECT   sales_center, COUNT (*) cnt
                 ,SUM (NVL (amount, 0) + NVL (attribute10, 0)) total_amt
             FROM swgcnv_dd_ar_history
            WHERE tax_status IN ('UI', 'UN', 'UP', 'UR', 'UC')
              AND sales_center = p_sales_center
         GROUP BY sales_center;

      l_rpt1_cnt   NUMBER := 0;
      l_rpt2_cnt   NUMBER := 0;
      l_rpt3_cnt   NUMBER := 0;
      l_rpt4_cnt   NUMBER := 0;
      l_rpt5_cnt   NUMBER := 0;
   BEGIN
      fnd_client_info.set_org_context (2);
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 30, ' ')
                          || 'Pre Conversion AR Reports Ver.1'
                        );
      fnd_file.put_line (fnd_file.output
                        , RPAD (' ', 33, ' ') || 'Report Date :' || SYSDATE
                        );
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 30, ' ')
                          || '-------------------------------'
                        );
      fnd_file.put_line (fnd_file.output, ' ');
      fnd_file.put_line (fnd_file.output, ' ');
      fnd_file.put_line (fnd_file.output
                        ,    'Report1 : Total Transactons for the '
                          || p_sales_center
                          || ' Sales center'
                        );
      fnd_file.put_line (fnd_file.output, ' ');
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 5, ' ')
                          || 'Sales Center'
                          || '  '
                          || 'No of Trans'
                          || '  '
                          || ' Trans Amount '
                          || '  '
                          || 'TAX Amount'
                          || ' '
                          || '  Total Amount  '
                        );
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 5, ' ')
                          || RPAD ('=', 12, '=')
                          || '  '
                          || RPAD ('=', 11, '=')
                          || '  '
                          || LPAD ('=', 14, '=')
                          || '  '
                          || LPAD ('=', 10, '=')
                          || ' '
                          || LPAD ('=', 16, '=')
                        );
      fnd_file.put_line (fnd_file.output, ' ');

      FOR i IN a
      LOOP
         fnd_file.put_line (fnd_file.output
                           ,    RPAD (' ', 5, ' ')
                             || '  '
                             || RPAD (i.sales_center, 12, ' ')
                             || '  '
                             || RPAD (i.transactions, 11, ' ')
                             || '  '
                             || LPAD (i.amt, 14, ' ')
                             || '  '
                             || LPAD (i.tax, 10, ' ')
                             || ' '
                             || LPAD (i.total, 16, ' ')
                           );
         l_rpt1_cnt := l_rpt1_cnt + 1;
      END LOOP;                                                            --i

      IF l_rpt1_cnt = 0
      THEN
         fnd_file.put_line (fnd_file.output
                           , RPAD (' ', 30, ' ') || '*****No Data Found*****'
                           );
      END IF;

      fnd_file.put_line (fnd_file.output, ' ');
      fnd_file.put_line (fnd_file.output
                        ,    'Report2 : Total Transactons for the '
                          || p_sales_center
                          || ' Sales center Transaction Type wise'
                        );
      fnd_file.put_line (fnd_file.output, ' ');
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 5, ' ')
                          || '  '
                          || 'Sales Center'
                          || ' '
                          || 'Transaction Type'
                          || ' '
                          || 'Tax Status'
                          || '  '
                          || 'No of Trans'
                          || '  '
                          || ' Trans Amount '
                          || '  '
                          || 'TAX Amount'
                          || ' '
                          || '  Total Amount  '
                        );
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 5, ' ')
                          || '  '
                          || RPAD ('=', 12, '=')
                          || ' '
                          || RPAD ('=', 16, '=')
                          || '  '
                          || RPAD ('=', 10, '=')
                          || '  '
                          || RPAD ('=', 11, '=')
                          || '  '
                          || LPAD ('=', 14, '=')
                          || '  '
                          || LPAD ('=', 10, '=')
                          || ' '
                          || LPAD ('=', 16, '=')
                        );
      fnd_file.put_line (fnd_file.output, ' ');

      FOR j IN b
      LOOP
         fnd_file.put_line (fnd_file.output
                           ,    RPAD (' ', 5, ' ')
                             || '  '
                             || RPAD (j.sales_center, 12, ' ')
                             || ' '
                             || RPAD (j.cust_trx_type_name, 16, ' ')
                             || '  '
                             || RPAD (j.tax_status, 10, ' ')
                             || '  '
                             || RPAD (j.transactions, 11, ' ')
                             || '  '
                             || LPAD (j.amt, 14, ' ')
                             || '  '
                             || LPAD (j.tax, 10, ' ')
                             || ' '
                             || LPAD (j.total, 16, ' ')
                           );
         l_rpt2_cnt := l_rpt2_cnt + 1;
      END LOOP;                                                            --i

      IF l_rpt2_cnt = 0
      THEN
         fnd_file.put_line (fnd_file.output
                           , RPAD (' ', 30, ' ') || '*****No Data Found*****'
                           );
      END IF;

      fnd_file.put_line (fnd_file.output, ' ');
      fnd_file.put_line (fnd_file.output
                        ,    'Report3 : Total Transactons for the '
                          || p_sales_center
                          || ' Sales center without Customers'
                        );
      fnd_file.put_line (fnd_file.output, ' ');
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 5, ' ')
                          || 'Legacy Customer'
                          || ' '
                          || 'Transaction Type'
                          || ' '
                          || 'Tax Status'
                          || '  '
                          || 'No of Trans'
                          || '  '
                          || ' Trans Amount '
                          || '  '
                          || 'TAX Amount'
                          || ' '
                          || '  Total Amount  '
                        );
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 5, ' ')
                          || RPAD ('=', 15, '=')
                          || ' '
                          || RPAD ('=', 16, '=')
                          || '  '
                          || RPAD ('=', 10, '=')
                          || '  '
                          || RPAD ('=', 11, '=')
                          || '  '
                          || LPAD ('=', 14, '=')
                          || '  '
                          || LPAD ('=', 10, '=')
                          || ' '
                          || LPAD ('=', 16, '=')
                        );
      fnd_file.put_line (fnd_file.output, ' ');

      FOR l IN d
      LOOP
         fnd_file.put_line (fnd_file.output
                           ,    RPAD (' ', 5, ' ')
                             || RPAD (l.orig_system_bill_customer_ref, 15
                                     ,' ')
                             || ' '
                             || RPAD (l.cust_trx_type_name, 16, ' ')
                             || '  '
                             || RPAD (l.tax_status, 10, ' ')
                             || '  '
                             || RPAD (l.transactions, 11, ' ')
                             || '  '
                             || LPAD (l.amt, 14, ' ')
                             || '  '
                             || LPAD (l.tax, 10, ' ')
                             || ' '
                             || LPAD (l.total, 16, ' ')
                           );
         l_rpt3_cnt := l_rpt3_cnt + 1;
      END LOOP;                                                            --i

      IF l_rpt3_cnt = 0
      THEN
         fnd_file.put_line (fnd_file.output
                           , RPAD (' ', 30, ' ') || '*****No Data Found*****'
                           );
      END IF;

      fnd_file.put_line (fnd_file.output, ' ');
--4)
      fnd_file.put_line (fnd_file.output
                        ,    'Report4 : Statement Balance for '
                          || p_sales_center
                          || ' Sales center'
                        );
      fnd_file.put_line (fnd_file.output, ' ');
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 5, ' ')
                          || 'Sales Center'
                          || ' '
                          || 'No of Trans'
                          || ' '
                          || ' Total Amount '
                        );
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 5, ' ')
                          || RPAD ('=', 12, '=')
                          || ' '
                          || RPAD ('=', 11, '=')
                          || '  '
                          || RPAD ('=', 14, '=')
                        );
      fnd_file.put_line (fnd_file.output, ' ');

      FOR m IN e
      LOOP
         fnd_file.put_line (fnd_file.output
                           ,    RPAD (' ', 5, ' ')
                             || RPAD (m.sales_center, 12, ' ')
                             || ' '
                             || RPAD (m.cnt, 11, ' ')
                             || '  '
                             || LPAD (m.total_amt, 14, ' ')
                           );
         l_rpt4_cnt := l_rpt4_cnt + 1;
      END LOOP;                                                            --i

      IF l_rpt4_cnt = 0
      THEN
         fnd_file.put_line (fnd_file.output
                           , RPAD (' ', 30, ' ') || '*****No Data Found*****'
                           );
      END IF;

      fnd_file.put_line (fnd_file.output, ' ');
--5)
      fnd_file.put_line (fnd_file.output, CHR (12));
      fnd_file.put_line (fnd_file.output
                        ,    'Report5 : AR Balances for '
                          || p_sales_center
                          || ' Sales center for Statements'
                        );
      fnd_file.put_line (fnd_file.output, ' ');
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 27, ' ')
                          || 'Sales Center'
                          || ' '
                          || 'No of Trans'
                          || ' '
                          || ' Total Amount '
                        );
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 27, ' ')
                          || RPAD ('=', 12, '=')
                          || ' '
                          || RPAD ('=', 11, '=')
                          || '  '
                          || RPAD ('=', 14, '=')
                        );
      fnd_file.put_line (fnd_file.output, ' ');

      FOR n IN f
      LOOP
         fnd_file.put_line (fnd_file.output
                           ,    RPAD (' ', 5, ' ')
                             || RPAD ('Exclude UI,UN,UP,UC  ', 22, ' ')
                             || ' '
                             || RPAD (n.sales_center, 12, ' ')
                             || ' '
                             || RPAD (n.cnt, 11, ' ')
                             || '  '
                             || LPAD (n.total_amt, 14, ' ')
                           );
         l_rpt5_cnt := l_rpt5_cnt + 1;
      END LOOP;                                                            --i

      FOR o IN g
      LOOP
         fnd_file.put_line (fnd_file.output
                           ,    RPAD (' ', 5, ' ')
                             || RPAD ('Exclude B,O  ', 22, ' ')
                             || ' '
                             || RPAD (o.sales_center, 12, ' ')
                             || ' '
                             || RPAD (o.cnt, 11, ' ')
                             || '  '
                             || LPAD (o.total_amt, 14, ' ')
                           );
      END LOOP;                                                            --i

      IF l_rpt4_cnt = 0
      THEN
         fnd_file.put_line (fnd_file.output
                           , RPAD (' ', 30, ' ') || '*****No Data Found*****'
                           );
      END IF;

      fnd_file.put_line (fnd_file.output, ' ');
      fnd_file.put_line (fnd_file.output
                        , RPAD (' ', 30, ' ') || '*****End of Report*****'
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'ERR for : ' || SQLERRM);
   END swgcnv_ar_preconv_reports;

--
   PROCEDURE swgcnv_ar_preconv_reports1 (
      ou_errmsg_s      OUT      VARCHAR2
     ,ou_errcode_n     OUT      NUMBER
     ,p_sales_center   IN       VARCHAR2
   )
   IS
      CURSOR a
      IS
         SELECT   sales_center, COUNT (*) transactions
                 ,SUM (NVL (amount, 0)) amt, SUM (NVL (attribute10, 0)) tax
                 ,SUM (NVL (amount, 0) + NVL (attribute10, 0)) total
             FROM swgcnv_dd_ar_interface
            WHERE sales_center = p_sales_center
         GROUP BY sales_center
         ORDER BY 2;

      CURSOR b
      IS
         SELECT   sales_center, cust_trx_type_name, COUNT (*) transactions
                 ,SUM (NVL (amount, 0)) amt, SUM (NVL (attribute10, 0)) tax
                 ,SUM (NVL (amount, 0) + NVL (attribute10, 0)) total
                 ,tax_status
             FROM swgcnv_dd_ar_interface
            WHERE sales_center = p_sales_center
         GROUP BY cust_trx_type_name, tax_status, sales_center
         ORDER BY 6;

      CURSOR c
      IS
         SELECT   sales_center, cust_trx_type_name, COUNT (*) transactions
                 ,SUM (NVL (amount, 0)) amt, SUM (NVL (attribute10, 0)) tax
                 ,SUM (NVL (amount, 0) + NVL (attribute10, 0)) total
             FROM swgcnv_dd_ar_interface
            WHERE sales_center = p_sales_center
         GROUP BY cust_trx_type_name, sales_center
         ORDER BY 6;

      CURSOR d
      IS
         SELECT   orig_system_bill_customer_ref
                 ,orig_system_bill_address_ref, cust_trx_type_name
                 ,COUNT (*) transactions, SUM (NVL (amount, 0)) amt
                 ,SUM (NVL (attribute10, 0)) tax
                 ,SUM (NVL (amount, 0) + NVL (attribute10, 0)) total
                 ,tax_status
             FROM swgcnv_dd_ar_interface
            WHERE sales_center = p_sales_center
              AND orig_system_bill_customer_ref IN (
                     SELECT orig_system_bill_customer_ref
                       FROM swgcnv_dd_ar_history
                      WHERE sales_center = p_sales_center
                     MINUS
                     SELECT legacy_customer_number
                       FROM swgcnv_dd_temp_customers)
         GROUP BY cust_trx_type_name
                 ,tax_status
                 ,orig_system_bill_customer_ref
                 ,orig_system_bill_address_ref
         ORDER BY 1, 2;

      l_rpt1_cnt   NUMBER := 0;
      l_rpt2_cnt   NUMBER := 0;
      l_rpt3_cnt   NUMBER := 0;
      l_rpt4_cnt   NUMBER := 0;
   BEGIN
      fnd_client_info.set_org_context (2);
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 30, ' ')
                          || 'Pre Conversion AR Reports Ver.2'
                        );
      fnd_file.put_line (fnd_file.output
                        , RPAD (' ', 33, ' ') || 'Report Date :' || SYSDATE
                        );
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 30, ' ')
                          || '-------------------------------'
                        );
      fnd_file.put_line (fnd_file.output, ' ');
      fnd_file.put_line (fnd_file.output, ' ');
      fnd_file.put_line (fnd_file.output
                        ,    'Report1 : Total Transactons for the '
                          || p_sales_center
                          || ' Sales center'
                        );
      fnd_file.put_line (fnd_file.output, ' ');
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 5, ' ')
                          || 'Sales Center'
                          || '  '
                          || 'No of Trans'
                          || '  '
                          || ' Trans Amount '
                          || '  '
                          || 'TAX Amount'
                          || ' '
                          || '  Total Amount  '
                        );
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 5, ' ')
                          || RPAD ('=', 12, '=')
                          || '  '
                          || RPAD ('=', 11, '=')
                          || '  '
                          || LPAD ('=', 14, '=')
                          || '  '
                          || LPAD ('=', 10, '=')
                          || ' '
                          || LPAD ('=', 16, '=')
                        );
      fnd_file.put_line (fnd_file.output, ' ');

      FOR i IN a
      LOOP
         fnd_file.put_line (fnd_file.output
                           ,    RPAD (' ', 5, ' ')
                             || '  '
                             || RPAD (i.sales_center, 12, ' ')
                             || '  '
                             || RPAD (i.transactions, 11, ' ')
                             || '  '
                             || LPAD (i.amt, 14, ' ')
                             || '  '
                             || LPAD (i.tax, 10, ' ')
                             || ' '
                             || LPAD (i.total, 16, ' ')
                           );
         l_rpt1_cnt := l_rpt1_cnt + 1;
      END LOOP;                                                            --i

      IF l_rpt1_cnt = 0
      THEN
         fnd_file.put_line (fnd_file.output
                           , RPAD (' ', 30, ' ') || '*****No Data Found*****'
                           );
      END IF;

      fnd_file.put_line (fnd_file.output, ' ');
      fnd_file.put_line (fnd_file.output
                        ,    'Report2 : Total Transactons for the '
                          || p_sales_center
                          || ' Sales center TAX Status wise'
                        );
      fnd_file.put_line (fnd_file.output, ' ');
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 5, ' ')
                          || '  '
                          || 'Sales Center'
                          || ' '
                          || 'Transaction Type'
                          || ' '
                          || 'Tax Status'
                          || '  '
                          || 'No of Trans'
                          || '  '
                          || ' Trans Amount '
                          || '  '
                          || 'TAX Amount'
                          || ' '
                          || '  Total Amount  '
                        );
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 5, ' ')
                          || '  '
                          || RPAD ('=', 12, '=')
                          || ' '
                          || RPAD ('=', 16, '=')
                          || '  '
                          || RPAD ('=', 10, '=')
                          || '  '
                          || RPAD ('=', 11, '=')
                          || '  '
                          || LPAD ('=', 14, '=')
                          || '  '
                          || LPAD ('=', 10, '=')
                          || ' '
                          || LPAD ('=', 16, '=')
                        );
      fnd_file.put_line (fnd_file.output, ' ');

      FOR j IN b
      LOOP
         fnd_file.put_line (fnd_file.output
                           ,    RPAD (' ', 5, ' ')
                             || '  '
                             || RPAD (j.sales_center, 12, ' ')
                             || ' '
                             || RPAD (j.cust_trx_type_name, 16, ' ')
                             || '  '
                             || RPAD (j.tax_status, 10, ' ')
                             || '  '
                             || RPAD (j.transactions, 11, ' ')
                             || '  '
                             || LPAD (j.amt, 14, ' ')
                             || '  '
                             || LPAD (j.tax, 10, ' ')
                             || ' '
                             || LPAD (j.total, 16, ' ')
                           );
         l_rpt2_cnt := l_rpt2_cnt + 1;
      END LOOP;                                                            --i

      IF l_rpt2_cnt = 0
      THEN
         fnd_file.put_line (fnd_file.output
                           , RPAD (' ', 30, ' ') || '*****No Data Found*****'
                           );
      END IF;

      fnd_file.put_line (fnd_file.output, ' ');
--3)
      fnd_file.put_line (fnd_file.output
                        ,    'Report3 : Total Transactons for the '
                          || p_sales_center
                          || ' Sales center Transaction Type wise'
                        );
      fnd_file.put_line (fnd_file.output, ' ');
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 5, ' ')
                          || '  '
                          || 'Sales Center'
                          || ' '
                          || 'Transaction Type'
                          || '  '
                          || 'No of Trans'
                          || '  '
                          || ' Trans Amount '
                          || '  '
                          || 'TAX Amount'
                          || ' '
                          || '  Total Amount  '
                        );
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 5, ' ')
                          || '  '
                          || RPAD ('=', 12, '=')
                          || ' '
                          || RPAD ('=', 16, '=')
                          || '  '
                          || RPAD ('=', 11, '=')
                          || '  '
                          || LPAD ('=', 14, '=')
                          || '  '
                          || LPAD ('=', 10, '=')
                          || ' '
                          || LPAD ('=', 16, '=')
                        );
      fnd_file.put_line (fnd_file.output, ' ');

      FOR k IN c
      LOOP
         fnd_file.put_line (fnd_file.output
                           ,    RPAD (' ', 5, ' ')
                             || '  '
                             || RPAD (k.sales_center, 12, ' ')
                             || ' '
                             || RPAD (k.cust_trx_type_name, 16, ' ')
                             || '  '
                             || RPAD (k.transactions, 11, ' ')
                             || '  '
                             || LPAD (k.amt, 14, ' ')
                             || '  '
                             || LPAD (k.tax, 10, ' ')
                             || ' '
                             || LPAD (k.total, 16, ' ')
                           );
         l_rpt3_cnt := l_rpt3_cnt + 1;
      END LOOP;                                                            --i

      IF l_rpt3_cnt = 0
      THEN
         fnd_file.put_line (fnd_file.output
                           , RPAD (' ', 30, ' ') || '*****No Data Found*****'
                           );
      END IF;

      fnd_file.put_line (fnd_file.output, ' ');
--4)
      fnd_file.put_line (fnd_file.output, CHR (12));
      fnd_file.put_line (fnd_file.output
                        ,    'Report4 : Total Transactons for the '
                          || p_sales_center
                          || ' Sales center without Customers'
                        );
      fnd_file.put_line (fnd_file.output, ' ');
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 5, ' ')
                          || 'Legacy Customer'
                          || ' '
                          || 'Transaction Type'
                          || ' '
                          || 'Tax Status'
                          || '  '
                          || 'No of Trans'
                          || '  '
                          || ' Trans Amount '
                          || '  '
                          || 'TAX Amount'
                          || ' '
                          || '  Total Amount  '
                        );
      fnd_file.put_line (fnd_file.output
                        ,    RPAD (' ', 5, ' ')
                          || RPAD ('=', 15, '=')
                          || ' '
                          || RPAD ('=', 16, '=')
                          || '  '
                          || RPAD ('=', 10, '=')
                          || '  '
                          || RPAD ('=', 11, '=')
                          || '  '
                          || LPAD ('=', 14, '=')
                          || '  '
                          || LPAD ('=', 10, '=')
                          || ' '
                          || LPAD ('=', 16, '=')
                        );
      fnd_file.put_line (fnd_file.output, ' ');

      FOR l IN d
      LOOP
         fnd_file.put_line (fnd_file.output
                           ,    RPAD (' ', 5, ' ')
                             || RPAD (l.orig_system_bill_customer_ref, 15
                                     ,' ')
                             || ' '
                             || RPAD (l.cust_trx_type_name, 16, ' ')
                             || '  '
                             || RPAD (l.tax_status, 10, ' ')
                             || '  '
                             || RPAD (l.transactions, 11, ' ')
                             || '  '
                             || LPAD (l.amt, 14, ' ')
                             || '  '
                             || LPAD (l.tax, 10, ' ')
                             || ' '
                             || LPAD (l.total, 16, ' ')
                           );
         l_rpt4_cnt := l_rpt4_cnt + 1;
      END LOOP;                                                            --i

      IF l_rpt4_cnt = 0
      THEN
         fnd_file.put_line (fnd_file.output
                           , RPAD (' ', 30, ' ') || '*****No Data Found*****'
                           );
      END IF;

      fnd_file.put_line (fnd_file.output, ' ');
      fnd_file.put_line (fnd_file.output
                        , RPAD (' ', 30, ' ') || '*****End of Report*****'
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'ERR for : ' || SQLERRM);
   END swgcnv_ar_preconv_reports1;

--
   PROCEDURE swgcnv_seq_prog (
      out_errbuf_s      OUT      VARCHAR2
     ,out_errnum_n      OUT      NUMBER
     ,p_legacy_system   IN       VARCHAR2
     ,p_sales_center    IN       VARCHAR2
   )
   IS
      l_request_id1       NUMBER         := NULL;
      l_phase1            VARCHAR2 (20);
      l_status1           VARCHAR2 (20);
      l_dev_phase1        VARCHAR2 (20);
      l_dev_status1       VARCHAR2 (20);
      l_message1          VARCHAR2 (100);
      l_status_b1         BOOLEAN;
      l_request_id2       NUMBER         := NULL;
      l_phase2            VARCHAR2 (20);
      l_status2           VARCHAR2 (20);
      l_dev_phase2        VARCHAR2 (20);
      l_dev_status2       VARCHAR2 (20);
      l_message2          VARCHAR2 (100);
      l_status_b2         BOOLEAN;
      l_request_id3       NUMBER         := NULL;
      l_phase3            VARCHAR2 (20);
      l_status3           VARCHAR2 (20);
      l_dev_phase3        VARCHAR2 (20);
      l_dev_status3       VARCHAR2 (20);
      l_message3          VARCHAR2 (100);
      l_status_b3         BOOLEAN;
      l_request_id4       NUMBER         := NULL;
      l_phase4            VARCHAR2 (20);
      l_status4           VARCHAR2 (20);
      l_dev_phase4        VARCHAR2 (20);
      l_dev_status4       VARCHAR2 (20);
      l_message4          VARCHAR2 (100);
      l_status_b4         BOOLEAN;
      l_request_id5       NUMBER         := NULL;
      l_phase5            VARCHAR2 (20);
      l_status5           VARCHAR2 (20);
      l_dev_phase5        VARCHAR2 (20);
      l_dev_status5       VARCHAR2 (20);
      l_message5          VARCHAR2 (100);
      l_status_b5         BOOLEAN;
      l_request_id6       NUMBER         := NULL;
      l_phase6            VARCHAR2 (20);
      l_status6           VARCHAR2 (20);
      l_dev_phase6        VARCHAR2 (20);
      l_dev_status6       VARCHAR2 (20);
      l_message6          VARCHAR2 (100);
      l_status_b6         BOOLEAN;
      error_encountered   EXCEPTION;
      l_error_reqid       VARCHAR2 (100);
   BEGIN
--1st
      l_request_id1 :=
         fnd_request.submit_request ('SWGCNV'
                                    ,'SWGCNV_AR_POSTUPDATE1'
                                    ,'SWGCNV_AR_POSTUPDATE1'
                                    ,NULL
                                    ,NULL
                                    ,p_sales_center
                                    );
      COMMIT;
      fnd_file.put_line (fnd_file.LOG, l_request_id1);

      LOOP
         l_status_b1 :=
            fnd_concurrent.wait_for_request (l_request_id1
                                            ,15
                                            ,15
                                            ,l_phase1
                                            ,l_status1
                                            ,l_dev_phase1
                                            ,l_dev_status1
                                            ,l_message1
                                            );
         EXIT WHEN l_dev_phase1 = 'COMPLETE';
      END LOOP;

      fnd_file.put_line (fnd_file.LOG
                        ,    'Status of the first conc prog  : '
                          || l_dev_phase1
                          || ' '
                          || l_dev_status1
                        );

--2nd
      IF     l_dev_phase1 = 'COMPLETE'
         AND l_dev_status1 = 'NORMAL'
         AND l_request_id1 <> 0
      THEN
         l_request_id2 :=
            fnd_request.submit_request ('SWGCNV'
                                       ,'SWGCNV_AR_POSTUPDATE2'
                                       ,'SWGCNV_AR_POSTUPDATE2'
                                       ,NULL
                                       ,NULL
                                       ,p_sales_center
                                       );
         COMMIT;
      ELSE
         l_error_reqid := ' GOT ERROR ' || l_request_id1;
         RAISE error_encountered;
      END IF;                                                                --

      fnd_file.put_line (fnd_file.LOG, l_request_id2);

      LOOP
         l_status_b2 :=
            fnd_concurrent.wait_for_request (l_request_id2
                                            ,15
                                            ,15
                                            ,l_phase2
                                            ,l_status2
                                            ,l_dev_phase2
                                            ,l_dev_status2
                                            ,l_message2
                                            );
         EXIT WHEN l_dev_phase2 = 'COMPLETE';
      END LOOP;

      fnd_file.put_line (fnd_file.LOG
                        ,    'Status of the first conc prog  : '
                          || l_dev_phase2
                          || ' '
                          || l_dev_status2
                        );

--3rd
      IF     l_dev_phase2 = 'COMPLETE'
         AND l_dev_status2 = 'NORMAL'
         AND l_request_id2 <> 0
      THEN
         l_request_id3 :=
            fnd_request.submit_request ('SWGCNV'
                                       ,'SWGCNV_POSTUPDATE_RECEIPT'
                                       ,'SWGCNV_POSTUPDATE_RECEIPT'
                                       ,NULL
                                       ,NULL
                                       ,p_sales_center
                                       );
         COMMIT;
      ELSE
         l_error_reqid := ' GOT ERROR ' || l_request_id2;
         RAISE error_encountered;
      END IF;                                                                --

      fnd_file.put_line (fnd_file.LOG, l_request_id3);

      LOOP
         l_status_b3 :=
            fnd_concurrent.wait_for_request (l_request_id3
                                            ,15
                                            ,15
                                            ,l_phase3
                                            ,l_status3
                                            ,l_dev_phase3
                                            ,l_dev_status3
                                            ,l_message3
                                            );
         EXIT WHEN l_dev_phase3 = 'COMPLETE';
      END LOOP;

      fnd_file.put_line (fnd_file.LOG
                        ,    'Status of the first conc prog  : '
                          || l_dev_phase3
                          || ' '
                          || l_dev_status3
                        );

--4th
      IF     l_dev_phase3 = 'COMPLETE'
         AND l_dev_status3 = 'NORMAL'
         AND l_request_id3 <> 0
      THEN
         l_request_id4 :=
            fnd_request.submit_request ('SWGCNV'
                                       ,'SWGCNV_STATEMENT_PROGRAM'
                                       ,'SWGCNV_STATEMENT_PROGRAM'
                                       ,NULL
                                       ,NULL
                                       ,p_legacy_system
                                       ,p_sales_center
                                       );
         COMMIT;
      ELSE
         l_error_reqid := ' GOT ERROR ' || l_request_id3;
         RAISE error_encountered;
      END IF;                                                                --

      fnd_file.put_line (fnd_file.LOG, l_request_id4);

      LOOP
         l_status_b4 :=
            fnd_concurrent.wait_for_request (l_request_id4
                                            ,15
                                            ,15
                                            ,l_phase4
                                            ,l_status4
                                            ,l_dev_phase4
                                            ,l_dev_status4
                                            ,l_message4
                                            );
         EXIT WHEN l_dev_phase4 = 'COMPLETE';
      END LOOP;

      fnd_file.put_line (fnd_file.LOG
                        ,    'Status of the first conc prog  : '
                          || l_dev_phase4
                          || ' '
                          || l_dev_status4
                        );

--5th
      IF     l_dev_phase4 = 'COMPLETE'
         AND l_dev_status4 = 'NORMAL'
         AND l_request_id4 <> 0
      THEN
         l_request_id5 :=
            fnd_request.submit_request ('SWGCNV'
                                       ,'SWGCNV_STAT_PERIOD_UPDATE'
                                       ,'SWGCNV_STAT_PERIOD_UPDATE'
                                       ,NULL
                                       ,NULL
                                       ,p_sales_center
                                       );
         COMMIT;
      ELSE
         l_error_reqid := ' GOT ERROR ' || l_request_id4;
         RAISE error_encountered;
      END IF;                                                                --

      fnd_file.put_line (fnd_file.LOG, l_request_id5);

      LOOP
         l_status_b5 :=
            fnd_concurrent.wait_for_request (l_request_id5
                                            ,15
                                            ,15
                                            ,l_phase5
                                            ,l_status5
                                            ,l_dev_phase5
                                            ,l_dev_status5
                                            ,l_message5
                                            );
         EXIT WHEN l_dev_phase5 = 'COMPLETE';
      END LOOP;

      fnd_file.put_line (fnd_file.LOG
                        ,    'Status of the first conc prog  : '
                          || l_dev_phase5
                          || ' '
                          || l_dev_status5
                        );

--6th
      IF     l_dev_phase5 = 'COMPLETE'
         AND l_dev_status5 = 'NORMAL'
         AND l_request_id5 <> 0
      THEN
         l_request_id6 :=
            fnd_request.submit_request ('SWGCNV'
                                       ,'SWGCNV_LAST_MSI_BILLTO'
                                       ,'SWGCNV_LAST_MSI_BILLTO'
                                       ,NULL
                                       ,NULL
                                       ,p_legacy_system
                                       ,p_sales_center
                                       );
         COMMIT;
      ELSE
         l_error_reqid := ' GOT ERROR ' || l_request_id5;
         RAISE error_encountered;
      END IF;                                                                --

      fnd_file.put_line (fnd_file.LOG, l_request_id6);

      LOOP
         l_status_b6 :=
            fnd_concurrent.wait_for_request (l_request_id6
                                            ,15
                                            ,15
                                            ,l_phase6
                                            ,l_status6
                                            ,l_dev_phase6
                                            ,l_dev_status6
                                            ,l_message6
                                            );
         EXIT WHEN l_dev_phase6 = 'COMPLETE';
      END LOOP;

      fnd_file.put_line (fnd_file.LOG
                        ,    'Status of the first conc prog  : '
                          || l_dev_phase6
                          || ' '
                          || l_dev_status6
                        );
   EXCEPTION
      WHEN error_encountered
      THEN
         fnd_file.put_line (fnd_file.LOG, 'ERROR : ' || l_error_reqid);
      WHEN NO_DATA_FOUND
      THEN
         fnd_file.put_line (fnd_file.LOG, 'No Data found : ' || SQLERRM);
         out_errnum_n := 2;
         out_errbuf_s := SQLERRM;
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Others : ' || SQLERRM);
         out_errnum_n := 2;
         out_errbuf_s := SQLERRM;
   END swgcnv_seq_prog;
END swgcnv_ar_conv_pkg;
/

EXIT
/
