"Name: \TY:/SYCLO/CL_PM_MEASURINGPOINT_DO\ME:GET_COMPLEX_TABLE\SE:BEGIN\EI
ENHANCEMENT 0 ZUSERPARAMCHECK.
Data: gv_good type c,
      gw_usr05 type usr05 .

constants: c_x TYPE c value 'X',
           c_z TYPE c value 'Z' .

select single *
  into gw_usr05
  from usr05
 where bname = syst-uname and
       parid = 'ZRMR' .

  clear: gv_good .
  if gw_usr05-parva = c_x  or
     gw_usr05-parva = c_z .
     gv_good = abap_true .
  endif .

  check gv_good is not initial .

ENDENHANCEMENT.
