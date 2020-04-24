module viscord
import net.http
import discord
import json

pub struct RestMessage {
	content	string
}
pub fn (c Connection) send_message(cid string, m RestMessage) ?http.Response {
	return c.post("channels/${cid}/messages", json.encode(m))
} 

fn (c Connection) post(p string, data string) ?http.Response {
	mut headers := map[string]string
	headers['authorization'] = "Bot $c.token"
	headers['content-type'] = 'application/json'

	res := http.fetch("https://discordapp.com/api/v6/$p", http.FetchConfig{
		method: "post",
		headers: headers,
		data: data
	})
	return res
}