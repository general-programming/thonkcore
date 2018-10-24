require "discordcr"
require "json"
require "./springcord/scripting/*"

module Springcord
    def self.main
        engine = Springcord::ScriptingEngine.new

        Springcord.bind_classes(engine)

        ptr = "import \"test\""
        engine.eval(ptr)
    end
end

Springcord.main
