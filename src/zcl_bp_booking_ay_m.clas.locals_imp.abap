CLASS lhc_zi_booking_ay_m DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS earlynumbering_cba_Bookingsupp FOR NUMBERING
      IMPORTING entities FOR CREATE zi_booking_ay_m\_Bookingsuppl.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zi_booking_ay_m RESULT result.
    METHODS validateconnection FOR VALIDATE ON SAVE
      IMPORTING keys FOR zi_booking_ay_m~validateconnection.

    METHODS validatecurrencycode FOR VALIDATE ON SAVE
      IMPORTING keys FOR zi_booking_ay_m~validatecurrencycode.

    METHODS validatecustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR zi_booking_ay_m~validatecustomer.

    METHODS validateflightprice FOR VALIDATE ON SAVE
      IMPORTING keys FOR zi_booking_ay_m~validateflightprice.

    METHODS validatestatus FOR VALIDATE ON SAVE
      IMPORTING keys FOR zi_booking_ay_m~validatestatus.
    METHODS calculateflightprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR zi_booking_ay_m~calculateflightprice.

ENDCLASS.

CLASS lhc_zi_booking_ay_m IMPLEMENTATION.

  METHOD earlynumbering_cba_Bookingsupp.

    DATA : lv_max_id TYPE /dmo/booking_supplement_id.

    READ ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_booking_ay_m
        BY \_BookingSuppl
        FROM CORRESPONDING #( entities )
        LINK DATA(lt_link_data).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<fs_group_entity>)
                               GROUP BY <fs_group_entity>-%key.


      lv_max_id = REDUCE #( INIT lv_max = CONV /dmo/booking_supplement_id( '0' )
                                 FOR ls_link IN lt_link_data USING KEY entity
                                     WHERE ( source-%key = <fs_group_entity>-%key )
                                 NEXT lv_max = COND #( WHEN lv_max < ls_link-target-BookingSupplimentId
                                                       THEN ls_link-target-BookingSupplimentId
                                                       ELSE lv_max
                                                     )
                          ).

      lv_max_id = REDUCE #( INIT lv_max = lv_max_id
                            FOR ls_entity IN entities USING KEY entity
                               WHERE ( %key = <fs_group_entity>-%key )
                               FOR ls_bookingsupp IN ls_entity-%target

                                   NEXT lv_max = COND #( WHEN lv_max < ls_bookingsupp-BookingSupplimentId
                                                           THEN ls_bookingsupp-BookingSupplimentId
                                                           ELSE lv_max
                                                       )
                          ).

      LOOP AT entities ASSIGNING FIELD-SYMBOL(<fs_entities>) USING KEY entity WHERE %key = <fs_group_entity>-%key.



        LOOP AT <fs_entities>-%target ASSIGNING FIELD-SYMBOL(<fs_booksup>).

          APPEND CORRESPONDING #( <fs_booksup> ) TO mapped-zi_booksupp_ay_m ASSIGNING FIELD-SYMBOL(<fs_new_booksup>).
          IF <fs_booksup>-BookingSupplimentId IS INITIAL.
            lv_max_id += 1.
            <fs_new_booksup>-BookingSupplimentId = lv_max_id.
          ENDIF.
        ENDLOOP.
      ENDLOOP.


    ENDLOOP.


  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_travel_ay_m BY \_Booking
        FIELDS ( TravelId BookingId BookingStatus )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_res).
*        LINK DATA(lt_result).

    result = VALUE #(
                        FOR ls_res IN lt_res
                        (
                            %tky = ls_res-%tky
                            %features-%assoc-_BookingSuppl = COND #( WHEN ls_res-BookingStatus = 'X'
                                                                          THEN if_abap_behv=>fc-o-disabled
                                                                          ELSE if_abap_behv=>fc-o-enabled )
                        )
                    ).

  ENDMETHOD.

  METHOD validateConnection.

    DATA : lt_booking TYPE TABLE FOR READ IMPORT zi_booking_ay_m.

    lt_booking = VALUE #(
                            FOR lwa_keys IN keys
                                ( %key = lwa_keys-%key )
                        ).

    READ ENTITY IN LOCAL MODE zi_booking_ay_m
        FIELDS ( CarrierId ConnectionId )
        WITH lt_booking
        RESULT DATA(lt_result).

    IF lt_result IS NOT INITIAL.

      SELECT
          FROM /DMO/I_Flight
          FIELDS AirlineID, ConnectionID
          FOR ALL ENTRIES IN @lt_result
          WHERE AirlineID = @lt_result-%data-CarrierId
          AND   ConnectionID = @lt_result-%data-ConnectionId
          INTO TABLE @DATA(lt_flight).

    ENDIF.

    LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<fs_result>).

      IF <fs_result>-%data-CarrierId IS INITIAL OR <fs_result>-%data-ConnectionId IS INITIAL.

        IF <fs_result>-%data-CarrierId IS INITIAL.

          APPEND VALUE #( %key = <fs_result>-%key ) TO failed-zi_booking_ay_m.

          APPEND VALUE #(
                          %key = <fs_result>-%key
                          %msg = NEW /dmo/cm_flight_messages(
                                                              textid                = /dmo/cm_flight_messages=>enter_airline_id
                                                              travel_id             = <fs_result>-%key-TravelId
                                                              booking_id            = <fs_result>-%key-BookingId
                                                              severity              = if_abap_behv_message=>severity-error
                                                            )
                          %element-carrierid = if_abap_behv=>mk-on
                        ) TO reported-zi_booking_ay_m.

        ENDIF.

        IF <fs_result>-%data-ConnectionId IS INITIAL.

          APPEND VALUE #( %key = <fs_result>-%key ) TO failed-zi_booking_ay_m.

          APPEND VALUE #(
                          %key = <fs_result>-%key
                          %msg = NEW /dmo/cm_flight_messages(
                                                              textid                = /dmo/cm_flight_messages=>enter_connection_id
                                                              travel_id             = <fs_result>-%key-TravelId
                                                              booking_id            = <fs_result>-%key-BookingId
                                                              severity              = if_abap_behv_message=>severity-error
                                                            )
                          %element-connectionid = if_abap_behv=>mk-on
                        ) TO reported-zi_booking_ay_m.

        ENDIF.

      ELSEIF NOT line_exists( lt_flight[ AirlineID =  <fs_result>-%data-CarrierId ConnectionID = <fs_result>-%data-ConnectionId ] ).

        APPEND VALUE #( %key = <fs_result>-%key ) TO failed-zi_booking_ay_m.

        APPEND VALUE #(
                        %key = <fs_result>-%key
                        %msg = me->new_message(
                                                id       = 'Z_MESSAGES_AY_M'
                                                number   = '003'
                                                severity = if_abap_behv_message=>severity-error
                                                v1       = <fs_result>-%data-CarrierId
                                                v2       = <fs_result>-%data-ConnectionId
                               )
                        %element-carrierid = if_abap_behv=>mk-on
                        %element-connectionid = if_abap_behv=>mk-on
                      ) TO reported-zi_booking_ay_m.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateCurrencyCode.

    DATA : lt_booking TYPE TABLE FOR READ IMPORT zi_booking_ay_m.

    lt_booking = VALUE #(
                            FOR lwa_keys IN keys
                                ( %key = lwa_keys-%key )
                        ).

    READ ENTITY IN LOCAL MODE zi_booking_ay_m
        FIELDS ( CustomerId )
        WITH lt_booking
        RESULT DATA(lt_result).

    IF lt_result IS NOT INITIAL.

      SELECT *
        FROM I_Currency
        FOR ALL ENTRIES IN @lt_result
        WHERE Currency = @lt_result-%data-CurrencyCode
        INTO TABLE @DATA(lt_curcode).

    ENDIF.

    LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<fs_currcode>).

      IF <fs_currcode>-%data-CurrencyCode IS INITIAL.

        APPEND VALUE #( %key = <fs_currcode>-%key ) TO failed-zi_booking_ay_m.

        APPEND VALUE #(
                        %key = <fs_currcode>-%key
                        %msg = NEW /dmo/cm_flight_messages(
                                                            textid                = /dmo/cm_flight_messages=>currency_required
                                                            travel_id             = <fs_currcode>-%key-TravelId
                                                            booking_id            = <fs_currcode>-%key-BookingId
                                                            severity              = if_abap_behv_message=>severity-error
                                                          )
                        %element-currencycode = if_abap_behv=>mk-on
                      ) TO reported-zi_booking_ay_m.

      ELSEIF NOT line_exists( lt_curcode[ Currency = <fs_currcode>-%data-CurrencyCode   ] ).

        APPEND VALUE #( %key = <fs_currcode>-%key ) TO failed-zi_booking_ay_m.

        APPEND VALUE #(
                        %key = <fs_currcode>-%key
                        %msg = NEW /dmo/cm_flight_messages(
                                                            textid                = /dmo/cm_flight_messages=>currency_not_existing
                                                            travel_id             = <fs_currcode>-%key-TravelId
                                                            booking_id            = <fs_currcode>-%key-BookingId
                                                            currency_code         = <fs_currcode>-%data-CurrencyCode
                                                            severity              = if_abap_behv_message=>severity-error
                                                          )
                        %element-currencycode = if_abap_behv=>mk-on
                      ) TO reported-zi_booking_ay_m.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateCustomer.

    DATA : lt_booking TYPE TABLE FOR READ IMPORT zi_booking_ay_m.

    lt_booking = VALUE #(
                            FOR lwa_keys IN keys
                                ( %key = lwa_keys-%key )
                        ).

    READ ENTITY IN LOCAL MODE zi_booking_ay_m
        FIELDS ( CustomerId )
        WITH lt_booking
        RESULT DATA(lt_result).

    IF lt_result IS NOT INITIAL.

      SELECT
          FROM /DMO/I_Customer
          FIELDS  CustomerID
          FOR ALL ENTRIES IN @lt_result
          WHERE CustomerID = @lt_result-%data-CustomerId
          INTO TABLE @DATA(lt_customer).

    ENDIF.

    LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<fs_customer>).

      IF <fs_customer>-%data-CustomerId IS INITIAL.

        APPEND VALUE #( %key = <fs_customer>-%key  ) TO failed-zi_booking_ay_m.

        APPEND VALUE #(
                        %key = <fs_customer>-%key
                        %msg = NEW /dmo/cm_flight_messages(
                                                            textid                = /dmo/cm_flight_messages=>enter_customer_id
                                                            travel_id             = <fs_customer>-%key-TravelId
                                                            booking_id            = <fs_customer>-%key-BookingId
                                                            severity              = if_abap_behv_message=>severity-error
                                                           )
                        %element-customerid = if_abap_behv=>mk-on

                      ) TO reported-zi_booking_ay_m.
      ELSEIF NOT line_exists( lt_customer[ CustomerID = <fs_customer>-%data-CustomerId ] ).

        APPEND VALUE #( %key = <fs_customer>-%key  ) TO failed-zi_booking_ay_m.

        APPEND VALUE #(
                        %key = <fs_customer>-%key
                        %msg = NEW /dmo/cm_flight_messages(
                                                            textid                = /dmo/cm_flight_messages=>customer_unkown
                                                            travel_id             = <fs_customer>-%key-TravelId
                                                            booking_id            = <fs_customer>-%key-BookingId
                                                            customer_id           = <fs_customer>-%data-CustomerId
                                                            severity              = if_abap_behv_message=>severity-error
                                                           )
                        %element-customerid = if_abap_behv=>mk-on

                      ) TO reported-zi_booking_ay_m.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateFlightPrice.

    DATA : lt_booking TYPE TABLE FOR READ IMPORT zi_booking_ay_m.

    lt_booking = VALUE #(
                            FOR lwa_keys IN keys
                            ( %key = lwa_keys-%key )
                        ).

    READ ENTITY  IN LOCAL MODE zi_booking_ay_m
        FIELDS ( FlightPrice )
        WITH lt_booking
        RESULT DATA(lt_result) .

    LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<fs_price>).

      IF <fs_price>-FlightPrice IS INITIAL.

        APPEND VALUE #( %key = <fs_price>-%key  ) TO failed-zi_booking_ay_m.

        APPEND VALUE #(
                        %key = <fs_price>-%key
                        %msg = me->new_message(
                                                id       = 'Z_MESSAGES_AY_M'
                                                number   = '002'
                                                severity = if_abap_behv_message=>severity-error
                                               )
                        %element-flightprice = if_abap_behv=>mk-on

                      ) TO reported-zi_booking_ay_m.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateStatus.

    DATA : lt_booking TYPE TABLE FOR READ IMPORT zi_booking_ay_m.

    lt_booking = VALUE #(
                            FOR lwa_keys IN keys
                            ( %key = lwa_keys-%key )
                        ).

    READ ENTITY  IN LOCAL MODE zi_booking_ay_m
        FIELDS ( BookingStatus )
        WITH lt_booking
        RESULT DATA(lt_result) .

    LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<fs_status>).

      CASE <fs_status>-%data-BookingStatus.
        WHEN 'N' OR 'B' OR 'X'.

        WHEN space.

          APPEND VALUE #( %key = <fs_status>-%key  ) TO failed-zi_booking_ay_m.

          APPEND VALUE #(
                          %key = <fs_status>-%key
                          %msg = NEW /dmo/cm_flight_messages(
                                                                textid                = /dmo/cm_flight_messages=>status_invalid
                                                                travel_id             = <fs_status>-%data-TravelId
                                                                booking_id            = <fs_status>-%data-BookingId
                                                                status                = <fs_status>-%data-BookingStatus
                                                                severity              = if_abap_behv_message=>severity-error
                                                            )
                          %element-bookingstatus = if_abap_behv=>mk-on

                        ) TO reported-zi_booking_ay_m.
        WHEN OTHERS.

          APPEND VALUE #( %key = <fs_status>-%key  ) TO failed-zi_booking_ay_m.

          APPEND VALUE #(
                          %key = <fs_status>-%key
                          %msg = NEW /dmo/cm_flight_messages(
                                                                textid                = /dmo/cm_flight_messages=>status_invalid
                                                                travel_id             = <fs_status>-%data-TravelId
                                                                booking_id            = <fs_status>-%data-BookingId
                                                                status                = <fs_status>-%data-BookingStatus
                                                                severity              = if_abap_behv_message=>severity-error
                                                            )
                          %element-bookingstatus = if_abap_behv=>mk-on

                        ) TO reported-zi_booking_ay_m.


      ENDCASE.


    ENDLOOP.

  ENDMETHOD.

  METHOD calculateFlightPrice.

    DATA : lt_travel TYPE STANDARD TABLE OF zi_travel_ay_m WITH UNIQUE HASHED KEY key COMPONENTS TravelId.

    lt_travel = CORRESPONDING #( keys DISCARDING DUPLICATES MAPPING TravelId = TravelId ).

    MODIFY ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_travel_ay_m
        EXECUTE reCalTotalPrice
        FROM CORRESPONDING #( lt_travel ).

  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
