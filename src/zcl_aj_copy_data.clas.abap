CLASS zcl_aj_copy_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_AJ_COPY_DATA IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    INSERT zaj_aug_chall FROM ( SELECT FROM /dmo/travel FIELDS travel_id, description, total_price, currency_code,
                                CASE
                                    WHEN status = 'N' THEN 'O'
                                    WHEN status = 'P' THEN 'O'
                                    WHEN status = 'B' THEN 'A'
                                    ELSE 'X'
                                END

                              ).
    IF sy-subrc Eq 0.
        COMMIT WORK.
        out->write(
          EXPORTING
            data   = |Inserted data|
*            name   =
*          RECEIVING
*            output =
        ).
    ENDIF.

  ENDMETHOD.
ENDCLASS.
