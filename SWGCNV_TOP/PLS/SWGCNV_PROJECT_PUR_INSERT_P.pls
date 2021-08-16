CREATE OR REPLACE PROCEDURE swgcnv_Project_pur_insert (
      ou_errbuf_s    	OUT   	VARCHAR2,
      ou_errcode_n   	OUT   	NUMBER,
      in_sales_center_s IN 	VARCHAR2,
      in_division_s  	IN 	VARCHAR2
   )
   IS
   g_stmt_msg_s                     VARCHAR2 (3000);
   l_error_msg_s                    VARCHAR2 (2000);
   l_system_code_s                  VARCHAR2 (20):='ARS02'; --For Abita Conversion 07/16/07

   l_average_qty_n                  NUMBER;
   l_customer_number_s              swgcnv_dd_customer_shipto.customer_number%TYPE;
   l_delivery_location_number_s     swgcnv_dd_customer_shipto.delivery_location_number%TYPE;

   g_cnt_inst_n                     number:=0;
   g_proj_pur_cnt_n                 number:=0;
   l_cnt_avg_n                      number:=0;
   l_err_cnt				        number:=0;
   DEL_LOC_NULL                     EXCEPTION;     

BEGIN

   -- Start of Procedure

 	ou_errbuf_s    	:= NULL;
      ou_errcode_n   	:= 0;

   g_stmt_msg_s :=' Before main cursor c1rec ';

   FOR c1rec IN (SELECT   * FROM swgcnv.swgcnv_proj_pur_prestage
                 WHERE sales_center = in_sales_center_s
                 AND   division     = in_division_s
                 ORDER BY route_id)
   LOOP
     BEGIN
      l_average_qty_n := 0;

      g_proj_pur_cnt_n :=g_proj_pur_cnt_n+1;

      g_stmt_msg_s :=' Getting avg qty ';

       SELECT   SUM (nvl(c1rec.qty1,0) + nvl(c1rec.qty2,0) + nvl(c1rec.qty3,0) + nvl(c1rec.qty4,0)
                    + nvl(c1rec.qty5,0)
                   )
             / 5
        INTO l_average_qty_n
        FROM DUAL;
         
            l_customer_number_s := c1rec.route_id;
         
           -- l_counter_n := 1;

		/*
		||   Get the delivery location number
		||   Call function swgcnv_cnv_util_pkg.swgcnv_get_del_loc
		*/
            g_stmt_msg_s :='Get delivery location number by calling -Function swgcnv_cnv_util_pkg.swgcnv_get_del_loc ';

	   	l_delivery_location_number_s   :=swgcnv_cnv_util_pkg.swgcnv_get_del_loc (l_system_code_s,l_customer_number_s );

            IF l_delivery_location_number_s   IS NULL
            THEN
              g_stmt_msg_s  :='Function Return Null  delivery location number for the customer :'||l_customer_number_s; 
              --fnd_file.put_line (fnd_file.LOG,'Function Return Null delivery loca num for the customer :'||l_customer_number_s );
              Raise DEL_LOC_NULL; 
            END IF;

             g_stmt_msg_s :='Insert rec into avg table ';

              INSERT INTO swgcnv.swgcnv_dd_avrg_order
                     (
                      	CUSTOMER_NUMBER,
			DELIVERY_LOCATION_NUMBER,
			ITEM_CODE, 
			AVERAGE_QTY,
			UNIT_PRICE,
			TAX_RATE,
			SALES_CENTER,
			DIVISION,
			VALID_FLAG,
                        ITEM_SUB_CODE
                     )
              VALUES (l_customer_number_s,
                      nvl(l_delivery_location_number_s,'XXX'),
                      c1rec.prod_id,                           
                      l_average_qty_n,
                      NULL,
                      NULL,
                      in_sales_center_s,      
                      in_division_s,            
                      'N',
                      NULL
                     );
			l_cnt_avg_n :=l_cnt_avg_n+1;

     EXCEPTION
	   WHEN DEL_LOC_NULL
	   THEN
	      l_error_msg_s := ' ---<Error DEL_LOC_NULL->---: ' || SQLERRM;
	      l_error_msg_s := g_stmt_msg_s ||'---'||l_error_msg_s ;
	      l_err_cnt :=l_err_cnt +1;
	      fnd_file.put_line (fnd_file.LOG,l_error_msg_s);

	  WHEN OTHERS 
          THEN
	    	l_error_msg_s := g_stmt_msg_s ||'--Error  Others in  Loop :'|| SQLERRM;	
            l_err_cnt :=l_err_cnt +1;
		fnd_file.put_line (fnd_file.LOG,l_error_msg_s);

      END;
   END LOOP;
	   		Fnd_File.Put_Line(Fnd_File.LOG,'*************************************************************************');
       		Fnd_File.Put_Line(Fnd_File.LOG,' S E E  T H E  O U T P U T  F I L E for records load details' );
      		Fnd_File.Put_Line(Fnd_File.LOG,'*************************************************************************');

      		Fnd_File.Put_Line(Fnd_File.OUTPUT,'*************************  RUN STATISTICS *******************************');

	       	Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of  Records read from proj_pur_prestag table  : ' ||g_proj_pur_cnt_n);
	   	      Fnd_File.Put_Line(Fnd_File.OUTPUT,'*************************************************************************');
       		Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of  Records Inserted in average table   : ' ||l_cnt_avg_n);
	   		Fnd_File.Put_Line(Fnd_File.OUTPUT,'*************************************************************************');
       		Fnd_File.Put_Line(Fnd_File.OUTPUT,' No. of  Records failed record  : ' ||l_err_cnt);
	   		Fnd_File.Put_Line(Fnd_File.OUTPUT,'*************************************************************************');
EXCEPTION

   WHEN OTHERS
   THEN
      l_error_msg_s := ' ---<Error>---: ' || SQLERRM;
      l_error_msg_s := l_error_msg_s || '---- ' || g_stmt_msg_s;
      
      fnd_file.put_line (fnd_file.LOG,l_error_msg_s);
END swgcnv_Project_pur_insert;
/
show err;
exit;

