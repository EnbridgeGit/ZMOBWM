class Z_SMERP_CL_HR_CTTIMEDEF_GET definition
  public
  inheriting from /SYCLO/CL_CORE_CT_HANDLER
  create public .

public section.
*"* public components of class Z_SMERP_CL_HR_CTTIMEDEF_GET
*"* do not include other source files here!!!

  methods /SYCLO/IF_CORE_FILTER_SERV~GET_DATA_FILTER_LIST
    redefinition .
  methods /SYCLO/IF_CORE_FLDSEL_SERV~GET_FIELD_SELECTOR_TABLES
    redefinition .
protected section.
*"* protected components of class Z_SMERP_CL_HR_CTTIMEDEF_GET
*"* do not include other source files here!!!

  methods GET_COMPLEX_TABLE
    redefinition .
*"* private components of class Z_SMERP_CL_HR_CTTIMEDEF_GET
*"* do not include other source files here!!!
private section.
ENDCLASS.



CLASS Z_SMERP_CL_HR_CTTIMEDEF_GET IMPLEMENTATION.


METHOD /SYCLO/IF_CORE_FILTER_SERV~GET_DATA_FILTER_LIST.
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

*Field selectors



  et_data_filters[] = lt_data_filter[].

ENDMETHOD.


METHOD /SYCLO/IF_CORE_FLDSEL_SERV~GET_FIELD_SELECTOR_TABLES.
*======================================================================*

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

ENDMETHOD.


METHOD get_complex_table.
*======================================================================*

**********************************************************************
* Data Declaration Section
**********************************************************************
*OO Reference Variables
  DATA: lref_tabledescr TYPE REF TO cl_abap_tabledescr,
        lref_exception  TYPE REF TO cx_root,
        lref_do_serv    TYPE REF TO /syclo/cl_core_do_services.

*Tables & Structures
  DATA: lt_hrtimedef TYPE zsmerp_hr_timesheetdef_tab,
        ls_hrtimedef LIKE LINE OF lt_hrtimedef.

*Variables
  DATA: lv_select_clause TYPE string,
        ls_return        TYPE bapiret2.

  DATA: BEGIN OF ls_mdo_output_vals,
        et_complex_table              TYPE REF TO zsmerp_hr_timesheetdef_tab,
      END OF ls_mdo_output_vals.

*  DATA: BEGIN OF ls_dof_filter_vals,
*      user_name TYPE REF TO /syclo/core_range_tab,
*        END OF ls_dof_filter_vals.

  DATA: lt_comm105 TYPE TABLE OF bapip0105b,
        ls_comm105 LIKE LINE OF lt_comm105,
        lv_uname TYPE bapip0105b-userid,
        it_0315 TYPE TABLE OF p0315,
        it_0027 TYPE TABLE OF p0027,
        ls_0315 LIKE LINE OF it_0315,
        ls_0027 LIKE LINE OF it_0027,
        rc TYPE subrc.

*Field Symbols
  FIELD-SYMBOLS: <target>       TYPE any,
                 <return>       TYPE bapiret2_t.

*Constants
  CONSTANTS: lc_mthd TYPE /syclo/core_do_mthd_dte VALUE 'GET'. "#EC NOTEXT

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

*Step 1 - Convert RFC Parameter into OO format
      "Set return time stamp at begining if exchange process not used
      IF me->str_bapi_input-timestamp_from_mobile IS INITIAL.
        me->str_bapi_output-timestamp_to_mobile = /syclo/cl_core_do_services=>get_sys_timestamp( ).
      ENDIF.

* Step 2 - Build & Perform SQL.....................................
      "Build Filter from Filter Service & BAPI Input
      me->logger->loginfo( iv_mobile_user = me->str_bapi_input-mobile_user
                           iv_mobile_id = me->str_bapi_input-mobile_id
                           iv_user_guid = me->str_bapi_input-user_guid
                           iv_message = me->message
                           iv_source = me->source ).

*-----------------------------------------------------------------------*
*Step 1 - Initialization
*-----------------------------------------------------------------------*
      lref_do_serv = /syclo/cl_core_do_services=>get_do_service(
                                      iref_logger = me->logger ).

      "initialize output tables
      CREATE DATA: ls_mdo_output_vals-et_complex_table.

*      " --Retrieve supplied MDO input data and map to local variables.
*      " MDO input data are supplied by BAPI wrapper and mapped to MDO
*      " data object by PREPROCESS_MAPPING
*      ME->OREF_MDO_DATA->MAP_LOCAL_MOBILE_FILTER(
*        CHANGING CS_FILTERS = LS_MDO_INPUT_VALS ).

      " -->Retrieve filter settings as defined via ConfigPanel.
      " ConfigPanel filter settings has been mapped to MDO data object
      " by INITIALIZE_MDO_DATA
*      me->oref_mdo_data->map_local_dof_filter(
*        CHANGING cs_filters = ls_dof_filter_vals ).

**    No Exchange process defined for this Data Object   **

* Get the key fields

      "Determine whether field selector associated with this get method
      " lv_select_clause = me->build_field_selector_string( iv_mthd = lc_mthd
      "                                                     iv_tabname = '').

*    Retrieve the User Name's personnel number and get defaults
*      from IT0315 and IT0027

      REFRESH:  lt_comm105, lt_hrtimedef.

* Get current user name and search for employee ID in HR IT 0105
      lv_uname = me->str_bapi_input-mobile_user.
      CALL FUNCTION 'BAPI_EMPLOYEE_GETDATA'
        EXPORTING
          userid          = lv_uname
          date            = sy-datum
          authority_check = ''
        TABLES
          communication   = lt_comm105.

      IF lt_comm105 IS INITIAL.
        ASSIGN iref_rfc_oo_data->dref_return->* TO <return>.
        ls_return-type = 'I'.
        ls_return-message = 'No data found'(i01).
        APPEND ls_return TO <return>.
        RETURN.
      ENDIF.

      READ TABLE  lt_comm105 INTO ls_comm105 WITH KEY subtype = '0001'.
      CHECK sy-subrc = 0.

      CLEAR: ls_hrtimedef.
      ls_hrtimedef-uname = lv_uname.
      ls_hrtimedef-perno = ls_comm105-perno.

*SDP90267-GYMANA - Added begin/end date parameters in the infotype 315
*                  call.
*
      CALL FUNCTION 'HR_READ_INFOTYPE_AUTHC_DISABLE'.
      CALL FUNCTION 'HR_READ_INFOTYPE'
        EXPORTING
*         TCLAS                 = 'A'
          pernr                 = ls_comm105-perno
          infty                 = '0315'
          BEGDA                 = sy-datum                    "SDP90267
          ENDDA                 = sy-datum                    "SDP90267
        TABLES
          infty_tab             = it_0315
        EXCEPTIONS
          INFTY_NOT_FOUND       = 1
          OTHERS                = 2.

      IF sy-subrc = 0.
        READ TABLE it_0315 INTO ls_0315 INDEX 1.
        ls_hrtimedef-lstar = ls_0315-lstar.
      ENDIF.

      CALL FUNCTION 'HR_READ_INFOTYPE_AUTHC_DISABLE'.
      CALL FUNCTION 'HR_READ_INFOTYPE'
        EXPORTING
*         TCLAS                 = 'A'
          pernr                 = ls_comm105-perno
          infty                 = '0027'
          BEGDA                 = sy-datum
          ENDDA                 = sy-datum
        TABLES
          infty_tab             = it_0027
        EXCEPTIONS
          INFTY_NOT_FOUND       = 1
          OTHERS                = 2.

      IF sy-subrc = 0.
        READ TABLE it_0027 INTO ls_0027 INDEX 1.
        CALL FUNCTION 'CONVERSION_EXIT_AUFNR_OUTPUT'
          EXPORTING
            input         = ls_0027-auf01
          IMPORTING
            OUTPUT        = ls_hrtimedef-homeio.

      ENDIF.

      APPEND ls_hrtimedef to lt_hrtimedef.
      APPEND LINES OF lt_hrtimedef[] TO ls_mdo_output_vals-et_complex_table->*.


      " --return output data to MDO data object, which mapped to BAPI
      " Wrapper data container automatically by POSTPROCESS_MAPPING
      me->oref_mdo_data->set_mdo_output_via_ref_struct(
         EXPORTING is_mdo_output = ls_mdo_output_vals ).

* Class-Based Exception Handling
    CATCH cx_root INTO lref_exception.                   "#EC CATCH_ALL
      me->logger->catch_class_exception(
        EXPORTING iv_mobile_user = me->str_bapi_input-mobile_user
                  iv_mobile_id = me->str_bapi_input-mobile_id
                  iv_user_guid = me->str_bapi_input-user_guid
                  iref_exception = lref_exception
                  iref_return_tab = iref_rfc_oo_data->dref_return ).

  ENDTRY.

ENDMETHOD.
ENDCLASS.
