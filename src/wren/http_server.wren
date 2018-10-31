foreign class HttpContext {
    construct new() {}

    foreign method
    foreign path
    foreign body
    foreign getHeader(name)

    foreign setStatus(statusCode)
    foreign write(response)
}
