module Springcord
    class ThonkServer < Springcord::Runnable
        def initialize(@manager : Springcord::CommunicationManager)
            @server = HTTP::Server.new([
                HTTP::WebSocketHandler.new(->self.handle_socket(HTTP::WebSocket, HTTP::Server::Context)),
                Springcord::ThonkServerHandler.new
            ])

            @server.bind_tcp(manager.config.http_port)
        end

        def handle_socket(socket : HTTP::WebSocket, ctx : HTTP::Server::Context)
            client = Springcord::WebsocketRemoteClient.new(socket)

            @manager.add_client client
        end

        def start
            @server.listen
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
