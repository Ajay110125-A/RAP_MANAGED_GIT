@EndUserText.label: 'Booking Approver Projection View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@UI.headerInfo: {
    typeName: 'Book',
    typeNamePlural: 'Bookings',
    title: {
        type: #STANDARD,
        label: 'Bookings',
        value: 'BookingId'
    }
}
@Search.searchable: true
define view entity zc_booking_approver_ay_m
  as projection on ZI_BOOKING_AY_M
{
      @UI.facet: [{
          id: 'Booking',
          purpose: #STANDARD,
          position: 10,
          label: 'Booking Details',
          type: #IDENTIFICATION_REFERENCE
      }]

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
  key TravelId,

      @UI:{
            lineItem: [{ position: 10, importance: #HIGH }],
            identification: [{ position: 10 }]
          }
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
  key BookingId,

      @UI:{
        lineItem: [{ position: 20, importance: #HIGH }],
        identification: [{ position: 20 }]
      }
      BookingDate,

      @UI:{
        lineItem: [{ position: 30, importance: #HIGH}],
        identification: [{ position: 30 }],
        selectionField: [{ position: 10 }]
      }
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
      @ObjectModel.text.element: [ 'CustomerName' ]
      CustomerId,
      _Customer.FirstName       as CustomerName,


      @UI:{
        lineItem: [{ position: 40, importance: #HIGH}],
        identification: [{ position: 40 }]
      }
      @ObjectModel.text.element: [ 'CarrierName' ]
      CarrierId,
      _Carrier.Name             as CarrierName,


      @UI:{
        lineItem: [{ position: 50, importance: #HIGH }],
        identification: [{ position: 50 }]
      }
      ConnectionId,


      @UI:{
        lineItem: [{ position: 60 }],
        identification: [{ position: 60 }]
      }
      FlightDate,

      @UI:{
        lineItem: [{ position: 70 }],
        identification: [{ position: 70 }]
      }
      @Semantics.amount.currencyCode: 'CurrencyCode'
      FlightPrice,
      CurrencyCode,

      @UI:{
        lineItem: [{ position: 80, importance: #HIGH, label: 'Status' }],
        identification: [{ position: 80, label: 'Status' }],
        textArrangement: #TEXT_ONLY
      }
      @Consumption.valueHelpDefinition: [{ entity: {
                    name: '/DMO/I_Booking_Status_VH',
                    element: 'BookingStatus'}
                    }]
      @ObjectModel.text.element: [ 'BookingStatusText' ]
      BookingStatus,

      @UI.hidden: true
      _BookingStatus._Text.Text as BookingStatusText : localized,

      @UI.hidden: true
      LastChangedAt,

      /* Associations */
      _BookingStatus,
      _BookingSuppl,
      _Carrier,
      _Connection,
      _Customer,
      _Travel : redirected to parent zc_travel_approver_ay_m
}
