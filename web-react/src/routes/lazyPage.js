import { lazy } from 'react'

/** Give the branded loader a brief moment on the first load of each page. */
export default function lazyPage(loadPage) {
  return lazy(async () => {
    const [page] = await Promise.all([
      loadPage(),
      new Promise((resolve) => setTimeout(resolve, 1200)),
    ])
    return page
  })
}
