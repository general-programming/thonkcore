@[Link("wren")]
lib Wren
    type WrenVM = Void*
    type WrenHandle = Void*
    alias WrenForeignMethod = ((WrenVM) ->)

    struct WrenForeignClassMethods
        allocate : WrenForeignMethod
        finalize : (Void* ->)
    end

    enum WrenErrorType
        Compile
        Runtime
        StackTrace
    end

    enum WrenInterpretResult
        Success
        CompileError
        RuntimeError
    end

    struct WrenConfiguration
        reallocate_fn : ((Void*, LibC::SizeT) -> Void*)
        # resolve_module_fn : ((WrenVM, UInt8*, UInt8*) -> UInt8*)
        load_module_fn : ((WrenVM, UInt8*) -> UInt8*)
        bind_method_fn : ((WrenVM, UInt8*, UInt8*, Bool, UInt8*) -> WrenForeignMethod)
        bind_class_fn : ((WrenVM, UInt8*, UInt8*) -> WrenForeignClassMethods)
        write_fn : ((WrenVM, UInt8*) ->)
        err_fn : ((WrenVM, WrenErrorType, UInt8*, Int32, UInt8*) ->)
        initial_heap : LibC::SizeT
        min_heap : LibC::SizeT
        heap_growth_percent : Int32
        user_data : Void*
    end

    fun initConfig = wrenInitConfiguration(config : WrenConfiguration*)
    fun newVM = wrenNewVM(config : WrenConfiguration*) : WrenVM
    fun freeVM = wrenFreeVM(vm : WrenVM)
    fun runGC = wrenCollectGarbage(vm : WrenVM)
    fun getUserData = wrenGetUserData(vm : WrenVM) : Void*
    fun setUserData = wrenSetUserData(vm : WrenVM, user_data : Void*)

    fun interpret = wrenInterpret(vm : WrenVM, source : UInt8*) : WrenInterpretResult
    fun makeCallHandle = wrenMakeCallHandle(vm : WrenVM, signature : UInt8*) : WrenHandle
    fun call = wrenCall(vm : WrenVM, method : WrenHandle) : WrenInterpretResult
    fun releaseHandle = wrenReleaseHandle(vm : WrenVM, handle : WrenHandle)

    fun getSlotCount = wrenGetSlotCount(vm : WrenVM) : Int32
    fun ensureSlots = wrenEnsureSlots(vm : WrenVM, slots : Int32)
    fun getSlotHandle = wrenGetSlotHandle(vm : WrenVM, slot : Int32) : WrenHandle
    fun setSlotToHandle = wrenSetSlotHandle(vm : WrenVM, slot : Int32, handle : WrenHandle)

    fun getBool = wrenGetSlotBool(vm : WrenVM, slot : Int32) : Bool
    fun getBytes = wrenGetSlotBytes(vm : WrenVM, slot : Int32, length : Int32*) : UInt8*
    fun getDouble = wrenGetSlotDouble(vm : WrenVM, slot : Int32) : Float64
    fun getForeign = wrenGetSlotForeign(vm : WrenVM, slot : Int32) : Void*
    fun getString = wrenGetSlotString(vm : WrenVM, slot : Int32) : UInt8*
    fun getListLength = wrenGetListCount(vm : WrenVM, slot : Int32) : Int32
    fun getListElement = wrenGetListElement(vm : WrenVM, slot : Int32, index : Int32, new_slot : Int32)
    fun getVariable = wrenGetVariable(vm : WrenVM, module : UInt8*, name : UInt8*, slot : Int32)

    fun setBool = wrenSetSlotBool(vm : WrenVM, slot : Int32, value : Bool)
    fun setBytes = wrenSetSlotBytes(vm : WrenVM, slot : Int32, value : UInt8*, length : LibC::SizeT)
    fun setDouble = wrenSetSlotDouble(vm : WrenVM, slot : Int32, value : Float64)
    fun setString = wrenSetSlotString(vm : WrenVM, slot : Int32, value : UInt8*)
    fun createClass = wrenSetSlotNewForeign(vm : WrenVM, slot : Int32, class_slot : Int32, length : LibC::SizeT) : Void*
    fun createList = wrenSetSlotNewList(vm : WrenVM, slot : Int32)
    fun setNull = wrenSetSlotNull(vm : WrenVM, slot : Int32)
    fun insertIntoList = wrenInsertInList(vm : WrenVM, slot : Int32, index : Int32, from_slot : Int32)

    fun abortFiber = wrenAbortFiber(vm : WrenVM, slot : Int32)
end
