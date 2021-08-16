CREATE OR REPLACE PACKAGE APPS.SWGCNV_RAINBOW_PRICING_PKG
AS
   /* $Header:  SWGCNV_RAINBOW_PRICING_PKS.pls 1.0 2016/03/01 09:33:33 PU $ */
   /*==========================================================================+
   | Copyright (c) 2016 DS Waters, Atlanta, GA 30328 USA All rights reserved.  |
   +===========================================================================+
   |                                                                           |
   | File Name:     SWGCNV_RAINBOW_PRICING_PKS.pls                             |
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
   +==========================================================================*/

PROCEDURE  SWGCNV_CREATE_PRICING(
                                 ou_err_buff_s    OUT    VARCHAR2
                                ,ou_err_code_n    OUT    NUMBER
                                ,in_legacy_code_s IN     VARCHAR2
                               );
END SWGCNV_RAINBOW_PRICING_PKG;
/
SHOW ERRORS
exit
