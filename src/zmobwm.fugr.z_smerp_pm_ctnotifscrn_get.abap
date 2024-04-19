FUNCTION Z_SMERP_PM_CTNOTIFSCRN_GET.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IS_BAPI_INPUT) TYPE  /SYCLO/CORE_BAPI_INPUT_STR OPTIONAL
*"  EXPORTING
*"     VALUE(ES_BAPI_OUTPUT) TYPE  /SYCLO/CORE_BAPI_OUTPUT_STR
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      ET_COMPLEX_TABLE STRUCTURE  ZSMERP_PM_NOTIFSCRN_STR OPTIONAL
*"      ET_EXCHANGE_ACTION_DELETED STRUCTURE
*"        /SYCLO/PM_QMART_DELETED_STR OPTIONAL
*"      IT_NOTIF_TYPE_RA STRUCTURE  /SYCLO/CORE_RANGE_STR OPTIONAL
*"----------------------------------------------------------------------

**********************************************************************
* Data Declaration Section
**********************************************************************
*Constants
  constants: lc_bapi_name type funcname value 'Z_SMERP_PM_CTNOTIFSCRN_GET'.

**********************************************************************
* Template Section
**********************************************************************
  include /syclo/core_bapi_template_incl.

ENDFUNCTION.
