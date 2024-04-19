class Z_SYCLO_CL_HR_PERNR_DOF definition
  public
  create public .

public section.
*"* public components of class Z_SYCLO_CL_HR_PERNR_DOF
*"* do not include other source files here!!!

  interfaces /SYCLO/IF_CORE_FILTER_HANDLER .
*"* protected components of class Z_SYCLO_CL_HR_PERNR_DOF
*"* do not include other source files here!!!
protected section.
private section.
*"* private components of class Z_SYCLO_CL_HR_PERNR_DOF
*"* do not include other source files here!!!
ENDCLASS.



CLASS Z_SYCLO_CL_HR_PERNR_DOF IMPLEMENTATION.


METHOD /SYCLO/IF_CORE_FILTER_HANDLER~GET_FILTER_LEVEL.
*======================================================================*
*<SYCLODOC>
*  <CREATE_DATE> 12/13/2010 </CREATE_DATE>
*  <AUTHOR> Syam Yalamati(Syclo LLC) </AUTHOR>
*  <DESCRIPTION>
*     Set filter level to Mobile Application
*  </DESCRIPTION>
*<!-- *----------------------CHANGE HISTORY-------------------------* -->
*  <REVISION_TAG date='12/13/2010' version='320_700 SP6' user='SYALAMA' >
*    <DESCRIPTION> Initial release. </DESCRIPTION>
*  </REVISION_TAG>
*<!-- *-------------------------------------------------------------* -->
*</SYCLODOC>
*======================================================================*
  ev_filter_level = 1.
ENDMETHOD.


METHOD /syclo/if_core_filter_handler~get_filter_value.

  DATA: lt_comm105 TYPE TABLE OF bapip0105b,
        ls_comm105 LIKE LINE OF lt_comm105,
        lv_uname TYPE bapip0105b-userid.

  FIELD-SYMBOLS: <filter_value> LIKE LINE OF et_filter_value.

  REFRESH: et_filter_value, lt_comm105.

* Get current user name and search for employee ID in HR IT 0105
  lv_uname = sy-uname.
  CALL FUNCTION 'BAPI_EMPLOYEE_GETDATA'
    EXPORTING
      userid                 = lv_uname
      date                   = sy-datum
      authority_check        = ''
* IMPORTING
*   RETURN                 =
    TABLES
      communication          = lt_comm105.

  LOOP AT lt_comm105 INTO ls_comm105 WHERE subtype = '0001'.
    APPEND INITIAL LINE TO et_filter_value ASSIGNING <filter_value>.
    <filter_value>-dof_name = iv_dof_name.
    <filter_value>-sign = 'I'.
    <filter_value>-option = 'EQ'.
    <filter_value>-low  = ls_comm105-perno.

  ENDLOOP.

  IF sy-subrc <> 0.
    APPEND INITIAL LINE TO et_filter_value ASSIGNING <filter_value>.
    <filter_value>-dof_name = iv_dof_name.
    <filter_value>-sign = 'I'.
    <filter_value>-option = 'EQ'.
    <filter_value>-low  = 'X'.     "Dummy Value for Personnel Number
  ENDIF.


ENDMETHOD.


method /SYCLO/IF_CORE_FILTER_HANDLER~GET_TABLE_FILTER_VALUE.
*======================================================================*
*<SMERPDOC>
*  <CREATE_DATE> 5/4/2014 </CREATE_DATE>
*  <AUTHOR> Jirong Wang (SAP Labs) </AUTHOR>
*  <DESCRIPTION>
*    Default implementation.
*  </DESCRIPTION>
*<!-- *----------------------CHANGE HISTORY-------------------------* -->
*  <REVISION_TAG date='5/4/2014' version='SMERP 610_700 SP03' user='WANGJIR' >
*    <DESCRIPTION> Initial release. </DESCRIPTION>
*  </REVISION_TAG>
*<!-- *-------------------------------------------------------------* -->
*</SMERPDOC>
*======================================================================*
**********************************************************************
* Data Declaration Section
**********************************************************************
*

**********************************************************************
* Main Section
**********************************************************************

  clear et_filter_value.

endmethod.
ENDCLASS.
