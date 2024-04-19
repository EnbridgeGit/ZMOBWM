class Z_SMERP_CL_PM_DTNOTIFTYPE_DO definition
  public
  inheriting from /SYCLO/CL_CORE_DT_HANDLER
  create public .

public section.
*"* public components of class Z_SMERP_CL_PM_DTNOTIFTYPE_DO
*"* do not include other source files here!!!

  methods CONSTRUCTOR
    importing
      value(IS_DO_SETTING) type /SYCLO/DO001 optional
      value(IV_USER_GUID) type /SYCLO/CORE_USER_GUID_DTE optional
      value(IREF_LOGGER) type ref to /SYCLO/CL_CORE_APPL_LOGGER optional
    preferred parameter IS_DO_SETTING .

  methods /SYCLO/IF_CORE_FILTER_SERV~GET_DATA_FILTER_LIST
    redefinition .
*"* protected components of class Z_SMERP_CL_PM_DTNOTIFTYPE_DO
*"* do not include other source files here!!!
protected section.

  methods GET_DATA_TABLE
    redefinition .
*"* private components of class Z_SMERP_CL_PM_DTNOTIFTYPE_DO
*"* do not include other source files here!!!
private section.
ENDCLASS.



CLASS Z_SMERP_CL_PM_DTNOTIFTYPE_DO IMPLEMENTATION.


METHOD /SYCLO/IF_CORE_FILTER_SERV~GET_DATA_FILTER_LIST.
*======================================================================*
*<SYCLODOC>
*  <CREATE_DATE> 6/10/2008 </CREATE_DATE>
*  <AUTHOR> Jirong Wang (Syclo LLC) </AUTHOR>
*  <DESCRIPTION>
*     This method identifies the list of filters supported by class handler
*     methods for Filter Services.
*  </DESCRIPTION>
*<!-- *----------------------CHANGE HISTORY-------------------------* -->
*  <REVISION_TAG date='6/10/2008' version='300_700' user='JWANG' >
*    <DESCRIPTION> Initial release. </DESCRIPTION>
*  </REVISION_TAG>
*<!-- *-------------------------------------------------------------* -->
*  <REVISION_TAG date='2/20/2008' version='310_700' user='JWANG' >
*    <DESCRIPTION>Use super class for logging info.</DESCRIPTION>
*  </REVISION_TAG>
*<!-- *-------------------------------------------------------------* -->
*</SYCLODOC>
*======================================================================*
**********************************************************************
* Data Declaration Section
**********************************************************************
*Tables & Structures
  DATA: lt_data_filter TYPE /syclo/core_filter_serv_tab.

*Field Symbols
  FIELD-SYMBOLS: <data_filter> TYPE LINE OF /syclo/core_filter_serv_tab.

**********************************************************************
* Main Section
**********************************************************************
*Delete start from here 310_700
*  me->message = 'Entering method ~ GET_DATA_FILTER_LIST...'(m02).
*  me->logger->loginfo( iv_mobile_user = me->str_bapi_input-mobile_user
*                       iv_mobile_id = me->str_bapi_input-mobile_id
*                       iv_message = me->message
*                       iv_source = me->source ).
*Delete end here 310_700

  super->get_data_filter_list( ).      "<-ins 310_700

  REFRESH et_data_filters.

*Field Filter for method GET
  APPEND INITIAL LINE TO lt_data_filter ASSIGNING <data_filter>.
  <data_filter>-do_handler = me->clsname.
  <data_filter>-do_mthd = 'GET'.
  <data_filter>-dof_name = 'NOTIF_CATEGORY'.
  <data_filter>-usage_tabname = 'TQ80'.
  <data_filter>-usage_fieldname = 'QMTYP'.

  APPEND INITIAL LINE TO lt_data_filter ASSIGNING <data_filter>.
  <data_filter>-do_handler = me->clsname.
  <data_filter>-do_mthd = 'GET'.
  <data_filter>-dof_name = 'NOTIF_TYPE'.
  <data_filter>-usage_tabname = 'TQ80'.
  <data_filter>-usage_fieldname = 'QMART'.

  et_data_filters[] = lt_data_filter[].
ENDMETHOD.


method CONSTRUCTOR.
*======================================================================*
*<SYCLODOC>
*  <CREATE_DATE> 6/10/2008 </CREATE_DATE>
*  <AUTHOR> Jirong Wang (Syclo LLC) </AUTHOR>
*  <DESCRIPTION>
*     class constructor.
*  </DESCRIPTION>
*<!-- *----------------------CHANGE HISTORY-------------------------* -->
*  <REVISION_TAG date='6/10/2008' version='300_700' user='JWANG' >
*    <DESCRIPTION> Initial release. </DESCRIPTION>
*  </REVISION_TAG>
*<!-- *-------------------------------------------------------------* -->
*  <REVISION_TAG date='2/20/2009' version='310_700' user='JWANG' >
*    <DESCRIPTION> Accept dedicated logger class. </DESCRIPTION>
*  </REVISION_TAG>
*<!-- *-------------------------------------------------------------* -->
*</SYCLODOC>
*======================================================================*
**********************************************************************
* Data Declaration Section
**********************************************************************
*

**********************************************************************
* Main Section
**********************************************************************
  super->constructor( is_do_setting = is_do_setting       "<-mod 310_700
                      iref_logger = iref_logger ).        "<-mod 310_700
endmethod.


METHOD GET_DATA_TABLE.
*======================================================================*
*<SYCLODOC>
*  <CREATE_DATE> 6/10/2008 </CREATE_DATE>
*  <AUTHOR> Jirong Wang (Syclo LLC) </AUTHOR>
*  <DESCRIPTION>
*     This method retrieves account indicator settings from TBMOT.
*  </DESCRIPTION>
*<!-- *----------------------CHANGE HISTORY-------------------------* -->
*  <REVISION_TAG date='6/10/2008' version='300_700' user='JWANG' >
*    <DESCRIPTION> Initial release. </DESCRIPTION>
*  </REVISION_TAG>
*<!-- *-------------------------------------------------------------* -->
*  <REVISION_TAG date='2/20/2009' version='310_700' user='JWANG' >
*    <DESCRIPTION> Clean up per inspector. </DESCRIPTION>
*  </REVISION_TAG>
*<!-- *-------------------------------------------------------------* -->
*</SYCLODOC>
*======================================================================*
**********************************************************************
* Data Declaration Section
**********************************************************************
*OO Reference Variables
  DATA: lref_exception TYPE REF TO cx_root,
        lref_do_serv TYPE REF TO /syclo/cl_core_do_services.

*Table & Structures
*  DATA: lt_abap_param TYPE abap_parmbind_tab.                "<-del 310_700

  DATA: lt_filter_list TYPE /syclo/core_filter_serv_tab.
*        lt_filter_value TYPE /syclo/core_filter_value_tab.    "<-del 310_700

  DATA: lt_data_table TYPE /syclo/core_dt_tab,
        ls_data_table TYPE /syclo/core_dt_str.

  DATA: lr_tq80_qmtyp_dof TYPE RANGE OF char100,
        lr_tq80_qmart_dof TYPE RANGE OF char100.             "#EC NEEDED

*Variables
  DATA: lv_filter TYPE string,                              "#EC NEEDED
        lv_range_name TYPE string.

*Field Symbols
  FIELD-SYMBOLS:
*                 <source> TYPE ANY,                           "<-del 310_700
                 <range_tab> TYPE /syclo/core_range_tab,
*                 <range_line> TYPE /syclo/core_range_str,     "<-del 310_700
                 <filter_list> LIKE LINE OF lt_filter_list.
*                 <filter_value> LIKE LINE OF lt_filter_value, "<-del 310_700
*                 <abap_param> LIKE LINE OF lt_abap_param,     "<-del 310_700
*                 <bapi_filter> TYPE ANY TABLE.                "<-del 310_700
*  FIELD-SYMBOLS: <sign> TYPE ANY,                             "<-del 310_700
*                 <option> TYPE ANY,                           "<-del 310_700
*                 <low> TYPE ANY,                              "<-del 310_700
*                 <high> TYPE ANY.                             "<-del 310_700

*Constants
  CONSTANTS: lc_mthd TYPE /syclo/core_do_mthd_dte VALUE 'GET'.

*********************************************************************
* Main Section
*********************************************************************
  TRY.
      me->message = 'Entering method ~ GET_DATA_TABLE...'(m01).
      me->logger->loginfo( iv_mobile_user = me->str_bapi_input-mobile_user
                           iv_mobile_id = me->str_bapi_input-mobile_id
                           iv_user_guid = me->str_bapi_input-user_guid  "<-ins 310_700 bugid 25317
                           iv_message = me->message
                           iv_source = me->source ).

      "Set return time stamp at begining if exchange process not used
      IF me->str_bapi_input-timestamp_from_mobile IS INITIAL.
        me->str_bapi_output-timestamp_to_mobile = /syclo/cl_core_do_services=>get_sys_timestamp( ).
      ENDIF.

      "Build Filter from Filter Service & BAPI Input
      lref_do_serv = /syclo/cl_core_do_services=>service.

      lt_filter_list = me->get_data_filter_list( ).
      DELETE lt_filter_list WHERE do_mthd <> lc_mthd.

      LOOP AT lt_filter_list ASSIGNING <filter_list>.
        CLEAR: lv_range_name, lv_filter.

        "Get filter values defined by filter service rule
        CONCATENATE 'LR' <filter_list>-usage_tabname <filter_list>-usage_fieldname
          'DOF' INTO lv_range_name SEPARATED BY '_'.
        ASSIGN (lv_range_name) TO <range_tab>.

        IF sy-subrc = 0.

          lref_do_serv->get_dofrule_filter_vals( EXPORTING iref_filter_serv = me
                                                           iv_mthd = lc_mthd
                                                           iv_dof_name = <filter_list>-dof_name
                                                           iv_user_guid = me->str_bapi_input-user_guid  "<-ins 310_700 bugid 25317
                                                 CHANGING ct_dofrule_filter_vals = <range_tab> ).
        ENDIF.
      ENDLOOP.

      "Perform main SQL selection
      SELECT tq80~qmart as key
             tq80_t~qmartx AS value
        FROM tq80 LEFT JOIN tq80_t ON tq80~qmart = tq80_t~qmart AND
                                      tq80_t~spras = sy-langu
        INTO CORRESPONDING FIELDS OF TABLE lt_data_table
        WHERE tq80~qmtyp IN lr_tq80_qmtyp_dof AND
              tq80~qmart IN lr_tq80_qmart_dof.

      ls_data_table-do_id = me->str_do_setting-do_id.
      MODIFY lt_data_table FROM ls_data_table TRANSPORTING do_id
        WHERE do_id IS INITIAL.

      ls_data_table-do_id = me->str_do_setting-do_id.
      MODIFY lt_data_table FROM ls_data_table TRANSPORTING do_id
        WHERE do_id IS INITIAL.

      me->tab_data_table[] = lt_data_table[].

* Class-Based Exception Handling
    CATCH cx_root INTO lref_exception.                   "#EC CATCH_ALL
      me->logger->catch_class_exception(
        EXPORTING iv_mobile_user = me->str_bapi_input-mobile_user
                  iv_mobile_id = me->str_bapi_input-mobile_id
                  iv_user_guid = me->str_bapi_input-user_guid  "<-ins 310_700 bugid 25317
                  iref_exception = lref_exception
                  iref_return_tab = iref_rfc_oo_data->dref_return ).
  ENDTRY.

ENDMETHOD.
ENDCLASS.
