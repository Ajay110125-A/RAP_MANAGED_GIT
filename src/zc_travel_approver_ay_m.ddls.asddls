@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel Approver Projection View'
@UI.headerInfo: {
    typeName: 'Travel',
    typeNamePlural: 'Travels',
    title: {
        type: #STANDARD,
        label: 'Travel',
        value: 'TravelId'
    }
}
@Search.searchable: true
define root view entity zc_travel_approver_ay_m
  provider contract transactional_query
  as projection on ZI_TRAVEL_AY_M
{
      @UI.facet: [{
          id: 'Travel',
          purpose: #STANDARD,
          position: 10,
          label: 'Travel Details',
          type: #IDENTIFICATION_REFERENCE
      },
      {
          id: 'Booking',
          purpose: #STANDARD,
          position: 20,
          label: 'Bookings',
          type: #LINEITEM_REFERENCE,
          targetElement: '_Booking'
      }
      ]

      @UI: {
                lineItem: [
                            { position: 10, importance: #HIGH }
                          ],
                identification: [{ position: 10 }]
           }
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
  key TravelId,
      @UI: {
         selectionField: [{ position: 20 }],
         lineItem: [{ position: 20, importance: #HIGH }],
         identification: [{ position: 20 }]
       }
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
      @Consumption.valueHelpDefinition: [{ entity: {
          name: '/DMO/I_Agency',
          element: 'AgencyID'
      } }]
      @ObjectModel.text.element: [ 'AgencyName' ]
      AgencyId,
      _Agency.Name        as AgencyName,
      @UI: {
         selectionField: [{ position: 30 }],
         lineItem: [{ position: 30, importance: #HIGH }],
         identification: [{ position: 30 }]
      }
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
      @Consumption.valueHelpDefinition: [{ entity: {
          name: '/DMO/I_Customer',
          element: 'CustomerID'
      } }]
      @ObjectModel.text.element: [ 'CustomerName' ]
      CustomerId,
      _Customer.FirstName as CustomerName,
      @UI: {
        lineItem: [{ position: 40 }],
        identification: [{ position: 40 }]
      }
      BeginDate,
      @UI: {
      lineItem: [{ position: 50 }],
      identification: [{ position: 50 }]
      }
      EndDate,
      @UI: {
      lineItem: [{ position: 51, importance: #MEDIUM }],
      identification: [{ position: 55 }]
      }
      @Semantics.amount.currencyCode: 'CurrencyCode'
      BookingFee,
      @UI: {
      lineItem: [{ position: 60, importance: #MEDIUM }],
      identification: [{ position: 60, label: 'Total Price' }]
      }
      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalPrice,
      @Consumption.valueHelpDefinition: [{ entity: {
      name: 'I_Currency',
      element: 'Currency'
      } }]
      CurrencyCode,
      @UI: {
      lineItem: [{ position: 65, importance: #MEDIUM }],
      identification: [{ position: 65 }]
      }
      Description,
      @UI: {
             selectionField: [{ position: 70 }],
             lineItem: [
                        { position: 15, importance: #HIGH },
                        { type: #FOR_ACTION, dataAction: 'acceptTravel', label: 'Accept' },
                        { type: #FOR_ACTION, dataAction: 'rejectTravel', label: 'Reject'}
                       ],
             identification: [
                                { position: 15 },
                                { type: #FOR_ACTION, dataAction: 'acceptTravel', label: 'Accept' },
                                { type: #FOR_ACTION, dataAction: 'rejectTravel', label: 'Reject'}
                             ],
             textArrangement: #TEXT_ONLY

           }
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
      @Consumption.valueHelpDefinition: [{ entity: {
          name: '/DMO/I_Overall_Status_VH',
          element: 'OverallStatus'
      } }]
      @ObjectModel.text.element: [ 'OverallStatusText' ]
      OverallStatus,
      @UI.hidden: true
      _Status._Text.Text  as OverallStatusText : localized,
      @UI.hidden: true
      CreatedBy,
      @UI.hidden: true
      CreatedAt,
      @UI.hidden: true
      LastChangedBy,
      @UI.hidden: true
      LastChangedAt,
      @UI.hidden: true
      /* Associations */
      _Agency,
      _Booking : redirected to composition child zc_booking_approver_ay_m,
      _Currency,
      _Customer,
      _Status
}
