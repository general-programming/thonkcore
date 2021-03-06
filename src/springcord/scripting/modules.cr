require "http/server"

module Springcord
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
        engine.bind_class("HttpContext", HTTP::Server::Context) do |binder|
            binder.bind_method "method" do |vm|
                ctx = Wren.getForeign(vm, 0).as(Pointer(HTTP::Server::Context)).value

                Wren.setString(vm, 0, ctx.request.method)
            end

            binder.bind_method "path" do |vm|
                ctx = Wren.getForeign(vm, 0).as(Pointer(HTTP::Server::Context)).value

                Wren.setString(vm, 0, ctx.request.path)
            end

            binder.bind_method "body" do |vm|
                ctx = Wren.getForeign(vm, 0).as(Pointer(HTTP::Server::Context)).value

                if body = ctx.request.body
                    Wren.setString(vm, 0, body.gets_to_end)
                else
                    Wren.setNull(vm, 0)
                end
            end

            binder.bind_method "getHeader(_)" do |vm|
                ctx = Wren.getForeign(vm, 0).as(Pointer(HTTP::Server::Context)).value
                name = String.new Wren.getString(vm, 1)

                if val = ctx.request.headers[name]?
                    Wren.setString(vm, 0, val)
                else
                    Wren.setNull(vm, 0)
                end
            end

            binder.bind_method "setStatus(_)" do |vm|
                ctx = Wren.getForeign(vm, 0).as(Pointer(HTTP::Server::Context)).value
                code = Wren.getDouble(vm, 1).to_i32

                ctx.response.status_code = code
            end

            binder.bind_method "write(_)" do |vm|
                ctx = Wren.getForeign(vm, 0).as(Pointer(HTTP::Server::Context)).value
                text = String.new Wren.getString(vm, 1)

                ctx.response.print text
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
                        elsif v.is_a?(Wren::WrenHandle)
                            Wren.setSlotToHandle(vm, i + 1, v)
                        elsif v.responds_to?(:to_f64)
                            Wren.setDouble(vm, i + 1, v.to_f64)
                        else
                            raise "Cannot send type #{v.class} to Wren!"
                        end
                    }

                    sig_args = args.join(",") { |v| "_" }
                    call_handle = Wren.makeCallHandle(vm, "call(#{sig_args})")

                    Wren.call(vm, call_handle)

                    Wren.releaseHandle(vm, call_handle)
                end
            end
        end
    end
end
