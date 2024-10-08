CLASS zcl_data_insert_ay_m DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_data_insert_ay_m IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

*    SELECT * FROM zay_travel_m INTO TABLE @DATA(li_travel).
*
*    DELETE FROM zay_travel_m WHERE travel_id = '00200704'.
*    DELETE FROM zay_travel_m WHERE travel_id = '00445566'.
*    DELETE FROM zay_travel_m WHERE travel_id = '00667755'.
*    DELETE FROM zay_travel_m WHERE travel_id = '00998877'.
*    DELETE FROM zay_travel_m WHERE travel_id = '06111989'.
    DELETE FROM zay_travel_m.
    DELETE FROM zay_booking_m.
    DELETE FROM zay_booksupp_m.
    COMMIT WORK.

    INSERT zay_travel_m FROM (
        SELECT * FROM /dmo/travel_m
     ).
    COMMIT WORK.

    INSERT zay_booking_m FROM (
        SELECT * FROM /dmo/booking_m
    ).
    COMMIT WORK.

    INSERT zay_booksupp_m FROM (
        SELECT * FROM /dmo/booksuppl_m
    ).
    COMMIT WORK.



    out->write( |Data is inserted in tables| ).

  ENDMETHOD.
ENDCLASS.
