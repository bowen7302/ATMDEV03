CREATE OR REPLACE PACKAGE BODY  APPS.SWGCNV_ADD_CON_POINTS_PKG    AS
/* $Header: SWGCNV_ADD_CON_POINTS_PKB.pls 1.0 2010/06/18 11:00:00 MTS $ */
/*----------------------------------------------------------------------------------------------------------------------------

    Title:       SWGCNV_ADD_CON_POINTS_PKG

    File:        SWGCNV_ADD_CON_POINTS_PKB.pls

    Description: Add additional phone numbers for acqusition customers

    Copyright:   Copyright(c)    DS WATERS


    Author:      Michael Schenk

    Date:        18-JUN-2010


    Modification History:

  Date        Author          PN#        Change Description                         
  ---------   ----------      ----       ------------------------------------- 
  18-JUN-10   Michael Schenk  1567       Initial Creation
  14-FEB-13   Stephen Bowen   21240      Just Fixin
----------------------------------------------------------------------------------------------------------------------------*/    
    PROCEDURE SWGCNV_ADD_CON_POINT 
         (ou_errbuff_s          OUT   VARCHAR2
         ,ou_errcode_n          OUT   NUMBER
         ,in_legacy_code_s               IN       VARCHAR2
         ,in_sales_center_s              IN       VARCHAR2
         ,in_debug_c                 IN   VARCHAR2   
         ,in_validate_only_c             IN       VARCHAR2   
    ) 
    IS
        TYPE    swgcnv_contact_point_rec_type IS RECORD(
        insert_update_flag      VARCHAR2(1),
        contact_point_id        NUMBER,
        related_party_id        NUMBER,
        contact_point_type      VARCHAR2(30),
        contact_point_purpose   VARCHAR2(30),
        status                  VARCHAR2(1),
        primary_flag            VARCHAR2(1),
        contact_point_object_version    NUMBER,
        phone_calling_calendar  VARCHAR2(30),
        last_contact_dt_time    DATE,
        timezone_id             NUMBER,
        phone_area_code         VARCHAR2(10),
        phone_country_code      VARCHAR2(10),
        phone_number            VARCHAR2(40),
        phone_extension         VARCHAR2(20),
        phone_line_type         VARCHAR2(30),
        raw_phone_number        VARCHAR2(60),
        edi_transaction_handling    VARCHAR2(25),
        edi_id_number           VARCHAR2(30),
        edi_payment_method      VARCHAR2(30),
        edi_payment_format      VARCHAR2(30),
        edi_remittance_method   VARCHAR2(30),
        edi_remittance_instruction  VARCHAR2(30),
        edi_tp_header_id        NUMBER,
        edi_ece_tp_location_code    VARCHAR2(40),
        email_format            VARCHAR2(30),
        email_address           VARCHAR2(2000),
        telex_number            VARCHAR2(50),
        web_type                VARCHAR2(60),
        url                     VARCHAR2(2000),
        eft_transmission_program_id     NUMBER,
        eft_printing_program_id     NUMBER,
        eft_user_number         VARCHAR2(30),
        eft_swift_code          VARCHAR2(30),
        orig_system_reference       VARCHAR2(240),
        attribute_category      VARCHAR2(30),
        attribute1              VARCHAR2(150),
        attribute2              VARCHAR2(150),
        attribute3              VARCHAR2(150),
        attribute4              VARCHAR2(150),
        attribute5              VARCHAR2(150),
        attribute6              VARCHAR2(150),
        attribute7              VARCHAR2(150),
        attribute8              VARCHAR2(150),
        attribute9              VARCHAR2(150),
        attribute10             VARCHAR2(150),
        attribute11             VARCHAR2(150),
        attribute12             VARCHAR2(150),
        attribute13             VARCHAR2(150),
        attribute14             VARCHAR2(150),
        attribute15             VARCHAR2(150),
        return_status           VARCHAR2(2000),
        msg_count               NUMBER,
        msg_data                VARCHAR2(2000));

    l_contact_point_rec         swgcnv_contact_point_rec_type;

    CURSOR  cur_phone IS
    SELECT  DISTINCT
             p.rowid row_id
            ,c.customer_id
            ,i.customer_number
            ,c.address_id
            ,c.contact_first_name
            ,c.contact_last_name
            ,c.telephone_area_code||c.telephone cont_phone
            ,p.home_phone
            ,p.work_phone
            ,p.cell_phone
            ,p.cell_phone2
            ,substr(p.work_phone,1,3) telephone_area_code
            ,substr(p.work_phone,4) telephone
            ,null telephone_extension
            ,c.telephone_type
            ,c.email_address
            ,p.sales_center
            ,i.oracle_ship_site_use_id
    FROM    swgcnv.swgcnv_secondary_phone          p,
            swgcnv.swgcnv_dd_customer_contact      c,
            swgcnv.swgcnv_dd_customer_shipto       i 
    WHERE   c.customer_id                  =    i.customer_id
--       and  P.customer_number             IN ('10169907')--,'101843')
    AND     c.address_id                   =    i.ship_to_address_id
    AND     I.delivery_location_number     =    p.delivery_location_number
    AND   ( i.sub_cust_number     IS NULL
    AND     i.customer_number              =    p.customer_number
    OR      i.sub_cust_number              =    p.customer_number )
    AND     p.processed_flag               IN    ('N','E')
    ;

    l_orig_prefix               VARCHAR2(40);
    l_orig_ref                  VARCHAR2(240);
    l_seq_n                     NUMBER := 0;
    g_contact_point_rec         Hz_Contact_Point_V2pub.contact_point_rec_type;
    g_email_rec                 Hz_Contact_Point_V2pub.email_rec_type;
    g_phone_rec                 Hz_Contact_Point_V2pub.phone_rec_type;
    l_error_message_s           VARCHAR2(2000);
    l_rel_party_id_n            NUMBER;
    l_err_msg_s                 VARCHAR2(500);
    l_cnt_n                     NUMBER := 0;
    l_tab_idx                   NUMBER := 0;

    TYPE ph_rec IS RECORD (PTYPE VARCHAR2(10), PAREA VARCHAR2(3), PNUM VARCHAR2(10));
    TYPE ph_tab IS TABLE OF ph_rec INDEX BY BINARY_INTEGER;

    ptab ph_tab;
    l_leg_s                     VARCHAR2(1);
    l_ttl_errors_n              NUMBER;

BEGIN

    MO_GLOBAL.SET_POLICY_CONTEXT('S',2);
    
    SELECT   1
    INTO     l_leg_s
    FROM     fnd_lookup_values
    WHERE    lookup_code   LIKE   in_legacy_code_s||'%'
    AND      lookup_type   =  'SWG_LEGACY_SYSTEMS';

    FOR l_phone IN cur_phone LOOP

        IF (l_phone.cont_phone <> l_phone.home_phone) THEN
            l_tab_idx := ptab.count + 1;
            ptab(l_tab_idx).ptype := 'GEN';
            ptab(l_tab_idx).parea := SUBSTR(l_phone.home_phone,1,3);
            ptab(l_tab_idx).pnum  := SUBSTR(l_phone.home_phone,4,7);
        END IF;

        IF (l_phone.work_phone NOT IN
                    (l_phone.cont_phone, NVL(l_phone.home_phone,l_phone.cont_phone))) THEN
            l_tab_idx := ptab.count + 1;
            --ptab(l_tab_idx).ptype := 'OFFICE'; has been end dated
            ptab(l_tab_idx).ptype := 'GEN';
            ptab(l_tab_idx).parea := SUBSTR(l_phone.work_phone,1,3);
            ptab(l_tab_idx).pnum  := SUBSTR(l_phone.work_phone,4,7);
        END IF;

        IF (l_phone.cell_phone NOT IN
                (l_phone.cont_phone, NVL(l_phone.work_phone,l_phone.cont_phone), NVL(l_phone.home_phone,l_phone.cont_phone))) THEN
            l_tab_idx := ptab.count + 1;
            ptab(l_tab_idx).ptype := 'MOBILE';
            ptab(l_tab_idx).parea := SUBSTR(l_phone.cell_phone,1,3);
            ptab(l_tab_idx).pnum  := SUBSTR(l_phone.cell_phone,4,7);
        END IF;

        IF (l_phone.cell_phone2 NOT IN
                (l_phone.cont_phone, NVL(l_phone.work_phone,l_phone.cont_phone), NVL(l_phone.home_phone,l_phone.cont_phone)
        ,NVL(l_phone.cell_phone,l_phone.cont_phone))) THEN
            l_tab_idx := ptab.count + 1;
            ptab(l_tab_idx).ptype := 'MOBILE';
            ptab(l_tab_idx).parea := SUBSTR(l_phone.cell_phone2,1,3);
            ptab(l_tab_idx).pnum  := SUBSTR(l_phone.cell_phone2,4,7);
        END IF;

        l_orig_prefix   :=  'DD-'||in_legacy_code_s||'-'||l_phone.sales_center; 

        IF  ptab.count > 0 THEN
            FOR j IN 1..ptab.count LOOP
                l_seq_n := l_seq_n + 1;
                l_orig_ref := l_orig_prefix||'-'||l_phone.customer_number||'-'||
                        l_phone.address_id||'-'||'HEADER-'||l_phone.contact_first_name|| '-' ||
                        l_phone.contact_last_name||'-'||l_seq_n;
                l_rel_party_id_n := NULL;
                l_err_msg_s := NULL;

                BEGIN
                    SELECT  owner_table_id
                    INTO    l_rel_party_id_n
                    FROM    hz_contact_points
                    WHERE   orig_system_reference LIKE l_orig_prefix||'-'||l_phone.customer_number||'%'
                    AND     contact_point_type = 'PHONE'
                    AND     primary_flag = 'Y'
                    AND     owner_table_name = 'HZ_PARTIES'
                    AND     rownum < 2;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        BEGIN
                            SELECT  owner_table_id
                            INTO    l_rel_party_id_n
                            FROM    hz_contact_points
                            WHERE   orig_system_reference LIKE l_orig_prefix||'-'||l_phone.customer_number||'%'
                            AND     contact_point_type = 'PHONE'
                            AND     primary_flag = 'N'
                            AND     owner_table_name = 'HZ_PARTIES'
                            AND     rownum < 2;
                        EXCEPTION
                            WHEN NO_DATA_FOUND THEN
                                l_rel_party_id_n := NULL;
                                l_err_msg_s := NULL;
                            WHEN OTHERS THEN
                                l_rel_party_id_n := NULL;
                                l_err_msg_s := SQLERRM;
                        END;
                    WHEN OTHERS THEN
                        l_rel_party_id_n := NULL;
                        l_err_msg_s := SQLERRM;
                END;

                IF l_rel_party_id_n IS NOT NULL AND l_err_msg_s IS NULL THEN

                    l_cnt_n := l_cnt_n + 1;
                    l_contact_point_rec.contact_point_type  := l_phone.telephone_type;
                    l_contact_point_rec.phone_area_code     := ptab(j).parea;
                    l_contact_point_rec.phone_number        := ptab(j).pnum;
                    l_contact_point_rec.phone_extension     := null;
                    l_contact_point_rec.email_address       := l_phone.email_address;
                    l_contact_point_rec.email_format        := 'MAILHTML';
                    l_contact_point_rec.related_party_id    := l_rel_party_id_n;  --l_phone.party_id; --l_contact_rec.related_party_id;
                    l_contact_point_rec.primary_flag        := 'N';

                    l_contact_point_rec.orig_system_reference := l_orig_ref||'-'||ptab(j).parea||'-'||ptab(j).pnum;

                    g_contact_point_rec.created_by_module   :=  'SWGCNV CONVERSION API';

                    g_contact_point_rec.owner_table_name    :=  'HZ_PARTIES';
                    g_contact_point_rec.owner_table_id      :=  l_contact_point_rec.related_party_id;
                    g_contact_point_rec.contact_point_type  :=  l_contact_point_rec.contact_point_type;
                    g_contact_point_rec.primary_flag        :=  'N';        -- Secondary Contact.

                    g_phone_rec.phone_area_code             :=  l_contact_point_rec.phone_area_code;
                    g_phone_rec.phone_number                :=  l_contact_point_rec.phone_number;
                    g_phone_rec.phone_extension             :=  l_contact_point_rec.phone_extension;
                    g_phone_rec.phone_line_type             :=  ptab(j).ptype;

                    g_email_rec.email_format                  :=  l_contact_point_rec.email_format;
                    g_email_rec.email_address                 :=  l_contact_point_rec.email_address;
                    g_contact_point_rec.orig_system_reference := l_contact_point_rec.orig_system_reference;

                    Hz_Contact_Point_V2pub.create_contact_point
                        (p_init_msg_list     => Fnd_Api.G_TRUE
                        ,p_contact_point_rec => g_contact_point_rec
                        ,p_phone_rec         => g_phone_rec
                        ,p_email_rec         => g_email_rec
                        ,x_contact_point_id  => l_contact_point_rec.contact_point_id
                        ,x_return_status     => l_contact_point_rec.return_status
                        ,x_msg_count         => l_contact_point_rec.msg_count
                        ,x_msg_data          => l_contact_point_rec.msg_data );

                    IF in_validate_only_c = 'Y' THEN 
                       ROLLBACK;
                    END IF;

                    IF (l_contact_point_rec.msg_count > 1) THEN
                        FOR I IN 1..l_contact_point_rec.msg_count LOOP
                            l_contact_point_rec.msg_data   := l_contact_point_rec.msg_data|| TO_CHAR(I) || '. '
                                || SUBSTR(Fnd_Msg_Pub.Get(p_encoded => Fnd_Api.G_FALSE ), 1, 255)
                                ||CHR(10);
                        END LOOP;
                    END IF;

                    IF in_debug_c = 'Y' THEN
                       fnd_file.put_line(fnd_file.log,'cust# '||l_phone.customer_number);
                       fnd_file.put_line(fnd_file.log,'swgcnv_contact_point_api return status  '||l_contact_point_rec.return_status);
                    END IF;         

                    ----dbms_output.PUT_LINE ('swgcnv_contact_point_api return status  '||l_contact_point_rec.return_status);
                    ----dbms_output.PUT_LINE ('g_phone_rec.phone_line_type '||g_phone_rec.phone_line_type);

                    IF (l_contact_point_rec.return_status != Fnd_Api.G_RET_STS_SUCCESS) THEN

                        l_error_message_s   :=  'SWGCNV_CONTACT_POINT_API API Error '||l_contact_point_rec.msg_data;
                        ou_errbuff_s        := l_error_message_s;
                        ou_errcode_n        := 1;

                       IF in_debug_c = 'Y' THEN
                           fnd_file.PUT_LINE(fnd_file.log,l_error_message_s);
                       END IF;

                      INSERT
                      INTO    swgcnv.swgcnv_conversion_exceptions
                       ( conversion_type
                        ,conversion_key_value
                        ,conversion_sub_key1
                        ,conversion_sub_key2
                        ,error_message
                               )
                      VALUES
                        ( 'ADD CNTCTS - CONV'
                      ,l_phone.customer_number
                      ,l_phone.address_id
                      ,l_phone.sales_center
                      ,l_error_message_s
                     );

                      UPDATE swgcnv.swgcnv_secondary_phone
                      SET    processed_flag = 'E'
                      WHERE  rowid = l_phone.row_id;

                    ELSE

                      Fnd_File.Put_Line ( Fnd_File.OUTPUT, 'LEGACY# '||l_phone.customer_number||' SHIP-TO# '||l_phone.oracle_ship_site_use_id||'|'||l_phone.home_phone||'|'||l_phone.work_phone||'|'||l_phone.cell_phone||'|'||l_phone.cell_phone2);

                      IF in_validate_only_c = 'N' THEN

                          UPDATE swgcnv.swgcnv_secondary_phone
                          SET    processed_flag = 'Y'
                          WHERE  rowid = l_phone.row_id;

                      END IF;                      


                    END IF;

                    --COMMIT;

                ELSIF l_rel_party_id_n IS NULL AND l_err_msg_s IS NULL THEN
                    -- Means no contact record.  We need to create contact record before creating contact point record.

                    l_error_message_s   := 'No contact record for: '||l_phone.customer_number;
                    ou_errbuff_s        := l_error_message_s;
                    ou_errcode_n        := 1;

                    IF in_debug_c = 'Y' THEN
                       fnd_file.put_line(fnd_file.log,l_error_message_s);
                    END IF;

                    INSERT
                    INTO    swgcnv.swgcnv_conversion_exceptions
                    ( conversion_type
                    ,conversion_key_value
                    ,conversion_sub_key1
                    ,conversion_sub_key2
                    ,error_message
                       )
                    VALUES
                    ( 'ADD CNTCTS - CONV'
                    ,l_phone.customer_number
                    ,l_phone.address_id
                    ,l_phone.sales_center
                    ,l_error_message_s
                    );

                    UPDATE swgcnv.swgcnv_secondary_phone
                    SET    processed_flag = 'E'
                    WHERE  rowid = l_phone.row_id;

                ELSE

                    -- Error in retreiving contact information.
                    l_error_message_s   := 'Error getting contact info for: '||l_phone.customer_number;
                    ou_errbuff_s        := l_error_message_s;
                    ou_errcode_n        := 1; 
 
                    IF in_debug_c = 'Y' THEN 
                       fnd_file.put_line(fnd_file.log,l_error_message_s);
                    END IF;
                    
                END IF;                    

            END LOOP;

            ptab.delete;

        END IF;

    END LOOP;
    COMMIT;
    Fnd_File.Put_Line ( Fnd_File.OUTPUT, 'Out of '||l_seq_n||' records, '||l_cnt_n||' records have been successfully processed.');
    Fnd_File.Put_Line ( Fnd_File.OUTPUT, '');

    l_ttl_errors_n := 0;

    SELECT  COUNT(*) 
    INTO    l_ttl_errors_n
    FROM    swgcnv.swgcnv_conversion_exceptions
    WHERE   conversion_type = 'ADD CNTCTS - CONV';

    Fnd_File.Put_Line ( Fnd_File.OUTPUT, 'Total Errors in Conversion Exception Table '||l_ttl_errors_n);

EXCEPTION
    WHEN OTHERS THEN
      ou_errbuff_s     := 'UNEXPECTED ERROR: '||SQLERRM;
      ou_errcode_n     := 2;        
      RETURN;
END SWGCNV_ADD_CON_POINT; 
END SWGCNV_ADD_CON_POINTS_PKG; 
/
SHOW ERRORS;
EXIT;
