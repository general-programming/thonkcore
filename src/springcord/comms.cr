module Springcord
    class CommunicationManager
        def initialize(@config : Springcord::Config)
            @clients = [] of AbstractRemoteClient
        end

        getter clients, config

        def add_client(client : AbstractRemoteClient)
            @clients << client
        end
    end

    abstract class AbstractRemoteClient
        abstract def dispatch_event(event_name : String, **params)
        abstract def dispatch_response(response : ResponsePacketWrapper(T)) forall T
        abstract def on_command(command_name : String, &block : (Array(JSON::Any)) ->)
    end

    class ResponsePacketWrapper(T)
        @type : String
        @event_name : String?
        @data : T

        def initialize(@type, @event_name, @data)
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

    class WebsocketRemoteClient < AbstractRemoteClient
        def initialize(@socket : HTTP::WebSocket)
            @handlers = {} of String => Array(Proc(Array(JSON::Any), Nil))

            @socket.on_message do |msg|
                data = JSON.parse(msg)

                cmd = data["cmd"].as_s
                args = data["args"].as_a

                if @handlers.has_key?(cmd)
                    @handlers[cmd].each { |h| h.call(args) }
                end
            end
        end

        def dispatch_event(event_name : String, **params)
            msg = {t: "event", e: event_name, d: params}.to_json

            @socket.send(msg)
        end

        def dispatch_response(packet : ResponsePacketWrapper(T)) forall T
            @socket.send(packet.to_json)
        end

        def on_command(command_name : String, &block : (Array(JSON::Any)) ->)
            unless @handlers.has_key?(command_name)
                @handlers[command_name] = [] of typeof(block)
            end

            @handlers[command_name] << block
        end
    end
end
