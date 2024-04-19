class Z_SYCLO_CL_PM_WORKCTR_DOF definition
  public
  create public .

public section.
*"* public components of class Z_SYCLO_CL_PM_WORKCTR_DOF
*"* do not include other source files here!!!

  interfaces /SYCLO/IF_CORE_FILTER_HANDLER .
*"* protected components of class Z_SYCLO_CL_PM_WORKCTR_DOF
*"* do not include other source files here!!!
protected section.
private section.
*"* private components of class Z_SYCLO_CL_PM_WORKCTR_DOF
*"* do not include other source files here!!!
ENDCLASS.



CLASS Z_SYCLO_CL_PM_WORKCTR_DOF IMPLEMENTATION.


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

  DATA: lv_arbpl    TYPE crhd-arbpl,
        lv_objty    TYPE crhd-objty,
        lv_objid    TYPE crhd-objid,
        lv_objty_hy TYPE cr_objty,
        lv_objid_hy TYPE cr_objid,

        lit_crhs    TYPE STANDARD TABLE OF crhs,
        ls_crhs     TYPE crhs.

*Field Symbols
  FIELD-SYMBOLS: <filter_value> LIKE LINE OF et_filter_value.

  REFRESH et_filter_value.

* Get Work center of current user from User Parameters
  GET PARAMETER ID 'VAP' FIELD lv_arbpl.

* Do no proceed if no work center is assigned
  IF lv_arbpl IS INITIAL.
    RETURN.
  ENDIF.

* Get current valid Object Id and Object type of the above work center
  SELECT SINGLE objty objid
         FROM crhd
         INTO (lv_objty, lv_objid)
         WHERE begda LE sy-datum AND
               endda GE sy-datum AND
               arbpl EQ lv_arbpl.

* Do no proceed if no record exists in CRHD table
  IF lv_objty IS INITIAL AND lv_objid IS INITIAL.
    RETURN.
  ENDIF.

* Get hierarchy node
  SELECT SINGLE objty_hy objid_hy
         FROM crhs
         INTO (lv_objty_hy, lv_objid_hy)
         WHERE objty_ho = lv_objty AND
               objid_ho = lv_objid.

* Do no proceed if no root hierarchy no exists
  IF lv_objty_hy IS INITIAL AND lv_objid_hy IS INITIAL.
    RETURN.
  ENDIF.

* Get All work centeres under the root hieararchy node
  SELECT *
         FROM crhs
         INTO TABLE lit_crhs
         WHERE objty_hy = lv_objty_hy AND
               objid_hy = lv_objid_hy.

  IF sy-subrc EQ 0.
    SORT lit_crhs BY objid_ho objty_ho.
  ENDIF.

* Return all work centers in the hierarchy
  LOOP AT lit_crhs INTO ls_crhs.

    APPEND INITIAL LINE TO et_filter_value ASSIGNING <filter_value>.
    <filter_value>-dof_name = iv_dof_name.
    <filter_value>-sign = 'I'.
    <filter_value>-option = 'EQ'.
    <filter_value>-low  = ls_crhs-objid_ho.

  ENDLOOP.
*{   INSERT         D30K924651                                        1
* SLOWENBE - PwC 2014/12/04 - Add Top Level Work Centers to facilitate Hierarchy

    APPEND INITIAL LINE TO et_filter_value ASSIGNING <filter_value>.
    <filter_value>-dof_name = iv_dof_name.
    <filter_value>-sign = 'I'.
    <filter_value>-option = 'EQ'.
    SELECT SINGLE objid FROM crhd INTO <filter_value>-low WHERE arbpl = 'SMC'.

    APPEND INITIAL LINE TO et_filter_value ASSIGNING <filter_value>.
    <filter_value>-dof_name = iv_dof_name.
    <filter_value>-sign = 'I'.
    <filter_value>-option = 'EQ'.
    SELECT SINGLE objid FROM crhd INTO <filter_value>-low WHERE arbpl = 'STO'.

*}   INSERT

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
