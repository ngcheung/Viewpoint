module Viewpoint::EWS::Types
  class CalendarFolder
    include Viewpoint::EWS
    include Viewpoint::EWS::Types
    include Viewpoint::EWS::Types::GenericFolder

    # Fetch items between a given time period
    # @param [DateTime] start_date the time to start fetching Items from
    # @param [DateTime] end_date the time to stop fetching Items from
    def items_between(start_date, end_date)
      items do |obj|
        obj.restriction = { and: [
          comparison_clause('is_greater_than_or_equal_to', 'calendar:Start', start_date),
          comparison_clause('is_less_than_or_equal_to', 'calendar:Start', end_date)
        ] }
      end
    end

    #not sure if it's possible to search by location or recurrence
    def search_for_event(subject, start_date, end_date, location)
      items do |query|
        query.restriction =
          { and: [
            comparison_clause('is_equal_to', 'item:Subject', subject),
            comparison_clause('is_greater_than_or_equal_to', 'calendar:Start', start_date - 1.minute),
            comparison_clause('is_less_than_or_equal_to', 'calendar:Start', end_date + 1.minute),
            comparison_clause('is_equal_to', 'calendar:Location', location)
          ] }
      end
    end

    def comparison_clause(operator, field, value)
      {
        "#{operator}": [
          { field_uRI: { field_uRI: field } },
          { field_uRI_or_constant: { constant: { value: value } } }
        ]
      }
    end

    # Creates a new appointment
    # @param attributes [Hash] Parameters of the calendar item. Some example attributes are listed below.
    # @option attributes :subject [String]
    # @option attributes :start [Time]
    # @option attributes :end [Time]
    # @return [CalendarItem]
    # @see Template::CalendarItem
    def create_item(attributes, to_ews_create_opts = {})
      template = Viewpoint::EWS::Template::CalendarItem.new attributes
      template.saved_item_folder_id = {id: self.id, change_key: self.change_key}
      rm = ews.create_item(template.to_ews_create(to_ews_create_opts)).response_messages.first
      if rm && rm.success?
        CalendarItem.new ews, rm.items.first[:calendar_item][:elems].first
      else
        raise EwsCreateItemError, "Could not create item in folder. #{rm.code}: #{rm.message_text}" unless rm
      end
    end

  end
end
