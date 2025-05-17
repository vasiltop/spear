import { serve } from '@hono/node-server'
import { Hono } from 'hono'
import { validator } from 'hono/validator'
import { z } from 'zod'
import { zValidator } from '@hono/zod-validator'

const app = new Hono();

const ServerInput = z.object({
	ip: z.string(),
	port: z.number(),
	name: z.string() 
});

const Server = ServerInput.extend({last_ping: z.string().datetime()});

type Server = z.infer<typeof Server>;
const servers = new Map<string, Server>();

app.get('/', (c) => {
	const rows = Array.from(servers.values())
  return c.json({data: rows});
})

app.post('/',
	zValidator(
    'json',
		ServerInput	
  ),
	(c) => {
		const v = c.req.valid('json');

		if (servers.has(v.name)) {
			servers.get(v.name).last_ping = Date.now();
			console.log("Received ping from server: " + v.name);
			return c.body(null, 201);
		}

		const server: Server = {
			ip: v.ip,
			port: v.port,
			name: v.name,
			last_ping: Date.now(),
		}

		console.log("Adding server: " + v.name);
		servers.set(v.name, server);
		return c.body(null, 201);
	}
)

setInterval(checkServerHealth, 1000 * 1);

const SERVER_HEALTH_TIMER = 1000 * 1 * 3

function checkServerHealth() {
	const d = Date.now();
	const latest = d - SERVER_HEALTH_TIMER;

	for (const [name, server] of servers) {
		if (server.last_ping < latest) {
			servers.delete(name);
			console.log("Removed server: " + name);
		}
	}
}

serve({
  fetch: app.fetch,
  port: 3000
}, (info) => {
  console.log(`Server is running on http://localhost:${info.port}`)
})
