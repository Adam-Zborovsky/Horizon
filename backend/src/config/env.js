const zod = require('zod');
const dotenv = require('dotenv');

dotenv.config();

const envSchema = zod.object({
  PORT: zod.string().default('3001'),
  NODE_ENV: zod.enum(['development', 'production', 'test']).default('development'),
  MONGODB_URI: zod.string().url(),
  API_PREFIX: zod.string().default('/api/v1'),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('❌ Invalid environment variables:', parsed.error.format());
  process.exit(1);
}

module.exports = parsed.data;
