import { Hono } from 'hono'
import { z } from 'zod'
import { zValidator } from '@hono/zod-validator'
import { auth } from '../middleware.ts';
import db from '../db/index.ts';
import { count, eq } from 'drizzle-orm';
import { type ProfileId, profiles, type UserId } from '../db/schema.ts';

type Variables = {
  user_id: string
}

const app = new Hono<{ Variables: Variables }>();

const CreateClassInput = z.object({
    name: z.string(),
    class: z.enum([
        "warrior",
        "ranger",
        "berserker",
        "mutant",
        "rogue"
    ]),
});

app.post('/', 
    auth,
    zValidator(
        'json',
        CreateClassInput
    ),
    async (c, next) => {
        const user_id = c.get('user_id');
		const v = c.req.valid('json');

        const [res] = (await db.select({ count: count() })
            .from(profiles)
            .where(eq(profiles.user_id, user_id as UserId)));
        
        const profileCount = res.count;

        if (profileCount >= 3) {
            return c.body(null, 400);
        }

        const [profile] = (await db.insert(profiles).values({
            user_id: user_id as UserId,
            class: v.class,
            name: v.name,
        }).returning());


        return c.json({
            data: profile
        }, 201);
    }
);

app.get('/', auth, async (c, next) => {
    const user_id = c.get('user_id');

    const data = await db.select()
        .from(profiles)
        .where(eq(profiles.user_id, user_id as UserId));

    return c.json({
        data
    });
});

app.delete('/:id', auth, async (c, next) => {
    const user_id = c.get('user_id');
    const id = c.req.param('id');

    await db.delete(profiles).where(eq(profiles.id, id as ProfileId));

    return c.body(null, 204);
});

export default app;