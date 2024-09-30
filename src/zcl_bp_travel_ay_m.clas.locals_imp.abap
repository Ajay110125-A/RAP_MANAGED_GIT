CLASS lhc_ZI_TRAVEL_AY_M DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zi_travel_ay_m RESULT result.
    METHODS accepttravel FOR MODIFY
      IMPORTING keys FOR ACTION zi_travel_ay_m~accepttravel RESULT result.

    METHODS copytravel FOR MODIFY
      IMPORTING keys FOR ACTION zi_travel_ay_m~copytravel.

    METHODS recaltotalprice FOR MODIFY
      IMPORTING keys FOR ACTION zi_travel_ay_m~recaltotalprice.

    METHODS rejecttravel FOR MODIFY
      IMPORTING keys FOR ACTION zi_travel_ay_m~rejecttravel RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zi_travel_ay_m RESULT result.
    METHODS validatecustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR zi_travel_ay_m~validatecustomer.
    METHODS validatebookingfee FOR VALIDATE ON SAVE
      IMPORTING keys FOR zi_travel_ay_m~validatebookingfee.

    METHODS validatecurrencycode FOR VALIDATE ON SAVE
      IMPORTING keys FOR zi_travel_ay_m~validatecurrencycode.

    METHODS validatedates FOR VALIDATE ON SAVE
      IMPORTING keys FOR zi_travel_ay_m~validatedates.

    METHODS validatestatus FOR VALIDATE ON SAVE
      IMPORTING keys FOR zi_travel_ay_m~validatestatus.
    METHODS calculatetotalprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR zi_travel_ay_m~calculatetotalprice.

    METHODS earlynumbering_cba_booking FOR NUMBERING
      IMPORTING entities FOR CREATE zi_travel_ay_m\_booking.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE zi_travel_ay_m.

ENDCLASS.

CLASS lhc_ZI_TRAVEL_AY_M IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA(lt_entities) = entities.

    DELETE lt_entities WHERE TravelId IS NOT INITIAL.

    TRY.

        cl_numberrange_runtime=>number_get(
          EXPORTING
*            ignore_buffer     =
            nr_range_nr       = '01'
            object            = '/DMO/TRV_M'
            quantity          = CONV #( lines( lt_entities ) )
*            subobject         =
*            toyear            =
          IMPORTING
            number            = DATA(lv_latest_num)
            returncode        = DATA(lv_return_code)
            returned_quantity = DATA(lv_qty)
        ).
      CATCH cx_nr_object_not_found.
      CATCH cx_number_ranges INTO DATA(lo_no_error).

        LOOP AT lt_entities INTO DATA(ls_entities).

          APPEND VALUE #( %cid = ls_entities-%cid
                          %key = ls_entities-%key ) TO failed-zi_travel_ay_m.

          APPEND VALUE #( %cid = ls_entities-%cid
                           %key = ls_entities-%key
                           %msg = lo_no_error ) TO reported-zi_travel_ay_m.
        ENDLOOP.

    ENDTRY.

    ASSERT lines( lt_entities ) = lv_qty.

    DATA : lv_old_num TYPE i.
    lv_old_num = lv_latest_num - lv_qty .

    LOOP AT lt_entities INTO ls_entities.

      lv_old_num += 1.

      APPEND VALUE #( %cid      = ls_entities-%cid
                      TravelId  = lv_old_num ) TO mapped-zi_travel_ay_m.

    ENDLOOP.



  ENDMETHOD.

  METHOD earlynumbering_cba_Booking.

    DATA : lv_max_id TYPE /dmo/booking_id.

    READ ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_travel_ay_m
        BY \_Booking
        FROM CORRESPONDING #( entities )
        LINK DATA(lt_link_data).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_group_entity>)
                               GROUP BY <ls_group_entity>-TravelId.


      lv_max_id = REDUCE #( INIT lv_max = CONV /dmo/booking_id( '0' )
                               FOR ls_link IN lt_link_data USING KEY entity
                                   WHERE ( source-TravelId = <ls_group_entity>-TravelId )
                                NEXT lv_max = COND #( WHEN lv_max < ls_link-target-BookingId
                                                           THEN ls_link-target-BookingId
                                                           ELSE lv_max
                                                     )


                                ).
      lv_max_id = REDUCE #( INIT lv_max = lv_max_id
                               FOR ls_entity IN entities USING KEY entity
                                   WHERE ( TravelId = <ls_group_entity>-TravelId )
                                 FOR ls_booking IN ls_entity-%target
                                 NEXT lv_max = COND #( WHEN lv_max < ls_booking-BookingId
                                                           THEN ls_booking-BookingId
                                                           ELSE lv_max
                                                     )

                          ).

      LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entities>).


        LOOP AT <ls_entities>-%target ASSIGNING FIELD-SYMBOL(<ls_booking>).

          APPEND CORRESPONDING #( <ls_booking> ) TO mapped-zi_booking_ay_m ASSIGNING FIELD-SYMBOL(<ls_new_map_booking>).

          IF <ls_booking>-BookingId IS INITIAL.

            lv_max_id += 10.

            <ls_new_map_booking>-BookingId = lv_max_id.
          ENDIF.

        ENDLOOP.


      ENDLOOP.




    ENDLOOP.


  ENDMETHOD.

  METHOD acceptTravel.


    MODIFY ENTITIES OF zi_travel_ay_m IN LOCAL MODE
       ENTITY zi_travel_ay_m
       UPDATE FIELDS ( OverallStatus )
       WITH VALUE #( FOR ls_keys IN keys (
                                           %tky = ls_keys-%tky
                                           %data-OverallStatus = 'A'
                                         ) )
    .

    READ ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_travel_ay_m
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_result).

    result = VALUE #( FOR ls_result IN lt_result (
                                                   %tky = ls_result-%tky
                                                   %param = ls_result
                                                 )
                    ).

  ENDMETHOD.

  METHOD copyTravel.

    DATA : lt_travel_new      TYPE TABLE FOR CREATE zi_travel_ay_m,
           lt_booking_new     TYPE TABLE FOR CREATE zi_travel_ay_m\_Booking,
           lt_bookingsupp_new TYPE TABLE FOR CREATE zi_booking_ay_m\_BookingSuppl.

    READ TABLE keys ASSIGNING FIELD-SYMBOL(<fs_without_cid>) WITH KEY %cid = ' '.
    ASSERT <fs_without_cid> IS NOT ASSIGNED.

    READ ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_travel_ay_m
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_travel_r)
        FAILED DATA(lt_failed_t).

    READ ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_travel_ay_m BY \_Booking
        ALL FIELDS WITH CORRESPONDING #( lt_travel_r )
        RESULT DATA(lt_booking_r)
        FAILED DATA(lt_failed_b).

    READ ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_booking_ay_m BY \_BookingSuppl
        ALL FIELDS WITH CORRESPONDING #( lt_booking_r )
        RESULT DATA(lt_booksup_r)
        FAILED DATA(lt_failed_bs).


    LOOP AT lt_travel_r ASSIGNING FIELD-SYMBOL(<fs_travel_r>).

*        APPEND INITIAL LINE TO lt_travel_new ASSIGNING FIELD-SYMBOL(<fs_travel>).
*        <fs_travel>-%cid = keys[ KEY entity TravelId = <fs_travel_r>-TravelId ]-%cid.
*        <fs_travel>-%data = CORRESPONDING #( <fs_travel_r>-%data EXCEPT TravelId ).

*        OR

      APPEND VALUE #(
                      %cid = keys[ KEY entity TravelId = <fs_travel_r>-TravelId ]-%cid
                      %data = CORRESPONDING #( <fs_travel_r>-%data EXCEPT TravelId )
                    ) TO lt_travel_new ASSIGNING FIELD-SYMBOL(<fs_travel>).

      <fs_travel>-BeginDate = cl_abap_context_info=>get_system_date( ).
      <fs_travel>-EndDate = cl_abap_context_info=>get_system_date( ) + 30.
      <fs_travel>-OverallStatus = 'O'.

      APPEND VALUE #(
                %cid_ref = <fs_travel>-%cid
              ) TO lt_booking_new ASSIGNING FIELD-SYMBOL(<fs_booking>).

      LOOP AT lt_booking_r ASSIGNING FIELD-SYMBOL(<fs_booking_r>)
                           USING KEY entity
                           WHERE TravelId = <fs_travel_r>-TravelId.

        APPEND VALUE #(
                        %cid = <fs_travel>-%cid && <fs_booking_r>-BookingId
                         %data  = CORRESPONDING #( <fs_booking_r> EXCEPT travelid )
                       ) TO <fs_booking>-%target ASSIGNING FIELD-SYMBOL(<fs_booking_n>).

        <fs_booking_n>-BookingStatus = 'N'.

        APPEND VALUE #( %cid_ref = <fs_booking_n>-%cid )
               TO lt_bookingsupp_new ASSIGNING FIELD-SYMBOL(<fs_bsup>).

        LOOP AT lt_booksup_r ASSIGNING FIELD-SYMBOL(<fs_booksup_r>)
                             USING KEY entity
                             WHERE TravelId = <fs_travel_r>-TravelId AND BookingId = <fs_booking_n>-BookingId.

          APPEND VALUE #(
                           %cid = <fs_travel>-%cid && <fs_booking_r>-BookingId && <fs_booksup_r>-BookingSupplimentId
                           %data = CORRESPONDING #( <fs_booksup_r> EXCEPT travelid bookingid )
                         )
                 TO <fs_bsup>-%target.

        ENDLOOP.

      ENDLOOP.

    ENDLOOP.

    MODIFY ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_travel_ay_m
        CREATE FIELDS (  agencyid customerid begindate enddate bookingfee totalprice currencycode description overallstatus )
        WITH lt_travel_new

        ENTITY zi_travel_ay_m
            CREATE BY \_Booking
            FIELDS ( bookingdate customerid carrierid connectionid flightdate flightprice currencycode bookingstatus )
            WITH lt_booking_new

        ENTITY zi_booking_ay_m
            CREATE BY \_BookingSuppl
            FIELDS ( supplimentid  price  currencycode )
            WITH lt_bookingsupp_new
        MAPPED DATA(lt_mapped_new)
        FAILED DATA(lt_failed_new)
        .

    mapped-zi_travel_ay_m = lt_mapped_new-zi_travel_ay_m.




  ENDMETHOD.

  METHOD reCalTotalPrice.

*    DATA : lt_reported TYPE TABLE FOR MAPPED zi_travel_ay_m.

    TYPES : BEGIN OF ty_total,
              price TYPE /dmo/total_price,
              curr  TYPE /dmo/currency_code,
            END OF ty_total.

    DATA : l_total_price TYPE /dmo/total_price,
           lt_total      TYPE TABLE OF ty_total.

    READ ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_travel_ay_m
        FIELDS ( BookingFee CurrencyCode )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_travel).

    DELETE lt_travel WHERE %data-CurrencyCode IS INITIAL.

    READ ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_travel_ay_m BY \_Booking
        FIELDS ( FlightPrice CurrencyCode )
        WITH CORRESPONDING #( lt_travel )
        RESULT DATA(lt_booking).

    READ ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_booking_ay_m BY \_BookingSuppl
        FIELDS ( Price )
        WITH CORRESPONDING #( lt_booking )
        RESULT DATA(lt_booksup).

    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<fs_travel>).


      lt_total = VALUE #( ( price = <fs_travel>-%data-BookingFee curr = <fs_travel>-%data-CurrencyCode ) ).

      LOOP AT lt_booking ASSIGNING FIELD-SYMBOL(<fs_booking>)
                                   USING KEY entity
                                   WHERE %key-TravelId = <fs_travel>-%key-TravelId
                                   AND   %data-CurrencyCode IS NOT INITIAL .

        APPEND VALUE #( price = <fs_booking>-%data-FlightPrice curr = <fs_booking>-%data-CurrencyCode ) TO lt_total.

        LOOP AT lt_booksup ASSIGNING FIELD-SYMBOL(<fs_booksup>)
                                     USING KEY entity
                                     WHERE %key-TravelId = <fs_booking>-%key-TravelId
                                     AND   %key-BookingId = <fs_booking>-%key-BookingId
                                     AND   %data-CurrencyCode IS NOT INITIAL.

          APPEND VALUE #( price = <fs_booksup>-%data-Price curr = <fs_booksup>-%data-CurrencyCode ) TO lt_total.

        ENDLOOP.

      ENDLOOP.

      CLEAR l_total_price.
      LOOP AT lt_total ASSIGNING FIELD-SYMBOL(<fs_total>).

*        IF <fs_total>-curr = <fs_travel>-%data-CurrencyCode.
        <fs_travel>-%data-TotalPrice += <fs_total>-price.
*        ELSE.
*          /dmo/cl_flight_amdp=>convert_currency(
*            EXPORTING
*              iv_amount               = <fs_total>-price
*              iv_currency_code_source = <fs_total>-curr
*              iv_currency_code_target = <fs_travel>-%data-CurrencyCode
*              iv_exchange_rate_date   = cl_abap_context_info=>get_system_date( )
*            IMPORTING
*              ev_amount               = l_total_price
*          ).
*
*          <fs_travel>-%data-TotalPrice += l_total_price.
*          CLEAR l_total_price.
*        ENDIF.

      ENDLOOP.

    ENDLOOP.

    MODIFY ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_travel_ay_m
        UPDATE FIELDS ( TotalPrice )
        WITH CORRESPONDING #( lt_travel ).
*    lt_reported = CORRESPONDING #( lt_travel ).
    reported-zi_travel_ay_m = CORRESPONDING #( lt_travel ).

  ENDMETHOD.

  METHOD rejectTravel.

    MODIFY ENTITIES OF zi_travel_ay_m IN LOCAL MODE
       ENTITY zi_travel_ay_m
       UPDATE FIELDS ( OverallStatus )
       WITH VALUE #( FOR ls_keys IN keys (
                                           %tky = ls_keys-%tky
                                           %data-OverallStatus = 'X'
                                         ) )
    .

    READ ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_travel_ay_m
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_result).

    result = VALUE #( FOR ls_result IN lt_result (
                                                   %tky = ls_result-%tky
                                                   %param = ls_result
                                                 )
                    ).

  ENDMETHOD.

  METHOD get_instance_features.


    READ ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_travel_ay_m
        FIELDS ( TravelId OverallStatus )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_result)
        FAILED DATA(lt_failed).

    result = VALUE #( FOR ls_result IN lt_result
                        ( %tky = ls_result-%tky
                          %features-%action-acceptTravel = COND #( WHEN ls_result-OverallStatus = 'A'
                                                                        THEN if_abap_behv=>fc-o-disabled
                                                                        ELSE if_abap_behv=>fc-o-enabled
                                                                  )
                          %features-%action-rejectTravel = COND #( WHEN ls_result-OverallStatus = 'X '
                                                                        THEN if_abap_behv=>fc-o-disabled
                                                                        ELSE if_abap_behv=>fc-o-enabled
                                                                  )
                          %features-%assoc-_Booking = COND #( WHEN ls_result-OverallStatus = 'X '
                                                                        THEN if_abap_behv=>fc-o-disabled
                                                                        ELSE if_abap_behv=>fc-o-enabled
                                                                  )
                        )
                    ).



  ENDMETHOD.

  METHOD validateCustomer.

    READ ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_travel_ay_m
**        FIELDS (  CustomerId )
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_result).

    DATA : lt_cust TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    lt_cust = CORRESPONDING #( lt_result DISCARDING DUPLICATES MAPPING customer_id = CustomerId ).

    IF lt_cust IS NOT INITIAL.

      SELECT
          FROM /dmo/customer
          FIELDS customer_id
          FOR ALL ENTRIES IN @lt_cust
          WHERE customer_id = @lt_cust-customer_id
          INTO TABLE @DATA(lt_customers).
      IF sy-subrc EQ 0.
      ENDIF.
      LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<fs_customer>).

        IF <fs_customer>-%data-CustomerId IS INITIAL
            OR NOT line_exists( lt_customers[ customer_id = <fs_customer>-%data-CustomerId ] ).

          APPEND VALUE #( %tky = <fs_customer>-%tky ) TO failed-zi_travel_ay_m.

          APPEND VALUE #(
                          %tky = <fs_customer>-%tky
                          %msg = NEW /dmo/cm_flight_messages(
                                                              textid                = /dmo/cm_flight_messages=>customer_unkown
                                                              customer_id           = <fs_customer>-%data-CustomerId
                                                              severity              = if_abap_behv_message=>severity-error
                                                            )
                          %element-customerid = if_abap_behv=>mk-on

                        ) TO reported-zi_travel_ay_m.

        ENDIF.

      ENDLOOP.


    ENDIF.

  ENDMETHOD.

  METHOD validateBookingFee.

    READ ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_travel_ay_m
        FIELDS ( BookingFee )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_result).

    LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<fs_bofee>).

      IF <fs_bofee>-%data-BookingFee IS INITIAL.

        APPEND VALUE #( %key = <fs_bofee>-%key ) TO failed-zi_travel_ay_m.

        APPEND VALUE #(
                        %key = <fs_bofee>-%key
                        %msg = me->new_message(
                                                id       = 'Z_MESSAGES_AY_M'
                                                number   = '001'
                                                severity = if_abap_behv_message=>severity-error
                                               )
                        %element-bookingfee = if_abap_behv=>mk-on
                      ) TO reported-zi_travel_ay_m.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateCurrencyCode.

    READ ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_travel_ay_m
        FIELDS ( CurrencyCode )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_result).

    IF lt_result IS NOT INITIAL.

      SELECT *
       FROM I_Currency
       FOR ALL ENTRIES IN @lt_result
       WHERE Currency = @lt_result-%data-CurrencyCode
       INTO TABLE @DATA(lt_curcode).

      LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<fs_curr>).

        IF <fs_curr>-%data-CurrencyCode IS INITIAL.

          APPEND VALUE #( %key = <fs_curr>-%key ) TO failed-zi_travel_ay_m.

          APPEND VALUE #(
                          %key = <fs_curr>-%key
                          %msg = NEW /dmo/cm_flight_messages(
                                                              textid                = /dmo/cm_flight_messages=>currency_required
                                                              travel_id             = <fs_curr>-%key-TravelId
                                                              severity              = if_abap_behv_message=>severity-error
                                                            )
                          %element-currencycode = if_abap_behv=>mk-on
                        ) TO reported-zi_travel_ay_m.

        ELSEIF NOT line_exists( lt_curcode[ Currency = <fs_curr>-%data-CurrencyCode ] ).

          APPEND VALUE #( %key = <fs_curr>-%key ) TO failed-zi_travel_ay_m.

          APPEND VALUE #(
                          %key = <fs_curr>-%key
                          %msg = NEW /dmo/cm_flight_messages(
                                                              textid                = /dmo/cm_flight_messages=>currency_not_existing
                                                              travel_id             = <fs_curr>-%key-TravelId
                                                              currency_code         = <fs_curr>-%data-CurrencyCode
                                                              severity              = if_abap_behv_message=>severity-error
                                                            )
                          %element-currencycode = if_abap_behv=>mk-on
                        ) TO reported-zi_travel_ay_m.

        ENDIF.

      ENDLOOP.


    ENDIF.

  ENDMETHOD.

  METHOD validateDates.

    READ ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_travel_ay_m
        FIELDS ( BeginDate EndDate )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_result).

    LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<fs_dates>).

      IF <fs_dates>-%data-BeginDate IS INITIAL OR <fs_dates>-%data-EndDate IS INITIAL.

        IF <fs_dates>-%data-BeginDate IS INITIAL.

          APPEND VALUE #( %key = <fs_dates>-%key  ) TO failed-zi_travel_ay_m.

          APPEND VALUE #(
                          %key = <fs_dates>-%key
                          %msg = NEW /dmo/cm_flight_messages(
                                                              textid                = /dmo/cm_flight_messages=>enter_begin_date
                                                              travel_id             = <fs_dates>-%key-TravelId
                                                              begin_date            = <fs_dates>-%data-BeginDate
                                                              severity              = if_abap_behv_message=>severity-error
                                                             )
                          %element-BeginDate = if_abap_behv=>mk-on


                        ) TO reported-zi_travel_ay_m.
        ENDIF.

        IF <fs_dates>-%data-EndDate IS INITIAL.

          APPEND VALUE #( %key = <fs_dates>-%key  ) TO failed-zi_travel_ay_m.

          APPEND VALUE #(
                          %key = <fs_dates>-%key
                          %msg = NEW /dmo/cm_flight_messages(
                                                              textid                = /dmo/cm_flight_messages=>enter_end_date                                                              travel_id             = <fs_dates>-%key-TravelId
                                                              end_date              = <fs_dates>-%data-EndDate
                                                              severity              = if_abap_behv_message=>severity-error
                                                             )

                          %element-EndDate   = if_abap_behv=>mk-on

                        ) TO reported-zi_travel_ay_m.

        ENDIF.

      ELSEIF <fs_dates>-%data-BeginDate > <fs_dates>-%data-EndDate. "End date before begin date

        APPEND VALUE #( %key = <fs_dates>-%key  ) TO failed-zi_travel_ay_m.

        APPEND VALUE #(
                        %key = <fs_dates>-%key
                        %msg = NEW /dmo/cm_flight_messages(
                                                            textid                = /dmo/cm_flight_messages=>begin_date_bef_end_date
                                                            travel_id             = <fs_dates>-%key-TravelId
                                                            begin_date            = <fs_dates>-%data-BeginDate
                                                            end_date              = <fs_dates>-%data-EndDate
                                                            severity              = if_abap_behv_message=>severity-error
                                                           )
                        %element-BeginDate = if_abap_behv=>mk-on
                        %element-EndDate   = if_abap_behv=>mk-on

                      ) TO reported-zi_travel_ay_m.

      ELSEIF <fs_dates>-BeginDate < cl_abap_context_info=>get_system_date( ). "begin date before current date

        APPEND VALUE #( %key = <fs_dates>-%key  ) TO failed-zi_travel_ay_m.

        APPEND VALUE #(
                        %key = <fs_dates>-%key
                        %msg = NEW /dmo/cm_flight_messages(
                                                            textid                = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
                                                            travel_id             = <fs_dates>-%key-TravelId
                                                            begin_date            = <fs_dates>-%data-BeginDate
                                                            severity              = if_abap_behv_message=>severity-error
                                                           )
                        %element-BeginDate = if_abap_behv=>mk-on

                      ) TO reported-zi_travel_ay_m.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateStatus.

    READ ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_travel_ay_m
        FIELDS ( OverallStatus )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_result).

    LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<fs_status>).

      CASE <fs_status>-%data-OverallStatus.
        WHEN 'O' OR 'A' OR 'X'.
        WHEN OTHERS.

          APPEND VALUE #( %key = <fs_status>-%key  ) TO failed-zi_travel_ay_m.

          APPEND VALUE #(
                          %key = <fs_status>-%key
                          %msg = NEW /dmo/cm_flight_messages(
                                                              textid                = /dmo/cm_flight_messages=>status_invalid
                                                              travel_id             = <fs_status>-%key-TravelId
                                                              status                = <fs_status>-%data-OverallStatus
                                                              severity              = if_abap_behv_message=>severity-error
                                                             )
                          %element-OverallStatus = if_abap_behv=>mk-on

                        ) TO reported-zi_travel_ay_m.


      ENDCASE.


    ENDLOOP.

  ENDMETHOD.

  METHOD calculateTotalPrice.

    MODIFY ENTITIES OF zi_travel_ay_m IN LOCAL MODE
        ENTITY zi_travel_ay_m
        EXECUTE reCalTotalPrice
        FROM CORRESPONDING #( keys ).

  ENDMETHOD.

ENDCLASS.
