CLASS lcl_zz_smerp_pm_notif DEFINITION DEFERRED.
CLASS /smerp/cl_pm_notification_do DEFINITION LOCAL FRIENDS lcl_zz_smerp_pm_notif.
*----------------------------------------------------------------------*
*       CLASS LCL_ZZ_SMERP_PM_NOTIF DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_zz_smerp_pm_notif DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA obj TYPE REF TO lcl_zz_smerp_pm_notif.       "#EC NEEDED
    DATA core_object TYPE REF TO /smerp/cl_pm_notification_do . "#EC NEEDED
 INTERFACES  IOW_ZZ_SMERP_PM_NOTIF.
    METHODS:
     constructor IMPORTING core_object
       TYPE REF TO /smerp/cl_pm_notification_do OPTIONAL.
ENDCLASS.                    "LCL_ZZ_SMERP_PM_NOTIF DEFINITION
*----------------------------------------------------------------------*
*       CLASS LCL_ZZ_SMERP_PM_NOTIF IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_zz_smerp_pm_notif IMPLEMENTATION.
  METHOD constructor.
    me->core_object = core_object.
  ENDMETHOD.                    "CONSTRUCTOR

  METHOD iow_zz_smerp_pm_notif~get_assignment9.
*"------------------------------------------------------------------------*
*" Declaration of Overwrite-method, do not insert any comments here please!
*"
*"methods GET_ASSIGNMENT9
*"  importing
*"    value(IREF_RFC_OO_DATA) type ref to /SYCLO/CL_CORE_RFC_OO_DATA optional
*"  exporting
*"    value(ET_RETURN) type BAPIRET2_T
*"    value(ET_NOTIF_OBJECT) type /SYCLO/PM_NOTIF_OBJECT_TAB .
*"------------------------------------------------------------------------*

* Overwrite Method to Search for Notifications Created by Logged in User
************************************************************************
* Data Declaration Section
************************************************************************
* Tables & Structures
    DATA: lt_notif_object TYPE /syclo/pm_notif_object_tab,
          ls_notif_object LIKE LINE OF lt_notif_object,
          ls_jest TYPE jest.

* Constants
    CONSTANTS: lc_obtyp_qm1  TYPE j_obtyp VALUE 'QMI',
               lc_istat_osno TYPE j_status VALUE 'I0068'.

************************************************************************
*Step 1 - Initialization
************************************************************************
    TRY.
      me->core_object->message = 'Entering method ~ GET_ASSIGNMENT9...'(m30).
      me->core_object->logger->loginfo( iv_mobile_user = me->core_object->str_bapi_input-mobile_user
                           iv_mobile_id = me->core_object->str_bapi_input-mobile_id
                           iv_user_guid = me->core_object->str_bapi_input-user_guid
                           iv_message = me->core_object->message
                           iv_source = me->core_object->source ).

************************************************************************
*Step 2 - Assignment Type 1 Header Query logic
************************************************************************
      "Prepare list of valid notifications based on filters for mobile device
      SELECT qmel~qmnum qmel~objnr FROM qmel
        INNER JOIN qmih ON qmel~qmnum = qmih~qmnum
        INNER JOIN iloa ON qmih~iloan = iloa~iloan
        INTO TABLE et_notif_object
        WHERE qmel~qmnum IN me->core_object->str_dof_filter_vals-notif_no->*
          AND qmel~qmnum IN me->core_object->str_mdo_input_vals-it_notif_no_ra->*
          AND qmel~qmart IN me->core_object->str_dof_filter_vals-notif_type->*
          AND qmel~qmart IN me->core_object->str_mdo_input_vals-it_notif_type_ra->*
          AND qmel~ernam = sy-uname
          AND qmel~qmdab IN me->core_object->str_dof_filter_vals-date_completion->*
          AND qmel~kzloesch = space
          AND qmih~equnr IN me->core_object->str_dof_filter_vals-equipment->*
          AND qmih~equnr IN me->core_object->str_mdo_input_vals-it_equipment_ra->*
          AND qmih~ingrp IN me->core_object->str_dof_filter_vals-plangroup->*
          AND qmih~ingrp IN me->core_object->str_mdo_input_vals-it_plangroup_ra->*
          AND qmih~iwerk IN me->core_object->str_dof_filter_vals-planplant->*
          AND qmih~iwerk IN me->core_object->str_mdo_input_vals-it_planplant_ra->*
          AND iloa~tplnr IN me->core_object->str_dof_filter_vals-func_loc->*
          AND iloa~tplnr IN me->core_object->str_mdo_input_vals-it_func_loc_ra->*
          AND iloa~eqfnr IN me->core_object->str_dof_filter_vals-sortfield->*
          AND iloa~eqfnr IN me->core_object->str_mdo_input_vals-it_sortfield_ra->*.

* Only Select Notifications that are Outstanding "OSNO"

      IF NOT et_notif_object[] IS INITIAL.
        LOOP AT et_notif_object INTO ls_notif_object.
          SELECT SINGLE * FROM jest INTO ls_jest
                 WHERE objnr = ls_notif_object-objnr AND
                       stat = lc_istat_osno AND
                       inact = space.
          IF sy-subrc <> 0.
            DELETE et_notif_object.
          ENDIF.

        ENDLOOP.
      ENDIF.

      FREE: lt_notif_object.
    ENDTRY.

  ENDMETHOD.                    "IOW_ZZ_SMERP_PM_NOTIF~GET_ASSIGNMENT9
ENDCLASS.
