require "discordcr"
require "json"
require "./springcord/*"
require "./springcord/scripting/*"

module Springcord
    RUN_LOCK = Channel(Nil).new

    def self.main
        engine = Springcord::ScriptingEngine.new

        Springcord.bind_classes(engine)

        ptr = "import \"test\""
        engine.eval(ptr)

        Springcord::EVENT_BUS.dispatch("hello", "Henry", "welcome to wren")

        RUN_LOCK.receive
    end
end

Springcord.main
