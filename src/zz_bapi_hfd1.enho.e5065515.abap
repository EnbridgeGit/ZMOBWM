"Name: \PR:SAPLIBAPI_H\FO:H_SET_NOTIF_DATA\SE:END\EI
ENHANCEMENT 0 ZZ_BAPI_HFD1.
* 20140916 PwC enhancement for BAPI_ALM_ORDER_MAINTAIN - need method 'CREATETONOTIF' to supply number on header
  IF cs_caufvd-akknz = y_akknz_iw34 AND
     cs_caufvd-qmnum IS INITIAL.
    cs_caufvd-qmnum = is_viqmel-qmnum.
  ENDIF.
ENDENHANCEMENT.
