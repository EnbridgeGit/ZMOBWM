CLASS LCL_ZZ_SYCLO_CL_PLANT_DO DEFINITION.
PUBLIC SECTION.
CLASS-DATA OBJ TYPE REF TO LCL_ZZ_SYCLO_CL_PLANT_DO. "#EC NEEDED
DATA CORE_OBJECT TYPE REF TO /SYCLO/CL_MM_PLANT_DO . "#EC NEEDED
 INTERFACES  IPO_ZZ_SYCLO_CL_PLANT_DO.
  METHODS:
   CONSTRUCTOR IMPORTING CORE_OBJECT
     TYPE REF TO /SYCLO/CL_MM_PLANT_DO OPTIONAL.
ENDCLASS.
CLASS LCL_ZZ_SYCLO_CL_PLANT_DO IMPLEMENTATION.
METHOD CONSTRUCTOR.
  ME->CORE_OBJECT = CORE_OBJECT.
ENDMETHOD.

METHOD IPO_ZZ_SYCLO_CL_PLANT_DO~GET_DATA_FILTER_LIST.
*"------------------------------------------------------------------------*
*" Declaration of POST-method, do not insert any comments here please!
*"
*"methods GET_DATA_FILTER_LIST
*"  importing
*"    value(IV_MTHD) type /SYCLO/CORE_DO_MTHD_DTE optional
*"  changing
*"    value(ET_DATA_FILTERS) type /SYCLO/CORE_FILTER_SERV_TAB . "#EC CI_VALPAR
*"------------------------------------------------------------------------*

ENDMETHOD.
ENDCLASS.
