class ZCL_PM_MDO_PM_CLASSIF definition
  public
  final
  create public .

public section.
*"* public components of class ZCL_PM_MDO_PM_CLASSIF
*"* do not include other source files here!!!

  interfaces /SMERP/IF_PM_CLASSIF_BADI .
  interfaces IF_BADI_INTERFACE .
protected section.
*"* protected components of class ZCL_PM_MDO_PM_CLASSIF
*"* do not include other source files here!!!
private section.
*"* private components of class ZCL_PM_MDO_PM_CLASSIF
*"* do not include other source files here!!!
ENDCLASS.



CLASS ZCL_PM_MDO_PM_CLASSIF IMPLEMENTATION.


method /SMERP/IF_PM_CLASSIF_BADI~GET_BEGIN.
endmethod.


METHOD /smerp/if_pm_classif_badi~get_end.

  TYPES: BEGIN OF ty_mdo_output_vals,
          et_classification       TYPE REF TO /syclo/pm_class_tab,
          et_characteristic       TYPE REF TO /syclo/pm_class_char_tab,
          et_characteristic_val   TYPE REF TO /syclo/pm_char_val_tab,
        END OF ty_mdo_output_vals.

  FIELD-SYMBOLS: <fs_mdo_output_vals>    TYPE ty_mdo_output_vals,
                 <fs_characteristic>     TYPE /syclo/pm_class_char_str,
                 <fs_classification>     TYPE /syclo/pm_class_str,
                 <fs_characteristic_val> TYPE /syclo/pm_char_val_str.

  DATA: ls_characteristic_val TYPE /syclo/pm_char_val_str,
        lt_char_val_tab       TYPE /syclo/pm_char_val_tab.

  ASSIGN cs_mdo_output TO <fs_mdo_output_vals>.
  IF <fs_mdo_output_vals> IS NOT ASSIGNED.
    RETURN.
  ENDIF.

  LOOP AT <fs_mdo_output_vals>-et_classification->* ASSIGNING <fs_classification>.
    LOOP AT <fs_mdo_output_vals>-et_characteristic->* ASSIGNING <fs_characteristic> WHERE clint = <fs_classification>-clint.
      READ TABLE <fs_mdo_output_vals>-et_characteristic_val->* WITH KEY objek = <fs_classification>-objek
                                                                        atinn = <fs_characteristic>-atinn
                                                               TRANSPORTING NO FIELDS.
      IF sy-subrc EQ 0.
        CONTINUE.
      ENDIF.

      ls_characteristic_val-atzhl = '001'.
      ls_characteristic_val-mafid = 'O'.
      ls_characteristic_val-objek = <fs_classification>-objek.
      ls_characteristic_val-atinn = <fs_characteristic>-atinn.
      ls_characteristic_val-klart = <fs_characteristic>-klart.
      ls_characteristic_val-atinn_%ext = <fs_characteristic>-atnam.
      ls_characteristic_val-equnr = <fs_classification>-equnr.
      ls_characteristic_val-tplnr = <fs_classification>-tplnr.
      APPEND ls_characteristic_val TO lt_char_val_tab.
      CLEAR ls_characteristic_val.

    ENDLOOP.
  ENDLOOP.

  APPEND LINES OF lt_char_val_tab TO <fs_mdo_output_vals>-et_characteristic_val->*.

ENDMETHOD.


method /SMERP/IF_PM_CLASSIF_BADI~GET_KEYLIST_FROM_EXCHOBJ.
endmethod.
ENDCLASS.
