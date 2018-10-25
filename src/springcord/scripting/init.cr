module Springcord
    class ScriptError < Exception
    end

    class ScriptCompileError < ScriptError
    end

    class ScriptRuntimeError < ScriptError
    end

    class EmptyStorage
        def initialize(vm : Wren::WrenVM)
        end
    end

    class EngineStorage
        def initialize
            @modules = {} of String => String
            @classes = {} of String => BoundForeignClass
        end

        getter modules, classes
    end

    class BoundForeignClass
        def initialize(@class_name : String, clazz : T.class, @methods : Hash(String, Wren::WrenForeignMethod)) forall T
            @class_callbacks = Wren::WrenForeignClassMethods.new

            @class_callbacks.allocate = ->(vm : Wren::WrenVM) {
                wren_ptr = Wren.createClass(vm, 0, 0, instance_sizeof(T)).as Pointer(T)
                inst = T.new(vm)

                wren_ptr.value = inst
                nil
            }
        end

        getter class_name, methods, class_callbacks
    end

    class ForeignClassBinder
        def initialize(@class_name : String)
            @methods = {} of String => Wren::WrenForeignMethod
        end

        getter methods

        def bind_method(signature : String, &block : (Wren::WrenVM) ->)
            @methods[signature] = block
        end
    end

    class ScriptingEngine
        def initialize
            @config = Wren::WrenConfiguration.new
            @storage = EngineStorage.new

            Wren.initConfig(pointerof(@config))

            @config.user_data = Box.box(@storage)
            @config.reallocate_fn  = ->(mem : Pointer(Void), size : LibC::SizeT) {
                if mem.null? && size > 0
                    return GC.malloc(size)
                end

                if size == 0
                    GC.free(mem)
                    return Pointer(Void).null
                end

                return GC.realloc(mem, size)
            }

            @config.write_fn = ->(vm : Wren::WrenVM, text : Pointer(UInt8)) {
                unless text.null?
                    print String.new(text)
                end
            }

            @config.err_fn = ->(vm : Wren::WrenVM, err : Wren::WrenErrorType, mod : Pointer(UInt8), line : Int32, message_n : Pointer(UInt8)) {
                message = String.new(message_n)

                case err
                when Wren::WrenErrorType::Compile
                    module_name = String.new(mod)
                    puts "Compile error: #{message} at #{module_name}:#{line}"
                when Wren::WrenErrorType::Runtime
                    puts "Runtime error: #{message}"
                when Wren::WrenErrorType::StackTrace
                    module_name = String.new(mod)
                    puts "\t #{module_name}:#{line}  #{message}"
                end
            }

            @config.load_module_fn = ->(vm : Wren::WrenVM, name_ptr : Pointer(UInt8)) {
                storage = Box(EngineStorage).unbox(Wren.getUserData(vm))
                name = String.new(name_ptr)

                if storage.modules.has_key?(name)
                    return storage.modules[name].to_unsafe
                end

                module_path = File.expand_path(name)
                if File.file?("#{module_path}.wren")
                    return File.read("#{module_path}.wren").to_unsafe
                end

                if Dir.exists?(module_path)
                    init_file = File.join(module_path, "init.wren")
                    if File.file?(init_file)
                        return File.read(init_file).to_unsafe
                    end

                    init_file = File.join(module_path, "#{name}.wren")
                    if File.file?(init_file)
                        return File.read(init_file).to_unsafe
                    end
                end

                return Pointer(UInt8).null
            }

            @config.bind_class_fn = ->(vm : Wren::WrenVM, module_name_ptr : Pointer(UInt8), class_name_ptr : Pointer(UInt8)) {
                storage = Box(EngineStorage).unbox(Wren.getUserData(vm))
                module_name = String.new(module_name_ptr)
                class_name = String.new(class_name_ptr)

                if storage.classes.has_key?(class_name)
                    storage.classes[class_name].class_callbacks
                else
                    Wren::WrenForeignClassMethods.new
                end
            }

            @config.bind_method_fn = ->(vm : Wren::WrenVM, module_name_ptr : Pointer(UInt8), class_name_ptr : Pointer(UInt8), is_static : Bool, signature_ptr : Pointer(UInt8)) {
                storage = Box(EngineStorage).unbox(Wren.getUserData(vm))
                module_name = String.new(module_name_ptr)
                class_name = String.new(class_name_ptr)
                signature = String.new(signature_ptr)

                if storage.classes.has_key?(class_name)
                    storage.classes[class_name].methods[signature]
                else
                    Wren::WrenForeignMethod.new(Pointer(Void).null, Pointer(Void).null)
                end
            }

            @vm = Wren.newVM(pointerof(@config))
        end

        def finalize
            Wren.freeVM(vm)
        end

        def vm
            @vm.not_nil!
        end

        def bind_class(name : String, storage_class : T.class, &block : (ForeignClassBinder) ->) forall T
            binder = ForeignClassBinder.new(name)
            block.call(binder)

            bound = BoundForeignClass.new(name, storage_class, binder.methods)
            @storage.classes[name] = bound
        end

        def eval(code : String)
            len = code.bytesize
            term = Bytes.new(len + 1)
            code.to_slice.copy_to(term)
            term[len] = 0_u8

            result = Wren.interpret(vm, term)

            case result
            when Wren::WrenInterpretResult::CompileError
                raise ScriptCompileError.new("Failed to compile Wren snippet")
            when Wren::WrenInterpretResult::RuntimeError
                raise ScriptRuntimeError.new("Snippet failed to evaluate")
            end
        end

        def eval_file(filename : String)
            path = File.expand_path(filename)
            contents = File.read(path)

            self.eval(contents)
        end
    end
end
