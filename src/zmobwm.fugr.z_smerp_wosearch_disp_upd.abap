FUNCTION z_smerp_wosearch_disp_upd.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IS_BAPI_INPUT) TYPE  /SYCLO/CORE_BAPI_INPUT_STR OPTIONAL
*"  EXPORTING
*"     VALUE(ES_BAPI_OUTPUT) TYPE  /SYCLO/CORE_BAPI_OUTPUT_STR
*"  TABLES
*"      IT_ORDERS STRUCTURE  ZSMERP_PM_WRKORD_UPD_STR OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------
************************************************************************
* Template Section
************************************************************************
  INCLUDE /syclo/core_bapi_template_incl.

ENDFUNCTION.
