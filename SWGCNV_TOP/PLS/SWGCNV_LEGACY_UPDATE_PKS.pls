CREATE OR REPLACE PACKAGE SWGCNV_LEGACY_UPDATE_PKG
AS

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
                          );

PROCEDURE UPD_ROUTES      (
                           in_legacy_system_s  IN     VARCHAR2
                          );

PROCEDURE UPD_CUSTOMERS   (
                           in_legacy_system_s  IN     VARCHAR2
                          );

PROCEDURE UPD_CYCLE_DAY   (
                           in_legacy_system_s  IN     VARCHAR2
                          );

PROCEDURE UPD_EQUIPMENT   (
                           in_legacy_system_s  IN     VARCHAR2
                          );

PROCEDURE UPD_PP_AVG_ORDER(
                           in_legacy_system_s  IN     VARCHAR2 
                          );

PROCEDURE UPD_BOH         (
                           in_legacy_system_s  IN     VARCHAR2
                          );

PROCEDURE UPD_PRICING     (
                           in_legacy_system_s  IN     VARCHAR2 
                          );

PROCEDURE UPD_NOTES       (
                           in_legacy_system_s  IN     VARCHAR2 
                          );

PROCEDURE UPD_AR          (
                           in_legacy_system_s  IN     VARCHAR2 
                          );

PROCEDURE POST_UPDATES   (
                           in_legacy_system_s  IN     VARCHAR2 
                          );
            
END SWGCNV_LEGACY_UPDATE_PKG;

/

SHOW ERRORS PACKAGE SWGCNV_LEGACY_UPDATE_PKG;

EXIT;



