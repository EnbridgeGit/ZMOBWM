"Name: \TY:/SMERP/CL_MM_MATERIAL_DO\IN:/SYCLO/IF_CORE_FILTER_SERV\ME:GET_DATA_FILTER_LIST\SE:END\EI
ENHANCEMENT 0 ZZ_SMERP_CTMATPLANT_DO.
 APPEND INITIAL LINE TO lt_data_filter ASSIGNING <data_filter>.
  <data_filter>-do_handler = me->clsname.
  <data_filter>-do_mthd = 'GET_MATPLANT'.
  <data_filter>-dof_name = 'CPMATERIAL'.
  <data_filter>-usage_tabname = 'MARA'.
  <data_filter>-usage_fieldname = 'MSTAE'.
  et_data_filters[] = lt_data_filter[].
ENDENHANCEMENT.
