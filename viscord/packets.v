module viscord
import json
import discord

enum Op {
	dispatch
	heartbeat
	identify
	presence_update
	voice_state_update
	five_undocumented
	resume
	reconnect
	request_guild_members
	invalid_session
	hello
	heartbeat_ack
}

pub struct DiscordPacket {
pub:
	op 			int
	sequence	int		[json:s]
	event		string	[json:t]
	d			string	[raw]
}

struct HelloPacket {
	heartbeat_interval int
}
pub fn decode_hello_packet(s string) ?HelloPacket {
	packet := json.decode(HelloPacket, s) or { return error(err) }
	return packet
}

struct IdentifyPacketProperties {
	os		string [json:"\$os"]
	browser string [json:"\$browser"]
	device	string [json:"\$device"]
}
struct IdentifyPacket {
	token 				string
	properties 			IdentifyPacketProperties
	compress			bool = false
	large_threshold		int = 250
	shard				[]int = [0, 1]
	presence			?discord.Status
	guild_subscriptions	bool = true
}
struct OutboundIdentifyPacket {
	op 	int
	d	IdentifyPacket
}
pub fn (p IdentifyPacket) encode() string {
	return json.encode(OutboundIdentifyPacket {
		op: int(Op.identify),
		d: p
	})
}

struct ReadyPacket {
	v					int
	private_channels	[]string
	guilds				[]discord.UnavailableGuild
	session_id			string
	shard				[]int
}
pub fn decode_ready_packet(s string) ?ReadyPacket {
	packet := json.decode(ReadyPacket, s) or { return error(err) }
	return packet
}

struct HeartbeatPacket {
	op 	int
	d	int
}
pub fn (p HeartbeatPacket) encode() string {
	return json.encode(p)
}

pub fn decode_message_packet(s string) ?discord.Message {
	packet := json.decode(discord.Message, s) or { return error(err) }
	return packet
}

pub fn decode_packet(s string) ?DiscordPacket {
	packet := json.decode(DiscordPacket, s) or { return error(err) }
	return packet
}
