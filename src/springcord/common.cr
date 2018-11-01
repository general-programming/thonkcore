module Springcord
    abstract class Runnable
        abstract def start
    end

    class TaskManager
        def initialize
            @workers = [] of Springcord::Runnable
        end

        def <<(worker : Springcord::Runnable)
            @workers << worker
        end

        def start
            @workers.each do |task|
                spawn do
                    task.start
                end
            end
        end
    end
end
