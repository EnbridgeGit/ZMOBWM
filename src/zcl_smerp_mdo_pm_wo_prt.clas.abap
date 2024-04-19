class ZCL_SMERP_MDO_PM_WO_PRT definition
  public
  final
  create public .

public section.
*"* public components of class ZCL_SMERP_MDO_PM_WO_PRT
*"* do not include other source files here!!!

  interfaces /SMERP/IF_PM_WO_PRT_BADI .
  interfaces IF_BADI_INTERFACE .
protected section.
*"* protected components of class ZCL_SMERP_MDO_PM_WO_PRT
*"* do not include other source files here!!!
private section.
*"* private components of class ZCL_SMERP_MDO_PM_WO_PRT
*"* do not include other source files here!!!
ENDCLASS.



CLASS ZCL_SMERP_MDO_PM_WO_PRT IMPLEMENTATION.


method /SMERP/IF_PM_WO_PRT_BADI~GET_OBJECT_HIERARCHY.
endmethod.


METHOD /smerp/if_pm_wo_prt_badi~get_oper_prt.

* SLOWENBE PwC: Ensure that PRT Measuring Points populated with Complete data
* Fixing an Issue with Standard SAP Coding.  Measuring Point assignment to "Resource ID"

  CONSTANTS: lc_prttable(40) TYPE c VALUE 'CS_MDO_OUTPUT-ET_WORKORDER_PRT->*'.

  FIELD-SYMBOLS: <lt_prt> TYPE /smerp/pm_oper_prt_assign_tab.

  DATA: ls_prt TYPE /smerp/pm_oper_prt_assign_str.

  ASSIGN: (lc_prttable) TO <lt_prt>.

  LOOP AT <lt_prt> INTO ls_prt WHERE fhmar = 'P'.

    SELECT SINGLE meas_point INTO ls_prt-fhmnr FROM crvp_a
           WHERE objty = ls_prt-objty AND
                 objid = ls_prt-objid.

    MODIFY <lt_prt> FROM ls_prt.
  ENDLOOP.


ENDMETHOD.
ENDCLASS.
