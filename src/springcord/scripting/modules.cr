require "http/server"

module Springcord
    # def self.unbox_foreign(vm : Wren::WrenVM, clazz : T.class) forall T
    #     Wren.getForeign(vm, 0).as(Pointer(Pointer(T))).value.value
    # end

    class HTTPServerStorage
        @handle_method : Wren::WrenHandle?

        def initialize(vm : Wren::WrenVM)
            @class_handle = Wren.getSlotHandle(vm, 0)
            @handle_method = nil
            @method_ref = Wren.makeCallHandle(vm, "call(_,_)")

            @server = HTTP::Server.new do |ctx|
                if @handle_method.is_a?(Nil)
                    next
                end

                # puts @handle_method

                Wren.ensureSlots(vm, 3)
                Wren.setSlotToHandle(vm, 0, @handle_method.not_nil!)
                Wren.setString(vm, 1, ctx.request.method)
                Wren.setString(vm, 2, ctx.request.path)
                Wren.call(vm, @method_ref)

                r_ptr = Wren.getString(vm, 0)
                # puts r_ptr
                if r_ptr.null?
                    next
                end

                response = String.new(r_ptr)
                ctx.response.print(response)
            end
        end

        getter server
        property handle_method
    end

    def self.bind_classes(engine : Springcord::ScriptingEngine)
        engine.bind_class("HTTPServer", HTTPServerStorage) do |binder|
            binder.bind_method "listen(_)" do |vm|
                Wren.ensureSlots(vm, 2)
                storage = Wren.getForeign(vm, 0).as(Pointer(HTTPServerStorage)).value
                port = Wren.getDouble(vm, 1).to_i32

                storage.server.bind_tcp(port)
                puts "Bound to #{port}"

                spawn do
                    storage.server.listen
                end
            end

            binder.bind_method "setHandler(_)" do |vm|
                Wren.ensureSlots(vm, 2)
                storage = Wren.getForeign(vm, 0).as(Pointer(HTTPServerStorage)).value
                handler = Wren.getSlotHandle(vm, 1)

                storage.handle_method = handler
            end

            binder.bind_method "close()" do |vm|
                storage = Wren.getForeign(vm, 0).as(Pointer(HTTPServerStorage)).value

                storage.server.close
            end
        end

        engine.bind_class("Dispatcher", Springcord::EmptyStorage) do |binder|
            binder.bind_method "on(_,_)" do |vm|
                event_name = String.new(Wren.getString(vm, 1))
                callback = Wren.getSlotHandle(vm, 2)

                Springcord::EVENT_BUS.add_script_handler(event_name) do |args|
                    Wren.ensureSlots(vm, args.size + 1)
                    Wren.setSlotToHandle(vm, 0, callback)

                    args.each_with_index { |v, i|
                        if v.is_a?(Bool)
                            Wren.setBool(vm, i + 1, v)
                        elsif v.is_a?(String)
                            Wren.setString(vm, i + 1, v)
                        elsif v.is_a?(Bytes)
                            Wren.setBytes(vm, i + 1, v.to_unsafe, v.bytesize)
                        elsif v.responds_to?(:to_f64)
                            Wren.setDouble(vm, i + 1, v.to_f64)
                        else
                            raise "Cannot send type #{v.class} to Wren!"
                        end
                    }

                    sig_args = args.join(",") { |v| "_" }
                    call_handle = Wren.makeCallHandle(vm, "call(#{sig_args})")

                    Wren.call(vm, call_handle)
                end
            end
        end
    end
end
