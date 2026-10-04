import { createServer } from 'vite'

const server = await createServer({ server: { middlewareMode: true, hmr: false } })
try {
  const { verifySupportWorkflow } = await server.ssrLoadModule('/tests/support-workflow.render.jsx')
  await verifySupportWorkflow()
} finally {
  await server.close()
}
