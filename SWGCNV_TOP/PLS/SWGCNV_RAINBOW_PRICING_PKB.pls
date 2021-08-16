CREATE OR REPLACE PACKAGE BODY APPS.SWGCNV_RAINBOW_PRICING_PKG
AS
   /* $Header:  SWGCNV_RAINBOW_PRICING_PKB.pls 1.0 2016/03/01 09:33:33 PU $ */
   /*==========================================================================+
   | Copyright (c) 2016 DS Waters, Atlanta, GA 30328 USA All rights reserved.  |
   +===========================================================================+
   |                                                                           |
   | File Name:     SWGCNV_RAINBOW_PRICING_PKB.pls                             |
   | Name:          SWGCNV_RAINBOW_PRICING_PKG                                 |
   | Description:   Rainbow Special Pricing for Acquisition Customers          |
   | Copyright:     Copyright(c) DS Services                                   |
   | Company:       DS Services                                                |
   | Author:        Michael Schenk                                             |
   | Date:          03/01/2016                                                 |
   |                                                                           |
   | Revision History:                                                         |
   | Date        Author          PN#   Change Description                      |
   | ---------   ----------      ----  ------------------------                |
   | 03/01/2016  Mike Schenk     1760  Initial version                         |
   | 06/08/2016  Mike Schenk     1929  fix subquery                            |
   +==========================================================================*/

PROCEDURE  SWGCNV_CREATE_PRICING(
                                 ou_err_buff_s    OUT    VARCHAR2
                                ,ou_err_code_n    OUT    NUMBER
                                ,in_legacy_code_s IN     VARCHAR2
                               ) IS
CURSOR c_sprice (in_legacy_code_s IN VARCHAR2) IS
SELECT 
     cust.account_number,
     cust.cust_account_id,
     sp.ship_to_site_use_id,
     sp.inventory_item_id,
     sp.special_price_reason,
     itm.segment1,
     itm.description,
     NVL((SELECT distinct itm1.segment1
      FROM
          mtl_system_items itm1,
          mtl_related_items rel
      WHERE
          rel.related_item_id = sp.inventory_item_id
      AND itm.segment1 LIKE '6%'
      AND rel.organization_id = 5
      AND itm1.inventory_item_id = rel.inventory_item_id
      AND itm1.organization_id = 5),itm.segment1)  non_rental_item,
      map.old_code,
      map.new_code,
      sp.special_price,
      sp.start_date_active
   FROM
     hz_cust_accounts cust,
     mtl_system_items itm,
     swg_special_pricing sp,
     swgcnv_map map
   WHERE
     sp.customer_id = cust.cust_account_id
   AND sp.ship_to_site_use_id <> 0
   AND sp.special_price_reason = 'CONVERSION'
   AND cust.orig_system_reference LIKE 'DD-'||in_legacy_code_s||'%'
   AND itm.inventory_item_id = sp.inventory_item_id
   AND itm.organization_id = 5
   AND map.new_code = NVL((SELECT distinct itm1.segment1
                           FROM
                               mtl_system_items itm1,
                               mtl_related_items rel
                           WHERE
                               rel.related_item_id = sp.inventory_item_id
                           AND itm1.segment1 LIKE '6%'                      --MTS 1929
                           AND rel.organization_id = 5
                           AND itm1.inventory_item_id = rel.inventory_item_id
                           AND itm1.organization_id = 5),itm.segment1)
    AND map.type_code = 'SPEC_PRC'
    AND map.system_code = in_legacy_code_s
    --    and sp.ship_to_site_use_id = 15172455
 AND EXISTS
    (SELECT 1
     FROM swgcnv_map map1
     WHERE
          map1.system_code = map.system_code
     AND  map1.old_code = map.old_code
     AND  map1.new_code <> map.new_code)
--  and itm.segment1 like '6%'
;

CURSOR c_rprice (in_system_code_s IN VARCHAR2, in_old_code_s IN VARCHAR2, in_item_s IN VARCHAR2) IS  
SELECT 
    map.new_code,
    itm.inventory_item_id,
    itm.segment1,
    (SELECT 
         itm1.segment1
      FROM
         mtl_system_items itm1,
         mtl_related_items rel
      WHERE
          rel.inventory_item_id = itm.inventory_item_id
      AND rel.organization_id = 5
      AND itm1.inventory_item_id = rel.related_item_id
      AND itm1.organization_id = 5
      AND itm.segment1 LIKE '4%')rental_item_code,
      (SELECT 
         itm1.inventory_item_id
      FROM
         mtl_system_items itm1,
         mtl_related_items rel
      WHERE
          rel.inventory_item_id = itm.inventory_item_id
      AND rel.organization_id = 5
      AND itm1.inventory_item_id = rel.related_item_id
      AND itm1.organization_id = 5
      AND itm.segment1 LIKE '4%')related_item_id
      FROM
    swgcnv_map map,
    mtl_system_items itm
    --mtl_related_items rel,
    --mtl_system_items itm1
WHERE
    itm.segment1 = map.new_code
AND itm.organization_id = 5
AND map.system_code = in_system_code_s
AND map.type_code = 'SPEC_PRC'
AND map.old_code = in_old_code_s
AND map.new_code <> in_item_s
--AND rel.inventory_item_id(+) = itm.inventory_item_id
--AND rel.organization_id(+) = 5
--AND itm1.inventory_item_id(+) = rel.related_item_id
--AND itm1.organization_id(+) = 5
;

CURSOR c_msrp (in_item_id_n NUMBER, in_site_use_id_n NUMBER) IS
      SELECT
         operand 
      FROM
          hz_cust_site_uses_all su,
          qp_list_lines_v  qllv
      WHERE
          qllv.list_header_id = su.price_list_id
      AND su.site_use_id = in_site_use_id_n
      AND SYSDATE BETWEEN qllv.start_date_active AND NVL(qllv.end_date_active,SYSDATE + 1)
      AND qllv.product_attr_value = in_item_id_n;
            
TYPE l_sprice_tbl IS TABLE OF c_sprice%ROWTYPE INDEX BY BINARY_INTEGER;
l_sprice_tab l_sprice_tbl;

l_sprice_item_id_n NUMBER;
--l_sprice_item_code_s VARCHAR2(30);
l_msrp_n NUMBER;
l_rec_cnt_n NUMBER;
l_message_s VARCHAR2(2000);

BEGIN
  l_message_s := 'Ship To|Item#|Price';
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_message_s);
	OPEN c_sprice (in_legacy_code_s);
	FETCH c_sprice BULK COLLECT INTO l_sprice_tab;
	CLOSE c_sprice;
	 
	FOR idx IN 1..l_sprice_tab.COUNT LOOP
	    FOR l_rprice_rec IN c_rprice(in_legacy_code_s,l_sprice_tab(idx).old_code,l_sprice_tab(idx).non_rental_item) LOOP
	        IF l_sprice_tab(idx).non_rental_item LIKE '4%' THEN
	           l_sprice_item_id_n := l_rprice_rec.related_item_id;
          ELSE
             l_sprice_item_id_n := l_rprice_rec.inventory_item_id;
          END IF;


          OPEN c_msrp (l_sprice_item_id_n,l_sprice_tab(idx).ship_to_site_use_id);
          FETCH c_msrp INTO l_msrp_n;
         BEGIN
          IF 	c_msrp%FOUND THEN	    
              INSERT INTO  swg_special_pricing( special_pricing_id
																				,customer_id
																				,ship_to_site_use_id
																				,inventory_item_id
																				,start_date_active
																				,pricing_mechanism
																				,special_price
																				,creation_time_list_price
																				,bid_flag
																				,special_price_reason
																				,pricing_source
																				,created_by
																				,creation_date
																				,last_updated_by
																				,last_update_date
																				,last_update_login
																				,sp_parent_itm_id)
              VALUES
																        (swg_special_pricing_s1.NEXTVAL
                                        ,l_sprice_tab(idx).cust_account_id
                                        ,l_sprice_tab(idx).ship_to_site_use_id
                                        ,l_sprice_item_id_n
                                        ,l_sprice_tab(idx).start_date_active
                                        ,'NEW'
                                        ,l_sprice_tab(idx).special_price
                                        ,l_msrp_n
                                        ,'N'
                                        ,'CONVERSION'
                                        ,'CONVERSION'
                                        ,fnd_global.user_id
                                        ,sysdate
                                        ,fnd_global.user_id
                                        ,sysdate
                                        ,fnd_global.login_id
                                        ,l_sprice_tab(idx).inventory_item_id
																				);  
						   COMMIT;
						  l_message_s := l_sprice_tab(idx).ship_to_site_use_id||'|'||l_sprice_tab(idx).new_code||'|'||l_sprice_tab(idx).special_price;
						  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_message_s);
		   END IF;
		   EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
		      l_message_s := 'Error duplicate rainbow special price not created  ship_to: '||l_sprice_tab(idx).ship_to_site_use_id||' Item: '||l_sprice_tab(idx).new_code;
		      FND_FILE.PUT_LINE(FND_FILE.LOG,l_message_s);
		      WHEN OTHERS THEN
		      l_message_s := 'Unexpected error creating rainbow special price ship_to: '||l_sprice_tab(idx).ship_to_site_use_id||' Item: '||l_sprice_tab(idx).new_code;
		      FND_FILE.PUT_LINE(FND_FILE.LOG,l_message_s);
		   END;
		   CLOSE c_msrp;
       l_msrp_n := NULL;
	    END LOOP; 
  END LOOP;
END SWGCNV_CREATE_PRICING;
END SWGCNV_RAINBOW_PRICING_PKG;	 
/
SHOW ERRORS
EXIT
   