// Генерируем тег banned из JSON при загрузке тегов
ServerEvents.tags('item', event => {
    let state = JsonIO.read('kubejs/config/banned_items.json')
    if (!state || !state.banned) return

    state.banned.forEach(id => {
        event.add('kubejs:banned', String(id))
    })
})