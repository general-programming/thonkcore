module Springcord
    class CommunicationManager
        def initialize
            @clients = [] of AbstractRemoteClient
        end
    end

    abstract class AbstractRemoteClient
        abstract def dispatch_event(event_name : String, **params)
        abstract def on_command(command_name : String, &block)
    end

    class ResponsePacketWrapper(T)
        @type : String
        @event_name : String?
        @data : T

        def initialize(@type, @data)

        end

        def to_json(builder : JSON::Builder)
            builder.object do
                builder.field "t", @type
                if ev = @event_name
                    builder.field "e", ev
                end
                builder.field "d", @data
            end
        end
    end
end
