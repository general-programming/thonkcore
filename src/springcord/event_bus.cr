module Springcord
    alias WrenTypes = Bool | Float64 | String | Bytes
    alias EventBusCollection = Tuple(WrenTypes)
    alias EventBusHandlers = Array(Proc(EventBusCollection, Nil))

    class EventBus
        def initialize()
            @handlers = {} of String => EventBusHandlers
        end

        def add_script_handler(event_name : String, &handler : (EventBusCollection) ->)
            unless @handlers.has_key?(event_name)
                @handlers[event_name] = EventBusHandlers.new
            end

            @handlers[event_name] << handler
        end

        def dispatch(event : String, *args : WrenTypes)
            if hdlrs = @handlers[event]
                hdlrs.each { |h| h.call(args.as(EventBusCollection)) }
            end
        end
    end

    EVENT_BUS = EventBus.new
end
