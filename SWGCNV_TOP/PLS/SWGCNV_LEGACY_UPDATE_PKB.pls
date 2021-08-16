CREATE OR REPLACE PACKAGE BODY SWGCNV_LEGACY_UPDATE_PKG
AS

PROCEDURE UPD_ROUTES      (
                           in_legacy_system_s  IN     VARCHAR2
                          )
IS
BEGIN
  NULL;
END;

PROCEDURE UPD_CUSTOMERS   (
                           in_legacy_system_s  IN     VARCHAR2
                          )
IS
BEGIN
  NULL;
END;

PROCEDURE UPD_CYCLE_DAY   (
                           in_legacy_system_s  IN     VARCHAR2
                          )
IS

FUNCTION get_first_cycle_day (in_cycle_day_n NUMBER) RETURN NUMBER;
  
CURSOR c_svc_days_e1w IS
       SELECT
             scd.customer_id,
             scd.shipping_site_id,
             scd.route_service_day,
             nvl(scd.route_sequence,999) route_sequence,
             scd.cycle_day,
             scd.driving_instructions,
             smap.old_code,
             smap.NEW_CODE,
             pc.delivery_frequency
       FROM
             swgcnv.swgcnv_dd_cycledays     scd,
             swgcnv.swgcnv_map              smap,
             swgcnv_dd_customer_interface   ci,
             swgcnv_dd_cb_prestaging_cust   pc,
             swgcnv_map                    smap1  
       WHERE
             scd.cycle_day           =   smap.old_code
       AND   smap.type_code          =   'RTSRVDAY'
       AND   smap.system_code        =   in_legacy_system_s
       AND   ci.customer_id          =   scd.customer_id
       AND   pc.customer_number      =   ci.customer_number
       AND   pc.delivery_frequency   =   smap1.old_code
       AND   smap1.system_code       =   in_legacy_system_s
       AND   smap1.type_code         =   'DELFREQ'
       AND   smap1.new_code          =   'E1W';

CURSOR c_svc_days_e2w IS
       SELECT  
             scd.customer_id,
             scd.shipping_site_id,
             scd.route_service_day,
             nvl(scd.route_sequence,999) route_sequence,
             scd.cycle_day,
             scd.driving_instructions,
             smap.old_code,
             smap.new_code,
             pc.delivery_frequency,
             CASE WHEN  smap.new_code < 11 then smap.new_code + 10
             ELSE smap.new_code - 10
             END              new_cycle_day
       FROM   
             swgcnv.swgcnv_dd_cycledays     scd,
             swgcnv.swgcnv_map              smap,
             swgcnv_dd_customer_interface   ci,
             swgcnv_dd_cb_prestaging_cust   pc,
             swgcnv_map                    smap1   
       WHERE   
             scd.cycle_day           =   smap.old_code
       AND   smap.type_code          =   'RTSRVDAY'
       AND   smap.system_code        =   in_legacy_system_s
       AND   ci.customer_id          =   scd.customer_id
       AND   pc.customer_number      =   ci.customer_number
       AND   pc.delivery_frequency   =   smap1.old_code
       AND   smap1.system_code       =   in_legacy_system_s
       AND   smap1.type_code         =   'DELFREQ'
       AND   smap1.new_code          =   'E2W';   



   TYPE l_cycle_day_table IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
   l_cycle_day_tab l_cycle_day_table;


FUNCTION get_first_cycle_day (in_cycle_day_n NUMBER) RETURN NUMBER IS
    l_cycle_day_n NUMBER;
BEGIN
   l_cycle_day_n := in_cycle_day_n;
   LOOP
      IF l_cycle_day_n <= 5 THEN
         RETURN l_cycle_day_n;
      ELSE
         l_cycle_day_n := l_cycle_day_n - 5;
      END IF;
  END LOOP;
END get_first_cycle_day;

BEGIN

FOR svc_days_rec_e1w IN c_svc_days_e1w LOOP
    l_cycle_day_tab(1) := get_first_cycle_day(svc_days_rec_e1w.new_code);
    l_cycle_day_tab(2) := l_cycle_day_tab(1) + 5;
    l_cycle_day_tab(3) := l_cycle_day_tab(1) + 10;
    l_cycle_day_tab(4) := l_cycle_day_tab(1) + 15;
    
    FOR idx IN 1 .. 4 LOOP
        IF l_cycle_day_tab(idx) <> svc_days_rec_e1w.new_code THEN
           INSERT INTO
                  swgcnv.swgcnv_dd_cycledays
           VALUES
                 (svc_days_rec_e1w.customer_id,
                  svc_days_rec_e1w.SHIPPING_SITE_ID,
                  l_cycle_day_tab(idx),
                  svc_days_rec_e1w.ROUTE_SEQUENCE,
                  l_cycle_day_tab(idx),
                  svc_days_rec_e1w.driving_instructions);
        END IF;    
    END LOOP;
END LOOP;

FOR svc_days_rec_e2w IN c_svc_days_e2w LOOP
        INSERT
        INTO swgcnv.swgcnv_dd_cycledays
        VALUES
             (svc_days_rec_e2w.customer_id,
              svc_days_rec_e2w.SHIPPING_SITE_ID,
              svc_days_rec_e2w.new_cycle_day,
              svc_days_rec_e2w.ROUTE_SEQUENCE,
              svc_days_rec_e2w.new_cycle_day,
              svc_days_rec_e2w.driving_instructions);
    END LOOP;         
    COMMIT;
    --ROLLBACK;
END UPD_CYCLE_DAY;   


PROCEDURE UPD_EQUIPMENT   (
                           in_legacy_system_s  IN     VARCHAR2
                          )
IS
BEGIN
  NULL;
END;

PROCEDURE UPD_PP_AVG_ORDER(
                           in_legacy_system_s  IN     VARCHAR2 
                          )
IS

CURSOR cur_avg_ord_data
IS 
SELECT sda.*,suc.*
  FROM swgcnv.swgcnv_dd_avrg_order sda,
       swgcnv.swgcnv_uom_conv_list suc
 WHERE sda.item_code = suc.std_item_nbr;

BEGIN

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'CUSTOMER_NUMBER|DELIVERY_NUMBER|ITEM_CODE');

FOR l_avg_ord_data IN cur_avg_ord_data
LOOP

UPDATE swgcnv_dd_avrg_order
   SET average_qty              = (average_qty*l_avg_ord_data.multiply_factor)
 WHERE customer_number          = l_avg_ord_data.customer_number
   AND delivery_location_number = l_avg_ord_data.delivery_location_number
   AND item_code                = l_avg_ord_data.item_code;

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_avg_ord_data.customer_number
                                   ||'|'||l_avg_ord_data.delivery_location_number
                                   ||'|'||l_avg_ord_data.item_code);

COMMIT;

END LOOP;

EXCEPTION WHEN OTHERS 
THEN

	FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error: '||SQLERRM);

END;

PROCEDURE UPD_BOH         (
                           in_legacy_system_s  IN     VARCHAR2
                          )
IS
BEGIN
  NULL;
END;

PROCEDURE UPD_PRICING     (
                           in_legacy_system_s  IN     VARCHAR2 
                          )
IS

CURSOR cur_spcl_prc_data
IS 
SELECT ssp.*,suc.*
  FROM swgcnv.swgcnv_dd_special_price ssp,
       swgcnv.swgcnv_uom_conv_list suc
 WHERE ssp.item_code = suc.std_item_nbr;

BEGIN

--1.	Special Price Start Date must = “System Date” at the time of the record creation.
--2.	If the Special price Start date = 01/01/0001 , Update to System Date.
--3.	If the special price end date = 12/31/999, update record to ‘NULL’.
update swgcnv.swgcnv_dd_special_price a
set   valid_to_date = NULL
where valid_to_date = '31-dec-9999';
    
update swgcnv.swgcnv_dd_special_price a
set   valid_from_date = TRUNC(sysdate);

update swgcnv.swgcnv_dd_special_price a
set    orig_customer_number  = customer_number;

FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'CUSTOMER_NUMBER|DELIVERY_NUMBER|ITEM_CODE');

FOR l_spcl_prc_data IN cur_spcl_prc_data
LOOP

UPDATE swgcnv_dd_special_price
   SET special_price            = (special_price/l_spcl_prc_data.multiply_factor)
 WHERE customer_number          = l_spcl_prc_data.customer_number
   AND delivery_location_number = l_spcl_prc_data.delivery_location_number
   AND item_code                = l_spcl_prc_data.item_code;

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_spcl_prc_data.customer_number
                                   ||'|'||l_spcl_prc_data.delivery_location_number
                                   ||'|'||l_spcl_prc_data.item_code);
COMMIT;

END LOOP;

EXCEPTION WHEN OTHERS 
THEN

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error: '||SQLERRM);

END;


PROCEDURE UPD_NOTES       (
                           in_legacy_system_s  IN     VARCHAR2 
                          )
IS
BEGIN
  NULL;
END;

PROCEDURE UPD_AR          (
                           in_legacy_system_s  IN     VARCHAR2 
                          )
IS
BEGIN
  NULL;
END;

PROCEDURE POST_UPDATES    (
                           in_legacy_system_s  IN     VARCHAR2 
                          )
IS
--update 220 customers to MATCH 1 to 1 if they are not recurring CC
CURSOR get_account
IS
SELECT oracle_customer_id, legacy_customer_number, oracle_customer_number 
FROM   swgcnv.swgcnv_dd_temp_customers tc,
       swgcnv_dd_cb_prestaging_cust cusl   
WHERE  cusl.customer_type   = '200'
AND    cusl.customer_number = tc.legacy_customer_number
AND NOT EXISTS ( select 1 from SWGCNV_DD_CUSTOMER_CREDITCARD CC WHERE cc.customer_number = legacy_customer_number );
--
BEGIN

     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'MOVING TO MATCH ONE TO ONE');
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'legacy_customer_number|oracle_customer_number');

  FOR I in get_account LOOP

     UPDATE hz_customer_profiles
     SET    autocash_hierarchy_id = 1000, autocash_hierarchy_id_for_adr = 1000
     WHERE  cust_account_id       = i.oracle_customer_id;

     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,i.legacy_customer_number||'|'||i.oracle_customer_number);

  END LOOP;

  FOR t in ( SELECT tc.oracle_customer_id FROM swgcnv_dd_temp_customers tc ) LOOP
     UPDATE  hz_cust_accounts a
     SET     attribute11       = 'P'
     WHERE   a.cust_account_id =  t.oracle_customer_id;
  END LOOP;

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'CAPTURE and PRINT SIGNATURE SET KC'); 

      UPDATE hz_cust_site_uses_all 
      SET attribute7 = 'USB' 
      WHERE orig_system_reference LIKE 'DD-IBM01%' 
      AND site_use_code = 'BILL_TO'
      AND attribute7 != 'USB';

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'REMIT TO BANK UPDATE FOR KW'); 

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');



END;

PROCEDURE UPD_MAIN_LEGACY ( 
                           ou_errbuf_s         OUT    VARCHAR2,
                           ou_errnum_n         OUT    NUMBER,
                           in_legacy_system_s  IN     VARCHAR2,
                           in_route_s          IN     VARCHAR2,
                           in_customer_s       IN     VARCHAR2,
                           in_equipment_s      IN     VARCHAR2,
                           in_pp_avg_order_s   IN     VARCHAR2,
                           in_boh_s            IN     VARCHAR2,
                           in_special_price_s  IN     VARCHAR2,
                           in_notes_s          IN     VARCHAR2,
                           in_ar_s             IN     VARCHAR2,
                           in_cycleday_s       IN     VARCHAR2,
                           in_post_s           IN     VARCHAR2
                          )
IS                          
BEGIN

  IF in_route_s = 'Y' THEN


  
    UPD_ROUTES       (
                               in_legacy_system_s =>  in_legacy_system_s
                     );
  
  END IF;
  
  IF in_customer_s = 'Y' THEN
  
    UPD_CUSTOMERS       (
                               in_legacy_system_s =>  in_legacy_system_s
                        );
  
  END IF;
  
  IF in_equipment_s = 'Y' THEN
  
    UPD_EQUIPMENT      (
                               in_legacy_system_s =>  in_legacy_system_s
                        );
  
  END IF;
  
  IF in_pp_avg_order_s = 'Y' THEN
  
    UPD_PP_AVG_ORDER    (
                               in_legacy_system_s =>  in_legacy_system_s
                        );

  
  
  END IF;
  
  IF in_boh_s = 'Y' THEN
  
    UPD_BOH         (
                               in_legacy_system_s =>  in_legacy_system_s
                     );
  
  END IF;
  
  IF in_special_price_s = 'Y' THEN

    fnd_file.put_line(FND_FILE.OUTPUT,'Special Pricing Update');
  
    UPD_PRICING      (
                               in_legacy_system_s =>  in_legacy_system_s
                     );
  
  END IF;
  
  IF in_notes_s = 'Y' THEN
  
    UPD_NOTES       (
                               in_legacy_system_s =>  in_legacy_system_s
                     );
  
  END IF;
  
  IF in_ar_s  = 'Y' THEN
  
    UPD_AR           (
                               in_legacy_system_s =>  in_legacy_system_s
                     );
  
  END IF;

  IF in_cycleday_s  = 'Y' THEN
  
    UPD_CYCLE_DAY    (
                               in_legacy_system_s =>  in_legacy_system_s
                     );
  
  END IF;

  IF in_post_s  = 'Y' THEN
  
    POST_UPDATES     (
                               in_legacy_system_s =>  in_legacy_system_s
                     );
  
  END IF;

EXCEPTION

    WHEN OTHERS THEN
    
    fnd_file.put_line(FND_FILE.OUTPUT,'Unexpected Error: '||dbms_utility.format_error_backtrace);
    
    ou_errbuf_s   :=   dbms_utility.format_error_backtrace;
    ou_errnum_n   :=   2;
    
END  upd_main_legacy;

END swgcnv_legacy_update_pkg;
/

SHOW ERRORS

EXIT;



