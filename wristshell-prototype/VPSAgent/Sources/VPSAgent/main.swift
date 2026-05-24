import Foundation
import NIO
import NIOHTTP1

// Minimal HTTP/1.1 server scaffold. In a real build:
//   - Bind only to the Tailscale tailnet IP (e.g. fd7a:115c:a1e0::1) by default.
//   - Optional second listener on a public TCP port doing mTLS, for the
//     opt-in "standalone watch" mode.
//   - Decode PlannedCommand JSON, validate against the local AllowlistRegistry
//     (a copy of the one shipped in WristShellCore — keep them in sync).
//   - Execute via Process with a tight env, capped wall-clock + memory.

// This file is a stub — it stands up the listener and 200s every request
// so the wire is testable from the iOS side. Wiring real allowlist execution
// is the next step.

struct AgentConfig {
    var bindHost: String
    var bindPort: Int

    static func fromEnv() -> AgentConfig {
        AgentConfig(
            bindHost: ProcessInfo.processInfo.environment["VPS_AGENT_HOST"] ?? "127.0.0.1",
            bindPort: Int(ProcessInfo.processInfo.environment["VPS_AGENT_PORT"] ?? "8443") ?? 8443
        )
    }
}

final class StubHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = unwrapInboundIn(data)
        if case .end = part {
            let body = #"{"stdout":"agent stub: not implemented","stderr":"","exit_code":0,"duration_ms":0}"#
            var headers = HTTPHeaders()
            headers.add(name: "Content-Type", value: "application/json")
            headers.add(name: "Content-Length", value: String(body.utf8.count))
            let head = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .ok, headers: headers)
            context.write(wrapOutboundOut(.head(head)), promise: nil)
            var buf = context.channel.allocator.buffer(capacity: body.utf8.count)
            buf.writeString(body)
            context.write(wrapOutboundOut(.body(.byteBuffer(buf))), promise: nil)
            context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
        }
    }
}

let config = AgentConfig.fromEnv()
let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
defer { try? group.syncShutdownGracefully() }

let bootstrap = ServerBootstrap(group: group)
    .serverChannelOption(ChannelOptions.backlog, value: 16)
    .childChannelInitializer { channel in
        channel.pipeline.configureHTTPServerPipeline().flatMap {
            channel.pipeline.addHandler(StubHandler())
        }
    }

let channel = try bootstrap.bind(host: config.bindHost, port: config.bindPort).wait()
FileHandle.standardError.write(Data("vps-agent listening on \(config.bindHost):\(config.bindPort) (stub)\n".utf8))
try channel.closeFuture.wait()
