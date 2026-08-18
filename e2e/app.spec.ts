import { test, expect, _electron as electron } from '@playwright/test'

test('app launches and shows a window', async () => {
  const app = await electron.launch({ args: ['out/main/index.js'] })
  const window = await app.firstWindow()
  expect(await window.title()).toBeTruthy()
  await app.close()
})