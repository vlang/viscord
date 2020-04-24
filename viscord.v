module main
import viscord

fn main () {
	mut d := viscord.new_connection(viscord.ConnectionConfig{
		gateway: 'wss://gateway.discord.gg:443/?encoding=json&v=6',
		token: ''
	})

	d.subscribe('on_ready', on_ready)
	d.subscribe('on_message_create', on_message_create)
	d.connect()
}

fn on_ready(c &viscord.Connection, packet &viscord.DiscordPacket) {
	println("Bot is ready.")
}

fn on_message_create(c &viscord.Connection, packet &viscord.DiscordPacket) {
	message_packet := viscord.decode_message_packet(packet.d) or {
		println('failed to parse message')
		return
	}
	if message_packet.content.starts_with('viscord') {
		println(message_packet.channel_id)
		res := c.send_message(message_packet.channel_id, viscord.RestMessage{
			content: "Yup, thats me!"
		}) or {
			println("Failed to send message")
			return
		}
		println(res.text)
	}
}
