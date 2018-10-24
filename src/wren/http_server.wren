foreign class HTTPServer {
    construct new() {}

    foreign listen(port)

    handle(method, path) {
        System.print("%(System.clock) %(method) %(path)")
    }
}
