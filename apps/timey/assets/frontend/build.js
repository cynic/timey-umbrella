const esbuild = require('esbuild');
const ElmPlugin = require('esbuild-plugin-elm');

const isProduction = process.env.MIX_ENV === "prod"

async function watch() {
  const ctx = await esbuild.context({
    entryPoints: ['main.js', 'debug.js'],
    bundle: true,
    outdir: '../js',
    format: 'esm',
    plugins: [
      ElmPlugin({
        debug: true
      }),
    ],
  }).catch(_e => process.exit(1))
  await ctx.watch()
}


async function build() {
  await esbuild.build({
    entryPoints: ['main.js'],
    bundle: true,
    format: 'esm',
    minify: true,
    outdir: '../js',
    plugins: [
      ElmPlugin(),
    ],
  }).catch(_e => process.exit(1))
}

if (isProduction)
  build()
else
  watch()