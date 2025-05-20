import db from './db/index.ts'
import { createMiddleware } from 'hono/factory';
import { type SessionId, sessions } from './db/schema.ts';
import { eq } from 'drizzle-orm';

export const auth = createMiddleware(async (c, next) => {
    const session_id = c.req.header('session-id');
    
    if (!session_id) {
        return c.body(null, 401);
    }

    const [user] = (await db.select()
        .from(sessions)
        .where(eq(sessions.id, session_id as SessionId)).limit(1));

    c.set('user_id', user.user_id);

    return next();
});