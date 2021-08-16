CREATE OR REPLACE PACKAGE BODY SWGCNV_SLCNTR_DIV_UPD_PKG
AS
 
/* $Header: SWGCNV_SLCNTR_DIV_UPD_PKB.pls 1.0 23-MAR-12 08:36:00  B.P                                       $ */

/*==========================================================================================================
| Copyright (c) 2006 DS Waters, Atlanta, GA 30328 USA All rights reserved.                                  |
+===========================================================================================================+
|   Name:                    SWGCNV_SLCNTR_DIV_UPD_PKG                                                      |
|                                                                                                           |
|   File:                    SWGCNV_SLCNTR_DIV_UPD_PKB.pls                                                  |
|                                                                                                           |
|   Description:             Package spec. for sales center and division update.                            |
|                                                                                                           |
|   Copyright:               Copyright(c) DS Waters                                                         |
|                                                                                                           |
|   Company:                 DS Waters                                                                      |
|                                                                                                           |
|   Author:                  Bala Palani                                                                    |
|                                                                                                           |
|   Date:                    08-MAR-2012                                                                    |
|                                                                                                           |
|   Modification History:                                                                                   |
|                                                                                                           |
|   Date          Author             WO #      Description                                                  |
|   ----          --------------     -----     -----------                                                  |
|   23-MAR-2012   Bala Palani        20129     Initial Creation                                             |
|                                                                                                           |
===========================================================================================================*/ 

  
PROCEDURE UPD_SALCNTR_DIV ( 
                           ou_errbuf_s         OUT    VARCHAR2,
                           ou_errnum_n         OUT    NUMBER,
                           in_legacy_system_s  IN     VARCHAR2,
                           in_table_name_s     IN     VARCHAR2 
                          )
IS

CURSOR location_csr IS  
     SELECT
            map.old_code legacy_sales_center,
            Swg_Hierarchy_Pkg.Get_Parent (  
                                               'ROUTE'
                                               ,map.new_code
                                               ,NULL
                                               ,'LOCATION'
                                               ,SYSDATE
                                               ,'CODE'
                                   ,'HTL')  as sales_center,
               Swg_Hierarchy_Pkg.Get_Parent (  
                                   'ROUTE'
                                   ,map.new_code
                                   ,NULL
                                   ,'DIVISION'
                                   ,SYSDATE
                                   ,'ID'
                                   ,'HTL'
                                  ) AS division            
     FROM   swgcnv_map map 
    WHERE   type_code     =   'ROUTES'
      AND   system_code   =   in_legacy_system_s
      AND   NEW_CODE     !=   'NOT MAPPED'
      AND   effctv_to IS NULL
      ;
   
   TYPE type_sales_center IS RECORD 
                                   ( 
                                    sales_center      VARCHAR2(10),
                                    division_code     VARCHAR2(10),
                                    old_sales_center  VARCHAR2(10)
                                   );
   
   TYPE location_type   IS  TABLE OF type_sales_center
      INDEX BY BINARY_INTEGER;

   location_tab   location_type;
   
   l_count_n              NUMBER := 0;
   l_route_n              NUMBER := 0;
   l_pre_route_n          NUMBER := 0;
   l_customer_n           NUMBER := 0;  
   l_pre_customer_n       NUMBER := 0;
   l_eqpmnt_n             NUMBER := 0;
   l_pre_eqpmnt_n         NUMBER := 0;
   l_ppchase_n            NUMBER := 0;
   l_pre_ppchase_n        NUMBER := 0;
   l_splprc_n             NUMBER := 0;
   l_pre_splprc_n         NUMBER := 0;
   l_ar_n                 NUMBER := 0;
   l_pre_ar_n             NUMBER := 0;
   l_avg_n                NUMBER := 0;
   l_pre_avg_n            NUMBER := 0;
   l_notes_n              NUMBER := 0;
   l_pre_notes_n          NUMBER := 0;
   l_vplan_n              NUMBER := 0;
   l_pre_vplan_n          NUMBER := 0;
   l_add_cont_n           NUMBER := 0;
   l_pre_add_cont_n       NUMBER := 0;
   
   
BEGIN

   ou_errbuf_s   :=   NULL;
   ou_errnum_n   :=   0;

   fnd_file.put_line (fnd_file.output, 'Update Legacy Sales Center Number Process');
   
   FOR location_rec IN location_csr LOOP
   
    l_count_n   := l_count_n + 1;
    
    location_tab(l_count_n).sales_center      := location_rec.sales_center;
    location_tab(l_count_n).division_code     := location_rec.division;   
    location_tab(l_count_n).old_sales_center  := location_rec.legacy_sales_center;  
    
   END LOOP;
   
   fnd_file.put_line(FND_FILE.OUTPUT,'Total Mapped Routes '||location_tab.COUNT);
   
   FOR i IN 1..location_tab.COUNT LOOP 
     
   IF UPPER(in_table_name_s) = 'SWGCNV_DD_ROUTE_INTERFACE'  OR UPPER(in_table_name_s) = 'ALL'
   THEN
   
       l_route_n      :=  0;
       l_pre_route_n  :=  0;
   
       SELECT   count(*) 
       INTO     l_pre_route_n
       FROM     SWGCNV_DD_ROUTE_INTERFACE
       WHERE    sales_center = location_tab(i).old_sales_center;
       
       IF l_pre_route_n > 0 THEN
       
         UPDATE   SWGCNV_DD_ROUTE_INTERFACE
            SET   sales_center = location_tab(i).sales_center,
                  division     = location_tab(i).division_code
          WHERE   sales_center  = location_tab(i).old_sales_center;
        
          l_route_n  := SQL%ROWCOUNT;
        
          IF l_route_n <> l_pre_route_n 
          THEN
                ou_errnum_n        := 2;
                fnd_file.put_line(FND_FILE.OUTPUT,'Error in record cnt for '||location_tab(i).old_sales_center||' SWGCNV_DD_ROUTE_INTERFACE table');
          ELSE
                fnd_file.put_line(FND_FILE.OUTPUT,'SUCCESS '||location_tab(i).old_sales_center||' => '||location_tab(i).sales_center||' SWGCNV_DD_ROUTE_INTERFACE table');          
                
                COMMIT;
                
          END IF;
          
        END IF;
        
   END IF;
    
   IF UPPER(in_table_name_s) = 'SWGCNV_DD_CB_PRESTAGING_CUST' OR UPPER(in_table_name_s) = 'ALL'
   THEN
   
      l_customer_n    :=0;
      l_pre_customer_n:=0;
   
      SELECT   count(*) 
      INTO     l_pre_customer_n
      FROM     SWGCNV_DD_CB_PRESTAGING_CUST
      WHERE    sales_center = location_tab(i).old_sales_center;
      
      IF  l_pre_customer_n  > 0
      THEN
      
            UPDATE   SWGCNV_DD_CB_PRESTAGING_CUST
               SET   sales_center  = location_tab(i).sales_center,
                     division      = location_tab(i).division_code
              WHERE  sales_center  = location_tab(i).old_sales_center;
             
            l_customer_n := SQL%ROWCOUNT;
   
            IF l_customer_n <> l_pre_customer_n THEN
              ou_errnum_n        := 2;
              fnd_file.put_line(FND_FILE.OUTPUT,'Error in record cnt for '||location_tab(i).old_sales_center||' SWGCNV_DD_CB_PRESTAGING_CUST table');
            ELSE
              fnd_file.put_line(FND_FILE.OUTPUT,'SUCCESS '||location_tab(i).old_sales_center||' => '||location_tab(i).sales_center||' SWGCNV_DD_CB_PRESTAGING_CUST table');
              
              COMMIT;
              
           END IF; 
           
      END IF;
      
   END IF;
   
   IF UPPER(in_table_name_s) = 'SWGCNV_DD_EQPMNT_INTERFACE' OR UPPER(in_table_name_s) = 'ALL'
   THEN
   
      l_eqpmnt_n     := 0;
      l_pre_eqpmnt_n := 0;
      
      SELECT   count(*) 
      INTO     l_pre_eqpmnt_n
      FROM     SWGCNV_DD_EQPMNT_INTERFACE
      WHERE    sales_center = location_tab(i).old_sales_center;
              
      IF  l_pre_eqpmnt_n > 0
      THEN
      
            UPDATE   SWGCNV_DD_EQPMNT_INTERFACE
               SET   sales_center = location_tab(i).sales_center,
                      division     = location_tab(i).division_code
              WHERE   sales_center = location_tab(i).old_sales_center;
             
              l_eqpmnt_n := SQL%ROWCOUNT;
              
           IF l_eqpmnt_n <> l_pre_eqpmnt_n THEN
              ou_errnum_n        := 2;
              fnd_file.put_line(FND_FILE.OUTPUT,'Error in record cnt for '||location_tab(i).old_sales_center||' SWGCNV_DD_EQPMNT_INTERFACE table');
              ELSE
              fnd_file.put_line(FND_FILE.OUTPUT,'SUCCESS '||location_tab(i).old_sales_center||' => '||location_tab(i).sales_center||' SWGCNV_DD_EQPMNT_INTERFACE table');
              
              COMMIT;
              
           END IF;

     END IF;
     
   END IF;
       
   IF UPPER(in_table_name_s) = 'SWGCNV_DD_SPECIAL_PRICE' OR UPPER(in_table_name_s) = 'ALL'
   THEN
   
       l_splprc_n     := 0;
       l_pre_splprc_n := 0;
   
      SELECT     count(*) 
        INTO     l_pre_splprc_n
        FROM     SWGCNV_DD_SPECIAL_PRICE
       WHERE     sales_center = location_tab(i).old_sales_center;
       
       IF l_pre_splprc_n > 0
       THEN
       
             UPDATE   SWGCNV_DD_SPECIAL_PRICE
                SET   sales_center = location_tab(i).sales_center,
                       division     = location_tab(i).division_code
               WHERE   sales_center = location_tab(i).old_sales_center;
              
              l_splprc_n := SQL%ROWCOUNT;
       
       IF l_splprc_n <> l_pre_splprc_n
       THEN

           ou_errnum_n        := 2;
           fnd_file.put_line(FND_FILE.OUTPUT,'Error in record cnt for '||location_tab(i).old_sales_center||' SWGCNV_DD_SPECIAL_PRICE table');
           ELSE
           fnd_file.put_line(FND_FILE.OUTPUT,'SUCCESS '||location_tab(i).old_sales_center||' => '||location_tab(i).sales_center||' SWGCNV_DD_SPECIAL_PRICE table');
           
           COMMIT;
                      
     END IF;
   END IF;
    
   END IF;
   
   IF UPPER(in_table_name_s) = 'SWGCNV_DD_AVRG_ORDER' OR UPPER(in_table_name_s) = 'ALL'
   THEN
   
      l_avg_n     := 0;
      l_pre_avg_n := 0;
   
      SELECT   count(*) 
      INTO     l_pre_avg_n
      FROM     SWGCNV_DD_AVRG_ORDER
     WHERE     sales_center = location_tab(i).old_sales_center;
     
     IF l_pre_avg_n  > 0
     THEN
        
        UPDATE  SWGCNV_DD_AVRG_ORDER
        SET     sales_center = location_tab(i).sales_center,
                division     = location_tab(i).division_code
        WHERE   sales_center = location_tab(i).old_sales_center;
        
        l_avg_n := SQL%ROWCOUNT;
      
        IF l_avg_n <> l_pre_avg_n 
        THEN
           ou_errnum_n        := 2;
           fnd_file.put_line(FND_FILE.OUTPUT,'Error in record cnt for '||location_tab(i).old_sales_center||' SWGCNV_DD_AVRG_ORDER table'); 
           ELSE
           fnd_file.put_line(FND_FILE.OUTPUT,'SUCCESS '||location_tab(i).old_sales_center||' => '||location_tab(i).sales_center||' SWGCNV_DD_AVRG_ORDER table'); 
           
           COMMIT;
           
        END IF;
        
     END IF;

   END IF;      

   IF UPPER(in_table_name_s) = 'SWGCNV_DD_AR_HISTORY' OR UPPER(in_table_name_s) = 'ALL'
   THEN
       
        l_pre_ar_n  := 0;
        l_ar_n      := 0;   
   
        SELECT   count(*) 
        INTO     l_pre_ar_n
        FROM     SWGCNV_DD_AR_HISTORY
       WHERE     sales_center = location_tab(i).old_sales_center;
           
        IF l_pre_ar_n  > 0
        THEN
        
              UPDATE   SWGCNV_DD_AR_HISTORY
                 SET   sales_center  = location_tab(i).sales_center,
                        division     = location_tab(i).division_code
                WHERE   sales_center = location_tab(i).old_sales_center;
               
           l_ar_n :=  SQL%ROWCOUNT;
        
         IF l_ar_n <> l_pre_ar_n 
         THEN
           ou_errnum_n        := 2;
           fnd_file.put_line(FND_FILE.OUTPUT,'Error in record cnt for '||location_tab(i).old_sales_center||' SWGCNV_DD_AR_HISTORY table'); 
           ELSE
           fnd_file.put_line(FND_FILE.OUTPUT,'SUCCESS '||location_tab(i).old_sales_center||' => '||location_tab(i).sales_center||' SWGCNV_DD_AR_HISTORY table');
           
           COMMIT;
           
         END IF;       
      
     END IF;
   
   END IF;
   
   IF UPPER(in_table_name_s) = 'SWGCNV_DD_CUST_NOTES' OR UPPER(in_table_name_s) = 'ALL'
   THEN
   
        l_pre_notes_n  := 0;
        l_notes_n      := 0;    
   
         SELECT   COUNT(*)
           INTO   l_pre_notes_n
           FROM   SWGCNV_DD_CUST_NOTES
          WHERE   sales_center = location_tab(i).old_sales_center;
           
         IF  l_pre_notes_n > 0
         THEN       
        
              UPDATE   SWGCNV_DD_CUST_NOTES
                 SET   sales_center = location_tab(i).sales_center
               WHERE   sales_center = location_tab(i).old_sales_center;
               
               l_notes_n :=  SQL%ROWCOUNT;
               
              IF l_notes_n <> l_pre_notes_n
              THEN     

                ou_errnum_n        := 2;
                fnd_file.put_line(FND_FILE.OUTPUT,'Error in record cnt for '||location_tab(i).old_sales_center||' SWGCNV_DD_CUST_NOTES table');
                ELSE
                fnd_file.put_line(FND_FILE.OUTPUT,'SUCCESS '||location_tab(i).old_sales_center||' => '||location_tab(i).sales_center||' SWGCNV_DD_CUST_NOTES table');
                
                COMMIT;
                            
              END IF;
         END IF;
     
   END IF;
   
   IF UPPER(in_table_name_s) = 'SWGCNV_SECONDARY_PHONE' OR UPPER(in_table_name_s) = 'ALL'
   THEN
   
        l_pre_add_cont_n  := 0;
        l_add_cont_n      := 0;    
   
         SELECT   COUNT(*)
           INTO   l_pre_add_cont_n
           FROM   SWGCNV_SECONDARY_PHONE
          WHERE   sales_center = location_tab(i).old_sales_center;
           
         IF  l_pre_add_cont_n > 0
         THEN       
        
              UPDATE   SWGCNV_SECONDARY_PHONE
                 SET   sales_center = location_tab(i).sales_center
               WHERE   sales_center = location_tab(i).old_sales_center;
               
               l_add_cont_n :=  SQL%ROWCOUNT;
               
              IF l_add_cont_n <> l_pre_add_cont_n
              THEN     

                ou_errnum_n        := 2;
                fnd_file.put_line(FND_FILE.OUTPUT,'Error in record cnt for '||location_tab(i).old_sales_center||' SWGCNV_SECONDARY_PHONE table');
                ELSE
                fnd_file.put_line(FND_FILE.OUTPUT,'SUCCESS '||location_tab(i).old_sales_center||' => '||location_tab(i).sales_center||' SWGCNV_SECONDARY_PHONE table');
                
                COMMIT;
            
              END IF;
         END IF;
     
   END IF;
          
   IF UPPER(in_table_name_s) = 'SWGCNV_DD_CUSTOMER_VPLAN' OR  UPPER(in_table_name_s) = 'ALL'
   THEN

      SELECT   COUNT(*)
        INTO   l_pre_vplan_n
        FROM   SWGCNV_DD_CUSTOMER_VPLAN
       WHERE   sales_center = location_tab(i).old_sales_center;
     
      IF l_pre_vplan_n > 0
      THEN
      
       UPDATE   SWGCNV_DD_CUSTOMER_VPLAN
         SET    sales_center = location_tab(i).sales_center,
                division     = location_tab(i).division_code
        WHERE   sales_center = location_tab(i).old_sales_center;
      
        l_vplan_n := SQL%ROWCOUNT;     

        IF l_pre_vplan_n <> l_pre_vplan_n
        THEN

           ou_errnum_n        := 2;
           fnd_file.put_line(FND_FILE.OUTPUT,'Error in record cnt for '||location_tab(i).old_sales_center||' SWGCNV_DD_CUSTOMER_VPLAN table');
        ELSE
           fnd_file.put_line(FND_FILE.OUTPUT,'SUCCESS '||location_tab(i).old_sales_center||' => '||location_tab(i).sales_center||' SWGCNV_DD_CUSTOMER_VPLAN table');
           
           COMMIT;
        
        END IF;
      
      END IF;
      
   END IF;
   
   END LOOP;
     
   fnd_file.put_line (fnd_file.output, 'All Route numbers mapped to sales centers');

EXCEPTION

    WHEN OTHERS THEN
    
    ROLLBACK;
    
    fnd_file.put_line(FND_FILE.OUTPUT,'Unexpected Error: '||dbms_utility.format_error_backtrace);
    
    ou_errbuf_s   :=   dbms_utility.format_error_backtrace;
    ou_errnum_n   :=   2;
    
END;

END SWGCNV_SLCNTR_DIV_UPD_PKG;

/

SHOW ERRORS

EXIT;



