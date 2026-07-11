ItemEvents.tooltip(event => {
    event.addAll(item => {
        if (item.hasTag('kubejs:banned')) {
            return [Component.red('ЗАБАНЕН').bold(true)]
        }
        return []
    })
})