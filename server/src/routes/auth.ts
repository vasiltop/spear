import { Hono } from 'hono';
import { setCookie } from 'hono/cookie';
import db from '../db/index.ts'
import { z } from 'zod'
import argon2 from 'argon2'
import { zValidator } from '@hono/zod-validator'
import { sessions, users } from '../db/schema.ts'
import { eq } from 'drizzle-orm';
import pg from "pg";
import { auth } from '../middleware.ts';

type Variables = {
  user_id: string
}

const app = new Hono<{ Variables: Variables }>();

const RegisterInput = z.object({
	email: z.string(),
	username: z.string(),
	password: z.string(),
})

app.post('/register',
	zValidator(
		'json',
		RegisterInput
	),
	async (c) => {
		const v = c.req.valid('json');

		try {
			const hash = await argon2.hash("password");

			await db.insert(users).values({
				username: v.username,
				email: v.email,
				password: hash,
			});
		} catch (err) {

			if (err instanceof pg.DatabaseError) {
				console.log(err)
				if (err.constraint === 'users_username_unique' || err.constraint === 'users_email_unique') {
					return c.body(null, 409);
				}
			}
			return c.body(null, 500);
		}

		return c.body(null, 201);
	}
)

const LoginInput = z.object({
	username: z.string(),
	password: z.string(),
})

app.post('/login',
	zValidator(
		'json',
		LoginInput
	),
	async (c) => {
		const v = c.req.valid('json');
		const [user] = await db.select().from(users).where(eq(users.username, v.username)).limit(1);

		if (!user) {
			return c.body(null, 401);
		}

		try {
			if (await argon2.verify(user.password, v.password)) {
				const [session] = await db.insert(sessions).values({
					user_id: user.id,
					expires_at: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // one year
				}).returning({ id: sessions.id });

				setCookie(c, 'sessionId', session.id)
				return c.json({
					session_id: session.id,
				});
			} else {
				return c.body(null, 401);
			}
		} catch (err) {
			console.log(err);
			return c.body(null, 500);
		}
	}
);

app.get('/me', auth, async (c) => {
	return c.json({
		user_id: c.get('user_id'),
	});
});


export default app;