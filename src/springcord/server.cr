module Springcord
    class ThonkServer < Springcord::Runnable
        # @server : HTTP::Server

        def initialize(@manager : Springcord::CommunicationManager, *extra_handlers : HTTP::Handler)
            @server = HTTP::Server.new([
                HTTP::WebSocketHandler.new(&->handle_socket(HTTP::WebSocket, HTTP::Server::Context)),
                Springcord::ThonkServerHandler.new
            ] + extra_handlers.to_a)

            @server.bind_tcp(manager.config.http_port)
        end

        def handle_socket(socket : HTTP::WebSocket, ctx : HTTP::Server::Context)
            client = Springcord::WebsocketRemoteClient.new(socket)

            @manager.add_client client
            nil
        end

        def start
            @server.listen
        end
    end

    class WrenHttpHandler
        include HTTP::Handler

        def initialize(@engine : Springcord::ScriptingEngine)
            Wren.ensureSlots(@engine.vm, 1)
            Wren.getVariable(@engine.vm, "main", "HttpContext", 0)

            @ctx_class_handle = Wren.getSlotHandle(@engine.vm, 0)
        end

        def finalize
            Wren.releaseHandle(@engine.vm, @ctx_class_handle)
        end

        def call(ctx : HTTP::Server::Context)
            vm = @engine.vm

            Wren.ensureSlots(vm, 2)
            Wren.setSlotToHandle(vm, 1, @ctx_class_handle)

            ptr = Wren.createClass(vm, 0, 1, instance_sizeof(HTTP::Server::Context)).as Pointer(HTTP::Server::Context)
            ptr.value = ctx

            ctx_handle = Wren.getSlotHandle(vm, 0)
            Springcord::EVENT_BUS.dispatch("http_request", ctx_handle)
            Wren.releaseHandle(vm, ctx_handle)

            unless ctx.response.closed?
                ctx.response.close
            end
        end
    end

    class ThonkServerHandler
        include HTTP::Handler

        def call(ctx : HTTP::Server::Context)
            ctx.response.print "ThonkCore v0.1.0"
            ctx.response.close
        end
    end
end
