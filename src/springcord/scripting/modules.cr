require "http/server"

module Springcord
    class HTTPServerStorage
        def initialize(vm : Wren::WrenVM)
            @class_handle = Wren.getSlotHandle(vm, 0)
            @handle_method = Wren.makeCallHandle(vm, "handle(_, _)")

            @server = HTTP::Server.new do |ctx|
                Wren.ensureSlots(vm, 3)
                Wren.setSlotToHandle(vm, 0, @class_handle)
                Wren.setString(vm, 1, ctx.request.method)
                Wren.setString(vm, 2, ctx.request.path)
                Wren.call(vm, @handle_method)
            end
        end

        getter server
    end

    def self.bind_classes(engine : Springcord::ScriptingEngine)
        engine.bind_class("HTTPServer", HTTPServerStorage) do |binder|
            binder.bind_method "listen(_)" do |vm|
                Wren.ensureSlots(vm, 2)
                storage = Wren.getForeign(vm, 0).as(HTTPServerStorage)
                port = Wren.getDouble(vm, 1).to_i32

                storage.server.listen(port)
            end

            binder.bind_method "close()" do |vm|
                storage = Wren.getForeign(vm, 0).as(HTTPServerStorage)

                storage.server.close
            end
        end
    end
end
