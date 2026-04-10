const CARD_ICON_KEYS = {
  1: 'move',
  2: 'turn-left',
  3: 'turn-right',
  4: 'attack',
  5: 'sprint',
  6: 'shoot',
  7: '180',
  8: 'strafe-left',
  9: 'strafe-right',
  10: 'sweep',
  11: 'slam',
  12: 'shockwave',
  13: 'disorient',
}

export function getCardIconKey(card) {
  const typeId = Number(card?.typeId ?? card?.type ?? -1)
  if (CARD_ICON_KEYS[typeId]) {
    return CARD_ICON_KEYS[typeId]
  }

  const name = String(card?.name ?? '').toLowerCase()
  if (name.includes('strafe') && name.includes('left')) {
    return 'strafe-left'
  }
  if (name.includes('strafe') && name.includes('right')) {
    return 'strafe-right'
  }
  if (name.includes('left')) {
    return 'turn-left'
  }
  if (name.includes('right')) {
    return 'turn-right'
  }
  if (name.includes('sweep')) {
    return 'sweep'
  }
  if (name.includes('slam')) {
    return 'slam'
  }
  if (name.includes('shockwave')) {
    return 'shockwave'
  }
  if (name.includes('disorient')) {
    return 'disorient'
  }
  if (name.includes('attack')) {
    return 'attack'
  }
  if (name.includes('shoot')) {
    return 'shoot'
  }
  if (name.includes('sprint') || name.includes('rush')) {
    return 'sprint'
  }
  if (name.includes('180') || name.includes('spin') || name.includes('u-turn')) {
    return '180'
  }

  return 'move'
}

export function getArchetypeIconKey(archetypeKey) {
  switch (archetypeKey) {
    case 'brawler': return 'brawler'
    case 'sniper':  return 'sniper'
    case 'snake':   return 'snake'
    default:        return 'brawler'
  }
}
