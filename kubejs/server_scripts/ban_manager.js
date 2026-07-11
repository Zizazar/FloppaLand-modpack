const BAN_FILE = 'kubejs/config/banned_items.json'
const BAN_TAG = 'kubejs:banned'

function loadBans() {
    let data = JsonIO.read(BAN_FILE)
    if (!data || !data.banned) {
        data = { banned: [], tag_keep: {} }
        JsonIO.write(BAN_FILE, data)
    }
    let banned = []
    data.banned.forEach(i => banned.push(String(i)))
    let tagKeep = {}
    if (data.tag_keep) for (let k in data.tag_keep) tagKeep[k] = String(data.tag_keep[k])
    return { banned: banned, tag_keep: tagKeep }
}

function saveBans(state) {
    JsonIO.write(BAN_FILE, { banned: state.banned, tag_keep: state.tag_keep })
}

// Проверка через тег — работает и на сервере (тег уже загружен)
function isBanned(itemStack) {
    if (!itemStack || itemStack.isEmpty()) return false
    return itemStack.hasTag(BAN_TAG)
}
global.isItemBanned = isBanned

// ---------- КОМАНДЫ ----------
ServerEvents.commandRegistry(event => {
    const { commands: Commands, arguments: Arguments } = event

    event.register(
        Commands.literal('itemban')
            .requires(src => src.hasPermission(2))

            .then(Commands.literal('add')
                .then(Commands.argument('item', Arguments.ITEM_STACK.create(event))
                    .executes(ctx => {
                        let stack = Arguments.ITEM_STACK.getResult(ctx, 'item').createItemStack(1, false)
                        let id = String(stack.id)
                        let state = loadBans()
                        if (state.banned.indexOf(id) === -1) {
                            state.banned.push(id)
                            saveBans(state)
                            ctx.source.sendSuccess(Component.green('Забанен: ' + id), false)
                            ctx.source.sendSuccess(Component.gray('Выполни /reload для применения'), false)
                        } else {
                            ctx.source.sendFailure(Component.yellow('Уже забанен: ' + id))
                        }
                        return 1
                    })))

            .then(Commands.literal('remove')
                .then(Commands.argument('item', Arguments.ITEM_STACK.create(event))
                    .executes(ctx => {
                        let stack = Arguments.ITEM_STACK.getResult(ctx, 'item').createItemStack(1, false)
                        let id = String(stack.id)
                        let state = loadBans()
                        let idx = state.banned.indexOf(id)
                        if (idx !== -1) {
                            state.banned.splice(idx, 1)
                            saveBans(state)
                            ctx.source.sendSuccess(Component.green('Разбанен: ' + id), false)
                            ctx.source.sendSuccess(Component.gray('Выполни /reload'), false)
                        } else {
                            ctx.source.sendFailure(Component.yellow('Не был забанен: ' + id))
                        }
                        return 1
                    })))

            .then(Commands.literal('list')
                .executes(ctx => {
                    let state = loadBans()
                    if (state.banned.length === 0) {
                        ctx.source.sendSuccess(Component.gray('Список банов пуст'), false)
                    } else {
                        ctx.source.sendSuccess(Component.gold('Забанено (' + state.banned.length + '):'), false)
                        state.banned.forEach(id => ctx.source.sendSuccess(Component.red(' - ' + id), false))
                    }
                    return 1
                }))

            .then(Commands.literal('bantag')
                .then(Commands.argument('tag', Arguments.STRING.create(event))
                    .then(Commands.argument('keep', Arguments.ITEM_STACK.create(event))
                        .executes(ctx => {
                            let tag = Arguments.STRING.getResult(ctx, 'tag')
                            let keepStack = Arguments.ITEM_STACK.getResult(ctx, 'keep').createItemStack(1, false)
                            let keepId = String(keepStack.id)
                            let ids = Ingredient.of('#' + tag).stacks.map(s => String(s.id))
                            let state = loadBans()
                            let count = 0
                            ids.forEach(id => {
                                if (id !== keepId && state.banned.indexOf(id) === -1) {
                                    state.banned.push(id)
                                    count++
                                }
                            })
                            state.tag_keep[tag] = keepId
                            saveBans(state)
                            ctx.source.sendSuccess(Component.green('Тег #' + tag + ': забанено ' + count + ', оставлен ' + keepId), false)
                            ctx.source.sendSuccess(Component.gray('Выполни /reload'), false)
                            return 1
                        }))))
    )
})

// ---------- ЗАПРЕТЫ ---------- (проверка через тег)

BlockEvents.placed(event => {
    if (isBanned(event.item)) {
        event.cancel()
        if (event.player) event.player.tell(Component.red('Этот предмет забанен'))
    }
})

ItemEvents.dropped(event => {
    if (isBanned(event.item)) {
        event.cancel()
        if (event.player) event.player.tell(Component.red('Забаненный предмет нельзя выбросить'))
    }
})

BlockEvents.broken(event => {
    if (event.player && isBanned(event.player.mainHandItem)) {
        event.cancel()
        event.player.tell(Component.red('Нельзя ломать блоки забаненным инструментом'))
    }
})

PlayerEvents.tick(event => {
    let player = event.player
    if (!player.isServerPlayer()) return
    if (player.age % 20 !== 0) return
    player.inventory.allItems.forEach((stack, i) => {
        if (isBanned(stack)) player.inventory.setItem(i, Item.empty)
    })
})