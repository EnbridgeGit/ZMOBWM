class Z_SMERP_MDO_PM_NOTIF definition
  public
  final
  create public .

public section.
*"* public components of class Z_SMERP_MDO_PM_NOTIF
*"* do not include other source files here!!!

  interfaces /SMERP/IF_PM_NOTIF_BADI .
  interfaces IF_BADI_INTERFACE .
protected section.
*"* protected components of class Z_SMERP_MDO_PM_NOTIF
*"* do not include other source files here!!!
private section.
*"* private components of class Z_SMERP_MDO_PM_NOTIF
*"* do not include other source files here!!!

  data GV_AUART type AUFART .
  data GV_ILART type ILA .
  data GV_TECOX type CHAR1 .
  data GV_DAUNO type DAUNOR .
  data GV_DAUNE type DAUNORE .
ENDCLASS.



CLASS Z_SMERP_MDO_PM_NOTIF IMPLEMENTATION.


METHOD /smerp/if_pm_notif_badi~create_begin.

  DATA: BEGIN OF ls_mdo_input_vals,
          iv_notif_no           TYPE REF TO qmnum,
          iv_notif_type         TYPE REF TO qmart,
          iv_task_determination TYPE REF TO bapiflag,
          is_notif_sender       TYPE REF TO bapi_sender,
          iv_notif_ref_orderid  TYPE REF TO aufnr,
          is_notif_header       TYPE REF TO bapi2080_nothdri,
          it_notif_item         TYPE REF TO /syclo/pm_notitemi_tab,
          it_notif_cause        TYPE REF TO /syclo/pm_notcausi_tab,
          it_notif_task         TYPE REF TO /syclo/pm_nottaski_tab,
          it_notif_activity     TYPE REF TO /syclo/pm_notactvi_tab,
          it_notif_partner      TYPE REF TO /syclo/pm_notpartnri_tab,
          it_notif_longtext     TYPE REF TO /syclo/pm_notfulltxti_tab,
          it_notif_key_rela     TYPE REF TO /syclo/pm_notkeye_tab,
        END OF ls_mdo_input_vals.

  DATA: ls_bapi2080 TYPE bapi2080_nothdri.

  ls_mdo_input_vals = cs_mdo_input_vals.

  ls_bapi2080 = ls_mdo_input_vals-is_notif_header->*.

  CLEAR: gv_auart, gv_ilart, gv_tecox.
  gv_auart = ls_bapi2080-zzauart.
  gv_ilart = ls_bapi2080-zzilart.
  gv_tecox = ls_bapi2080-zztecox.
  gv_dauno = ls_bapi2080-zzdauno.
  gv_daune = ls_bapi2080-zzdaune.

ENDMETHOD.


METHOD /smerp/if_pm_notif_badi~create_end.

  DATA: BEGIN OF ls_mdo_output_vals,
          es_notif_header      TYPE REF TO bapi2080_nothdre,
          es_notif_header_text TYPE REF TO bapi2080_nothdtxte,
          et_notif_item        TYPE REF TO /syclo/pm_notitemi_tab,
          et_notif_cause       TYPE REF TO /syclo/pm_notcausi_tab,
          et_notif_task        TYPE REF TO /syclo/pm_nottaski_tab,
          et_notif_activity    TYPE REF TO /syclo/pm_notactvi_tab,
          et_notif_partner     TYPE REF TO /syclo/pm_notpartnri_tab,
          et_notif_longtext    TYPE REF TO /syclo/pm_notfulltxti_tab,
          et_notif_key_rela    TYPE REF TO /syclo/pm_notkeye_tab,
        END OF ls_mdo_output_vals,

       lit_methods    TYPE STANDARD TABLE OF bapi_alm_order_method,
       ls_methods     TYPE bapi_alm_order_method,
       lit_header     TYPE STANDARD TABLE OF bapi_alm_order_headers_i,
       ls_header      TYPE bapi_alm_order_headers_i,
       lit_objects    TYPE STANDARD TABLE OF bapi_alm_order_objectlist,
       ls_objects     TYPE bapi_alm_order_objectlist,
       lit_operations TYPE STANDARD TABLE OF bapi_alm_order_operation,
       ls_operations  TYPE bapi_alm_order_operation,
       lit_header_up  TYPE STANDARD TABLE OF bapi_alm_order_headers_up,
       ls_header_up   TYPE bapi_alm_order_headers_up,
       lit_return     TYPE STANDARD TABLE OF bapiret2,
       ls_return      TYPE bapiret2.

  DATA: lv_arbpl TYPE arbpl,
        lv_aufnr TYPE aufnr,
        lv_aufpl TYPE afko-aufpl,
        lv_aplzl TYPE afvc-aplzl,
        lv_objnr TYPE jsto-objnr.

  IF gv_auart IS NOT INITIAL.
    ls_mdo_output_vals = cs_mdo_output.

    ls_methods-refnumber = '000001'.
    ls_methods-objecttype = 'HEADER'.
    ls_methods-method = 'CREATETONOTIF'.
    CONCATENATE '%00000000001' ls_mdo_output_vals-es_notif_header->*-notif_no INTO ls_methods-objectkey.
    APPEND ls_methods TO lit_methods.
    CLEAR ls_methods.

    ls_methods-refnumber = '000001'.
    ls_methods-objecttype = 'OPERATION'.
    ls_methods-method = 'CREATE'.
    ls_methods-objectkey = '%000000000010010'.
    APPEND ls_methods TO lit_methods.
    CLEAR ls_methods.

    ls_methods-refnumber = '000001'.
    ls_methods-objecttype = 'HEADER'.
    ls_methods-method = 'RELEASE'.
    ls_methods-objectkey = '%00000000001'.
    APPEND ls_methods TO lit_methods.
    CLEAR ls_methods.

    ls_methods-refnumber = '000001'.
    ls_methods-objecttype = space.
    ls_methods-method = 'SAVE'.
    ls_methods-objectkey = '%00000000001'.
    APPEND ls_methods TO lit_methods.
    CLEAR ls_methods.

    ls_header-orderid = '%00000000001'.
    ls_header-order_type = gv_auart.
    ls_header-pmacttype = gv_ilart.
    ls_header-notif_no = ls_mdo_output_vals-es_notif_header->*-notif_no.
    APPEND ls_header TO lit_header.
    CLEAR ls_header.

*    ls_header_up-orderid = '%00000000001'.
*    ls_header_up-notif_no = 'X'.
*    ls_header_up-pmacttype = 'X'.
*    APPEND ls_header_up TO lit_header_up.
*    CLEAR ls_header_up.

    GET PARAMETER ID 'VAP' FIELD lv_arbpl.
    ls_operations-control_key = 'PM01'.
    ls_operations-work_cntr = lv_arbpl.
    ls_operations-plant = ls_mdo_output_vals-es_notif_header->*-planplant.
    ls_operations-description = ls_mdo_output_vals-es_notif_header->*-short_text.
    ls_operations-duration_normal = gv_dauno.
    ls_operations-duration_normal_unit = gv_daune.
    ls_operations-activity = '0010'.
    APPEND ls_operations TO lit_operations.
    CLEAR ls_operations.

    CALL FUNCTION 'BAPI_ALM_ORDER_MAINTAIN'
      TABLES
        it_methods    = lit_methods
        it_header     = lit_header
*        it_header_up  = lit_header_up
        it_operation  = lit_operations
        it_objectlist = lit_objects
        return        = lit_return.

    READ TABLE lit_return WITH KEY type = 'E'
                                id = 'C2'
                                number = '009'
                       TRANSPORTING NO FIELDS.

    IF sy-subrc = 0.
      REFRESH: lit_return.
      READ TABLE lit_methods INTO ls_methods WITH KEY method = 'RELEASE'.
      DELETE TABLE lit_methods FROM ls_methods.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

      CALL FUNCTION 'BAPI_ALM_ORDER_MAINTAIN'
        TABLES
          it_methods   = lit_methods
          it_header    = lit_header
          it_operation = lit_operations
          return       = lit_return.
    ENDIF.


    LOOP AT lit_return INTO ls_return WHERE type = 'E' OR
                                            type = 'A'.
      EXIT.
    ENDLOOP.

    CHECK sy-subrc NE 0.

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'.

    READ TABLE lit_return INTO ls_return WITH KEY type = 'S'
                                                  id = 'IWO_BAPI2'
                                                  number = '112'.
    IF sy-subrc NE 0.
      READ TABLE lit_return INTO ls_return WITH KEY type = 'S'
                                                  id = 'IWO_BAPI2'
                                                  number = '126'.

      IF SY-subrc NE 0.
        EXIT.
      ENDIF.

    ENDIF.

    lv_aufnr = ls_return-message_v2.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_aufnr
      IMPORTING
        output = lv_aufnr.

    SELECT SINGLE  aufpl FROM afko
                         INTO lv_aufpl
                         WHERE aufnr = lv_aufnr.
    IF sy-subrc EQ 0.

      SELECT SINGLE aplzl FROM afvc
                          INTO lv_aplzl
                          WHERE aufpl = lv_aufpl AND vornr = '0010'.

      CONCATENATE 'OV' lv_aufpl lv_aplzl INTO lv_objnr.

      CALL FUNCTION 'STATUS_CHANGE_EXTERN'
        EXPORTING
          objnr               = lv_objnr
          user_status         = 'E0002'
        EXCEPTIONS
          object_not_found    = 1
          status_inconsistent = 2
          status_not_allowed  = 3
          OTHERS              = 4.

      IF sy-subrc EQ 0.
        COMMIT WORK.
      ENDIF.
    ENDIF.
  ENDIF.

ENDMETHOD.


method /SMERP/IF_PM_NOTIF_BADI~GET_ASSIGNMENT_OTHERS.

endmethod.


method /SMERP/IF_PM_NOTIF_BADI~GET_ASSIGNMENT_TYPE1.
endmethod.


method /SMERP/IF_PM_NOTIF_BADI~GET_ASSIGNMENT_TYPE2.
endmethod.


method /SMERP/IF_PM_NOTIF_BADI~GET_ASSIGNMENT_TYPE3.
endmethod.


method /SMERP/IF_PM_NOTIF_BADI~GET_ASSIGNMENT_TYPE4.
endmethod.


method /SMERP/IF_PM_NOTIF_BADI~GET_ASSIGNMENT_TYPE5.
endmethod.


method /SMERP/IF_PM_NOTIF_BADI~GET_ASSIGNMENT_TYPE9.
* Get Notifications Assigned based on work orders currently assigned to user

  DATA: lit_woassign TYPE TABLE OF zsmerp_woassign,
        lwa_woassign LIKE LINE OF lit_woassign,
        lit_notif_tab TYPE /syclo/pm_notif_object_tab.

  SELECT * FROM zsmerp_woassign INTO TABLE lit_woassign
           WHERE uname = sy-uname.

  IF NOT lit_woassign[] is initial.

    SELECT qmnum objnr FROM qmel
      INTO TABLE lit_notif_tab
      FOR ALL ENTRIES IN lit_woassign
      WHERE aufnr = lit_woassign-aufnr.

    APPEND LINES OF lit_notif_tab to ct_notif_object.
    SORT ct_notif_object by QMNUM.
    DELETE ADJACENT DUPLICATES FROM ct_notif_object.

  ENDIF.
endmethod.


method /SMERP/IF_PM_NOTIF_BADI~GET_BEGIN.
endmethod.


method /SMERP/IF_PM_NOTIF_BADI~GET_END.
endmethod.


method /SMERP/IF_PM_NOTIF_BADI~GET_KEYLIST_FROM_EXCHOBJ.
endmethod.


method /SMERP/IF_PM_NOTIF_BADI~MAP_SYST_STATUS.
endmethod.


method /SMERP/IF_PM_NOTIF_BADI~MAP_USER_STATUS.
endmethod.


method /SMERP/IF_PM_NOTIF_BADI~UPDATE_BEGIN.
endmethod.


method /SMERP/IF_PM_NOTIF_BADI~UPDATE_END.
endmethod.


method /SMERP/IF_PM_NOTIF_BADI~UPDATE_SYST_STATUS.
endmethod.
ENDCLASS.
