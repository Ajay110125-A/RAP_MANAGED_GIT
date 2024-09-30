@EndUserText.label: 'Projection View of Booking View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity zc_booking_ay_m
  //provider contract transactional_query //No need of contract because Root View is contract is inherited in child view
  as projection on ZI_BOOKING_AY_M
{
  key TravelId,
  key BookingId,
      BookingDate,
      @ObjectModel.text.element: [ 'CustomerName' ]
      CustomerId,
      _Customer.LastName        as CustomerName,
      @ObjectModel.text.element: [ 'CarrierName' ]
      CarrierId,
      _Carrier.Name             as CarrierName,
      ConnectionId,
      FlightDate,
      FlightPrice,
      CurrencyCode,
      @ObjectModel.text.element: [ 'BookingStatusText' ]
      BookingStatus,
      _BookingStatus._Text.Text as BookingStatusText : localized,
      LastChangedAt,
      /* Associations */
      _BookingSuppl : redirected to composition child ZC_BOOKSUPP_AY_M,
      _Carrier,
      _Connection,
      _Customer,
      _BookingStatus,
      _Travel       : redirected to parent zc_travel_ay_m
}
