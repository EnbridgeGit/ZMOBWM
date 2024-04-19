class ZCL_SMERP_MDO_PM_WO definition
  public
  final
  create public .

public section.
*"* public components of class ZCL_SMERP_MDO_PM_WO
*"* do not include other source files here!!!

  interfaces /SMERP/IF_PM_WO_BADI .
  interfaces IF_BADI_INTERFACE .
protected section.
*"* protected components of class ZCL_SMERP_MDO_PM_WO
*"* do not include other source files here!!!
private section.
*"* private components of class ZCL_SMERP_MDO_PM_WO
*"* do not include other source files here!!!

  class-data GT_METHODS type BAPI_ALM_ORDER_METHOD_T .
ENDCLASS.



CLASS ZCL_SMERP_MDO_PM_WO IMPLEMENTATION.


method /SMERP/IF_PM_WO_BADI~CREATE_BEGIN.
endmethod.


method /SMERP/IF_PM_WO_BADI~CREATE_END.
endmethod.


method /SMERP/IF_PM_WO_BADI~GET_ASSIGNMENT_OTHERS.
endmethod.


method /SMERP/IF_PM_WO_BADI~GET_ASSIGNMENT_TYPE1.
endmethod.


method /SMERP/IF_PM_WO_BADI~GET_ASSIGNMENT_TYPE2.
endmethod.


method /SMERP/IF_PM_WO_BADI~GET_ASSIGNMENT_TYPE3.
endmethod.


method /SMERP/IF_PM_WO_BADI~GET_ASSIGNMENT_TYPE4.
endmethod.


method /SMERP/IF_PM_WO_BADI~GET_ASSIGNMENT_TYPE5.
endmethod.


METHOD /smerp/if_pm_wo_badi~get_assignment_type6.

  DATA: lit_woassign TYPE TABLE OF zsmerp_woassign,
        ls_woassign LIKE LINE OF lit_woassign,
        ls_woobject LIKE LINE OF ct_wo_object.

  "  DELETE FROM zsmerp_woassign WHERE uname = sy-uname.

  " Compare the ct_wo_object and zsmerp_woassign tables
  " Any entry in zsmerp_woassign not in ct_wo_object is removed
  REFRESH: lit_woassign.
  SELECT * FROM zsmerp_woassign INTO TABLE lit_woassign
           WHERE uname = sy-uname.
  LOOP AT lit_woassign INTO ls_woassign.
    READ TABLE ct_wo_object INTO ls_woobject WITH KEY aufnr = ls_woassign-aufnr.
    IF sy-subrc <> 0.
      DELETE FROM zsmerp_woassign WHERE uname = sy-uname AND aufnr = ls_woassign-aufnr.
    ENDIF.
  ENDLOOP.


ENDMETHOD.


method /SMERP/IF_PM_WO_BADI~GET_ASSIGNMENT_TYPE7.
endmethod.


method /SMERP/IF_PM_WO_BADI~GET_ASSIGNMENT_TYPE8.
endmethod.


method /SMERP/IF_PM_WO_BADI~GET_ASSIGNMENT_TYPE9.
endmethod.


method /SMERP/IF_PM_WO_BADI~GET_ASSIGNMENT_TYPEA.
endmethod.


method /SMERP/IF_PM_WO_BADI~GET_BEGIN.
endmethod.


METHOD /smerp/if_pm_wo_badi~get_end.

* Enter logic here to populate the currently assigned work orders in a custom table
* This is to drive the notifications returned to the work manager notification list

  CONSTANTS: lc_table TYPE string VALUE 'CS_MDO_OUTPUT-ET_VALID_WORKORDER->*',
             lc_optable TYPE string VALUE 'CS_MDO_OUTPUT-ET_WORKORDER_OPERATION->*'.

  DATA: lwa_woassign TYPE zsmerp_woassign,
        lwa_validwo TYPE /syclo/pm_valid_aufnr_str.

  FIELD-SYMBOLS: <validwo> TYPE /syclo/pm_valid_aufnr_tab,
                 <validop> TYPE /syclo/pm_afvc_tab.

  DELETE FROM zsmerp_woassign WHERE uname = sy-uname.

  ASSIGN: (lc_table) TO <validwo>.
*          (lc_optable) TO <validop>.

  LOOP AT <validwo> INTO lwa_validwo.
    lwa_woassign-uname = sy-uname.
    lwa_woassign-aufnr = lwa_validwo-aufnr.
    INSERT INTO zsmerp_woassign VALUES lwa_woassign.
  ENDLOOP.

ENDMETHOD.


method /SMERP/IF_PM_WO_BADI~GET_KEYLIST_FROM_EXCHOBJ.
endmethod.


method /SMERP/IF_PM_WO_BADI~MAP_SYST_STATUS.
endmethod.


method /SMERP/IF_PM_WO_BADI~MAP_USER_STATUS.
endmethod.


METHOD /smerp/if_pm_wo_badi~update_begin.

  DATA: BEGIN OF ls_mdo_input_vals,
          it_methods TYPE REF TO bapi_alm_order_method_t,
          it_header TYPE REF TO bapi_alm_order_headers_i_t,
          it_header_up TYPE REF TO bapi_alm_order_headers_i_ut,
          it_header_srv TYPE REF TO bapi_alm_order_srvdat_e_t,
          it_header_srv_up TYPE REF TO bapi_alm_order_srvdat_ut,
          it_userstatus TYPE REF TO bapi_alm_order_usrstat_t,
          it_partner TYPE REF TO bapi_alm_order_partn_mul_t,
          it_partner_up TYPE REF TO /smerp/pm_ord_partn_mul_up_tab,
          it_operation TYPE REF TO bapi_alm_order_operation_t,
          it_operation_up TYPE REF TO bapi_alm_order_operation_ut,
          it_relation TYPE REF TO bapi_alm_order_relation_t,
          it_relation_up TYPE REF TO bapi_alm_order_relation_ut,
          it_component TYPE REF TO bapi_alm_order_component_t,
          it_component_up TYPE REF TO bapi_alm_order_component_ut,
          it_objectlist TYPE REF TO bapi_alm_order_objectlist_t,
          it_objectlist_up TYPE REF TO bapi_alm_order_olist_ut,
          it_olist_relation TYPE REF TO bapi_alm_order_olst_relation_t,
          it_text TYPE REF TO bapi_alm_text_t,
          it_text_lines TYPE REF TO bapi_alm_text_lines_t,
          it_srule TYPE REF TO bapi_alm_order_srule_t,
          it_srule_up TYPE REF TO bapi_alm_order_srule_ut,
          it_tasklists TYPE REF TO bapi_alm_order_tasklists_i_t,
          it_extension_in TYPE REF TO bapiparex_t,
        END OF ls_mdo_input_vals.

  ls_mdo_input_vals = cs_mdo_input_vals.

  REFRESH gt_methods.
  gt_methods = ls_mdo_input_vals-it_methods->*.

ENDMETHOD.


METHOD /smerp/if_pm_wo_badi~update_end.

  TYPES : BEGIN OF ty_objnr,
         objnr TYPE jsto-objnr,
          END OF ty_objnr.

  DATA: lv_aufnr TYPE aufnr,
        lv_aufpl TYPE afko-aufpl,
        lv_aplzl TYPE afvc-aplzl,
        ls_objnr TYPE ty_objnr,
        lt_objnr TYPE TABLE OF ty_objnr,
        lt_objnr_crtd TYPE TABLE OF ty_objnr,
        lt_aplzl TYPE TABLE OF afvc-aplzl.

  FIELD-SYMBOLS: <fs_methods> LIKE LINE OF gt_methods.
  DELETE gt_methods WHERE NOT ( objecttype = 'OPERATION' AND method = 'CREATE' ).

  LOOP AT gt_methods ASSIGNING <fs_methods>.
    AT END OF refnumber.
      lv_aufnr = <fs_methods>-objectkey+0(12).

      SELECT SINGLE  aufpl FROM afko
                               INTO lv_aufpl
                               WHERE aufnr = lv_aufnr.
      IF sy-subrc EQ 0.

        SELECT aplzl FROM afvc
                     INTO TABLE lt_aplzl
                     WHERE aufpl = lv_aufpl.

        LOOP AT lt_aplzl INTO lv_aplzl.
          CONCATENATE 'OV' lv_aufpl lv_aplzl INTO ls_objnr-objnr.
          APPEND ls_objnr TO lt_objnr.
          CLEAR ls_objnr.
        ENDLOOP.

        IF lt_objnr IS NOT INITIAL.

          SELECT objnr FROM jest
                 INTO TABLE lt_objnr_crtd
                 FOR ALL ENTRIES IN lt_objnr
                 WHERE objnr = lt_objnr-objnr AND
                       stat  = 'E0001' AND
                       inact = space.

          LOOP AT lt_objnr_crtd INTO ls_objnr.
            CALL FUNCTION 'STATUS_CHANGE_EXTERN'
              EXPORTING
                objnr               = ls_objnr-objnr
                user_status         = 'E0002'
              EXCEPTIONS
                object_not_found    = 1
                status_inconsistent = 2
                status_not_allowed  = 3
                OTHERS              = 4.

            IF sy-subrc EQ 0.
              COMMIT WORK.
            ENDIF.
          ENDLOOP.
        ENDIF.
      ENDIF.
    ENDAT.
  ENDLOOP.

  REFRESH gt_methods.

ENDMETHOD.


method /SMERP/IF_PM_WO_BADI~UPDATE_SYST_STATUS.
endmethod.
ENDCLASS.
