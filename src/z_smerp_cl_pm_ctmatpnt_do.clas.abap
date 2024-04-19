class Z_SMERP_CL_PM_CTMATPNT_DO definition
  public
  inheriting from /SYCLO/CL_CORE_CT_HANDLER
  create public .

public section.
*"* public components of class Z_SMERP_CL_PM_CTMATPNT_DO
*"* do not include other source files here!!!

  methods /SYCLO/IF_CORE_FILTER_SERV~GET_DATA_FILTER_LIST
    redefinition .
  methods /SYCLO/IF_CORE_FLDSEL_SERV~GET_FIELD_SELECTOR_TABLES
    redefinition .
*"* protected components of class /SYCLO/CL_PM_NOTIF_TYPE_DO
*"* do not include other source files here!!!
protected section.

  methods GET_COMPLEX_TABLE
    redefinition .
*"* private components of class /SYCLO/CL_MM_PLANT_DO
*"* do not include other source files here!!!
private section.
ENDCLASS.



CLASS Z_SMERP_CL_PM_CTMATPNT_DO IMPLEMENTATION.


METHOD /SYCLO/IF_CORE_FILTER_SERV~GET_DATA_FILTER_LIST.
*======================================================================*
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
  super->get_data_filter_list( ).

  REFRESH et_data_filters.

*Field Filter for method GET
  APPEND INITIAL LINE TO lt_data_filter ASSIGNING <data_filter>.
  <data_filter>-do_handler = me->clsname.
  <data_filter>-do_mthd = 'GET'.
  <data_filter>-dof_name = 'PLAN_PLANT'.
  <data_filter>-usage_tabname = 'ZPMT_MAIN_MATPNT'.
  <data_filter>-usage_fieldname = 'ZMAIN_PLANT'.

  APPEND INITIAL LINE TO lt_data_filter ASSIGNING <data_filter>.
  <data_filter>-do_handler = me->clsname.
  <data_filter>-do_mthd = 'GET'.
  <data_filter>-dof_name = 'WAREHOUSE_PLANT'.
  <data_filter>-usage_tabname = 'ZPMT_MAIN_MATPNT'.
  <data_filter>-usage_fieldname = 'ZMAT_PLANT'.

  et_data_filters[] = lt_data_filter[].

ENDMETHOD.


METHOD /SYCLO/IF_CORE_FLDSEL_SERV~GET_FIELD_SELECTOR_TABLES.

**********************************************************************
* Data Declaration Section
**********************************************************************
*Tables & Structures
  DATA: lt_field_selector_tables TYPE /syclo/core_fldsel_serv_tab,
        lt_req_fldlist TYPE /syclo/core_req_fldlist_tab.

*Field Symbols
  FIELD-SYMBOLS: <selector_table> TYPE LINE OF /syclo/core_fldsel_serv_tab,
                 <req_fld> TYPE LINE OF /syclo/core_req_fldlist_tab.

**********************************************************************
* Main Section
**********************************************************************
  super->get_field_selector_tables( ).

  REFRESH et_fldsel_table_list.

*Field selector for method GET
  APPEND INITIAL LINE TO lt_field_selector_tables ASSIGNING <selector_table>.
  <selector_table>-do_handler = me->clsname.
  <selector_table>-do_mthd = 'GET'.
  <selector_table>-tabname = 'ZPMT_MAIN_MATPNT'.

  " Define the required fields
  APPEND INITIAL LINE TO lt_req_fldlist ASSIGNING <req_fld>.
  <req_fld>-do_handler = me->clsname.
  <req_fld>-do_mthd = 'GET'.                                "#EC NOTEXT
  <req_fld>-tabname = 'ZPMT_MAIN_MATPNT'.                              "#EC NOTEXT
  <req_fld>-fieldname = 'ZMAIN_PLANT'.                            "#EC NOTEXT

  " Define the required fields
  APPEND INITIAL LINE TO lt_req_fldlist ASSIGNING <req_fld>.
  <req_fld>-do_handler = me->clsname.
  <req_fld>-do_mthd = 'GET'.                                "#EC NOTEXT
  <req_fld>-tabname = 'ZPMT_MAIN_MATPNT'.                              "#EC NOTEXT
  <req_fld>-fieldname = 'ZMAT_PLANT'.                            "#EC NOTEXT

  et_req_field_list[] = lt_req_fldlist[].
  et_fldsel_table_list[] = lt_field_selector_tables[].

ENDMETHOD.


METHOD get_complex_table.

**********************************************************************
* Data Declaration Section
**********************************************************************
*OO Reference Variables
  DATA: lref_exception TYPE REF TO cx_root,
        lref_do_serv TYPE REF TO /syclo/cl_core_do_services,
        lref_data         TYPE REF TO data,
        lref_exch_keylist TYPE REF TO data,
        lref_package_data TYPE REF TO data.

*Tables & Structures
  DATA: lt_abap_param TYPE abap_parmbind_tab,               "#EC NEEDED
        ls_abap_param TYPE abap_parmbind,
        ls_return TYPE bapiret2.

  DATA: lt_matpnt   TYPE STANDARD TABLE OF zsmerp_pm_matpnt_str.

  DATA: lt_filter_list TYPE /syclo/core_filter_serv_tab,
        lt_filter_value TYPE /syclo/core_filter_value_tab.

*Tables & Structures
  "The following structure contains reference to all available filters
  "from ConfigPanel. Filter name is consistent with what is declared
  "in filter service method GET_DATA_FILTER_LIST
  DATA: BEGIN OF ls_dof_filter_vals,
          plan_plant              TYPE REF TO  /syclo/core_range_tab,
          warehouse_plant         TYPE REF TO  /syclo/core_range_tab,
        END OF ls_dof_filter_vals.

  "The following structure contains reference to all supported output parameter
  "from MDO handler. Output parameter name is set to the same as what is declared
  "in receiving BAPI warpper signature for simplicity.
  DATA: BEGIN OF ls_mdo_output_vals,
          et_complex_table              TYPE REF TO zsmerp_pm_matpnt_tab,
        END OF ls_mdo_output_vals.

*Variables
  DATA: lv_select_clause TYPE string,
        lv_filter TYPE string,                              "#EC NEEDED
        lv_range_name TYPE string.

*Field Symbols
  FIELD-SYMBOLS:
                 <return> TYPE bapiret2_t,
                 <fs_matpnt>   TYPE zsmerp_pm_matpnt_str.

*Constants
  CONSTANTS: lc_mthd TYPE /syclo/core_do_mthd_dte VALUE 'GET'.

*****************************************************
* Main Section
*****************************************************
  TRY.
      me->message = 'Entering method ~ GET_COMPLEX_TABLE...'(m01).
      me->logger->loginfo( iv_mobile_user = me->str_bapi_input-mobile_user
                           iv_mobile_id = me->str_bapi_input-mobile_id
                           iv_user_guid = me->str_bapi_input-user_guid
                           iv_message = me->message
                           iv_source = me->source ).

      " Set return time stamp at begining if exchange process not used
      IF me->mobile_timestamp_in IS INITIAL.
        me->mobile_timestamp_out =
        /syclo/cl_core_do_services=>get_sys_timestamp( ).
      ENDIF.

*Step 1 - Convert RFC Parameter into OO format
      lref_do_serv = /syclo/cl_core_do_services=>get_do_service(
                                   iref_logger = me->logger ).
      "-->Initialize output tables
      CREATE DATA: ls_mdo_output_vals-et_complex_table.

      " -->Retrieve filter settings as defined via ConfigPanel.
      " ConfigPanel filter settings has been mapped to MDO data object
      " by INITIALIZE_MDO_DATA
      me->oref_mdo_data->map_local_dof_filter(
        EXPORTING iv_auto_init = abap_true
        CHANGING cs_filters = ls_dof_filter_vals ).

*Step 2 - Build & Perform SQL
      "Build Filter from Filter Service & BAPI Input

      "Determine if there is a field catelog associated with this get method
      lv_select_clause = me->build_field_selector_string( iv_mthd = lc_mthd ).

      "Perform main SQL selection
      "EAM #58326 GYMANA - modify select to get plant description
      SELECT (lv_select_clause)
        FROM zpmt_main_matpnt INNER JOIN t001w
          ON zpmt_main_matpnt~zmat_plant = t001w~werks
        INTO CORRESPONDING FIELDS OF TABLE lt_matpnt
        WHERE zpmt_main_matpnt~zmain_plant IN ls_dof_filter_vals-plan_plant->* AND
              zpmt_main_matpnt~zmat_plant IN ls_dof_filter_vals-warehouse_plant->* AND
              t001w~spras = sy-langu.

* Step 3 - Build output data in OO parameter format

      LOOP AT lt_matpnt ASSIGNING <fs_matpnt>.
        <fs_matpnt>-zmain_plant = <fs_matpnt>-zmat_plant.
      ENDLOOP.

      IF lt_matpnt[] IS INITIAL.
        ASSIGN iref_rfc_oo_data->dref_return->* TO <return>.
        ls_return-type = 'I'.
        ls_return-message = 'No data found'(i01).
        APPEND ls_return TO <return>.
      ELSE.
        APPEND LINES OF lt_matpnt TO ls_mdo_output_vals-et_complex_table->*.
      ENDIF.

      " -->return output data to MDO data object,
      " output data in MDO data are mapped to BAPI Wrapper
      " data container automatically by POSTPROCESS_MAPPING
      me->oref_mdo_data->set_mdo_output_via_ref_struct(
          EXPORTING is_mdo_output = ls_mdo_output_vals ).

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
