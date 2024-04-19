FUNCTION Z_SMERP_MM_CTGLACCOUNT_GET.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IS_BAPI_INPUT) TYPE  /SYCLO/CORE_BAPI_INPUT_STR OPTIONAL
*"  EXPORTING
*"     VALUE(ES_BAPI_OUTPUT) TYPE  /SYCLO/CORE_BAPI_OUTPUT_STR
*"  TABLES
*"      IT_KOKRS_RA STRUCTURE  /SYCLO/CORE_RANGE_STR OPTIONAL
*"      IT_KSTAR_RA STRUCTURE  /SYCLO/CORE_RANGE_STR OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      ET_COMPLEX_TABLE STRUCTURE  ZSMERP_MM_GLACCOUNT_STR OPTIONAL
*"      ET_EXCHANGE_ACTION_DELETED STRUCTURE
*"        /SYCLO/CORE_CT_DELETED_STR OPTIONAL
*"----------------------------------------------------------------------
**********************************************************************
* Data Declaration Section
**********************************************************************
*Constants
  CONSTANTS: lc_bapi_name TYPE funcname VALUE 'Z_SMERP_MM_CTGLACCOUNT_GET'.

**********************************************************************
* Template Section
**********************************************************************
  INCLUDE /syclo/core_bapi_template_incl.

ENDFUNCTION.
