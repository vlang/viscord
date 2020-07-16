module main
import discord
import viscord
import json

struct App {
	timestamps map[string][]int
	mutestamps map[string][]int
	mutes map[string]bool
	owners []string
	c &viscord.Connection
}

fn main () {
	mut c := viscord.new_connection(viscord.ConnectionConfig{
		gateway: 'wss://gateway.discord.gg:443/?encoding=json&v=6',
		token: ''
	})

	mut app := App{
		c: c,
		owners: ["215143736114544640"]
	}

	c.subscribe('on_ready', on_ready)
	c.subscribe_method('on_message_create', on_message_create, app)
	c.connect()
}

fn on_ready(c &viscord.Connection, packet &viscord.DiscordPacket) {
	println("Bot is ready.")
}

// smaller structs without unnecesary information for faster decoding
struct UserPart {
	id					string
}
struct MessagePart {
	id					string
	channel_id			string
	guild_id			string
	content				string
	author				UserPart
	timestamp			string
	mentions			[]UserPart
}

fn on_message_create(app mut App, c viscord.Connection, packet &viscord.DiscordPacket) {
	// for some reason c is corrupted so use the connection provided by app instead.

	message := json.decode(MessagePart, packet.d) or {
		println('failed to parse message')
		return
	}

	unix := discord.parse_timestamp(message.timestamp).unix

	if app.mutes[message.author.id] == true {
		if unix - app.mutestamps[message.author.id].last() > 10 {
			app.mutes[message.author.id] = false
		} else {
			app.c.delete_message(message.channel_id, message.id) or {}
		}
	}

	mut arr := app.timestamps[message.author.id]
	if arr.len >= 5 {
		arr[0] = arr[1]
		arr[1] = arr[2]
		arr[2] = arr[3]
		arr[3] = arr[4]
		arr[4] = unix
	} else {
		arr << unix
	}
	app.timestamps[message.author.id] = arr

	if arr.len >= 5 && unix - arr[0] < 120 {
		app.mutes[message.author.id] = true
		mut marr := app.mutestamps[message.author.id]
		marr << unix
		app.mutestamps[message.author.id] = marr
		if marr.len >= 3 && unix - marr[0] < 1800 {
			app.c.ban_member(message.guild_id, message.author.id, viscord.RestBan{
				reason: 'auto - spam',
				delete_message_days: 1
			}) or {}
		}
		return
	}

	if app.owners.index(message.author.id) > -1 {
		if message.content.starts_with('vis unmute') {
			if message.mentions.len == 0 {
				app.c.send_message(message.channel_id, viscord.RestMessage{
					content: "",
					_embed: discord.Embed {
						description: "🚫 You didn't mention anyone to unmute!",
						color: 13060682
					}
				}) or {}
				return
			}
			app.mutes[message.mentions[0].id] = false
			mut marr := app.mutestamps[message.mentions[0].id]
			if marr.len > 0 {
				marr = marr[0..marr.len-1]
				app.mutestamps[message.mentions[0].id] = marr
			}
			app.c.send_message(message.channel_id, viscord.RestMessage{
				content: "",
				_embed: discord.Embed {
					description: "✅ Unmuted <@${message.mentions[0].id}>",
					color: 4900682
				}
			}) or {}
		}
	}
}
