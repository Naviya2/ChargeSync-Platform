import { createResourceApi } from './createResourceApi'

const base = '/charging-plans'

export const chargingPlansApi = {
  ...createResourceApi(base),
}

export default chargingPlansApi
