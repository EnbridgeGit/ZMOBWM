FUNCTION z_smerp_mm_ctmatgrp_get.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IS_BAPI_INPUT) TYPE  /SYCLO/CORE_BAPI_INPUT_STR OPTIONAL
*"  EXPORTING
*"     VALUE(ES_BAPI_OUTPUT) TYPE  /SYCLO/CORE_BAPI_OUTPUT_STR
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      ET_COMPLEX_TABLE STRUCTURE  ZSMERP_MM_MATKL_STR OPTIONAL
*"      ET_EXCHANGE_ACTION_DELETED STRUCTURE
*"        /SYCLO/MM_WERKS_DELETED_STR OPTIONAL
*"----------------------------------------------------------------------
**********************************************************************
* Data Declaration Section
**********************************************************************
*Constants
  CONSTANTS: lc_bapi_name TYPE funcname VALUE 'Z_SMERP_MM_CTMATGRP_GET'.

**********************************************************************
* Template Section
**********************************************************************
  INCLUDE /syclo/core_bapi_template_incl.

ENDFUNCTION.
