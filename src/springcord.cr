require "discordcr"
require "json"
require "./springcord/*"
require "./springcord/scripting/*"

module Springcord
    RUN_LOCK = Channel(Nil).new

    def self.main
        config = Springcord::Config.new
        taskmgr = Springcord::TaskManager.new
        comms = Springcord::CommunicationManager.new(config)
        engine = Springcord::ScriptingEngine.new

        taskmgr << Springcord::ThonkServer.new(comms, Springcord::WrenHttpHandler.new(engine))

        Springcord.bind_classes(engine)

        ptr = "import \"test\""
        engine.eval(ptr)

        Springcord::EVENT_BUS.dispatch("hello", "Henry", "welcome to wren")

        RUN_LOCK.receive
    end

    macro read_bundled(filename)
        {{ run("./read", filename).stringify }}
    end
end

Springcord.main
