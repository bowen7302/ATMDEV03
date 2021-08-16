create or replace
PACKAGE BODY Swgcnv_Pricelist_Pkg
IS
/*===============================================================================+
| Copyright (c) 2005 DS Waters, Atlanta, GA 30328 USA All rights reserved.       |
+================================================================================+
|                                                                                |
| File Name:     SWGCNV_PRICELIST_PKG.pls                                        |
| Description:   Converion AR Package                                            |
|                                                                                |
| Revision History:                                                              |
| Date        Author          Change Description                                 |
| ---------   ----------      -------------------------------------------        |
| 03/20/2012  Stephen Bowen   Conversion for Pricing                             |
| 07/2/2012   Stephen Bowen   WO20477  Retrieving date value from input record,  |
|                             no longer using default from Price List Header     |
| 07/23/2012  Stephen Bowen   WO20550  Retrieving date value from input record,  |
|                             no longer using default from Price List Header     |
| 08/09/2012  Mohan Abburu    WO#20601: End date price list items before adding. |
| 12/11/2012  Ramprasad Kadiyala    WO#21053 End dating List lines and adding    |
|                                   them with new price for selected MSRP Lists  |
| 01/08/2012  Ramprasad Kadiyala    WO#21115 Update MSRP_STATUS based upon       |
|                                    success and failure of price list effective |
|                                    dates adjustment                            |
| 06/06/2013  Stephen Bowen   WO21460 Performance issue cur_list_lines           |
+===============================================================================*/

g_swg_sts_success                   CONSTANT VARCHAR2 (1)               := 'S';
g_swg_sts_error                     CONSTANT NUMBER                     := 3;


PROCEDURE SWG_PRICE_REQUEST (
                ou_errbuff_s         OUT      VARCHAR2,
                ou_errcode_n         OUT      NUMBER,
                in_nm_list_s         IN       VARCHAR2,
                in_request_id_n      IN       NUMBER,
                in_tab_data_s        IN       VARCHAR2
                             )
IS

l_item_list_s      LONG;            --:= '45100103|PD - THE HOME DEPOT|2|07/02/2012'
l_cur_pos          NUMBER         := 1;
l_pos_n            NUMBER         := 0;
l_pos_n_pipe       NUMBER         := 0;
l_tot_length       NUMBER         := 0;
l_tot_length_app   NUMBER         := 0;
l_temp             NUMBER         := 0;
l_temp1            NUMBER         := 0;
l_created_by_n     NUMBER         := 0;
l_item_code_s      VARCHAR2 (40)  := 0;
l_value_s          VARCHAR2 (2000);
io_err_stat_s      VARCHAR2(5)    := NULL;
io_err_msg_s       VARCHAR2(5000) := NULL;

l_price_name_s     VARCHAR2 (500);
l_item_price_n     NUMBER         := 0;
l_start_date_d     DATE;
l_preferred_s      VARCHAR2 (100);
l_cu_order_s       VARCHAR2 (100);
l_cu_line_s        VARCHAR2 (100);
l_ivr_preferred_s  VARCHAR2 (100);
l_vp_value_s       VARCHAR2 (100);
l_temp_str_s       VARCHAR2(2000);
l_header_n         NUMBER;
l_uom_code         VARCHAR2(10);
l_item_n           NUMBER;
l_line_id_n        NUMBER;
l_status_c         VARCHAR2(10);
l_message_s        VARCHAR2(2000);
l_context_s        VARCHAR2(50);

CURSOR get_cust_list_csr ( in_submit_id_n   NUMBER )
IS
SELECT long_parameter1
FROM   swg_custom_req_submit
WHERE  swg_req_submit_id = in_submit_id_n;

-- Added by VSP to process data from Table
CURSOR get_item_list_csr
IS
SELECT *
FROM   swgcnv.swgcnv_item_prclist_load
WHERE  price_header  IS NULL;

CURSOR get_prc_list_csr
IS
SELECT *
FROM   SWGCNV.SWGCNV_PRCLIST_LOAD;

l_tbl_cnt     NUMBER:=0;
l_errnum_n    NUMBER;
l_errbuf_s    VARCHAR2(100);

BEGIN

    ou_errbuff_s := 'Success';

    -- SWG_LOG('Before Org Setup');

    Begin

      Mo_Global.Set_policy_context('S',3);
Mo_Global.Set_policy_context('S',3);

    End;

    IF in_tab_data_s = 'N' -- Added by VSP to process data from Table
    THEN

    OPEN get_cust_list_csr (in_request_id_n);

    FETCH get_cust_list_csr
    INTO l_item_list_s;

    CLOSE get_cust_list_csr;

    IF    instr(l_item_list_s,chr(10)||chr(10)) > 0
    THEN

       fnd_file.put_line(FND_FILE.LOG,'Input Data Has Empty Lines. Please Check The Data And Resubmit.');
       fnd_file.put_line(FND_FILE.OUTPUT,'Input Data Has Empty Lines. Please Check The Data And Resubmit.');

       ou_errbuff_s := 'Input Data Has Empty Lines. Please Check The Data And Resubmit.';
       ou_errcode_n :=  g_swg_sts_error;
       RETURN;

    END IF;

    l_item_list_s   := l_item_list_s || CHR(10);

    --fnd_file.put_line (fnd_file.LOG, 'Outside the loop:' || in_l_item_list_s);
    l_tot_length              := LENGTH (l_item_list_s);
    l_created_by_n            := fnd_global.user_id;

    fnd_file.put_line(fnd_file.OUTPUT,'SPECIAL PRICING INSERT        '||TRUNC(SYSDATE));
    fnd_file.put_line(fnd_file.OUTPUT,'');
    fnd_file.put_line(fnd_file.OUTPUT,'ITEM_CODE|PRICE_LIST_NAME|ITEM_START_DATE|ITEM_PRICE|STATUS|MSG');

    -- Loop Through Above Pipe Delimited String And Process Records

    LOOP

        l_item_code_s    :=  NULL;
        l_price_name_s   :=  NULL;
        l_item_price_n   :=  NULL;
        l_start_date_d   :=  NULL;
        l_preferred_s    :=  NULL;
        l_cu_order_s     :=  NULL;
        l_cu_line_s      :=  NULL;
        l_ivr_preferred_s:=  NULL;
        l_vp_value_s     :=  NULL;
        l_header_n       :=  NULL;
        l_uom_code       :=  NULL;
        l_item_n         :=  NULL;
        l_context_s      :=  NULL;

        BEGIN

              l_temp_str_s  :=  SUBSTR(l_item_list_s, 1, INSTR(l_item_list_s, CHR(10)) - 1);

              IF l_temp_str_s != CHR(10) AND l_temp_str_s IS NOT NULL THEN

                   l_item_code_s    :=   SUBSTR( l_temp_str_s, 1, INSTR(l_temp_str_s, '|') - 1);
                   l_temp_str_s     :=   SUBSTR( l_temp_str_s, INSTR(l_temp_str_s, '|') + 1);
                   l_price_name_s   :=   SUBSTR( l_temp_str_s, 1, INSTR(l_temp_str_s, '|') - 1);
                   l_temp_str_s     :=   SUBSTR( l_temp_str_s, INSTR(l_temp_str_s, '|') + 1);
                   l_item_price_n   :=   SUBSTR( l_temp_str_s, 1, INSTR(l_temp_str_s, '|') - 1);
                   l_temp_str_s     :=   SUBSTR( l_temp_str_s, INSTR(l_temp_str_s, '|') + 1);

                   --WO20477  Retrieving date value from input record, no longer using default from Price List Header
                   --l_start_date_d   :=   to_date(SUBSTR( l_temp_str_s, 1, INSTR(l_temp_str_s, '|') - 1),'MM/DD/RRRR');

                   BEGIN

                   l_start_date_d   :=   to_date(SUBSTR( l_temp_str_s, 1, LENGTH(l_temp_str_s)),'MM/DD/RRRR');

                   EXCEPTION
                   WHEN OTHERS THEN
                     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_item_code_s||'|'||l_price_name_s||'|'||l_start_date_d||'|'||l_item_price_n
                                                  ||'|E|BAD DATE FORMAT ');
                     RETURN;
                   END;

                   /*
                   l_temp_str_s     :=   SUBSTR( l_temp_str_s, INSTR(l_temp_str_s, '|') + 1);
                   l_context_s      :=   SUBSTR( l_temp_str_s, 1, INSTR(l_temp_str_s, '|') - 1);
                   l_temp_str_s     :=   SUBSTR( l_temp_str_s, INSTR(l_temp_str_s, '|') + 1);
                   l_preferred_s    :=   SUBSTR( l_temp_str_s, 1, INSTR(l_temp_str_s, '|') - 1);
                   l_temp_str_s     :=   SUBSTR( l_temp_str_s, INSTR(l_temp_str_s, '|') + 1);
                   l_cu_order_s     :=   SUBSTR( l_temp_str_s, 1, INSTR(l_temp_str_s, '|') - 1);
                   l_temp_str_s     :=   SUBSTR( l_temp_str_s, INSTR(l_temp_str_s, '|') + 1);
                   l_cu_line_s      :=   SUBSTR( l_temp_str_s, 1, INSTR(l_temp_str_s, '|') - 1);
                   l_temp_str_s     :=   SUBSTR( l_temp_str_s, INSTR(l_temp_str_s, '|') + 1);
                   l_ivr_preferred_s:=   SUBSTR( l_temp_str_s, 1, INSTR(l_temp_str_s, '|') - 1);
                   l_vp_value_s     :=   SUBSTR( l_temp_str_s, INSTR(l_temp_str_s, '|') + 1);
                   */

                BEGIN

                    SELECT  h.list_header_id,
                            p.primary_uom_code,
                            p.inventory_item_id
                            -- ,h.start_date_active
                    INTO    l_header_n,
                            l_uom_code,
                            l_item_n
                            --, l_start_date_d
                    FROM    mtl_system_items_b  p, qp_list_headers h
                    WHERE   p.organization_id  = 5
                    AND     p.segment1         = l_item_code_s
                    AND     h.name             = l_price_name_s;
                     
                    --added for WO#20601
                    end_date_item_rec(l_price_name_s,l_item_code_s,l_start_date_d-1,l_message_s);

                    create_item_rec (
                                                  in_cre_list_header_id_n  => l_header_n
                                                , in_item_new_price_n      => l_item_price_n
                                                , in_new_item_id_n         => l_item_n
                                                , in_uom_code              => l_uom_code
                                                , in_itm_start_d           => l_start_date_d
                                                , ou_line_id               => l_line_id_n
                                                , ou_status_c_s            => l_status_c
                                                , ou_message_s             => l_message_s
                                     );

                     fnd_file.put_line(fnd_file.OUTPUT,l_item_code_s||'|'||l_price_name_s
                                                                                     ||'|'||l_start_date_d
                                                                                     ||'|'||l_item_price_n
                                                                                     ||'|'||l_status_c
                                                                                     ||'|'||NVL(l_message_s,'SUCCESS'));
                     IF  NVL(l_status_c,'S') = 'S' THEN

                       l_context_s  :=  NULL;  --WO20477  Hardcoded to bypass condition.  No longer updating DFF

                       IF  l_context_s  IS NOT NULL THEN

                           IF ( l_line_id_n > 0 ) THEN
                                 UPDATE qp_list_lines
                                 SET    context           =   NVL (l_context_s,context),
                                        attribute5        =   NVL (l_preferred_s,attribute5),
                                        attribute1        =   NVL (l_cu_order_s,attribute1),
                                        attribute2        =   NVL (l_cu_line_s,attribute2),
                                        attribute3        =   NVL (l_ivr_preferred_s,attribute3),
                                        attribute6        =   NVL (l_vp_value_s,attribute6)
                                 WHERE  list_line_id      =   l_line_id_n;
                           END IF;

                       END IF;

                     END IF;

                EXCEPTION
                WHEN OTHERS THEN

                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_item_code_s||'|'||l_price_name_s||'|'||l_start_date_d||'|'||l_item_price_n
                                                  ||'|E|BAD PRICELIST NAME/ITEM ');

                END;

              ELSE

                   FND_FILE.PUT_LINE(FND_FILE.LOG,'Cannot Process Record As Record Line Seems To Be NULL');

              END IF;

        END;

           l_item_list_s :=  SUBSTR(l_item_list_s, INSTR(l_item_list_s, CHR(10)) + 1);

       EXIT WHEN  NVL(INSTR(l_item_list_s, CHR(10)), 9999)  IN (0, 9999);

     END LOOP;

    ELSIF in_tab_data_s = 'Y' -- Added by VSP to process data from Table
    THEN

         SELECT count(*)
         INTO   l_tbl_cnt
         FROM   SWGCNV.SWGCNV_PRCLIST_LOAD;

         IF l_tbl_cnt = 0 THEN

           price_list_main (  ou_errbuf_s          => l_errbuf_s,
                              ou_errnum_n          => l_errnum_n
                            );

           ou_errcode_n  := l_errnum_n;
           ou_errbuff_s  := l_errbuf_s;

           RETURN;

         ELSE

          fnd_file.put_line(fnd_file.OUTPUT,'ITEM_CODE|PRICE_LIST_NAME|ITEM_START_DATE|ITEM_PRICE|STATUS|MSG');

          FOR   l_prc_list IN get_prc_list_csr
          LOOP

            FOR l_item_list IN get_item_list_csr
            LOOP

                BEGIN

                      l_header_n       := NULL;
                      l_uom_code       := NULL;
                      l_item_n         := NULL;
                      l_start_date_d   :=  NULL;

                      l_line_id_n   := NULL;
                      l_status_c    := NULL;
                      l_message_s   := NULL;

                      SELECT h.list_header_id,
                             p.primary_uom_code,
                             p.inventory_item_id,
                             h.start_date_active
                      INTO   l_header_n
                           , l_uom_code
                           , l_item_n
                           , l_start_date_d
                      FROM   mtl_system_items_b  p
                           , qp_list_headers     h
                     WHERE p.organization_id  = 5
                       AND p.segment1         = l_item_list.item_code
                       AND h.name             = l_prc_list.prc_list;

                    l_item_list.item_strt_dt   :=  NVL( l_item_list.item_strt_dt, l_start_date_d );

                    create_item_rec (   in_cre_list_header_id_n  => l_header_n
                                      , in_item_new_price_n      => l_item_list.item_prc
                                      , in_new_item_id_n         => l_item_n
                                      , in_uom_code              => l_uom_code
                                      , in_itm_start_d           => l_item_list.item_strt_dt
                                      , ou_line_id               => l_line_id_n
                                      , ou_status_c_s            => l_status_c
                                      , ou_message_s             => l_message_s
                                    );

                    fnd_file.put_line(fnd_file.OUTPUT,l_item_list.item_code
                                               ||'|'||l_prc_list.prc_list
                                               ||'|'||l_item_list.item_strt_dt
                                               ||'|'||l_item_list.item_prc
                                               ||'|'||l_status_c
                                               ||'|'||NVL(l_message_s,'SUCCESS'));

                    IF  NVL(l_status_c,'S') = 'S'
                    THEN

                        IF  l_item_list.context  IS NOT NULL
                        THEN

                            IF ( l_line_id_n > 0 )
                            THEN
                                UPDATE qp_list_lines
                                   SET context           =   NVL (l_item_list.context,context),
                                       attribute5        =   NVL (l_item_list.preferred,attribute5),
                                       attribute1        =   NVL (l_item_list.cu_order,attribute1),
                                       attribute2        =   NVL (l_item_list.cu_line,attribute2),
                                       attribute3        =   NVL (l_item_list.ivr_preferred,attribute3),
                                       attribute6        =   NVL (l_item_list.vp_value,attribute6)
                                 WHERE  list_line_id     =   l_line_id_n;
                            END IF;

                         END IF;

                    END IF;

                EXCEPTION
                WHEN OTHERS THEN

                    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,l_item_list.item_code
                                               ||'|'||l_prc_list.prc_list
                                               ||'|'||l_item_list.item_strt_dt
                                               ||'|'||l_item_list.item_prc
                                               ||'|E|BAD PRICELIST NAME/ITEM ');

                END;

            END LOOP; -- Item   Loop

          END LOOP; -- Price List Loop

     END IF;

    END IF;  -- Table Data Process Flag Check

EXCEPTION
WHEN OTHERS
THEN

    ou_errcode_n               := 2;
    ou_errbuff_s               := 'ERROR: Unexpected error in SWG_DM_NBR Procedure: ' || SQLERRM;
    RETURN;

END swg_price_request;

PROCEDURE price_list_main (   ou_errbuf_s              OUT    VARCHAR2,
                              ou_errnum_n              OUT    NUMBER
                          )
IS

CURSOR get_pricing_info
IS
SELECT h.list_header_id,
       int.item_code,
       int.price_header,
       int.item_prc,
       NVL ( int.item_strt_dt, h.start_date_active )   item_strt_dt,  --WO20550
       p.primary_uom_code,
       p.inventory_item_id,
       int.preferred,
       int.cu_order,
       int.cu_line,
       int.ivr_preferred,
       int.vp_value
FROM   mtl_system_items_b  p, qp_list_headers h, SWGCNV.SWGCNV_ITEM_PRCLIST_LOAD int
WHERE  p.organization_id  = 5
AND    p.segment1         = int.item_code
AND    h.name             = int.price_header
AND    int.price_header  IS NOT NULL;

TYPE     cust_bill_tbl_type
IS     TABLE     OF             get_pricing_info%ROWTYPE;

l_price_to_tbl       cust_bill_tbl_type;
l_status_c           VARCHAR2(10);
l_message_s          VARCHAR2(500);
l_idx_bi             BINARY_INTEGER;
l_line_id_n          NUMBER;
BEGIN

OPEN    get_pricing_info;
FETCH   get_pricing_info
BULK    COLLECT
INTO    l_price_to_tbl;
CLOSE   get_pricing_info;

fnd_file.put_line(fnd_file.OUTPUT,'SPECIAL PRICING INSERT        '||TRUNC(SYSDATE));
fnd_file.put_line(fnd_file.OUTPUT,'');
fnd_file.put_line(fnd_file.OUTPUT,'ITEM_CODE|PRICE_LIST_NAME|ITEM_START_DATE|ITEM_PRICE|STATUS|MSG');

IF l_price_to_tbl.COUNT <> 0 THEN

     l_idx_bi := l_price_to_tbl.FIRST;

  LOOP

     l_status_c            :=     g_swg_sts_success;
     l_message_s           :=     NULL;

     create_item_rec (
                                   in_cre_list_header_id_n  => l_price_to_tbl(l_idx_bi).list_header_id
                                 , in_item_new_price_n      => l_price_to_tbl(l_idx_bi).item_prc
                                 , in_new_item_id_n         => l_price_to_tbl(l_idx_bi).inventory_item_id
                                 , in_uom_code              => l_price_to_tbl(l_idx_bi).primary_uom_code
                                 , in_itm_start_d           => NVL( l_price_to_tbl(l_idx_bi).item_strt_dt, TRUNC(SYSDATE))
                                 , ou_line_id               => l_line_id_n
                                 , ou_status_c_s            => l_status_c
                                 , ou_message_s             => l_message_s
                      );
     
      fnd_file.put_line(fnd_file.OUTPUT,l_price_to_tbl(l_idx_bi).item_code||'|'||l_price_to_tbl(l_idx_bi).price_header
                                                                          ||'|'||NVL( l_price_to_tbl(l_idx_bi).item_strt_dt, TRUNC(SYSDATE))
                                                                          ||'|'||l_price_to_tbl(l_idx_bi).item_prc
                                                                          ||'|'||l_status_c
                                                                          ||'|'||l_message_s);

      IF ( l_price_to_tbl(l_idx_bi).preferred  IS NOT NULL  OR
              l_price_to_tbl(l_idx_bi).cu_order  IS NOT NULL  OR
               l_price_to_tbl(l_idx_bi).cu_line   IS NOT NULL  OR
                 l_price_to_tbl(l_idx_bi).ivr_preferred  IS NOT NULL  OR
                    l_price_to_tbl(l_idx_bi).vp_value  IS NOT NULL  )
      THEN

            IF ( l_line_id_n > 0 ) THEN
              

                  UPDATE qp_list_lines
                  SET    context           =   'DIRECT DELIVERY',
                         attribute5        =   NVL (l_price_to_tbl(l_idx_bi).preferred,attribute5),
                         attribute1        =   NVL (l_price_to_tbl(l_idx_bi).cu_order,attribute1),
                         attribute2        =   NVL (l_price_to_tbl(l_idx_bi).cu_line,attribute2),
                         attribute3        =   NVL (l_price_to_tbl(l_idx_bi).ivr_preferred,attribute3),
                         attribute6        =   NVL (l_price_to_tbl(l_idx_bi).vp_value,attribute6)
                  WHERE  list_line_id      =   l_line_id_n;
              
            END IF;

      END IF;

      COMMIT;

  EXIT WHEN (l_idx_bi = l_price_to_tbl.LAST);

     l_idx_bi := l_price_to_tbl.NEXT( l_idx_bi );

  END LOOP;

END IF;

EXCEPTION
WHEN OTHERS THEN

               ou_errnum_n    := 2;
               ou_errbuf_s    := SUBSTR (SQLERRM, 1, 100);

END price_list_main;

PROCEDURE create_item_rec (
                              in_cre_list_header_id_n  IN  NUMBER
                            , in_item_new_price_n      IN  NUMBER
                            , in_new_item_id_n         IN  NUMBER
                            , in_uom_code              IN  VARCHAR2
                            , in_itm_start_d           IN  DATE
                            , ou_line_id               OUT NUMBER
                            , ou_status_c_s            OUT VARCHAR2
                            , ou_message_s             OUT VARCHAR2
                           )
IS

l_new_price_list_line_tbl       qp_price_list_pub.price_list_line_tbl_type;
l_new_pricing_attr_tbl          qp_price_list_pub.pricing_attr_tbl_type;
l_new_ou_price_list_rec         qp_price_list_pub.price_list_rec_type;
l_new_ou_price_list_val_rec     qp_price_list_pub.price_list_val_rec_type;
l_new_ou_list_line_tbl          qp_price_list_pub.price_list_line_tbl_type;
l_new_ou_list_line_val_tbl      qp_price_list_pub.price_list_line_val_tbl_type;
l_new_ou_qualifiers_tbl         qp_qualifier_rules_pub.qualifiers_tbl_type;
l_new_ou_qualifiers_val_tbl     qp_qualifier_rules_pub.qualifiers_val_tbl_type;
l_new_ou_pricing_attr_tbl       qp_price_list_pub.pricing_attr_tbl_type;
l_new_ou_pricing_attr_val_tbl   qp_price_list_pub.pricing_attr_val_tbl_type;
l_ou_return_status_c            VARCHAR2 (1);
l_ou_msg_data_s                 VARCHAR2 (4000);
l_list_line_id_n                NUMBER;
l_ou_msg_count_n                NUMBER                   := 0;
l_pll_idx_bi                    BINARY_INTEGER           := 0;
in_effective_date_d             DATE                     := SYSDATE;
l_flexfield_rec                 fnd_dflex.dflex_r;
l_flexinfo_rec                  fnd_dflex.dflex_dr;
l_context_rec                   fnd_dflex.context_r;
l_segments_rec                  fnd_dflex.segments_dr;
l_attribute_grouping_no_n       NUMBER;
l_precedence_n                  NUMBER;
l_err_msg_data_S                VARCHAR2 (9000)          := NULL;
l_item_number_s                 VARCHAR2(50)             := NULL;   -- Added by VSP
l_qp_primary_uom_flag           VARCHAR2(5)              := NULL;   -- Added by VSP
l_qp_uom_code                   VARCHAR2(5)              := NULL;   -- Added by VSP
g_login_id                      NUMBER                   := -1;
g_user_id                       NUMBER                   := -1;
g_swg_debug            CONSTANT VARCHAR2 (1)             := 'D';
g_swg_nodebug          CONSTANT VARCHAR2 (1)             := 'N';
g_swg_sts_success      CONSTANT VARCHAR2 (1)             := 'S';
g_swg_sts_error        CONSTANT VARCHAR2 (1)             := 'E';
g_swg_sts_unexp_error  CONSTANT VARCHAR2 (1)             := 'U';
g_price_list_change    CONSTANT VARCHAR2 (30)            := 'PRICE LIST CHANGE';
g_price_lock           CONSTANT VARCHAR2 (30)            := 'PRICE LOCK';
g_process_update       CONSTANT VARCHAR2 (1)             := 'U';
l_new_code_exist_flag_s         VARCHAR2 (1)             := 'N';    -- new update
l_price_list_name_s             VARCHAR2(500)            := NULL;   -- Added by VSP
l_new_code_exist                qp_pricing_attributes.product_attr_value%TYPE;


/*---------------------------------------------------------------------------------------------------------------------------------
-- Cursor to find the precedence
---------------------------------------------------------------------------------------------------------------------------------*/

CURSOR cur_precedence ( in_pte_code_s IN VARCHAR2 )
IS
  SELECT qsg.user_precedence
    FROM qp_segments_v qsg
       , qp_prc_contexts_b qpc
       , qp_pte_segments qps
   WHERE qpc.prc_context_type       = 'PRODUCT'
     AND qpc.prc_context_code       = 'ITEM'
     AND qpc.prc_context_id         = qsg.prc_context_id
     AND qsg.segment_mapping_column = 'PRICING_ATTRIBUTE1'
     AND qsg.segment_id             = qps.segment_id
     AND qps.pte_code               = in_pte_code_s;


BEGIN

        BEGIN

          mo_global.set_policy_context('S',2);

        END;

        BEGIN

            -- Start of changes by VSP
            SELECT qph.name
            INTO   l_price_list_name_s
            FROM   qp_list_headers qph
            WHERE  list_header_id = in_cre_list_header_id_n;

            SELECT msi.segment1
            INTO   l_item_number_s
            FROM   mtl_system_items_b msi
            WHERE  msi.inventory_item_id = in_new_item_id_n
            AND    msi.organization_id   = 5;

            -- End of changes by VSP

            l_pll_idx_bi              := 0;

            l_new_code_exist_flag_s   := 'N';

        EXCEPTION
        WHEN OTHERS
        THEN

            fnd_file.put_line (fnd_file.LOG,'Unexpected Error in retrieving the Price List Name or Item Number: '||SQLERRM); -- Added by VSP
            fnd_file.put_line (fnd_file.LOG,'Price List Name: '||l_price_list_name_s||' '||' - Item Number: '||l_item_number_s);

        END;

        IF l_new_code_exist_flag_s = 'N'       --new update, if new item is already present in pricelist
        THEN

            SAVEPOINT create_item_rec_a;


            l_qp_primary_uom_flag     :=  'Y';

            l_qp_uom_code             :=  in_uom_code;


            IF l_qp_primary_uom_flag IS NOT NULL
            THEN

                l_pll_idx_bi := l_pll_idx_bi + 1;

                fnd_dflex.get_flexfield ( appl_short_name  =>  'QP'
                                        , flexfield_name   =>  'QP_ATTR_DEFNS_PRICING'
                                        , flexfield        =>  l_flexfield_rec
                                        , flexinfo         =>  l_flexinfo_rec
                                        );

                l_context_rec := fnd_dflex.make_context (flexfield => l_flexfield_rec, context_code => 'ITEM');

                fnd_dflex.get_segments  ( context          =>  l_context_rec
                                        , segments         =>  l_segments_rec
                                        , enabled_only     =>  TRUE
                                        );

                FOR i IN 1 .. NVL (l_segments_rec.nsegments, 0)
                LOOP

                    IF l_segments_rec.application_column_name (i) = 'PRICING_ATTRIBUTE1'
                    THEN

                       l_precedence_n  := l_segments_rec.SEQUENCE (i);

                    END IF;

                END LOOP;

                fnd_file.put_line (fnd_file.LOG,  ' PRECEDENCE: ' || l_precedence_n); -- Removed by VSP as PTE is not reqd

                l_new_price_list_line_tbl (l_pll_idx_bi).list_header_id        := in_cre_list_header_id_n;
                l_new_price_list_line_tbl (l_pll_idx_bi).list_line_id          := fnd_api.g_miss_num;
                l_new_price_list_line_tbl (l_pll_idx_bi).arithmetic_operator   := 'UNIT_PRICE';
                l_new_price_list_line_tbl (l_pll_idx_bi).list_line_type_code   := 'PLL';
                l_new_price_list_line_tbl (l_pll_idx_bi).operand               := in_item_new_price_n;
                l_new_price_list_line_tbl (l_pll_idx_bi).start_date_active     := NVL(in_itm_start_d,SYSDATE);
                l_new_price_list_line_tbl (l_pll_idx_bi).product_precedence    := l_precedence_n;
                l_new_price_list_line_tbl (l_pll_idx_bi).primary_uom_flag      := l_qp_primary_uom_flag;
                l_new_price_list_line_tbl (l_pll_idx_bi).created_by            := g_user_id;
                l_new_price_list_line_tbl (l_pll_idx_bi).last_updated_by       := g_user_id;
                l_new_price_list_line_tbl (l_pll_idx_bi).creation_date         := SYSDATE;
                l_new_price_list_line_tbl (l_pll_idx_bi).last_update_date      := SYSDATE;
                l_new_price_list_line_tbl (l_pll_idx_bi).last_update_login     := g_login_id;
                l_new_price_list_line_tbl (l_pll_idx_bi).operation             := qp_globals.g_opr_create;

                SELECT qp_pricing_attr_group_no_s.NEXTVAL
                INTO l_attribute_grouping_no_n
                FROM DUAL;

                l_new_pricing_attr_tbl (l_pll_idx_bi).list_header_id            := in_cre_list_header_id_n;
                l_new_pricing_attr_tbl (l_pll_idx_bi).pricing_attribute_id      := fnd_api.g_miss_num;
                l_new_pricing_attr_tbl (l_pll_idx_bi).list_line_id              := fnd_api.g_miss_num;
                l_new_pricing_attr_tbl (l_pll_idx_bi).product_attribute_context := 'ITEM';
                l_new_pricing_attr_tbl (l_pll_idx_bi).product_attribute         := 'PRICING_ATTRIBUTE1';
                l_new_pricing_attr_tbl (l_pll_idx_bi).product_attr_value        := in_new_item_id_n;
                l_new_pricing_attr_tbl (l_pll_idx_bi).product_uom_code          := l_qp_uom_code;
                l_new_pricing_attr_tbl (l_pll_idx_bi).excluder_flag             := 'N';
                l_new_pricing_attr_tbl (l_pll_idx_bi).attribute_grouping_no     := l_attribute_grouping_no_n;
                l_new_pricing_attr_tbl (l_pll_idx_bi).price_list_line_index     := l_pll_idx_bi;
                l_new_pricing_attr_tbl (l_pll_idx_bi).created_by                := g_user_id;
                l_new_pricing_attr_tbl (l_pll_idx_bi).last_updated_by           := g_user_id;
                l_new_pricing_attr_tbl (l_pll_idx_bi).creation_date             := SYSDATE;
                l_new_pricing_attr_tbl (l_pll_idx_bi).last_update_date          := SYSDATE;
                l_new_pricing_attr_tbl (l_pll_idx_bi).last_update_login         := g_login_id;
                l_new_pricing_attr_tbl (l_pll_idx_bi).operation                 := qp_globals.g_opr_create;
                l_ou_return_status_c                                            := NULL;
                l_ou_msg_count_n                                                := NULL;
                l_ou_msg_data_s                                                 := NULL;

                --fnd_file.put_line(fnd_file.LOG,' Calling qp_price_list_pub.process_price_list API to Enter Item: '|| in_new_item_id_n || ' Into PriceList: ' || in_list_header_id_n);
                --fnd_file.put_line(fnd_file.LOG,'=============================================');

                qp_price_list_pub.process_price_list ( p_api_version_number      =>  1
                                                     , p_init_msg_list           =>  fnd_api.g_true
                                                     , p_return_values           => fnd_api.g_false
                                                     , p_commit                  => fnd_api.g_false
                                                     , x_return_status           => l_ou_return_status_c
                                                     , x_msg_count               => l_ou_msg_count_n
                                                     , x_msg_data                => l_ou_msg_data_s
                                                     , p_price_list_line_tbl     => l_new_price_list_line_tbl
                                                     , p_pricing_attr_tbl        => l_new_pricing_attr_tbl
                                                     , x_price_list_rec          => l_new_ou_price_list_rec
                                                     , x_price_list_val_rec      => l_new_ou_price_list_val_rec
                                                     , x_price_list_line_tbl     => l_new_ou_list_line_tbl
                                                     , x_price_list_line_val_tbl => l_new_ou_list_line_val_tbl
                                                     , x_qualifiers_tbl          => l_new_ou_qualifiers_tbl
                                                     , x_qualifiers_val_tbl      => l_new_ou_qualifiers_val_tbl
                                                     , x_pricing_attr_tbl        => l_new_ou_pricing_attr_tbl
                                                     , x_pricing_attr_val_tbl    => l_new_ou_pricing_attr_val_tbl
                                                     );

                    IF l_ou_return_status_c IN (fnd_api.g_ret_sts_unexp_error, fnd_api.g_ret_sts_error)
                    THEN

                        ou_status_c_s    := 'E';
                        ou_message_s     := l_ou_msg_data_s;

                        swg_msrp_inc_pkg.parse_message (l_ou_msg_data_s, l_ou_msg_count_n);

                        IF l_ou_msg_count_n > 0
                        THEN

                             swg_msrp_inc_pkg.parse_message (l_ou_msg_data_s, l_ou_msg_count_n);

                        END IF;

                        ou_status_c_s   := 'E';
                        ou_message_s    := l_ou_msg_data_s;

                        -- fnd_file.put_line (fnd_file.LOG,'Error in creating Inventory_Item:' ||in_new_item_id_n|| ' in pricelist ' ||in_cre_list_header_id_n || ' Err Msg: ' || ou_message_s);
                        fnd_file.put_line (fnd_file.LOG,'Error in creating Inventory_Item:' ||l_item_number_s|| ' in pricelist: ' ||l_price_list_name_s || ' Err Msg: ' || ou_message_s);

                        ROLLBACK TO SAVEPOINT create_item_rec_a;

                        RETURN;

                    ELSE

                        COMMIT;

                        ou_status_c_s := 'S';
                        ou_message_s  := l_ou_msg_data_s;
                        ou_line_id    := l_new_ou_list_line_tbl(1).list_line_id;

                    END IF;

            END IF; --l_qp_primary_uom_flag

            ou_status_c_s := 'S';

        END IF;    --l_new_code_exist_flag_s = 'N'

EXCEPTION
WHEN NO_DATA_FOUND
THEN

      ou_status_c_s := 'E';
      ou_message_s  := SQLERRM;

WHEN OTHERS
THEN
      ou_status_c_s := 'E';
      ou_message_s  := SQLERRM;
      fnd_file.put_line(fnd_file.LOG,'Unexpected Error Message: '||SQLERRM);

END create_item_rec;
----------------------------------------------------------------------------
-- WO#20601: Added by Mohan 9/AUG/12
PROCEDURE end_date_item_rec( 
                             in_price_list_name_s      IN VARCHAR2,
                             in_item_segment_s         IN VARCHAR2,
                             in_end_date_d             IN DATE,
                             ou_status_s               OUT VARCHAR2
                           )
IS
--WO21460 Performance issue cur_list_lines
--CURSOR cur_list_lines(in_header_id_n IN NUMBER, in_item_no_s IN VARCHAR2)
CURSOR cur_list_lines(in_header_id_n IN NUMBER, in_item_no_s IN VARCHAR2, in_date_d DATE, in_date_d1 DATE)
IS
SELECT list_line_id,
       start_date_active
FROM   qp_list_lines_v
WHERE  product_attribute_context = 'ITEM'
AND EXISTS
  (SELECT '1'
     FROM mtl_system_items mtl
    WHERE product_attr_value = mtl.inventory_item_id
      AND mtl.organization_id  =  (SELECT qp_util.get_item_validation_org FROM Dual)
      AND product_attribute= 'PRICING_ATTRIBUTE1'
  UNION
   SELECT '1' FROM dual WHERE product_attribute != 'PRICING_ATTRIBUTE1'
  )
AND (list_header_id        =   in_header_id_n)
AND (pa_list_header_id     =   to_char(in_header_id_n))
AND product_attr_val_disp  =   in_item_no_s
AND (in_date_d)           >=   start_date_active 
AND (in_date_d)           <=   NVL(end_date_active,in_date_d1);

l_end_date_d   DATE;
l_end_date_d1  DATE;
/*
   SELECT list_line_id,start_date_active
      FROM qp_list_lines_v qlv
        WHERE   list_header_id       =   in_header_id_n
          AND product_attr_val_disp  =   in_item_no_s
          AND in_end_date_d+1 BETWEEN qlv.start_date_active AND NVL(qlv.end_date_active,in_end_date_d+2);
*/

l_list_header_id_n             NUMBER;
                               
--Variables for api             
                               
l_return_status_s              VARCHAR2(1) := NULL; 
l_msg_count_n                  NUMBER := 0; 
l_msg_data_s                   VARCHAR2(2000); 
l_price_list_rec               QP_PRICE_LIST_PUB.PRICE_LIST_REC_TYPE; 
l_price_list_val_rec           QP_PRICE_LIST_PUB.PRICE_LIST_VAL_REC_TYPE; 
l_price_list_line_tbl          QP_PRICE_LIST_PUB.PRICE_LIST_LINE_TBL_TYPE; 
l_price_list_line_val_tbl      QP_PRICE_LIST_PUB.PRICE_LIST_LINE_VAL_TBL_TYPE; 
l_pricing_attr_tbl             QP_PRICE_LIST_PUB.PRICING_ATTR_TBL_TYPE; 
l_pricing_attr_val_tbl         QP_PRICE_LIST_PUB.PRICING_ATTR_VAL_TBL_TYPE; 
l_ppr_price_list_rec           QP_PRICE_LIST_PUB.PRICE_LIST_REC_TYPE; 
l_ppr_price_list_val_rec       QP_PRICE_LIST_PUB.PRICE_LIST_VAL_REC_TYPE; 
l_ppr_price_list_line_tbl      QP_PRICE_LIST_PUB.PRICE_LIST_LINE_TBL_TYPE; 
l_ppr_price_list_line_val_tbl  QP_PRICE_LIST_PUB.PRICE_LIST_LINE_VAL_TBL_TYPE; 
l_ppr_qualifiers_tbl           QP_QUALIFIER_RULES_PUB.QUALIFIERS_TBL_TYPE; 
l_ppr_qualifiers_val_tbll      QP_QUALIFIER_RULES_PUB.QUALIFIERS_VAL_TBL_TYPE; 
l_ppr_pricing_attr_tbl         QP_PRICE_LIST_PUB.PRICING_ATTR_TBL_TYPE; 
l_ppr_pricing_attr_val_tbl     QP_PRICE_LIST_PUB.PRICING_ATTR_VAL_TBL_TYPE; 
l_debug_file_s                 VARCHAR2(100); 
l_update_cnt_n                 NUMBER    :=0;
BEGIN

    SAVEPOINT end_date_item_sp;

    fnd_file.put_line(fnd_file.log,'Inside end_date_item_rec.');

    -- Fetcht the header id
    BEGIN
         SELECT list_header_id
           INTO l_list_header_id_n
             FROM qp_list_headers
         WHERE name=in_price_list_name_s;
    EXCEPTION
    WHEN OTHERS THEN 
         ou_status_s:='Failed to fetch price list header id: '||in_price_list_name_s;
         RETURN;
    END;
    
       oe_msg_pub.initialize; 
    -- oe_debug_pub.initialize; 
    -- l_debug_file_s := oe_debug_pub.set_debug_mode('FILE'); 
    -- oe_debug_pub.setdebuglevel(5); 

    -- End date for each active record.

--    l_end_date_d  := in_end_date_d+1;
--    l_end_date_d1 := in_end_date_d+2;
    
    --WO21460 Performance issue cur_list_lines
    --FOR rec in cur_list_lines(l_list_header_id_n,in_item_segment_s  )
    FOR rec in cur_list_lines(l_list_header_id_n,in_item_segment_s, l_end_date_d,l_end_date_d1  )
    LOOP
         l_update_cnt_n := l_update_cnt_n+1;
        
         fnd_file.put_line(fnd_file.log,'Calling api for list line id: '||rec.list_line_id);

         l_price_list_rec.list_header_id := l_list_header_id_n ; 
         l_price_list_rec.operation := QP_GLOBALS.G_OPR_UPDATE; 
         
         -- end-dating existing price list line 
         l_price_list_line_tbl(1).list_line_id := rec.list_line_id  ; 
         l_price_list_line_tbl(1).operation := QP_GLOBALS.G_OPR_UPDATE; 
         l_price_list_line_tbl(1).end_date_active :=  in_end_date_d; 

         qp_price_list_pub.process_price_list( 
                                               p_api_version_number        =>   1 
                                             , p_init_msg_list             =>   FND_API.G_FALSE 
                                             , p_return_values             =>   FND_API.G_FALSE 
                                             , p_commit                    =>   FND_API.G_FALSE 
                                             , x_return_status             =>   l_return_status_s 
                                             , x_msg_count                 =>   l_msg_count_n 
                                             , x_msg_data                  =>   l_msg_data_s 
                                             , p_price_list_rec            =>   l_price_list_rec 
                                             , p_PRICE_LIST_LINE_tbl       =>   l_price_list_line_tbl 
                                             , p_pricing_attr_tbl          =>   l_pricing_attr_tbl 
                                             , x_PRICE_LIST_rec            =>   l_ppr_price_list_rec 
                                             , x_PRICE_LIST_val_rec        =>   l_ppr_price_list_val_rec 
                                             , x_PRICE_LIST_LINE_tbl       =>   l_ppr_price_list_line_tbl 
                                             , x_PRICE_LIST_LINE_val_tbl   =>   l_ppr_price_list_line_val_tbl 
                                             , x_QUALIFIERS_tbl            =>   l_ppr_qualifiers_tbl 
                                             , x_QUALIFIERS_val_tbl        =>   l_ppr_qualifiers_val_tbll 
                                             , x_PRICING_ATTR_tbl          =>   l_ppr_pricing_attr_tbl 
                                             , x_PRICING_ATTR_val_tbl      =>   l_ppr_pricing_attr_val_tbl 
                                            );

         IF l_return_status_s <> FND_API.G_RET_STS_SUCCESS 
         THEN 
              fnd_file.put_line(fnd_file.log,'Update API returned failure for list line id:'||rec.list_line_id);

              FOR  i in 1 .. l_msg_count_n 
              LOOP 

                  l_msg_data_s := oe_msg_pub.get(p_msg_index  => i,p_encoded => 'F'); 
                     
                   fnd_file.put_line(fnd_file.log,l_msg_data_s);

              END LOOP;

              ROLLBACK TO end_date_item_sp; 
              ou_status_s := 'API_ERROR';
              RETURN;

         END IF; 
         
    END LOOP;
EXCEPTION
WHEN OTHERS THEN
 ou_status_s:=substr(sqlerrm,1,2000);
 fnd_file.put_line(fnd_file.log,ou_status_s);
END;

FUNCTION IS_QP_EFFDATES_VALID( IN_LIST_HEADER_ID_N IN NUMBER
                             ,IN_INVENT0RY_ITEM_ID_N IN NUMBER
                            ) RETURN VARCHAR2
AS

l_price_list_active_s VARCHAR2(1)  := 'N';

BEGIN

   SELECT   'Y'
   INTO     l_price_list_active_s
   FROM     qp_list_headers         hl, 
            qp_pricing_attributes   qp,
            QP_LIST_LINES           ql        
   WHERE   TRUNC(sysdate)    between  HL.START_DATE_ACTIVE AND     NVL(HL.END_DATE_ACTIVE,TRUNC(sysdate))   
   AND     TRUNC(sysdate)  between    QL.START_DATE_ACTIVE   AND     NVL(QL.END_DATE_ACTIVE,TRUNC(sysdate))   
   AND     QL.LIST_LINE_TYPE_CODE              =   'PLL'
   AND     QL.ARITHMETIC_OPERATOR              =   'UNIT_PRICE'
   AND     QP.PRODUCT_ATTRIBUTE                =   'PRICING_ATTRIBUTE1'      
   AND     QP.LIST_LINE_ID                     =   QL.LIST_LINE_ID  
   AND     QL.LIST_HEADER_ID                   =   HL.LIST_HEADER_ID
   AND     TO_NUMBER(QP.PRODUCT_ATTR_VALUE)    =   IN_INVENT0RY_ITEM_ID_N 
   AND     HL.LIST_HEADER_ID                   =   IN_LIST_HEADER_ID_N;
   
   RETURN l_price_list_active_s;
   
EXCEPTION   
   WHEN OTHERS THEN   
   
   RETURN l_price_list_active_s;
   
END;                        
----------------------------------------------------------------------------
---Added for WO#21053.
PROCEDURE adjust_msrp_price( ou_errcode_n 	            OUT		NUMBER,
                             ou_errbuff_s              OUT  VARCHAR2,                             
                             in_insert_msrp_item_s     IN VARCHAR2
                           )
AS

   --Declaring local variables.
   
   l_tbl_cnt     NUMBER     :=0;
   l_effective_date_d       DATE;
   l_errnum_n               NUMBER;
   l_errbuf_s               VARCHAR2(250); 
   
   CURSOR cur_msrp_lines
   IS
   SELECT   hl.name price_list_name,
            hl.list_header_id,
            ql.list_line_id,
            item.inventory_item_id,
            item.segment1,
            ql.operand msrp_price,
            item.msrp_new_price,
            item.effective_date
   FROM     swg_msrp_increase  item,
            qp_list_headers hl, 
            qp_pricing_attributes   qp,
            qp_list_lines   ql       
   WHERE   trunc(sysdate)  between  hl.start_date_active
   AND     NVL(hl.end_date_active,trunc(sysdate))
   AND     qp.list_line_id                  =   ql.list_line_id
   AND     trunc(sysdate)  between  ql.start_date_active  
   AND     NVL(ql.end_date_active,trunc(sysdate))
   AND     hl.list_header_id                =   ql.list_header_id 
   AND     ql.list_line_type_code           =   'PLL'
   AND     ql.arithmetic_operator           =   'UNIT_PRICE'
   AND     qp.product_attribute             =   'PRICING_ATTRIBUTE1'
   AND     TO_CHAR(item.inventory_item_id)  =   qp.product_attr_value
   AND     item.price_list_name = hl.name
   AND     item.list_header_id = hl.list_header_id
   AND     MSRP_STATUS                      =   'Y';
   
   
   
   CURSOR cur_validate_msrp_check--Modified as part of WO#21115
   IS
   SELECT   hl.list_header_id,
            item.INVENTORY_ITEM_ID
   FROM     swg_msrp_increase  item,
            qp_list_headers hl, 
            qp_pricing_attributes   qp,
            qp_list_lines   ql        
   WHERE   trunc(sysdate)  between  hl.start_date_active
   AND     NVL(hl.end_date_active,trunc(sysdate))
   AND     qp.list_line_id                  =   ql.list_line_id  
   --AND     trunc(sysdate)  between  ql.start_date_active          --commented to address WO#21115
   --AND     NVL(ql.end_date_active,trunc(sysdate))                --commented to address WO#21115
   AND     hl.list_header_id                =   ql.list_header_id 
   AND     ql.list_line_type_code           =   'PLL'
   AND     ql.arithmetic_operator           =   'UNIT_PRICE'
   AND     qp.product_attribute             =   'PRICING_ATTRIBUTE1'
   AND     TO_CHAR(item.inventory_item_id)  =   qp.product_attr_value
   AND     item.price_list_name             =   hl.name
   AND     item.list_header_id              =   hl.list_header_id
   AND     MSRP_STATUS                      =   'Y'   
   AND     ql.END_DATE_ACTIVE               =   ITEM.EFFECTIVE_DATE-1;   --Added to address WO#21115
   --AND     ql.END_DATE_ACTIVE    =  in_effective_date_d;             --commented to address WO#21115

   l_preferred_s       QP_LIST_LINES.attribute5%TYPE:=NULL;
   l_cu_order_s        QP_LIST_LINES.attribute1%TYPE:=NULL;
   l_cu_line_s         QP_LIST_LINES.attribute2%TYPE:=NULL;
   l_ivr_preferred_s   QP_LIST_LINES.attribute3%TYPE:=NULL;
   l_vp_value_s        QP_LIST_LINES.attribute6%TYPE:=NULL;
   
                         
   TYPE	msrp_lines_tbl_type	IS	TABLE	OF	cur_msrp_lines%ROWTYPE INDEX BY BINARY_INTEGER;
   
   l_msrp_lins_tbl msrp_lines_tbl_type; 
   
   TYPE	msrp_qp_ids_rec_type	IS	RECORD    ( list_header_id			NUMBER,
                                            INVENTORY_ITEM_ID			  NUMBER
                                          );
    
   TYPE	msrp_qp_ids_tbl_type	IS	TABLE	OF	msrp_qp_ids_rec_type INDEX	BY	BINARY_INTEGER;
   
   l_msrp_qp_ids_tbl msrp_qp_ids_tbl_type;
   
BEGIN
  
   IF  NVL(in_insert_msrp_item_s,'N') = 'Y'
   THEN
  


      DELETE from SWGCNV.SWGCNV_PRCLIST_LOAD;
      DELETE from SWGCNV_ITEM_PRCLIST_LOAD;
      
   END IF;
   
   
   OPEN cur_msrp_lines;
   LOOP
   
      FETCH cur_msrp_lines BULK COLLECT INTO l_msrp_lins_tbl limit 1000;
      EXIT WHEN l_msrp_lins_tbl.COUNT = 0;

      
         FOR i IN 1..l_msrp_lins_tbl.count LOOP
         
            
           IF TRUNC(l_msrp_lins_tbl(i).EFFECTIVE_DATE)   >    TRUNC(SYSDATE) --Added for WO#21115
           THEN
            
              IF NVL(in_insert_msrp_item_s,'N') = 'Y'
              THEN
                 l_effective_date_d := l_msrp_lins_tbl(i).EFFECTIVE_DATE - 1;
    
              ELSE
              
                 l_effective_date_d := l_msrp_lins_tbl(i).EFFECTIVE_DATE;
    
              END IF;
            
            
            
             --Update QP Lines for end dating with the given effective date -1
              UPDATE QP_LIST_LINES QPLINS 
              SET    END_DATE_ACTIVE         =  l_effective_date_d
                     ,LAST_UPDATE_DATE        =  SYSDATE
                     ,LAST_UPDATED_BY          =   G_USER_ID_N
              WHERE  QPLINS.LIST_HEADER_ID   =  l_msrp_lins_tbl(i).LIST_HEADER_ID
              AND    QPLINS.LIST_LINE_ID     =  l_msrp_lins_tbl(i).LIST_LINE_ID;
               
           
            
               /*Insert into PRCLIST_LOAD Table in order to create new line 
                 under the existing qp header id using price_list_main procedure.*/
            
            
            
              IF NVL(in_insert_msrp_item_s,'N') = 'Y'
              THEN 

            
                 BEGIN
                  
                    SELECT       attribute5,
                                 attribute1,
                                 attribute2,
                                 attribute3,
                                 attribute6
                    INTO         l_preferred_s,
                                 l_cu_order_s,
                                 l_cu_line_s,
                                 l_ivr_preferred_s,
                                 l_vp_value_s  
                    FROM         QP_LIST_LINES QPLINS
                                                
                    WHERE   QPLINS.list_line_id  = l_msrp_lins_tbl(i).LIST_LINE_ID;

                 EXCEPTION
                     WHEN OTHERS THEN  
                    NULL;
                 END;
               
                 INSERT INTO SWGCNV_ITEM_PRCLIST_LOAD
                             (item_code,
                              price_header,
                              item_prc,
                              item_strt_dt,
                              preferred,
                              cu_order,
                              cu_line,
                              ivr_preferred,
                              vp_value
                             )
                  
                 VALUES     ( l_msrp_lins_tbl(i).segment1,
                               l_msrp_lins_tbl(i).price_list_name,
                               l_msrp_lins_tbl(i).msrp_new_price,
                               l_msrp_lins_tbl(i).EFFECTIVE_DATE,
                               l_preferred_s,
                               l_cu_order_s,
                               l_cu_line_s,
                               l_ivr_preferred_s,
                               l_vp_value_s                            
                             );
  
              END IF;

           END IF;  
           
         END LOOP;
         
   END LOOP;
   
   CLOSE cur_msrp_lines;
   
   IF NVL(in_insert_msrp_item_s,'N') = 'Y'
   THEN     
      SELECT count(*)
            INTO   l_tbl_cnt
            FROM   SWGCNV.SWGCNV_PRCLIST_LOAD;
            

      IF l_tbl_cnt = 0 THEN
 
              price_list_main (  ou_errbuf_s          => l_errbuf_s,
                                  ou_errnum_n          => l_errnum_n
                                );

               ou_errcode_n  := l_errnum_n;
               ou_errbuff_s  := l_errbuf_s;

         IF ( l_errnum_n = 2 ) THEN
            RETURN;
         END IF;
    
            
         OPEN cur_validate_msrp_check;
         LOOP
            FETCH cur_validate_msrp_check BULK COLLECT INTO l_msrp_qp_ids_tbl limit 1000;
            EXIT WHEN l_msrp_qp_ids_tbl.COUNT = 0;
                 
               FOR i IN 1..l_msrp_qp_ids_tbl.COUNT LOOP
                      ---Update MSRP Log table status to 'P' of the line which got updated successfully.
                     
                  UPDATE     SWG_MSRP_INCREASE MSRP 
                      SET    MSRP.MSRP_STATUS     =  'P'
                      WHERE  MSRP.LIST_HEADER_ID  =  l_msrp_qp_ids_tbl(i).LIST_HEADER_ID 
                      AND    MSRP.INVENTORY_ITEM_ID    =  l_msrp_qp_ids_tbl(i).INVENTORY_ITEM_ID;
 
               END LOOP;
         END LOOP;
      
         CLOSE cur_validate_msrp_check;
      END IF;  
   END IF;
   
   FOR I IN (SELECT price_list_name
                   ,list_header_id
                   ,inventory_item_id
                   ,segment1
                   ,effective_date
             FROM SWG_MSRP_INCREASE MSRP
             WHERE MSRP_STATUS='Y') 
   LOOP
   
      IF IS_QP_EFFDATES_VALID( I.list_header_id,I.inventory_item_id ) = 'N' 
      THEN
      
         UPDATE SWG_MSRP_INCREASE MSRP SET MSRP.MSRP_STATUS='E' WHERE MSRP.LIST_HEADER_ID =I.list_header_id AND MSRP.INVENTORY_ITEM_ID=I.inventory_item_id AND MSRP.effective_date=I.effective_date AND MSRP.MSRP_STATUS='Y';    
         fnd_file.put_line(fnd_file.LOG,''||'Please check Price List and Line Effective Start and End Dates |'||I.price_list_name||'|'||I.segment1);
         
      ELSIF  TRUNC(I.effective_date)      <=    TRUNC(SYSDATE)
      THEN
      
         UPDATE SWG_MSRP_INCREASE MSRP SET MSRP.MSRP_STATUS='E' WHERE MSRP.LIST_HEADER_ID =I.list_header_id AND MSRP.INVENTORY_ITEM_ID=I.inventory_item_id AND MSRP.effective_date=I.effective_date AND MSRP.MSRP_STATUS='Y';
         fnd_file.put_line(fnd_file.LOG,''||'MSRP Effective Date cannot be less then or equal to Sysdate |'||I.price_list_name||'|'||I.segment1||'|'||I.effective_date);  
         
      END IF;
      
   END LOOP;
   
COMMIT;
EXCEPTION
WHEN OTHERS THEN
ou_errcode_n     := 2;
ou_errbuff_s 	   :=  'Program Aborted '||SUBSTR(sqlerrm,1,250);

END adjust_msrp_price;
----------------------------------------------------------------------------
END swgcnv_Pricelist_Pkg;
/
SHOW ERRORS;

EXIT;
