CREATE OR REPLACE PACKAGE BODY    SWGCNV_DD_ROUTE_PKG    AS

/* $Header: SWGCNV_DD_ROUTE_PKB.pls  1.1 2010/04/09 09:33:33 PU $ */
/*===================================================================================+
| Copyright (c) 2005 DS Waters, Atlanta, GA 30328 USA All rights reserved.           |
+====================================================================================+
| Name:           SWGCNV_DD_ROUTE_PKG                                                |
| File:           SWGCNV_DD_ROUTE_PKB.pls                                            |
| Description:    Package For Converting Legacy Routes To Oracle                     |
|                                                                                    |
| Company:        DS Waters                                                          |
| Author:         Unknown                                                            |
| Date:           Unknown                                                            |
|                                                                                    |
| Modification History:                                                              |
| Date            Author          Description                                        |
| ----            ------          -----------                                        |
| Unknown         Unknown         Production Release                                 |
| 11/26/2008      Pankaj Umate    Modified For ARS03 Conversion. Daptiv No:  752     |
| 01/08/2008      Pankaj Umate    Modified For ARS04 Conversion. Daptiv No:  768     |
| 11/25/2009      Pankaj Umate    Changes For SAGE Conversion. Daptive No: 1299      | 
| 01/11/2010      Shashi Begar    Added a new procedure to insert route parameters   |
|                                 Added new parameters to convert_routes for SAM     |
|                                 conversion purpose.  Proj# 1358                    |
| 04/09/2010      Pankaj Umate    Daptiv # 1471. Conversion Mapping Table Migration  |
+===================================================================================*/
   PROCEDURE   convert_routes
      (   Ou_errmsg_s            OUT  VARCHAR2
         ,Ou_errcode_n           OUT  NUMBER
         ,in_legacy_system_s     IN   VARCHAR2
         ,in_sales_center_s      IN   VARCHAR2
         ,in_start_date_s	 IN   VARCHAR2	-- SSB added for Route Start Date.  01-19-2010
         ,in_debug_c             IN   VARCHAR2  DEFAULT  'N'
      )
   IS
      CURSOR   cursor_legacy_route ( in_sales_center_s   VARCHAR2
                                    )
      IS
      SELECT   *
      FROM     swgcnv_dd_route_interface
      WHERE    process_flag   =  'N'
      AND      sales_center   =  in_sales_center_s
      ORDER BY route_number ;
   
      --
      -- This Cursor is used to know the time taken for the load.
      --
      /*Commented by Bharat
      -- CURSOR   cur_prog_setup
      -- IS
      -- SELECT   progress_record_count
      -- FROM     swgcnv_prog_time_setup
      -- WHERE    conversion_type   =  'ROUTE';
      Bharat */

      --
      -- Variable Declaration Section.
      --

      l_legacy_route_rec      cursor_legacy_route%ROWTYPE;
      l_orcl_route_rec        swgrtm_routes%ROWTYPE;
      l_orcl_route_svc_rec    swgrtm_route_svc_types%ROWTYPE;
      l_orcl_veh_rec          swgrtm_vehicles%ROWTYPE;
      l_orcl_hier_rec         swgrtm_org_relations%ROWTYPE;

      l_service_tab           service_tab_type;
      l_empty_service_tab     service_tab_type;

      l_prog_rec_cnt_n        NUMBER;
      l_conversion_userid_n   NUMBER;

      l_recs_read_n           NUMBER   :=    0;
      l_route_recs_written_n  NUMBER   :=    0;
      l_veh_recs_written_n    NUMBER   :=    0;
      l_srvc_recs_written_n   NUMBER   :=    0;
      l_err_recs_n            NUMBER   :=    0;
      l_proc_recs_n           NUMBER   :=    0;
      l_hier_recs_written_n   NUMBER   :=    0;

      l_route_exists_c        VARCHAR2(1);
      l_new_code_s            VARCHAR2(100);
      l_new_sub_code_s        VARCHAR2(100);
      io_service_type         VARCHAR2(100);
      l_error_message_s       VARCHAR2(2000);
   
      l_idx_bi                BINARY_INTEGER;

      l_start_date_d	      DATE;	-- SSB added for Route Start Date.  01-19-2010

   BEGIN
      IF (in_start_date_s IS NULL) THEN
	 l_start_date_d	:= SYSDATE;
      ELSE
         l_start_date_d	:= FND_DATE.CANONICAL_TO_DATE(in_start_date_s);
      END IF;

      --
      -- Check to determine conversion user exists or not.
      --

      BEGIN
         SELECT   user_id
         INTO     l_conversion_userid_n
         FROM     fnd_user
         WHERE    user_name  =  'SWGCNV';
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            swg_output ('SWGCNV is not defined as an user');
            RETURN;
      END;

      --
      -- Logic for the cursor to determine the time required for processing the records.
      --
      /* Comment By Bharat
      --     OPEN   cur_prog_setup;
      --     FETCH  cur_prog_setup
      --     INTO   l_prog_rec_cnt_n;
      --
      --     IF cur_prog_setup%NOTFOUND THEN
      --       CLOSE cur_prog_setup;
      --       swg_output ('Setup for ROUTE Conversion does not exist in SWGCNV_PROG_TIME_SETUP');
      --       RETURN;
      --     END IF;
      -- 
      --     CLOSE cur_prog_setup;
      Bharat */

      --
      -- Program for Conversion begins.
      --

      FOR l_legacy_route_rec  IN    cursor_legacy_route( in_sales_center_s )
      LOOP
   
         l_error_message_s    :=    NULL;
         l_orcl_route_rec     :=    NULL;
         l_orcl_veh_rec       :=    NULL;
         l_orcl_hier_rec      :=    NULL;
         l_recs_read_n        :=    l_recs_read_n  +  1;
      
         --
         -- Check to see if the Route number already exists
         --

         BEGIN
   
            SELECT   'Y'
            INTO     l_route_exists_c
            FROM     swgrtm_routes
            WHERE    legacy_system     =  in_legacy_system_s
            AND      legacy_route_id   =  in_sales_center_s||': '||LTRIM(RTRIM(l_legacy_route_rec.route_number));
      
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               l_route_exists_c  :=    'N';
            WHEN TOO_MANY_ROWS THEN
               l_route_exists_c  :=    'Y';
         END;

         IF l_route_exists_c = 'Y'        THEN

            l_proc_recs_n := l_proc_recs_n + 1;
            GOTO    LOOP_END;

         END IF;

         --
         -- Get the values for the Oracle Route Table.
         --
         SELECT  swgrtm_routes_seq.NEXTVAL
         INTO    l_orcl_route_rec.rte_id
         FROM    DUAL;
   
         --
         -- Procedure called for debugging the problem encounterd in the procedures.
         --

         debug_mesg ( in_debug_c, 'l_orcl_route_rec.rte_id: ' || l_orcl_route_rec.rte_id);

         --
         -- Call for the mapping tables to get the oracle code.
         --
         BEGIN
   
            l_new_code_s    :=    NULL;
            swgcnv_conversion_pkg.swg_map_lookup
               (   in_legacy_system_s
                  ,'SALESREP'
                  ,LTRIM(RTRIM(l_legacy_route_rec.salesperson_code))
                  ,NULL
                  ,l_new_code_s
                  ,l_new_sub_code_s
                  ,NULL
               );

            IF l_new_code_s  IS  NULL  THEN
               RAISE    NO_DATA_FOUND;
            END IF;

         EXCEPTION
            WHEN OTHERS THEN
               l_error_message_s := 'Error getting Salesrep from Map, Old Code: ' || l_legacy_route_rec.salesperson_code || CHR(10) || SQLERRM;
               GOTO    LOOP_END;
         END;

         --
         -- Based on the new code, go to the salesrep table to get the person id.
         --
   
         BEGIN
            SELECT  person_id
            INTO    l_orcl_route_rec.person_id
            FROM    jtf_rs_salesreps
            WHERE   salesrep_number    =    l_new_code_s
            AND     org_id             =    FND_PROFILE.VALUE('ORG_ID');
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               l_error_message_s    :=    'Salesrep Number ' || l_new_code_s || ' not defined in Oracle';
               GOTO LOOP_END;
            WHEN OTHERS THEN
               l_error_message_s    :=    'Error getting Salesrep from RA_SALESREPS ' || CHR(10) || SQLERRM;
               GOTO LOOP_END;
         END;  

         --
         -- Get the Route Number from a Sequence and assign values to the variables.
         --
         SELECT  swgrtm_route_number.NEXTVAL
         INTO    l_orcl_route_rec.route_number
         FROM    DUAL;

         l_orcl_route_rec.profile_required_flag       :=    'N';
         l_orcl_route_rec.non_bumpable_flag           :=    'N';  -- Changed For ARS04 
         l_orcl_route_rec.hh_extended                 :=    'N';

         l_orcl_route_rec.route_status                :=    'ACTIVE';
         l_orcl_route_rec.end_date                    :=     NULL;

         l_orcl_route_rec.start_date                  :=     l_start_date_d;  --TO_DATE('01-NOV-2009', 'DD-MON-RRRR'); -- Changed For SAGE  --SSB COMMENTED 01-19-2010
         l_orcl_route_rec.legacy_route_id             :=     in_sales_center_s||': '||LTRIM(RTRIM(l_legacy_route_rec.route_number));
         l_orcl_route_rec.description                 :=     SUBSTR(LTRIM(RTRIM(l_legacy_route_rec.route_description)),1,40);
         l_orcl_route_rec.route_type                  :=     LTRIM(RTRIM(l_legacy_route_rec.route_type));

         l_orcl_route_rec.legacy_system               :=     in_legacy_system_s;
         l_orcl_route_rec.base_cycle_day              :=     l_legacy_route_rec.service_day;
         l_orcl_route_rec.base_date                   :=     l_legacy_route_rec.service_date;
         l_orcl_route_rec.created_by                  :=     l_conversion_userid_n;
         l_orcl_route_rec.last_updated_by             :=     l_conversion_userid_n;

         l_orcl_route_rec.last_update_date            :=     SYSDATE;
         l_orcl_route_rec.creation_date               :=     SYSDATE;

         l_orcl_route_rec.last_update_login           :=     -1;

         --Added by bharat
         BEGIN
            --select DECODE(l_legacy_route_rec.frequency,'E2W',4,'E4W',3,3) --Commented by syed on 07/20/07

            SELECT DECODE(l_legacy_route_rec.frequency,'E2W',4,'E3W',10,'E4W',3,3) --Added by Syed on 07/20/07 including E3W
            INTO   l_orcl_route_rec.dfy_id
            FROM   dual;
         EXCEPTION
            WHEN OTHERS THEN
               Fnd_File.put_line(Fnd_File.LOG,'Others : '||SQLERRM);
         END;
         ---end of additions

         BEGIN
            SELECT  LTRIM(RTRIM(contacts))
            INTO    l_orcl_route_rec.contacts
            FROM    swgcnv_dd_route_interface
            WHERE   sales_center    =    l_legacy_route_rec.sales_center
            AND     route_number    =    l_legacy_route_rec.route_number
            AND     ROWNUM          =    1;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               l_orcl_route_rec.contacts    :=    NULL;
            WHEN OTHERS THEN
               l_error_message_s        :=    'Error getting UNIS Route Pagers. ' || CHR(10) ||SQLERRM;
               GOTO LOOP_END;
         END;

         --
         -- That the Route Information has been created, create the Vehicle Information.
         -- After the Vehicle Information is created, make sure that the Veh_Id in the Route Record is appropriately set.
         --

         SELECT  swgrtm_vehicles_seq.NEXTVAL
         INTO    l_orcl_veh_rec.veh_id
         FROM    DUAL;

         l_new_code_s  :=  l_legacy_route_rec.sales_center;

         BEGIN
            SELECT  organization_id
            INTO    l_orcl_veh_rec.organization_id
            FROM    org_organization_definitions
            WHERE   organization_code    =    l_new_code_s;
         EXCEPTION
            WHEN OTHERS THEN
               l_error_message_s    :=    'Error getting Inv. Org from Org_Organization_Definitions. ' || CHR(10) ||SQLERRM;
               GOTO LOOP_END;
         END;

         --
         -- Create a Dummy Vehicle Number for the Route Number.
         --

         l_orcl_veh_rec.vehicle_number        :=    'VEH-' || l_orcl_route_rec.route_number;

         IF l_orcl_route_rec.route_type    =     'DLVRY'       THEN
            l_orcl_veh_rec.vehicle_type    :=    'DELIVERY';
         ELSE
            l_orcl_veh_rec.vehicle_type    :=    'SERVICE';
         END IF;


         l_orcl_veh_rec.start_date  :=    l_start_date_d;  --TO_DATE ('01-NOV-2009', 'DD-MON-RRRR'); -- Changed For SAGE  -- SSB commented 01-19-2010
         l_orcl_veh_rec.end_date    :=    NULL;


         IF l_orcl_veh_rec.vehicle_type = 'SERVICE' THEN
            l_orcl_veh_rec.bays             :=    1;        --0;
            l_orcl_veh_rec.cubic_feet       :=    160;
            l_orcl_veh_rec.product_units    :=    99999;
            l_orcl_veh_rec.weight           :=    2160;
         ELSE
            l_orcl_veh_rec.bays             :=    8;
            l_orcl_veh_rec.cubic_feet       :=    514;
            l_orcl_veh_rec.product_units    :=    99999;
            l_orcl_veh_rec.weight           :=    12960;
         END IF;

         l_orcl_veh_rec.status               :=    'AVAILABLE';
         l_orcl_veh_rec.created_by           :=    l_conversion_userid_n;
         l_orcl_veh_rec.creation_date        :=    SYSDATE;
         l_orcl_veh_rec.last_updated_by      :=    l_conversion_userid_n;
         l_orcl_veh_rec.last_update_date     :=    SYSDATE;
         l_orcl_veh_rec.last_update_login    :=    -1;

         --
         -- Insert Vehicle Information.
         --
         BEGIN
            insert_vehicles ( l_orcl_veh_rec );
            l_veh_recs_written_n        :=    l_veh_recs_written_n    +    1;
         EXCEPTION
            WHEN OTHERS THEN
               l_error_message_s        :=    'Error inserting into Vehicles.' || CHR(10) ||SQLERRM;
               GOTO LOOP_END;
         END;
   
         --
         -- Insert Route Information.
         --

         l_orcl_route_rec.veh_id    :=    l_orcl_veh_rec.veh_id;

         BEGIN
            insert_routes ( l_orcl_route_rec );
            l_route_recs_written_n        :=    l_route_recs_written_n    +    1;
         --
         -- update the process flag in the intreface table
         --
            UPDATE swgcnv_dd_route_interface
            SET    process_flag       =   'Y'
            WHERE  route_number       =    l_legacy_route_rec.route_number
            AND    legacy_system      =    l_orcl_route_rec.legacy_system
            AND    sales_center       =    in_sales_center_s;
         EXCEPTION
            WHEN OTHERS THEN
               l_error_message_s  :=    'Error inserting into Routes.' || CHR(10) ||SQLERRM;
               GOTO LOOP_END;
         END;

         IF l_legacy_route_rec.route_service_type != 'A' THEN

            --
            --Now, start working on the SWGRTM_ROUTE_SVC_TYPES table.
            --

            l_service_tab    :=    l_empty_service_tab;

            get_service_tab
               (   l_service_tab
                  ,l_legacy_route_rec.route_number
                  ,l_legacy_route_rec.route_service_type
               );

            FOR  l_idx_bi   IN    1..l_service_tab.COUNT
            LOOP

               l_orcl_route_svc_rec    :=    NULL;

               SELECT swgrtm_rte_svc_type_seq.NEXTVAL
               INTO   l_orcl_route_svc_rec.rst_id
               FROM   DUAL;

               l_orcl_route_svc_rec.rte_id        :=    l_orcl_route_rec.rte_id;

               BEGIN

                  SELECT  inventory_item_id
                  INTO    l_orcl_route_svc_rec.service_inventory_item
                  FROM    mtl_system_items
                  WHERE   item_type          =   'SL'
                  AND     description        =    l_service_tab (l_idx_bi)
                  AND     organization_id    =    5;

                  l_orcl_route_svc_rec.created_by           :=    l_conversion_userid_n;
                  l_orcl_route_svc_rec.creation_date        :=    SYSDATE;
                  l_orcl_route_svc_rec.last_updated_by      :=    l_conversion_userid_n;
                  l_orcl_route_svc_rec.last_update_date     :=    SYSDATE;
                  l_orcl_route_svc_rec.last_update_login    :=    -1;

               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     l_error_message_s        :=    'No inventory Item Id found. ' || CHR(10) ||SQLERRM;
                  WHEN OTHERS THEN
                     l_error_message_s        :=    'Other error ' || CHR(10) ||SQLERRM;
                     GOTO LOOP_END;
               END;

               BEGIN
                  insert_route_services ( l_orcl_route_svc_rec );
                  l_srvc_recs_written_n    :=    l_srvc_recs_written_n    +    1;
               EXCEPTION
                  WHEN OTHERS THEN
                     l_error_message_s    :=    'Error inserting Services ' || CHR(10) ||SQLERRM;
                     GOTO LOOP_END;
               END;

            END LOOP; -- l_idx_bi

            IF     l_error_message_s IS NOT NULL THEN
               GOTO    LOOP_END;
            END IF;

         END IF;              -- For service type 'A', there are no services

         --
         -- Add the route to the hierarchy.
         -- The following select has to be changed to a Sequence when the form is developed.
         --

         SELECT  SWGRTM_HIERARCHY_S1.NEXTVAL
         INTO    l_orcl_hier_rec.org_relation_id
         FROM    dual;

         l_orcl_hier_rec.child_org_type    :=    'ROUTE';
         l_orcl_hier_rec.child_org_id      :=    l_orcl_route_rec.rte_id;
         l_orcl_hier_rec.parent_org_type   :=    'SWGORG';

         BEGIN

            l_new_code_s    :=    NULL;
            swgcnv_conversion_pkg.swg_map_lookup
               (   in_legacy_system_s
                  ,'ROUTE-DIST'
                  ,LTRIM(RTRIM(l_legacy_route_rec.route_number))
                  ,NULL
                  ,l_new_code_s
                  ,l_new_sub_code_s
                  ,NULL
               );

            IF     l_new_code_s IS NULL THEN
               RAISE    NO_DATA_FOUND;
            END IF;
         EXCEPTION
            WHEN OTHERS THEN
               l_error_message_s    :=  'Error getting District from Map, Old Code: ' || l_legacy_route_rec.district || CHR(10) || SQLERRM;
               GOTO LOOP_END;
         END;

         BEGIN
            SELECT swg_org_id
            INTO   l_orcl_hier_rec.parent_org_id
            FROM   swgrtm_org_definitions
            WHERE  org_type       =    'DISTRICT'
            AND       org_code    =    l_new_code_s;
         EXCEPTION
            WHEN   OTHERS THEN
               l_error_message_s    :=    'Error getting district from swgrtm_org_definitions for ' || l_new_code_s|| CHR(10) || SQLERRM;
               GOTO LOOP_END;
         END;

         l_orcl_hier_rec.start_date          :=    l_start_date_d;  --TO_DATE('01-NOV-2009', 'DD-MON-RRRR'); -- Changed For SAGE --SSB commented 01-19-2010
         l_orcl_hier_rec.end_date            :=    NULL;
         l_orcl_hier_rec.last_update_date    :=    SYSDATE;
         l_orcl_hier_rec.last_updated_by     :=    l_conversion_userid_n;
         l_orcl_hier_rec.creation_date       :=    SYSDATE;
         l_orcl_hier_rec.created_by          :=    l_conversion_userid_n;
         l_orcl_hier_rec.last_update_login   :=    NULL;

         BEGIN
            insert_hierarchy ( l_orcl_hier_rec );
            l_hier_recs_written_n        :=    l_hier_recs_written_n    +    1;
         EXCEPTION
            WHEN OTHERS THEN
               l_error_message_s        :=    'Error Inserting hierarchy. ' || CHR(10) || SQLERRM;
               GOTO LOOP_END;
         END;

         COMMIT;
         --
         -- LOOP_END Program.
         --

         <<LOOP_END>>

         IF l_error_message_s    IS NOT    NULL THEN
            ROLLBACK;
            l_err_recs_n    :=    l_err_recs_n    +    1;
            insert_exception
               (   'ROUTE'
                  ,LTRIM(RTRIM(l_legacy_route_rec.route_number))
                  ,l_error_message_s
                  ,in_sales_center_s
               ); 
            COMMIT;

         END IF;

         /* Commented by bharat
         --     IF MOD(l_recs_read_n, l_prog_rec_cnt_n) = 0 THEN
         --        INSERT 
         --        INTO        swgcnv_conversion_progress
         --             ( conversion_type
         --              ,date_time
         --              ,records_processed
         --             )
         --         VALUES    ( 'ROUTE'
         --              ,SYSDATE
         --              ,l_recs_read_n
         --             );
         --            COMMIT;
         --
         --     END IF;
         Bharat */

         Fnd_File.Put_Line(FND_FILE.LOG,'Legacy Route Number : '||l_legacy_route_rec.route_number||' Oracle Route Number: '||l_orcl_route_rec.route_number);

      END LOOP;

      Fnd_File.put_line(Fnd_File.output,in_outmsg_s);
      swg_output ('------------------------- RUN STATISTICS -----------------------------');
      swg_output (' No. of Legacy Records Read                         : ' || l_recs_read_n);
      swg_output (' No. of Legacy Records that were already processed  : ' || l_proc_recs_n);
      swg_output (' No. of Oracle Route Records Written                : ' || l_route_recs_written_n);
      swg_output (' No. of Oracle Vehicle Records Written              : ' || l_veh_recs_written_n);
      swg_output (' No. of Oracle Service Records Written              : ' || l_srvc_recs_written_n);
      swg_output (' No. of Hierarchy Records Written                   : ' || l_hier_recs_written_n);
      swg_output (' No. of Legacy Records in Error                     : ' || l_err_recs_n);
      swg_output ('----------------------------------------------------------------------');
      swg_output ('----------------------------------------------------------------------');

   END convert_routes;
   
   ------------------------------------

   PROCEDURE    swg_output(in_outmsg_s    VARCHAR2)
   IS
   BEGIN
      Fnd_File.put_line(Fnd_File.output,in_outmsg_s);
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END;
   -----------------------------------
   
   PROCEDURE   insert_exception
      (   in_conversion_type_s         IN    VARCHAR2
         ,in_conversion_key_value_s    IN    VARCHAR2
         ,in_error_message_s           IN    VARCHAR2
         ,in_conversion_sub_key2_s     IN    VARCHAR2
      )
   IS
   BEGIN
      INSERT
      INTO  swgcnv_conversion_exceptions
         (   conversion_type
            ,conversion_key_value
            ,error_message
            ,conversion_sub_key2
         )
      VALUES
         (   in_conversion_type_s
            ,in_conversion_key_value_s
            ,in_error_message_s
            ,in_conversion_sub_key2_s
         );
   EXCEPTION
      WHEN OTHERS THEN
         Fnd_File.put_line(Fnd_File.output,'error occured in insert_exception proc : '||SQLERRM);
   END insert_exception;
   
   --------------------------------------
   
   PROCEDURE   insert_vehicles ( in_orcl_veh_rec    IN    swgrtm_vehicles%ROWTYPE
                              )
   IS
   BEGIN
      INSERT
      INTO    swgrtm_vehicles
         (   veh_id
            ,organization_id
            ,vehicle_number
            ,vehicle_type
            ,start_date
            ,end_date
            ,bays
            ,cubic_feet
            ,product_units
            ,weight
            ,status
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login
         )
      VALUES
         (   in_orcl_veh_rec.veh_id
            ,in_orcl_veh_rec.organization_id
            ,in_orcl_veh_rec.vehicle_number
            ,in_orcl_veh_rec.vehicle_type
            ,in_orcl_veh_rec.start_date
            ,in_orcl_veh_rec.end_date
            ,in_orcl_veh_rec.bays
            ,in_orcl_veh_rec.cubic_feet
            ,in_orcl_veh_rec.product_units
            ,in_orcl_veh_rec.weight
            ,in_orcl_veh_rec.status
            ,in_orcl_veh_rec.created_by
            ,in_orcl_veh_rec.creation_date
            ,in_orcl_veh_rec.last_updated_by
            ,in_orcl_veh_rec.last_update_date
            ,in_orcl_veh_rec.last_update_login
         );
   EXCEPTION   
      WHEN OTHERS THEN
         Fnd_File.put_line(Fnd_File.output,'error occured in insert vehicles proc : '||SQLERRM);
   END insert_vehicles;
   
   -----------------------------------------------------
   
   PROCEDURE   insert_routes ( in_orcl_route_rec    IN    swgrtm_routes%ROWTYPE
                              )
   IS
   BEGIN

      /*
      swg_output (' Inside Insert_Routes ');
      swg_output (' in_orcl_route_rec.rte_id: ' || in_orcl_route_rec.rte_id);
      swg_output (' in_orcl_route_rec.route_number: ' || in_orcl_route_rec.route_number);
      swg_output (' in_orcl_route_rec.veh_id: ' || in_orcl_route_rec.veh_id);
      */
      INSERT
      INTO    swgrtm_routes
         (   rte_id
            ,person_id
            ,route_number
            ,veh_id
            ,route_status
            ,start_date
            ,end_date
            ,profile_required_flag
            ,non_bumpable_flag
            ,legacy_route_id
            ,description
            ,route_type
            ,legacy_system
            ,hh_extended
            ,base_date
            ,base_cycle_day
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login
            ,contacts
            ,cycle_id
            ,dfy_id
            ,holiday_auto_split
         )
      VALUES
        (    in_orcl_route_rec.rte_id
            ,in_orcl_route_rec.person_id
            ,in_orcl_route_rec.route_number
            ,in_orcl_route_rec.veh_id
            ,in_orcl_route_rec.route_status
            ,in_orcl_route_rec.start_date
            ,in_orcl_route_rec.end_date
            ,in_orcl_route_rec.profile_required_flag
            ,in_orcl_route_rec.non_bumpable_flag
            ,in_orcl_route_rec.legacy_route_id
            ,in_orcl_route_rec.description
            ,in_orcl_route_rec.route_type
            ,in_orcl_route_rec.legacy_system
            ,in_orcl_route_rec.hh_extended
            ,in_orcl_route_rec.base_date
            ,in_orcl_route_rec.base_cycle_day
            ,in_orcl_route_rec.created_by
            ,in_orcl_route_rec.creation_date
            ,in_orcl_route_rec.last_updated_by
            ,in_orcl_route_rec.last_update_date
            ,in_orcl_route_rec.last_update_login
            ,in_orcl_route_rec.contacts
            ,1
            ,in_orcl_route_rec.dfy_id --4
            ,'N'
         );
   EXCEPTION
      WHEN OTHERS THEN
         Fnd_File.put_line(Fnd_File.output,'error occured in insert route proc : '||SQLERRM);
   END insert_routes;
   
   -----------------------------------------
   
   PROCEDURE   get_service_tab
      (   io_service_tab               IN OUT    service_tab_type
         ,in_legacy_route_number_s     IN        VARCHAR2
         ,in_route_type_s              IN        VARCHAR2
      )
   IS
   BEGIN

      -- swg_output (in_route_type_s);

      IF  LTRIM(RTRIM(in_route_type_s))   =  'C'   THEN
         --    io_service_type            :=    'COFFEE SERVICE';
         io_service_tab (1)    :=    'COFFEE SERVICE';   -- Added word 'SERVICE' by Ravi on 03/04/2003
      ELSIF LTRIM(RTRIM(in_route_type_s))    =  'P'   THEN
         --    io_service_type            :=    'POU SERVICE';
         io_service_tab (1)    :=    'POU SERVICE';
      ELSIF LTRIM(RTRIM(in_route_type_s))  = 'W' THEN
         --    io_service_type            :=    'WATER SERVICE';
         io_service_tab (1)    :=    'WATER SERVICE';
      ELSIF LTRIM(RTRIM(in_route_type_s))  = 'I' THEN
         --    io_service_type            :=    'WATER SERVICE';
         io_service_tab (1)    :=    'WATER SERVICE';
      ELSIF
         LTRIM(RTRIM(in_route_type_s)) = 'WC' THEN
         --         io_service_type            :=    'WATER SERVICE';
         io_service_tab (1)    :=    'WATER SERVICE';
         --    io_service_type            :=    'WATER SERVICE';
         io_service_tab (2)    :=    'COFFEE SERVICE';
      ELSIF
         LTRIM(RTRIM(in_route_type_s)) = 'X' THEN
         --         io_service_type            :=    'WATER SERVICE';
         io_service_tab (1)    :=    'WATER SERVICE';
         --    io_service_type            :=    'WATER SERVICE';
         io_service_tab (2)    :=    'COFFEE SERVICE';
         io_service_tab (3)    :=    'POU SERVICE';
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         Fnd_File.put_line(Fnd_File.output,'error occured in get_service_tab : '||SQLERRM);
   END get_service_tab;
   
   ---------------------------------------------
   PROCEDURE   insert_route_services
      (  in_orcl_route_svc_rec       IN    swgrtm_route_svc_types%ROWTYPE
      )
   IS
   BEGIN
      INSERT
      INTO    swgrtm_route_svc_types
         (   rst_id
            ,rte_id
            ,service_inventory_item
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login
         )
      VALUES
         (   in_orcl_route_svc_rec.rst_id
            ,in_orcl_route_svc_rec.rte_id
            ,in_orcl_route_svc_rec.service_inventory_item
            ,in_orcl_route_svc_rec.created_by
            ,in_orcl_route_svc_rec.creation_date
            ,in_orcl_route_svc_rec.last_updated_by
            ,in_orcl_route_svc_rec.last_update_date
            ,in_orcl_route_svc_rec.last_update_login
         );
   EXCEPTION
      WHEN OTHERS THEN
         Fnd_File.put_line(Fnd_File.output,'error occured in insert_route_services : '||SQLERRM);
   END    insert_route_services;
   
   ------------------------------------------------
   
   PROCEDURE  debug_mesg
      (   in_debug_c    IN    VARCHAR2
         ,in_message_s  IN    VARCHAR2
      )
   IS
   BEGIN

      IF in_debug_c = 'Y' THEN
         swg_output (in_message_s);
      END IF;

   END    debug_mesg;
   
   ------------------------------------------------
   
   PROCEDURE    insert_hierarchy
      ( in_orcl_hier_rec    IN    swgrtm_org_relations%ROWTYPE
      )
   IS
   BEGIN
      INSERT
      INTO    swgrtm_org_relations
         (   org_relation_id
            ,child_org_type
            ,child_org_id
            ,parent_org_type
            ,parent_org_id
            ,start_date
            ,end_date
            ,last_update_date
            ,last_updated_by
            ,creation_date
            ,created_by
            ,last_update_login
         )
      VALUES
         (   in_orcl_hier_rec.org_relation_id
            ,in_orcl_hier_rec.child_org_type
            ,in_orcl_hier_rec.child_org_id
            ,in_orcl_hier_rec.parent_org_type
            ,in_orcl_hier_rec.parent_org_id
            ,in_orcl_hier_rec.start_date
            ,in_orcl_hier_rec.end_date
            ,in_orcl_hier_rec.last_update_date
            ,in_orcl_hier_rec.last_updated_by
            ,in_orcl_hier_rec.creation_date
            ,in_orcl_hier_rec.created_by
            ,in_orcl_hier_rec.last_update_login
         );
   EXCEPTION
      WHEN OTHERS THEN
         Fnd_File.put_line(Fnd_File.output,'error occured in insert hierarchy : '||SQLERRM);
   END    insert_hierarchy;
  
   ---------------------------------------------
   PROCEDURE ADD_ROUTE_PARAMETERS 
         (Ou_errmsg_s            OUT VARCHAR2
         ,Ou_errcode_n           OUT NUMBER
         ,in_sales_center_s      IN  VARCHAR2
         ,in_route_id_n          IN  NUMBER
         ,in_from_date_s         IN  VARCHAR2
         ,in_st_sale_loc_s       IN  VARCHAR2  
         ,in_wakeup_time_s       IN  VARCHAR2
      ) 
   IS
    CURSOR rte (c_rte_id_n NUMBER, c_sales_center_s VARCHAR2) 
    IS
	SELECT  DISTINCT route_id, 
            route_number 
	FROM    swg_hierarchy_info_v
    WHERE  	((c_rte_id_n IS NOT NULL AND route_id = c_rte_id_n) 
       OR   (c_rte_id_n IS NULL AND location_code = c_sales_center_s))
	ORDER BY route_number DESC;
          
    CURSOR param IS
    SELECT  lookup_code param_code,
            DECODE (lookup_code, 'AVG','Y','BRS','Y','DBU','D',
                                 'DDY_VALIDATION_N_UPLOAD','NEW',
                                 'DOWNLOAD_VERSION','NEW',
                                 'FCC','4','INV','N','LCK','H',
                                 'LTM','30','OAT','M','QTC','10',
                                 'QTR','5','QTV','Y','RDT','NGD',
                                 'SCA','N','SLF','Y','STC','1529886',
                                 'VINV_ALLWBL_INV_MISMATCH','0',
                                 'VINV_CODE_VERSION','NEW','') param_value
    FROM    fnd_lookup_values
    WHERE 	lookup_type    = 'SWG_DDY_PROCESSING_PARAMETERS'
    AND    	enabled_flag = 'Y'
    AND    	lookup_code != 'CFR'
    AND    	LOOKUP_CODE IN ('AVG','BRS','DBU', 'DDY_VALIDATION_N_UPLOAD',
            'DOWNLOAD_VERSION', 'FCC','INV','LCK','LTM', 'OAT','QTC','QTR','QTV', 'RDT',
            'SCA','SLF','STC', 'VINV_ALLWBL_INV_MISMATCH', 'VINV_CODE_VERSION','STL','WKT')
    AND    	TRUNC(SYSDATE) BETWEEN NVL ( start_date_active, TRUNC(SYSDATE) ) 
			AND NVL (end_date_active, TRUNC(SYSDATE))
	ORDER 	BY lookup_code;
	
	l_conversion_userid_n 	NUMBER;
	l_from_date_d			DATE;
	l_param_code			VARCHAR2(30);
	l_param_value			VARCHAR2(240);
	l_param_error_s			VARCHAR2(1) := 'N';
	l_error_flag_s			VARCHAR2(1) := 'N';
	l_error_msg_s			VARCHAR2(500);
	l_param_count_n			NUMBER := 0;
  BEGIN
	l_from_date_d := FND_DATE.CANONICAL_TO_DATE(in_from_date_s); 
	
	FND_FILE.PUT_LINE(FND_FILE.LOG,'Parameters:');
	FND_FILE.PUT_LINE(FND_FILE.LOG,'----------');
	FND_FILE.PUT_LINE(FND_FILE.LOG,'            in_sales_center_s: '||in_sales_center_s);
	FND_FILE.PUT_LINE(FND_FILE.LOG,'            in_route_id_n:        '||in_route_id_n);
	FND_FILE.PUT_LINE(FND_FILE.LOG,'            in_from_date_s:    '||in_from_date_s);
	FND_FILE.PUT_LINE(FND_FILE.LOG,'            in_st_sale_loc_s:  '||in_st_sale_loc_s);
	FND_FILE.PUT_LINE(FND_FILE.LOG,'            in_wakeup_time_s:  '||in_wakeup_time_s);
	FND_FILE.PUT_LINE(FND_FILE.LOG,'   ');
	
    SELECT   user_id
    INTO     l_conversion_userid_n
    FROM     fnd_user
    WHERE    user_name  =  'SWGCNV';
	
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Route#  Result');
	FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------  --------------------------------------------------------------------');
    
	FOR rte_rec IN rte (in_route_id_n, in_sales_center_s) LOOP
        SELECT COUNT(*) 
        INTO     l_param_count_n
        FROM    swg_ddy_rte_parameters
        WHERE  rte_id = rte_rec.route_id;

        IF l_param_count_n = 0 THEN
            IF (in_st_sale_loc_s IS NOT NULL AND in_wakeup_time_s IS NOT NULL) THEN
                -- Insert the new route parameters, exept STL and WKT .
				l_param_error_s := 'N';
				
				FOR param_rec IN param LOOP
					IF param_rec.param_code = 'STL' THEN
						l_param_value := TO_CHAR(in_st_sale_loc_s);
					ELSIF param_rec.param_code = 'WKT' THEN
						l_param_value := TO_CHAR(in_wakeup_time_s);
					ELSE
						l_param_value := param_rec.param_value;
					END IF;
					
					BEGIN
						-- Insert the Route parameter records.
						INSERT 
						INTO 	swg_ddy_rte_parameters 
							(RTE_ID				--NOT NULL NUMBER
							,ROUTE_NUMBER    	--NOT NULL VARCHAR2(4)
							,PARAMETER_CODE 	--NOT NULL VARCHAR2(30)
							,PARAMETER_VALUE 	--NOT NULL VARCHAR2(240)
							,START_DATE_ACTIVE 	--NOT NULL DATE
							,CREATION_DATE     	--NOT NULL DATE
							,CREATED_BY         --NOT NULL NUMBER
							,LAST_UPDATE_DATE 	--NOT NULL DATE
							,LAST_UPDATED_BY )	--NOT NULL NUMBER
						VALUES 	(rte_rec.route_id
							,rte_rec.route_number
							,param_rec.param_code
							,l_param_value
							,l_from_date_d
							,SYSDATE
							,l_conversion_userid_n
							,SYSDATE
							,l_conversion_userid_n);
					EXCEPTION
						WHEN OTHERS THEN
							l_error_msg_s := 'Error inserting parameters for Route:'||rte_rec.route_number||' - '||SQLERRM;
							l_param_error_s := 'Y';
							GOTO LOOP_END;
					END;
				END LOOP;
				
				<<LOOP_END>>
				IF (l_param_error_s = 'Y') THEN
					ROLLBACK;
					l_error_flag_s := 'Y';
					l_param_error_s := 'N';
					FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(rte_rec.route_number,8,' ')||l_error_msg_s);
					l_error_msg_s := NULL;
				ELSE
					COMMIT;
					FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(rte_rec.route_number,8,' ')||' Successfully inserted parameters.');
				END IF;
			ELSE
				-- Error: Mandatory value missing.
				l_error_flag_s := 'Y';
				FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(rte_rec.route_number,8,' ')||' Error: Value for "Street Sale Location" and "Wake up Time used in PC1" must be provided.');
			END IF;
		ELSE
			-- Error: Route Parameters Already exists.
			l_error_flag_s := 'Y';
			FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(rte_rec.route_number,8,' ')||' Parameters already exist.  No changes made.');
		END IF;
	END LOOP;
	IF l_error_flag_s = 'Y' THEN
	   FND_FILE.PUT_LINE(FND_FILE.LOG,'One or more route(s) failed while adding parameters.');
	   FND_FILE.PUT_LINE(FND_FILE.LOG,'Please check the output file for more information about the error.');
	   Ou_errcode_n := 1;
	END IF;
  EXCEPTION
    WHEN OTHERS THEN
	  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error: '||SQLERRM);
	  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error: '||SQLERRM);
	  Ou_errcode_n := 2;
  END add_route_parameters;
END    Swgcnv_Dd_Route_Pkg;
/
SHOW ERRORS;
EXIT;
