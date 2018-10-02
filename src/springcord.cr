require "discordcr"
require "json"
require "./springcord/scripting/*"

module Springcord
    def self.main
        engine = Springcord::ScriptingEngine.new

        ptr = "System.print(\"hi\")"
        engine.eval(ptr)
    end
end

Springcord.main
