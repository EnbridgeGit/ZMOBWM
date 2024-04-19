class Z_SMERP_CL_PM_DTWAGETYPE_GET definition
  public
  inheriting from /SYCLO/CL_CORE_DT_HANDLER
  create public .

public section.
*"* public components of class Z_SMERP_CL_PM_DTWAGETYPE_GET
*"* do not include other source files here!!!

  methods CONSTRUCTOR
    importing
      value(IS_DO_SETTING) type /SYCLO/DO001 optional
      value(IV_USER_GUID) type /SYCLO/CORE_USER_GUID_DTE optional
      value(IREF_LOGGER) type ref to /SYCLO/CL_CORE_APPL_LOGGER optional
    preferred parameter IS_DO_SETTING .

  methods /SYCLO/IF_CORE_FILTER_SERV~GET_DATA_FILTER_LIST
    redefinition .
protected section.
*"* protected components of class Z_SMERP_CL_PM_DTWAGETYPE_GET
*"* do not include other source files here!!!

  methods GET_DATA_TABLE
    redefinition .
*"* private components of class Z_SMERP_CL_PM_DTWAGETYPE_GET
*"* do not include other source files here!!!
private section.
ENDCLASS.



CLASS Z_SMERP_CL_PM_DTWAGETYPE_GET IMPLEMENTATION.


METHOD /syclo/if_core_filter_serv~get_data_filter_list.

**********************************************************************
* Data Declaration Section
**********************************************************************
*Tables & Structures
  DATA: lt_data_filter TYPE /syclo/core_filter_serv_tab.

*Field Symbols
  FIELD-SYMBOLS: <data_filter> TYPE LINE OF /syclo/core_filter_serv_tab.

  super->get_data_filter_list( ).                        "<-ins 310_700

  REFRESH et_data_filters.

*Field Filter for method GET_DATA_TABLE
  APPEND INITIAL LINE TO lt_data_filter ASSIGNING <data_filter>.
  <data_filter>-do_handler = me->clsname.
  <data_filter>-do_mthd = 'GET'.
  <data_filter>-dof_name = 'WAGE_TYPE'.
  <data_filter>-usage_tabname = 'T512T'.
  <data_filter>-usage_fieldname = 'LGART'.

*Field Filter for method GET_DATA_TABLE
  APPEND INITIAL LINE TO lt_data_filter ASSIGNING <data_filter>.
  <data_filter>-do_handler = me->clsname.
  <data_filter>-do_mthd = 'GET'.
  <data_filter>-dof_name = 'COUNTRY_GROUP'.
  <data_filter>-usage_tabname = 'T512T'.
  <data_filter>-usage_fieldname = 'MOLGA'.

*Field Filter for method GET_DATA_TABLE
  APPEND INITIAL LINE TO lt_data_filter ASSIGNING <data_filter>.
  <data_filter>-do_handler = me->clsname.
  <data_filter>-do_mthd = 'GET'.
  <data_filter>-dof_name = 'INFOTYPE'.
  <data_filter>-usage_tabname = 'T512Z'.
  <data_filter>-usage_fieldname = 'INFTY'.

  et_data_filters[] = lt_data_filter[].

ENDMETHOD.


METHOD CONSTRUCTOR.
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
ENDMETHOD.


METHOD get_data_table.
**********************************************************************
* Data Declaration Section
**********************************************************************
*OO Reference Variables
  DATA: lref_exception TYPE REF TO cx_root,
        lref_do_serv TYPE REF TO /syclo/cl_core_do_services.

*Table & Structures
  DATA: lt_data_table TYPE /syclo/core_dt_tab,
        ls_data_table TYPE /syclo/core_dt_str.

*Tables & Structures
  "The following structure contains reference to all available filters
  "from ConfigPanel. Filter name is consistent with what is declared
  "in filter service method GET_DATA_FILTER_LIST
  DATA: BEGIN OF ls_dof_filter_vals,
          wage_type     TYPE REF TO /syclo/core_range_tab,
          infotype      TYPE REF TO /syclo/core_range_tab,
          country_group TYPE REF TO /syclo/core_range_tab,
        END OF ls_dof_filter_vals.

*Constants
  CONSTANTS: lc_mthd TYPE /syclo/core_do_mthd_dte VALUE 'GET'.

*********************************************************************
* Main Section
*********************************************************************
  TRY.
      me->message = 'Entering method ~ GET_DATA_TABLE...'(m01).
      me->logger->loginfo( iv_mobile_user = me->str_bapi_input-mobile_user
                           iv_mobile_id = me->str_bapi_input-mobile_id
                           iv_user_guid = me->str_bapi_input-user_guid
                           iv_message = me->message
                           iv_source = me->source ).

      "Set return time stamp at begining if exchange process not used
      IF me->str_bapi_input-timestamp_from_mobile IS INITIAL.
        me->str_bapi_output-timestamp_to_mobile = /syclo/cl_core_do_services=>get_sys_timestamp( ).
      ENDIF.

      lref_do_serv = /syclo/cl_core_do_services=>get_do_service(
                                          iref_logger = me->logger ).

      " -->Retrieve filter settings as defined via ConfigPanel.
      " ConfigPanel filter settings has been mapped to MDO data object
      " by INITIALIZE_MDO_DATA
      me->oref_mdo_data->map_local_dof_filter(
        CHANGING cs_filters = ls_dof_filter_vals ).

      "Perform main SQL selection
      "EAM #58326 GYMANA - modify select to use table T511 instead of
      "T512Z and use the begin and end dates for the wage type

      SELECT a~lgart AS key
             a~lgtxt AS value
        FROM ( t512t AS a INNER JOIN t511 AS b ON a~mandt = b~mandt AND
                                                a~molga = b~molga AND
                                                a~lgart = b~lgart )
              INNER JOIN t512z as c ON c~mandt = b~mandt AND
                                       c~molga = b~molga AND
                                       c~lgart = b~lgart
        INTO CORRESPONDING FIELDS OF TABLE lt_data_table
        WHERE a~sprsl = sy-langu AND
              a~molga IN ls_dof_filter_vals-country_group->* AND
              a~lgart IN ls_dof_filter_vals-wage_type->*     AND
              c~infty IN ls_dof_filter_vals-infotype->*      AND
              b~begda <= sy-datum AND
              b~endda >= sy-datum.

      ls_data_table-do_id = me->str_do_setting-do_id.
      MODIFY lt_data_table FROM ls_data_table TRANSPORTING do_id
        WHERE do_id IS INITIAL.

      me->tab_data_table[] = lt_data_table[].

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
