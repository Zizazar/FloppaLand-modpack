ServerEvents.recipes(event => {
    event.remove({ output: '#kubejs:banned' })
    event.remove({ input: '#kubejs:banned' })

    let state = JsonIO.read('kubejs/config/banned_items.json')
    if (state && state.tag_keep) {
        for (let tag in state.tag_keep) {
            let keepId = String(state.tag_keep[tag])
            event.replaceInput({ input: '#' + tag }, '#' + tag, keepId)
        }
    }
})