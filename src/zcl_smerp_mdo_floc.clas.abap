class ZCL_SMERP_MDO_FLOC definition
  public
  final
  create public .

public section.
*"* public components of class ZCL_SMERP_MDO_FLOC
*"* do not include other source files here!!!

  interfaces /SMERP/IF_PM_FLOC_BADI .
  interfaces IF_BADI_INTERFACE .
protected section.
*"* protected components of class ZCL_SMERP_MDO_FLOC
*"* do not include other source files here!!!
private section.
*"* private components of class ZCL_SMERP_MDO_FLOC
*"* do not include other source files here!!!
ENDCLASS.



CLASS ZCL_SMERP_MDO_FLOC IMPLEMENTATION.


method /SMERP/IF_PM_FLOC_BADI~GET_BEGIN.
endmethod.


METHOD /smerp/if_pm_floc_badi~get_end.

  DATA: ls_floc TYPE /syclo/pm_iflot_str,
        ls_adrc TYPE adrc.

  FIELD-SYMBOLS: <et_floc> TYPE /syclo/pm_iflot_tab.

  CONSTANTS: lc_val TYPE string VALUE 'CS_MDO_OUTPUT-ET_FUNC_LOCATION->*'.

* Populate additional information for Functional Location Object in Work order
  ASSIGN (lc_val) TO <et_floc>.

  LOOP AT <et_floc> INTO ls_floc.

    IF NOT ls_floc-adrnr IS INITIAL.
      SELECT SINGLE * FROM adrc INTO ls_adrc
             WHERE addrnumber = ls_floc-adrnr.

      CONCATENATE ls_adrc-street ',' ls_adrc-city1 ls_adrc-region ls_adrc-country
             INTO ls_floc-zzaddress SEPARATED BY space.


      MODIFY <et_floc> FROM ls_floc.
    ENDIF.

  ENDLOOP.


ENDMETHOD.


method /SMERP/IF_PM_FLOC_BADI~GET_KEYLIST_FROM_EXCHOBJ.
endmethod.
ENDCLASS.
