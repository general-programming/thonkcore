require "discordcr"
require "json"
require "./springcord/scripting/*"

module Springcord
    RUN_LOCK = Channel(Nil).new

    def self.main
        engine = Springcord::ScriptingEngine.new

        Springcord.bind_classes(engine)

        ptr = "import \"test\""
        engine.eval(ptr)

        loop do
            RUN_LOCK.receive
        end
    end
end

Springcord.main
