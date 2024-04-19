FUNCTION Z_SMERP_DOCLASSIFICATION_UPD.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IS_BAPI_INPUT) TYPE  /SYCLO/CORE_BAPI_INPUT_STR OPTIONAL
*"     VALUE(IV_EQUNR) TYPE  EQUNR OPTIONAL
*"     VALUE(IV_CLASSNUM) TYPE  KLASSE_D
*"     VALUE(IV_CHARACT) TYPE  ATNAM
*"     VALUE(IV_VALUE) TYPE  ATWRT
*"     VALUE(IV_FUNCLOC) TYPE  TPLNR OPTIONAL
*"  EXPORTING
*"     VALUE(ES_BAPI_OUTPUT) TYPE  /SYCLO/CORE_BAPI_OUTPUT_STR
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------
************************************************************************
* Template Section
************************************************************************
  INCLUDE /syclo/core_bapi_template_incl.

ENDFUNCTION.
