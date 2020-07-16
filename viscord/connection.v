module viscord
import net.websocket
import eventbus
import time

pub struct Connection {
	gateway				string
pub:
	token				string
	events				&eventbus.EventBus
	op_events			&eventbus.EventBus
mut:
	ws					&websocket.Client
	session_id			string
	sequence			int
	heartbeat_interval	int
	last_heartbeat		int
}

pub struct ConnectionConfig {
	gateway string
	token	string
}

pub fn new_connection(c ConnectionConfig) &Connection {
	mut d := &Connection {
		gateway: c.gateway,
		token: c.token,
		ws: &websocket.new(c.gateway)
		events: eventbus.new()
		op_events: eventbus.new()
	}

	d.ws.subscriber.subscribe_method('on_open', on_open, d)
	d.ws.subscriber.subscribe_method('on_message', on_message, d)
	d.ws.subscriber.subscribe_method('on_error', on_error, d)
	d.ws.subscriber.subscribe_method('on_close', on_close, d)

	d.op_events.subscriber.subscribe_method('on_hello', on_hello, d)
	d.op_events.subscriber.subscribe_method('on_dispatch', on_dispatch, d)

	d.events.subscriber.subscribe_method('on_ready', on_ready, d)

	return d
}

pub fn (d mut Connection) connect () {
	mut ws := d.ws
	ws.connect()
	go ws.listen()
	for true {
		sleep(1)
		if time.now().unix - d.last_heartbeat > d.heartbeat_interval {
			heartbeat := HeartbeatPacket {
				op: Op.heartbeat,
				d: d.sequence
			}.encode()
			println("HEARTBEAT $heartbeat")
			d.ws.write(heartbeat.str, heartbeat.len, .text_frame)
			d.last_heartbeat = time.now().unix
		}
	}
}

pub fn (d mut Connection) subscribe(name string, handler eventbus.EventHandlerFn) {
	d.events.subscriber.subscribe(name, handler)
}

pub fn (d mut Connection) subscribe_method(name string, handler eventbus.EventHandlerFn, receiver voidptr) {
	d.events.subscriber.subscribe_method(name, handler, receiver)
}

fn on_open(d mut Connection, ws websocket.Client, _ voidptr) {
	println('websocket opened.')
}

fn on_message(d mut Connection, ws websocket.Client, msg &websocket.Message) {
	match msg.opcode {
		.text_frame {
			packet := decode_packet(string(byteptr(msg.payload))) or {
				println(err)
				return
			}
			d.sequence = packet.sequence
			match Op(packet.op) {
				.dispatch { d.op_events.publish('on_dispatch', &ws, &packet) }
				.hello { d.op_events.publish('on_hello', &ws, &packet) }
				else {}
			}
		}
		else {
			println("unhandled opcode")
		}
	}
}

fn on_dispatch(d mut Connection, ws websocket.Client, packet &DiscordPacket) {
	event := packet.event.to_lower()
	d.events.publish('on_$event', d, packet)
}

fn on_hello(d mut Connection, ws websocket.Client, packet &DiscordPacket) {
	hello_data := decode_hello_packet(packet.d) or {
		println(err)
		return
	}
	d.heartbeat_interval = hello_data.heartbeat_interval/1000
	d.last_heartbeat = time.now().unix
	identify_packet := IdentifyPacket{
		token: d.token,
		properties: IdentifyPacketProperties{
			os: 'linux',
			browser: 'viscord',
			device: 'viscord'
		},
		shard: [0,1],
		guild_subscriptions: true
	}
	encoded := identify_packet.encode()
	//println(encoded)
	d.ws.write(encoded.str, encoded.len, .text_frame)
	
}

fn on_ready(d mut Connection, ws websocket.Client, packet &DiscordPacket) {
	ready_packet := decode_ready_packet(packet.d) or { return }
	d.session_id = ready_packet.session_id
}

fn on_close(d mut Connection, ws websocket.Client, _ voidptr) {
	println('websocket closed.')
}

fn on_error(d mut Connection, ws websocket.Client, err string) {
	println('we have an error.')
	println(err)
}
