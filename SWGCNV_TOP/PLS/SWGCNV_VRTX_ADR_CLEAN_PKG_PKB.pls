
--conn apps/&1

CREATE OR REPLACE PACKAGE BODY SWGCNV_VRTX_ADR_CLEAN_PKG
AS

/*======================================================================================+
 | Copyright (c) 2007 DS Waters, Atlanta, GA 30152 USA All rights reserved.         |
+=====================================================================-=================+
 | FILENAME   : SWGCNV_VRTX_ADR_CLEAN_PKG_PKB.pls                                     |
 |                                                                              |
 | DESCRIPTION:                                                       |
 |                                                                              |
 | HISTORY                                                                      |
 | unknown            -----------                    Initial version              |
 | Feb-29-2008            Suganthi Uthaman                 WO#18762 Rel 12 changes      |
 | Jun-06-2012            Stephen Bowen                    WO#20368 Set timout 90 to 10 |
 |                                                                                |
 |                                                                              |
 |                                                                              |
+======================================================================================*/

    /*-----------------------------------------------------------------------------
  PACKAGE BODY RECORD TYPES
    -------------------------------------------------------------------------------*/

    TYPE  request_rec_type  IS  RECORD
  ( request_id      NUMBER
   ,proc_seq      NUMBER
  );

    /*------------------------------------------------------------------------------
  PACKAGE BODY TABLE TYPES
    --------------------------------------------------------------------------------*/

    TYPE  request_tbl_type  IS  TABLE OF  request_rec_type
  INDEX BY  BINARY_INTEGER;

/*---------------------------------------------------------------------------------------*/

PROCEDURE assign_sequences
( in_split_proc_cnt_n   IN  NUMBER
 ,in_sales_center_s             IN    VARCHAR2
 ,ou_child_proc_cnt_n   OUT NUMBER
 ,ou_status_c     OUT VARCHAR2
 ,ou_message_s      OUT VARCHAR2
)
IS

    CURSOR  cur_cust    (in_sc_s    VARCHAR2)
    IS
    SELECT  ROWID row_id
    ,address_id
    FROM    swgcnv.swgcnv_dd_addresses
    WHERE   sales_center    = in_sc_s;
--    AND ROWNUM <= 1000;

    l_total_cust_cnt_n    NUMBER    :=  0;
    l_count_n     NUMBER    :=  0;
    l_seq_n     NUMBER    :=  0;
    l_split_cnt_n         NUMBER    :=  0;

BEGIN

    SELECT  COUNT(*)
    INTO    l_total_cust_cnt_n
    FROM    swgcnv.swgcnv_dd_addresses
    WHERE     sales_center    = in_sales_center_s;
--    AND ROWNUM <= 1000;

    IF l_total_cust_cnt_n = 0 THEN
      ou_status_c     :=  G_ERROR_C;
      ou_message_s  :=  'No addresses found in SWGCNV_DD_ADDRESSES';
      RETURN;
    END IF;

    l_split_cnt_n :=  CEIL (l_total_cust_cnt_n / in_split_proc_cnt_n);

    l_seq_n   :=  1;

    FOR l_cust_rec  IN  cur_cust (in_sales_center_s)
    LOOP

      l_count_n :=  l_count_n + 1;

      UPDATE  swgcnv.swgcnv_dd_addresses
      SET   seq               = l_seq_n
      WHERE ROWID   = l_cust_rec.row_id;
--        AND sales_center    = in_sales_center_s;


      IF l_count_n  > l_split_cnt_n THEN
          l_count_n :=  0;
          l_seq_n :=  l_seq_n + 1;
      END IF;

    END LOOP;

    COMMIT;

    ou_status_c     :=  G_SUCCESS_C;
    ou_message_s    :=  NULL;

    IF l_split_cnt_n > in_split_proc_cnt_n THEN

      ou_child_proc_cnt_n :=  in_split_proc_cnt_n;

    ELSE

      ou_child_proc_cnt_n :=  l_split_cnt_n;

    END IF;

EXCEPTION
    WHEN OTHERS THEN
        ou_message_s  :=  'Error in splitting: ' || SQLERRM;
        ou_status_c   :=  G_ERROR_C;

        ROLLBACK;

END   assign_sequences;

------------------------------------------------------------------------------------------------------------------------------------------

PROCEDURE ADDR_CLNUP
(ou_errbuf_s      OUT VARCHAR2
,ou_errcode_n     OUT NUMBER
,in_sales_center      IN  VARCHAR2
,in_seq_num_n               IN    NUMBER
--,in_mode_c      IN  VARCHAR2  DEFAULT   G_SWG_CONCURRENT
--,in_debug_flag_c      IN  VARCHAR2  DEFAULT   G_SWG_NODEBUG
--,in_validate_only_c         IN    VARCHAR2      DEFAULT         'Y'
)
IS

  CURSOR C1 (in_sales_center VARCHAR2, in_seq_n NUMBER)
  IS
  SELECT  e.ROWID     row_id,
          e.*
  FROM    swgcnv_dd_addresses    e
  WHERE   sales_center        = in_sales_center
  AND     addr_clean_up_flag  = 'N'
  AND     seq                 = in_seq_n;

  l_retval                BOOLEAN;
  l_count_n               NUMBER;
  l_totl_recd_read_n      NUMBER    :=  0;
  l_totl_corrctd_city_cnt_n     NUMBER    :=  0;
  l_totl_prcssd_city_cnt_n      NUMBER    :=  0;
  l_totl_multi_cnty_cnt_n     NUMBER    :=  0;
  l_totl_error_city_cnt_n     NUMBER    :=  0;

  l_city_name_s         VARCHAR2(60);
  l_county_name_s       VARCHAR2(60);
  l_test_county_s       VARCHAR2(60);
  l_start_time_s        VARCHAR2(30);

  search_rec        ZX_TAX_VERTEX_GEO.tGeoSearchRecord; --R12 Changes WO#18762 by SU on 02/29/2008
  result_rec        ZX_TAX_VERTEX_GEO.tGeoResultsRecord;--R12 Changes WO#18762 by SU on 02/29/2008
  
  TYPE   cust_C1_tbl_type
  IS     TABLE     OF          C1%ROWTYPE;

  i               cust_C1_tbl_type;
  l_idx_bi        BINARY_INTEGER;
  l_address1_s    VARCHAR2(100);
  l_address2_s    VARCHAR2(100);
  l_city_s        VARCHAR2(100);
  l_state_s       VARCHAR2(100);
  l_zip_s         VARCHAR2(100);
  l_latitude_n    VARCHAR2(100);
  l_longitude_n   VARCHAR2(100);
  l_geo_stat_s    VARCHAR2(100);
  l_rte_stat_s    VARCHAR2(100);

BEGIN

  ou_errbuf_s     :=  NULL;
  ou_errcode_n    :=  0;

  l_start_time_s    :=  TO_CHAR(SYSDATE,'DD-MON-RRRR HH24:MI:SS');
  
  OPEN    C1(in_sales_center,in_seq_num_n);
  FETCH   C1  BULK COLLECT INTO i;
  CLOSE   C1;

  l_totl_error_city_cnt_n :=  0;

 IF i.COUNT <> 0 THEN

     l_idx_bi := i.FIRST;
     
 LOOP
  
    BEGIN

        l_totl_recd_read_n  :=  l_totl_recd_read_n + 1;
        
        --WO21676

        IF ( i(l_idx_bi).latitude IS NULL  
             AND  i(l_idx_bi).longitude  IS NULL
               AND  i(l_idx_bi).address1  IS NOT NULL)  THEN

		        BEGIN
		
		            l_latitude_n    :=  NULL;
		            l_longitude_n   :=  NULL;
		            
		            SWG_SAGENT_PKG.proc_address_postgis (io_address1_s    =>    i(l_idx_bi).address1,
		                                                 io_address2_s    =>    i(l_idx_bi).address2,
		                                                 io_city_s        =>    i(l_idx_bi).city,
		                                                 io_state_s       =>    i(l_idx_bi).state,
		                                                 io_zip_s         =>    i(l_idx_bi).postal_code,
		                                                 in_geo_only_s    =>    'N',
		                                                 in_branch_only_s =>    'N',
		                                                 ou_latitude_n    =>    l_latitude_n,
		                                                 ou_longitude_n   =>    l_longitude_n,
		                                                 ou_geo_stat_s    =>    l_geo_stat_s,
		                                                 ou_rt_stat_s     =>    l_rte_stat_s
		                                                );
		                                                
					        i(l_idx_bi).latitude   :=  l_latitude_n;
					        i(l_idx_bi).longitude  :=  l_longitude_n;
					        
					        IF ( l_latitude_n IS NOT NULL ) AND ( l_longitude_n IS NOT NULL ) THEN
					        
						        UPDATE  swgcnv_dd_addresses
						        SET     address1            =  i(l_idx_bi).address1,     
														address2            =  i(l_idx_bi).address2,    
														city                =  i(l_idx_bi).city,  
														state               =  i(l_idx_bi).state, 
														postal_code         =  i(l_idx_bi).postal_code,
														latitude            =  i(l_idx_bi).latitude,
						                longitude           =  i(l_idx_bi).longitude  
						        WHERE   ROWID               =  i(l_idx_bi).row_id; 
					        
					        END IF;      
		        
		        EXCEPTION 
		        WHEN OTHERS THEN
		          NULL;
		        END;
		        
		        COMMIT;
        
        END IF;
        
        --END WO21676
        
        ZX_TAX_VERTEX_GEO.GeoSetNameCriteria --R12 Changes WO#18762 by SU on 02/29/2008
        (
           pGeoSearchRec      =>  search_rec
         , pGeoLevel          =>  ZX_TAX_VERTEX_GEO.cGeoCodeLevelCity --R12 Changes WO#18762 by SU on 02/29/2008
         , pStateAbbrev       =>  SUBSTRB(i(l_idx_bi).state, 1, 2)
         , pStateNamePrefix   =>  FALSE
         , pStateName         =>  ''
         , pCountyNamePrefix  =>  FALSE
         , pCountyName        =>  SUBSTRB(i(l_idx_bi).county, 1, 20) -- County readded Sacs7 Muthu
         , pCityNamePrefix    =>  FALSE
         , pCityNameCompress  =>  TRUE
         , pCityName          =>  SUBSTRB(i(l_idx_bi).city, 1, 25)
         , pZipCodePrefix     =>  FALSE
         , pZipCode           =>  SUBSTRB(i(l_idx_bi).postal_code, 1, 5)
         , pCityRecType       =>  NULL
        );

     l_retval := ZX_TAX_VERTEX_GEO.GeoRetrieveFirst(search_rec, result_rec); --R12 Changes WO#18762 by SU on 02/29/2008

     l_count_n  :=  0;

     LOOP
    EXIT WHEN l_retval =  FALSE;

    l_count_n    := l_count_n + 1;

    /**********
    dbms_output.put_line(' ----------------- Start Address Information -----------  ');
    dbms_output.put_line(' FRESGEOSTATE   :'||result_rec.FRESGEOSTATE   );
    dbms_output.put_line(' FRESGEOCOUNTY    :'||result_rec.FRESGEOCOUNTY    );
    dbms_output.put_line(' FRESGEOCITY    :'||result_rec.FRESGEOCITY    );
    dbms_output.put_line(' FRESSTATEABBREV    :'||result_rec.FRESSTATEABBREV    );
    dbms_output.put_line(' FRESSTATENAME    :'||result_rec.FRESSTATENAME    );
    dbms_output.put_line(' FRESCOUNTYNAME   :'||result_rec.FRESCOUNTYNAME   );
    dbms_output.put_line(' FRESCOUNTYABBREV   :'||result_rec.FRESCOUNTYABBREV   );
    dbms_output.put_line(' FRESCITYNAME   :'||result_rec.FRESCITYNAME   );
    dbms_output.put_line(' FRESCITYNAMECOMPRESSED :'||result_rec.FRESCITYNAMECOMPRESSED );
    dbms_output.put_line(' FRESCITYNAMEABBREV :'||result_rec.FRESCITYNAMEABBREV );
    dbms_output.put_line(' FRESCITYNAMETYPE   :'||result_rec.FRESCITYNAMETYPE   );
    dbms_output.put_line(' FRESZIPCODESTART   :'||result_rec.FRESZIPCODESTART   );
    dbms_output.put_line(' FRESZIPCODEEND   :'||result_rec.FRESZIPCODEEND   );
    dbms_output.put_line(' ----------------- End Address Information -----------  '||chr(10)||chr(10));
    ********/

    IF l_count_n = 1 THEN
       l_city_name_s      :=  LTRIM(RTRIM(result_rec.FRESCITYNAME));
       l_county_name_s    :=  LTRIM(RTRIM(result_rec.FRESCOUNTYNAME));
    END IF;

      l_retval := ZX_TAX_VERTEX_GEO.GeoRetrieveNext(search_rec, result_rec); --R12 Changes WO#18762 by SU on 02/29/2008

     END LOOP;

    EXCEPTION
  WHEN OTHERS THEN
     Fnd_File.Put_Line(Fnd_File.OUTPUT,'UNEXPECTED ERROR in loop..customer_number::'||i(l_idx_bi).customer_number
              ||', address_id::'||i(l_idx_bi).address_id||'   ERROR::'||SQLERRM);
              
     UPDATE  swgcnv_dd_addresses
     SET     addr_clean_up_flag  =       'E',
             latitude            =       NULL,
						 longitude           =       NULL
     WHERE   ROWID               =       i(l_idx_bi).row_id;

     ou_errcode_n  := 1;
     ou_errbuf_s   := 'An error occurred in processing please see the log file.';

    END;

    --SGB WO#20368 if address1 is null error out
    IF  i(l_idx_bi).address1 IS NULL THEN
       l_count_n := 0;
       Fnd_File.Put_Line(Fnd_File.LOG, 'NO ADDRESS1 FOR ADDRESS ID '||i(l_idx_bi).address_id);
    END IF;

    IF l_count_n = 1 THEN
    
        IF LTRIM(RTRIM(result_rec.FRESCITYNAME)) != LTRIM(RTRIM(i(l_idx_bi).city)) THEN

				  UPDATE swgcnv_dd_addresses
				  SET   city               =   LTRIM(RTRIM(result_rec.FRESCITYNAME))
				       ,county             =   LTRIM(RTRIM(result_rec.FRESCOUNTYNAME))
				       ,addr_clean_up_flag =   'C'
				  WHERE  ROWID      = i(l_idx_bi).row_id;

          l_totl_corrctd_city_cnt_n :=  l_totl_corrctd_city_cnt_n + 1;

       ELSIF LTRIM(RTRIM(nvl(i(l_idx_bi).COUNTY,'~'))) != LTRIM(RTRIM(result_rec.FRESCOUNTYNAME)) THEN
       
          UPDATE swgcnv_dd_addresses
          SET    county             =   LTRIM(RTRIM(result_rec.FRESCOUNTYNAME))
                ,addr_clean_up_flag = 'Y'
          WHERE  ROWID      = i(l_idx_bi).row_id;

      ELSE

            UPDATE  swgcnv_dd_addresses
            SET     addr_clean_up_flag = 'P'
            WHERE   ROWID              = i(l_idx_bi).row_id;

            l_totl_prcssd_city_cnt_n  :=  l_totl_prcssd_city_cnt_n + 1;

        END IF;
        
    ELSIF l_count_n > 1 THEN

        ----------------------------------------
        -- If the City has multiple counties then
        -- assign the firt County
        -----------------------------------------

--Fnd_File.Put_Line(Fnd_File.LOG,'Multiple county, first one: '||l_county_name_s);

        UPDATE swgcnv_dd_addresses
        SET city               = l_city_name_s
           ,county             = l_county_name_s
           ,addr_clean_up_flag = 'M'
           ,latitude           = NULL
					 ,longitude          = NULL
        WHERE ROWID   = i(l_idx_bi).row_id;

        l_totl_multi_cnty_cnt_n :=  l_totl_multi_cnty_cnt_n + 1;

    ELSIF l_count_n = 0 THEN

        UPDATE  swgcnv_dd_addresses
        SET     addr_clean_up_flag  =       'E',
                latitude            =       NULL,
						    longitude           =       NULL
        WHERE  ROWID             = i(l_idx_bi).row_id;

        l_totl_error_city_cnt_n :=  NVL(l_totl_error_city_cnt_n,0)  + 1;

    END IF;

    COMMIT;
    
    EXIT WHEN (l_idx_bi = i.LAST);

        l_idx_bi := i.NEXT( l_idx_bi );

END LOOP;

END IF; 

 Fnd_File.Put_Line(Fnd_File.OUTPUT,'                                 ');
 Fnd_File.Put_Line(Fnd_File.OUTPUT,'                                 ');
 Fnd_File.Put_Line(Fnd_File.OUTPUT,'*------------------------------------*');
 Fnd_File.Put_Line(Fnd_File.OUTPUT,'No. of records read                 : ' || l_Totl_Recd_Read_n);
 Fnd_File.Put_Line(Fnd_File.OUTPUT,'No. of records city corrected       : ' || l_totl_corrctd_city_cnt_n);
 Fnd_File.Put_Line(Fnd_File.OUTPUT,'No. of cities with mutliple county  : ' || l_totl_corrctd_city_cnt_n);
 Fnd_File.Put_Line(Fnd_File.OUTPUT,'No. of records with no changes      : ' || l_totl_prcssd_city_cnt_n);
 Fnd_File.Put_Line(Fnd_File.OUTPUT,'No. of records with error           : ' || l_totl_error_city_cnt_n);
 Fnd_File.Put_Line(Fnd_File.OUTPUT,'*------------------------------------*');
 Fnd_File.Put_Line(Fnd_File.OUTPUT,'Start Time                          : ' || l_Start_Time_s);
 Fnd_File.Put_Line(Fnd_File.OUTPUT,'End Time                            : ' || TO_CHAR(SYSDATE, 'DD-MON-RRRR HH24:MI:SS'));

EXCEPTION
    WHEN OTHERS THEN
  ou_errcode_n  := 2;
  ou_errbuf_s := 'An error occurred in processing please see the log file::' ||SQLERRM;
  RETURN;

END   ADDR_CLNUP;

----------------------------------------------------------------------------------------

PROCEDURE   Master_Program
(ou_errbuf_s      OUT VARCHAR2
,ou_errcode_n     OUT NUMBER
,in_sales_center_s          IN    VARCHAR2
--,in_system_name_s   IN  VARCHAR2
,in_split_proc_cnt_n        IN    NUMBER
--,in_mode_c      IN  VARCHAR2  DEFAULT   G_SWG_CONCURRENT
--,in_debug_flag_c      IN  VARCHAR2  DEFAULT   G_SWG_NODEBUG
--,in_validate_only_c         IN    VARCHAR2      DEFAULT     'Y'
)
IS


    l_request_tbl   request_tbl_type;
    l_request_empty_tbl   request_tbl_type;


    l_no_of_child_n   NUMBER;

    l_request_id_n    NUMBER;
    l_idx_bi      BINARY_INTEGER;


    l_check_req_b   BOOLEAN;

    l_call_status_b   BOOLEAN;
    l_rphase_s      VARCHAR2(80);
    l_rstatus_s     VARCHAR2(80);
    l_dphase_s      VARCHAR2(30);
    l_dstatus_s     VARCHAR2(30);
    l_message_s     VARCHAR2(2000);
    l_status_c      VARCHAR2(1);
    l_error_message_s   VARCHAR2(2000);

    ERROR_ENCOUNTERED   EXCEPTION;
    
    CURSOR  get_location ( in_sc_center  VARCHAR2 )
    IS
    SELECT  unique a.sales_center sales_Center
    FROM    swgcnv_dd_addresses     a
    WHERE   a.addr_clean_up_flag  = 'N'
    AND     a.sales_center              =       NVL( in_sc_center, a.sales_center ) ;
       
    TYPE   sc_tbl_type
    IS     TABLE     OF                      get_location%ROWTYPE;
       
    l_loc_tbl                  sc_tbl_type;
    l_loc_empty_tbl          sc_tbl_type;
    l_idx_bis                                BINARY_INTEGER;
    l_sc_center_s                            VARCHAR2(100);

BEGIN

   l_loc_tbl    :=  l_loc_empty_tbl;

   FND_STATS.GATHER_TABLE_STATS('SWGCNV', 'SWGCNV_DD_ADDRESSES',90);

   IF in_sales_center_s = 'ALL' THEN
      l_sc_center_s :=  NULL;
   ELSE
      l_sc_center_s :=  in_sales_center_s;
   END IF; 

   OPEN     get_location  ( l_sc_center_s ) ;
   FETCH    get_location
   BULK     COLLECT  INTO     l_loc_tbl;
   CLOSE    get_location;

   IF l_loc_tbl.COUNT <> 0 THEN
   
        l_idx_bis := l_loc_tbl.FIRST;
        
   LOOP

    ou_errbuf_s     :=  NULL;
    ou_errcode_n    :=  0;
    l_no_of_child_n   :=  in_split_proc_cnt_n;

    assign_sequences
        (in_split_proc_cnt_n    =>  in_split_proc_cnt_n
        ,in_sales_center_s        =>      l_loc_tbl(l_idx_bis).sales_center
        ,ou_child_proc_cnt_n    =>  l_no_of_child_n
        ,ou_status_c          =>  l_status_c
        ,ou_message_s           =>  l_error_message_s);

    IF l_status_c !=  G_SUCCESS_C THEN
        RAISE       ERROR_ENCOUNTERED;
    ELSE
        Fnd_File.Put_Line ( Fnd_File.LOG, 'Assigning Sequences Success');
    END IF;

    ---------------------------------------------------
    -- Submit the Child Process ( Process by Sequence )
    ----------------------------------------------------
    l_idx_bi    :=  0;
    l_request_tbl :=  l_request_empty_tbl;


    FOR l_proc_seq_n    IN  1..l_no_of_child_n
    LOOP

      l_request_id_n  :=  Fnd_Request.Submit_Request
                                ( application =>  'SWGCNV'
    ,program    =>  'SWGCNV_ADR_CHILD_PROG'
    ,description  =>  NULL
    ,start_time =>  NULL
    ,sub_request  =>  FALSE
    ,argument1  =>  l_loc_tbl(l_idx_bis).sales_center   --  Sales Center
--    ,argument2      =>    in_system_name_s
    ,argument2  =>  l_proc_seq_n);      --  Process Sequence
--    ,argument4  =>  in_debug_flag_c
--    ,argument5      =>    in_validate_only_c);

      IF l_request_id_n = 0 THEN

            ou_errbuf_s     :=  'ERROR: Unable to Submit Child Concurrent Request, Process Seq: '|| l_proc_seq_n;
    ou_errcode_n    := 2;
            RAISE ERROR_ENCOUNTERED;

      ELSE

                l_idx_bi                        :=  l_idx_bi  + 1;
              l_request_tbl(l_idx_bi).request_id      :=  l_request_id_n;
              l_request_tbl(l_idx_bi).proc_seq      :=  l_proc_seq_n;

      END IF;

    END LOOP;

    COMMIT;   -- Concurrent Request Commit

    ---------------------------------------------------
    -- Check all the child process has been completed
    ----------------------------------------------------
    l_check_req_b :=  TRUE;
/*
    WHILE l_check_req_b
    LOOP

  --Fnd_File.Put_Line ( Fnd_File.LOG,   'Time: '|| TO_CHAR(sysdate, 'DD-MON-RR HH24:MI:SS'));

  FOR l_req_idx_bi  IN  1..l_request_tbl.COUNT
    LOOP

      l_call_status_b :=  Fnd_Concurrent.Get_Request_Status
                                    (request_id =>  l_request_tbl(l_req_idx_bi).request_id
                                    ,phase  =>  l_rphase_s
                                    ,status =>  l_rstatus_s
                                    ,dev_phase  =>  l_dphase_s
                                    ,dev_status =>  l_dstatus_s
                                    ,message  =>  l_message_s);

     
     -- Fnd_File.Put_Line ( Fnd_File.LOG,   'Request Id: '|| l_request_tbl(l_req_idx_bi).request_id  || ' ' ||
     --           'Proc Seq: '  || l_request_tbl(l_req_idx_bi).proc_seq    || ' ' ||
     --         'Dev Phase: ' || l_dphase_s);
     --

      IF NVL(l_dphase_s, '~') != 'COMPLETE' THEN
            EXIT;
      END IF;

  END LOOP;

  IF NVL(l_dphase_s, '~') != 'COMPLETE' THEN

      --dbms_lock.sleep (90);
            dbms_lock.sleep (10);

  ELSE

      l_check_req_b :=  FALSE;

  END IF;

    END LOOP;   -- While Loop
*/

  EXIT WHEN (l_idx_bis = l_loc_tbl.LAST);
   
       l_idx_bis := l_loc_tbl.NEXT( l_idx_bis );
   
  END LOOP;

  ELSE

   ou_errbuf_s   :=  'No Sales Centers Are Loaded for Processing';
         ou_errcode_n    :=   2;
   RAISE  ERROR_ENCOUNTERED;
  
  END IF;
  
EXCEPTION
    WHEN ERROR_ENCOUNTERED THEN
        RETURN;
    WHEN OTHERS THEN
        ou_errbuf_s     :=  'UNEXPECTED ERROR: '||SQLERRM;
        ou_errcode_n    := 2;
        RETURN;
END     Master_Program;

END   SWGCNV_VRTX_ADR_CLEAN_PKG;
/
SHOW ERRORS;
EXIT;

