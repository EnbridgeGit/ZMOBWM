class Z_SMERP_CL_PM_USERSTAT_DOF definition
  public
  create public .

public section.
*"* public components of class Z_SMERP_CL_PM_USERSTAT_DOF
*"* do not include other source files here!!!

  interfaces /SYCLO/IF_CORE_FILTER_HANDLER .
*"* protected components of class Z_SMERP_CL_PM_USERSTAT_DOF
*"* do not include other source files here!!!
protected section.
private section.
*"* private components of class Z_SMERP_CL_PM_USERSTAT_DOF
*"* do not include other source files here!!!
ENDCLASS.



CLASS Z_SMERP_CL_PM_USERSTAT_DOF IMPLEMENTATION.


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


METHOD /SYCLO/IF_CORE_FILTER_HANDLER~GET_FILTER_VALUE.

  CONSTANTS: lc_profile TYPE tj30t-stsma VALUE 'UG_OP_01',
             lc_crtd TYPE tj30t-txt04 VALUE 'CRTD',
             lc_rtrn TYPE tj30t-txt04 VALUE 'RTRN'.

  DATA: lt_tj30t TYPE table of tj30t,
        ls_tj30t LIKE LINE OF lt_tj30t.

*Field Symbols
  FIELD-SYMBOLS: <filter_value> LIKE LINE OF et_filter_value.

  REFRESH et_filter_value.

* This Data Object Filter includes the operation user statuses that indicate
* Whether an operation is downloaded to SAP Work Manager.  This filter is EXCLUSIONARY
* They statuses to Exclude are: CRTD, RTRN

  REFRESH lt_tj30t.
  SELECT * FROM tj30t INTO CORRESPONDING FIELDS OF TABLE lt_tj30t
           WHERE stsma = lc_profile AND
                 spras = 'E' AND
                ( txt04 = lc_crtd OR txt04 = lc_rtrn ).

* Return all work centers in the hierarchy
  LOOP AT lt_tj30t INTO ls_tj30t.

    APPEND INITIAL LINE TO et_filter_value ASSIGNING <filter_value>.
    <filter_value>-dof_name = iv_dof_name.
    <filter_value>-sign = 'I'.
    <filter_value>-option = 'EQ'.
    <filter_value>-low  = ls_tj30t-estat.

  ENDLOOP.

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
