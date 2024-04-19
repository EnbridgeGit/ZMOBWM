"Name: \TY:/SMERP/CL_PM_WORKORDER_DO\ME:UPDATE_WO_MOBILE_STATUS\SE:END\EI
ENHANCEMENT 0 ZZENH_SMERP_WO_STATUS.
* 2014/10/09 PwC SLOWENBE
* If the Mobile Status is "STRT" ensure the non-sequential status "HOLD" is set to inactive
  CONSTANTS lv_holdstatus TYPE tj30-estat VALUE 'E0006'.
  IF me->user_status = 'E0003' AND me->object_type = lc_woop_object_type.

    CALL FUNCTION 'STATUS_CHANGE_EXTERN'
          EXPORTING
            client              = sy-mandt
            objnr               = lv_objnr
            user_status         = lv_holdstatus
            SET_INACT           = 'X'
          EXCEPTIONS
            object_not_found    = 1
            status_inconsistent = 2
            status_not_allowed  = 3
            OTHERS              = 4.
  ENDIF.
* End SLOWENBE
ENDENHANCEMENT.
