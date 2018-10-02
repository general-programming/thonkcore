module Springcord
    class ScriptCompileError < Exception
    end

    class ScriptRuntimeError < Exception
    end

    class ScriptingEngine
        def initialize
            @config = Wren::WrenConfiguration.new
            Wren.initConfig(pointerof(@config))

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

            @vm = Wren.newVM(pointerof(@config))
        end

        def finalize
            Wren.freeVM(@vm)
        end

        def eval(code : String)
            len = code.bytesize
            term = Bytes.new(len + 1)
            code.to_slice.copy_to(term)
            term[len] = 0_u8

            result = Wren.interpret(@vm, term)

            case result
            when Wren::WrenInterpretResult::CompileError
                raise ScriptCompileError.new("Failed to compile Wren snippet")
            when Wren::WrenInterpretResult::RuntimeError
                raise ScriptRuntimeError.new("Snippet failed to evaluate")
            end
        end
    end
end
