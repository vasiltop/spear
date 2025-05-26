import { Hono } from 'hono'
import { z } from 'zod'
import { zValidator } from '@hono/zod-validator'

const app = new Hono();

const ServerInput = z.object({
	ip: z.string(),
	port: z.number(),
	name: z.string(),
});

const Server = ServerInput.extend({ 
	last_ping: z.coerce.date(),
});

type Server = z.infer<typeof Server>;
const servers = new Map<string, Server>();

app.get('/', (c) => {
	const serverList = Array.from(servers.values())
	return c.json({
		data: serverList
	});
});

app.post('/',
	zValidator(
		'json',
		ServerInput
	),
	(c) => {
		const v = c.req.valid('json');

		console.log(servers);
		if (servers.has(v.name)) {
			servers.get(v.name)!.last_ping = new Date();
			console.log("Received ping from server: " + v.name);
			return c.body(null, 201);
		}

		const server: Server = {
			ip: v.ip,
			port: v.port,
			name: v.name,
			last_ping: new Date(),
		}

		console.log("Adding server: " + v.name);
		servers.set(v.name, server);

		return c.body(null, 201);
	}
)

setInterval(checkServerHealth, 1000 * 10); // check every 3 seconds

const SERVER_HEALTH_TIMER = 1000 * 60 // server must be down for 1 minute

function checkServerHealth() {
	const d = Date.now();
	const latest = d - SERVER_HEALTH_TIMER;

	for (const [name, server] of servers) {
		if (server.last_ping.getTime() < latest) {
			servers.delete(name);
			console.log("Removed server: " + name);
		}
	}
}

export default app;
